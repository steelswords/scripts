#!/usr/bin/env python
# Name: firmware-dump-helper.py
# Description: Takes a hexprint of firmware, like from a uboot `md` command,
#              and assembles it into a single binary file.

import argparse

def line_matches_format(line: str) -> bool:
    return True

def main():
    parser = argparse.ArgumentParser(
            prog="Firmware Dump Helper",
            description = """Takes a hexprint of firmware, like from a uboot `md` command,
            and assembles it into a single file"""
            )
    parser.add_argument("input_file")
    parser.add_argument("output_file")

    args = parser.parse_args()

    with open(args.input_file, 'r') as input_file:
        with open(args.output_file, 'wb') as output_file:
            for line in input_file:
                if not line_matches_format(line):
                    print(f"Skipping invalid line: {line}")
                    break
                # Format assumed like this:
                #001cafe0: 8e 27 00 04 92 26 00 01 02 00 28 21 0c 07 29 c3    .'...&....(!..).
                #001caff0: 02 40 20 21 08 07 2c 0a 00 00 00 00 12 60 00 06    .@ !..,......`..
                #001cb000: 3c 02 80 49 8e 63 00 bc 8c 62 00 08 24 42 00 01    <..I.c...b..$B..

                chunks = line.split(' ')
                # Take elements 1-16 and convert that string.
                actual_data = chunks[1:17]
                try:
                    output_file.write(bytes.fromhex(''.join(actual_data)))
                except ValueError:
                    print(f"Error converting \"{actual_data}\" to hex bytes!")

if __name__ == "__main__":
    main()
