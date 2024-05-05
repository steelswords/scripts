#!/usr/bin/python3

import asyncio
import tzlocal
from datetime import datetime, timezone, time
import gi # For calendar integration
#from ICalGLib import Timezone
import sys

gi.require_version("EDataServer", "1.2")
gi.require_version("ECal", "2.0")
from gi.repository import EDataServer, ECal, ICalGLib


def eprint(*args, **kwargs):
    print(*args, file=sys.stderr, **kwargs)

def time_left_until(target_time: datetime) -> str:
    now = datetime.now()

    time_left = target_time - now

    time_left_in_hours = time_left.total_seconds() / (60 * 60)

    return str(round(time_left_in_hours, 2))


def time_left_in_workday() -> str:
    # Easiest way to get "5pm today" is to replace the hour, second, and us in now()
    now = datetime.now()
    quitting_time = now.replace(hour=17, minute=0, second=0, microsecond=0)

    return time_left_until(quitting_time)

def main():
    print(time_left_in_workday())

async def get_calendar_clients():
    source_registry = EDataServer.SourceRegistry.new_sync(None)
    if not source_registry:
        print("ERROR: Unable to get calendar events")
        sys.exit(1)
    sources = source_registry.list_enabled(None)
    sources = [s for s in sources if s.has_extension("Calendar")]

    #print({source.get_display_name(): source for source in sources})

    # TODO: Filter obviously bad calendars, like Birthdays and Hllidays
    # TODO: This asynchronously

    clients = []
    #print("Sources in order:")
    for source in sources:
        client = ECal.Client.connect_sync(source, ECal.ClientSourceType.EVENTS, 15, None)
        if client:
            #print(client)
            #print(f"Found source: {source.get_display_name()}")
            clients.append(client)
        else:
            print(f"Err: Could not get client for {source.get_display_name()}")

    while len(clients) < len(sources):
        await asyncio.sleep(0.01)
        #print("waiting for clients to connect...")

    return clients

async def get_calendar_events_between_times(clients: list, start_datetime: datetime, end_datetime: datetime):
    result_events = []

    # TODO: Do time zone dynamically
    time_format = "%Y%m%dT%H%M%SZ"

    # Example S-Expression from https://mail.gnome.org/archives/evolution-hackers/2022-March/msg00001.html:
    # (occur-in-time-range? (make-time "20220227T230000Z") (make-time "20220410T000000Z") "Europe/Prague")
    sexp = f"(occur-in-time-range? (make-time \"{start_datetime.strftime(time_format)}\") (make-time \"{end_datetime.strftime(time_format)}\") \"America/Denver\" )"
    for client in clients:

        events_from_this_client = []

        # Get list of ECalComponents from the given calendar/client
        result, events_from_this_client = client.get_object_list_sync(sexp, None)
        if result:
            for event in events_from_this_client:
                if not event.get_dtstart():
                    continue

                #print(f"Found event {event}")
                #print(f"Summary: {event.get_summary()}, Starts: {starttime.get_time()}")
                result_events.append(event)

        # I have been informed this is deprecated
        #EDataServer.Client.util_free_object_slist(events_from_this_client)
    return result_events

def get_local_ical_timezone():
    local_timezone = tzlocal.get_localzone()
    ical_timezone = ICalGLib.Timezone.get_builtin_timezone(local_timezone.key)
    if not ical_timezone:
        raise Exception(f"ICal doesn't understand your weird timezone: \"{local_timezone.key}\"")
    return ical_timezone

def datetime_to_hms_tuple(value: datetime) -> tuple:
    """Yields a tuple of (hour, min, sec) from a datetime object"""
    return (value.hour, value.minute, value.second)

def hms_tuple_to_fractional_hours(value: tuple) -> float:
    """Yields the number of hours as a decimal from a tuple of (hours, min, sec)"""
    return value[0] + (value[1] / 60.0) + (value[2] / 3600.0)

def event_to_time_block_tuple(event) -> list:
    """Transmogrifies an ICal event into a list of the form
    [ (start_hour, start_min, start_sec), (end_hour, end_min, end_sec) ]"""

    calendar_local_timezone = get_local_ical_timezone()

    # get_time returns an (hour, min, sec) tuple
    start_time = event.get_dtstart().convert_to_zone(calendar_local_timezone).get_time()
    end_time = event.get_dtend().convert_to_zone(calendar_local_timezone).get_time()

    #print(f"In event_to_time_block_tuple, returning {[start_time, end_time]}")
    return [start_time, end_time]

def difference_between_hms_tuples(start, later) -> tuple:
    """Takes two hms tuples and returns the difference between them in an hms tuple"""
    hours   = min(0, later[0] - start[0])
    minutes = min(0, later[1] - start[1])
    seconds = min(0, later[2] - start[2])
    return (hours, minutes, seconds)


def available_hours_until(commitments: list, start_time: datetime, end_time: datetime):
    """Gets the number of hours from now until `end_time`, minus any `commitments`
    on your calendar. This takes into account edge cases like double booking, but
    nothing tricky with timezones."""

    # List of (hour, min, sec) tuples of commitments, but combined so double-bookings
    # just replace or append each other, rather than overlapping.
    # Example: I have appointments from 9:30 - 10:30, 10:00 - 11:00, and 3:15-4:00.
    # My `committed_blocks` would look like this:
    # [ ((9, 30, 0), (11, 0, 0)),
    #  ((3, 15, 0), (4,  0, 0)) ]
    committed_blocks = []

    eprint(f"It is {time_left_until(end_time)} hours until the end of the day.")

    # If there are no events, just return the trivial case
    if len(commitments) < 1:
        return (end_time - start_time).total_seconds() / 3600.0

    # If there is at least one event on the calendar, do this
    # Take the first event as a starting point for your committed time blocks.
    committed_blocks = [event_to_time_block_tuple(commitments[0])]
    for event in commitments[1:]:
        (start_in_localtime, end_in_localtime) = event_to_time_block_tuple(event)

        eprint(f"-> Description: '{event.get_summary()}' Begins: {start_in_localtime}, Ends: {event.get_dtend().get_time()}")
        # TODO: Check if we're actually busy during these. Or does that happen upstream?

        # Take the first one as a reference. For each subsequent event, check for overlap.
        # Merge if overlap occcurs.
        for block in committed_blocks:
            # This is for my own sanity. It will catch if I missed an edge
            # case so I can fix it later.
            was_case_handled = False
            # Is it easier to detect not overlapping?
            if end_in_localtime < block[0] or start_in_localtime > block[1]:
                # No overlap
                was_case_handled = True
            else:
                # There is overlap.
                block[0] = min(block[0], start_in_localtime)
                block[1] = max(block[1], end_in_localtime)
                was_case_handled = True



#            if start_in_localtime >= block[0] and start_in_localtime <= block[1]:
#                # Overlap.
#                print(
#f"""
#Detected overlap between this block: {block}
#                     and this event: Description: '{event.get_summary()}' Begins: {start_in_localtime}, Ends: {event.get_dtend().get_time()}
#  -> Event starts during the block.
#"""
#                      )
#                block[1] = max(block[1], end_in_localtime)
#                print(f"  -> modifying block to be {block}")
#                was_case_handled = True
#            if start_in_localtime <= block[1] and start_in_localtime <= block[0]:
#                print(
#f"""
#Detected overlap between this block: {block}
#                     and this event: Description: '{event.get_summary()}' Begins: {start_in_localtime}, Ends: {end_in_localtime}
#  -> Event ends after block.
#"""
#                )
#                # Overlap.
#                block[1] = max(block[1], start_in_localtime)
#                print(f"  -> modifying block to be {block}")
#                was_case_handled = True
#
#            if start_in_localtime > block[1] or end_in_localtime < block[0]:
#                # No overlap. Add this event as a separate block.
#                committed_blocks.append([start_in_localtime, end_in_localtime])
#                was_case_handled = True
#
            if not was_case_handled:
                eprint("ERROR! Unexpected edge case!")
                eprint(f"start_in_localtime = {start_in_localtime}, end_in_localtime = {end_in_localtime}, committed_blocks = {committed_blocks}, events = {commitments}")
                sys.exit(10)

    # Now the list of committed blocks is built.
    # Iterate over the list and subtract committed blocks from the available number
    # of hours left on the clock.
    clock_hours = (end_time - start_time).total_seconds() / 3600.0
    print("8888888888888888")
    print(f"committed_blocks = {committed_blocks}")
    print(f"datetime_to_hms_tuple(start_time) = {datetime_to_hms_tuple(start_time)}")
    for block in committed_blocks:
        if block[0] >= datetime_to_hms_tuple(start_time):

            # TODO: This line is wrong
            end_block_time = min(block[1], datetime_to_hms_tuple(end_time))
            start_block_time = max(block[0], datetime_to_hms_tuple(start_time))
            
            time_to_subtract = difference_between_hms_tuples(start=start_block_time, later=end_block_time)

            print(f"Taking off {hms_tuple_to_fractional_hours(time_to_subtract)} hours for chunk of comitted time {block}. Clock hours was {clock_hours}")

            clock_hours = clock_hours + hms_tuple_to_fractional_hours(time_to_subtract)
            print(f"Now clock hours is {clock_hours}")
    return clock_hours

async def test_main():
    today = datetime.now()
    beginning_time = today.replace(hour = 9, minute = 0, second = 0, microsecond = 0)
    end_time = today.replace(hour = 17, minute = 0, second = 0, microsecond = 0)

    clients = await get_calendar_clients()
    events = await get_calendar_events_between_times(clients, beginning_time, end_time)
    time_left = available_hours_until(events, start_time=beginning_time, end_time=end_time)
    print(time_left)


if __name__ == "__main__":

    #main()
    asyncio.run(test_main())
