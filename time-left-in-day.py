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
    print(f"Doing this source registry:")
    source_registry.debug_dump()
    if not source_registry:
        print("ERROR: Unable to get calendar events")
        sys.exit(1)
    #sources = EDataServer.SourceRegistry.list_sources(source_registry, EDataServer.SOURCE_EXTENSION_CALENDAR)
    #sources = [s for s in sources if s.has_extension("Calendar")]
    sources = source_registry.list_enabled("Calendar")
    sources = [source for source in sources if source.get_display_name() not in ("Birthdays", "Birthdays & Anniversaries", "Holidays in United States")]

    print({source.get_display_name(): source for source in sources})

    # TODO: Filter obviously bad calendars, like Birthdays and Hllidays
    # TODO: This asynchronously

    clients = []
    #print("Sources in order:")
    for source in sources:
        client = ECal.Client.connect_sync(source, ECal.ClientSourceType.EVENTS, 15, None)
        if client:
            #print(client)
            print(f"Found source: {source.get_display_name()}")
            clients.append(client)
        else:
            print(f"Err: Could not get client for {source.get_display_name()}")

    while len(clients) < len(sources):
        await asyncio.sleep(0.01)
        #print("waiting for clients to connect...")

    print(f"found {len(sources)} sources and {len(clients)} clients")
    return clients

async def get_calendar_events_between_times(clients: list, start_datetime: datetime, end_datetime: datetime):
    result_events = []

    print(f"get_calendar_events_between_times Passed {len(clients)} clients")

    # TODO: Do time zone dynamically
    time_format = "%Y%m%dT%H%M%S"

    # Example S-Expression from https://mail.gnome.org/archives/evolution-hackers/2022-March/msg00001.html:
    # (occur-in-time-range? (make-time "20220227T230000Z") (make-time "20220410T000000Z") "Europe/Prague")
    sexp = f"(occur-in-time-range? (make-time \"{start_datetime.strftime(time_format)}\") (make-time \"{end_datetime.strftime(time_format)}\") \"America/Denver\" )"
    print(f"******* sexp = {sexp}")
    for client in clients:
        print("----------------------")
        print(f"Checking client {client}")

        events_from_this_client = []

        # Get list of ECalComponents from the given calendar/client
        result, events_from_this_client = client.get_object_list_sync(sexp, None)
        if result:
            for event in events_from_this_client:
                #if not event.get_dtstart():
                #    continue

                print(f"))))))Found event {event}")
                print(f"))))))Summary: {event.get_summary()}, Starts: {event.get_dtstart().get_time()}")
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

    # These come out as ResultTuples, like `(hour=8, minute=0, second=0)`. Strip the `foo=`
    start_time = (start_time.hour, start_time.minute, start_time.second)
    end_time = (end_time.hour, end_time.minute, end_time.second)

    #print(f"in event_to_time_block_tuple for event starting at {event.get_dtstart().get_time()} and ending at {event.get_dtend().get_time()}: type= {type(start_time)} start_time = {start_time}, end_time = {end_time}")

    #print(f"In event_to_time_block_tuple, returning {[start_time, end_time]}")
    return [start_time, end_time]

def difference_between_hms_tuples(start, later) -> tuple:
    """Takes two hms tuples and returns the difference between them in an hms tuple"""
    hours   = later[0] - start[0]
    minutes = later[1] - start[1]
    seconds = later[2] - start[2]
    print(f"Difference between start={start}, later={later} = ({hours}, {minutes}, {seconds})")
    return (hours, minutes, seconds)

def consolidate_events_into_commitment_blocks(commitments: list):
    """Takes a list of calendar events and combine any overlaps into a list of
    commitment blocks. They take this form:
        [ [(start_h, start_m, start_s), (end_h, end_m, end_s),
        ...
        ]
    Example: I have appointments from 9:30 - 10:30, 10:00 - 11:00, and 3:15-4:00.
    My `committed_blocks` would look like this:
    [ ((9, 30, 0), (11, 0, 0)),
     ((3, 15, 0), (4,  0, 0)) ]
    """
    # Trivial case
    if len(commitments) < 1:
        return []

    committed_blocks = []

    ## Since there is at least one event on the calendar, do this
    ## Take the first event as a starting point for your committed time blocks.
    #committed_blocks = [event_to_time_block_tuple(commitments[0])]
    #for event in commitments:
    #    (start_in_localtime, end_in_localtime) = event_to_time_block_tuple(event)
    #    if (0,0,0) == difference_between_hms_tuples(start_in_localtime, end_in_localtime):
    #        event.remove(event)
    #        eprint("\t-> Skipping due to duration of zero")
    #        continue


    for event in commitments:
        (start_in_localtime, end_in_localtime) = event_to_time_block_tuple(event)

        eprint(f"-> Description: '{event.get_summary()}' Begins: {start_in_localtime}, Ends: {end_in_localtime}")
        # TODO: Check if we're actually busy during these. Or does that happen upstream?

        # Skip all-day events, or events with 0 duration.
        if (0,0,0) == difference_between_hms_tuples(start_in_localtime, end_in_localtime):
            eprint("\t-> Skipping due to duration of zero")
            continue

        # If we went through all the blocks and there was no overlap, we need to add
        # this event to our blocks.
        was_event_handled = False

        # Take the first one as a reference. For each subsequent event, check for overlap.
        # Merge if overlap occcurs.
        for block in committed_blocks:
            # This is for my own sanity. It will catch if I missed an edge
            # case so I can fix it later.
            was_case_handled = False

            # Is it easier to detect not overlapping and avoid that.
            if end_in_localtime < block[0] or start_in_localtime > block[1]:
                print(f"==> No overlap. Block remains {block}")
                # No overlap
                was_case_handled = True
                was_event_handled = False
            else:
                # There is overlap.
                block[0] = min(block[0], start_in_localtime)
                block[1] = max(block[1], end_in_localtime)
                print(f"==> Dealt with overlap. Now block = {block}")
                was_case_handled = True
                was_event_handled = True

            if not was_case_handled:
                eprint("ERROR! Unexpected edge case!")
                eprint(f"start_in_localtime = {start_in_localtime}, end_in_localtime = {end_in_localtime}, committed_blocks = {committed_blocks}, events = {commitments}")
                sys.exit(10)
        if not was_event_handled:
            # Add to committed_blocks.
            committed_blocks.append([start_in_localtime, end_in_localtime])
            eprint("==> This event has no overlap with any blocks. Adding to blocks list.")
            eprint(f"==> blocks now = {committed_blocks}")
            
    return committed_blocks

def available_hours_until(commitments: list, start_time: datetime, end_time: datetime):
    """Gets the number of hours from now until `end_time`, minus any `commitments`
    on your calendar. This takes into account edge cases like double booking, but
    nothing tricky with timezones."""

    committed_blocks = consolidate_events_into_commitment_blocks(commitments)
    print(f"~~~> Committed blocks = {committed_blocks}")
    # Iterate over the list and subtract committed blocks from the available number
    # of hours left on the clock.
    clock_hours = (end_time - start_time).total_seconds() / 3600.0
    start_time_tuple = datetime_to_hms_tuple(start_time)
    end_time_tuple = datetime_to_hms_tuple(end_time)
    print(f"Checking dead time between {start_time_tuple} and {end_time_tuple}")
    for block in committed_blocks:
        # Clamp end of examination time to the start_time and end_time
        print(f"::Checking fresh block {block}")
        if block[0] < start_time_tuple:
            block[0] = start_time_tuple

        if block[1] > end_time_tuple:
            block[1] = end_time_tuple
        
        print(f"::Checking clamped block {block}")
        length_of_time_block = difference_between_hms_tuples(block[0], block[1])
        length_of_time_block = hms_tuple_to_fractional_hours(length_of_time_block)
        length_of_time_block = abs(length_of_time_block)

        print(f"Taking off {length_of_time_block} hours because this block coincides with our start time: {block}. Clock hours was {clock_hours}.")

        clock_hours = clock_hours - length_of_time_block
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
