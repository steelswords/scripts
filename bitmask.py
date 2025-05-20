#!/usr/bin/env python3
# Author:      Tristan Andrus (steelswords)
# Description: Takes a bitmask and splits it into its constituent flags.
################################################################################

import argparse
import sys


class BitmaskDefinition:
    def __init__(self, definition_file_path: str):
        self._flags = {}

        with open(definition_file_path, 'r') as definition_file:
            line_no = 0
            for line in definition_file:
                line_no += 1

                line = line.strip()

                # Skip empty lines
                if not line:
                    continue

                # Skip comment lines
                if line.startswith('#'):
                    continue

                try:
                    parts = line.split();


                    if len(parts) < 2:
                        print(f"Warning: Line {line_no} is invalid: {line}")
                        continue

                    parameter_name = parts[0]
                    bit_position_in_hex = parts[1]

                    # Check if the hex value starts with 0x
                    if not bit_position_in_hex.startswith('0x'):
                        print(f"Warning: Hex value doesn't start with 0x: {bit_position_in_hex} in line {line_no}: {line}.  Skipping.")
                        continue

                    hex_value = int(bit_position_in_hex[2:], 16)  # Remove "0x" and convert to integer

                    self.add_flag(parameter_name, hex_value);

                except FileNotFoundError:
                    print(f"Error: File not found: {definition_file_path}")
                except Exception as e:
                    print(f"An unexpected error occurred: {e}")

    def add_flag(self, parameter_name, bit_position):
        self._flags[bit_position] = parameter_name

    def show_flags(self, value: int):
        # TODO: Support 64 bit bitmasks
        print("Enabled Flags:")

        for i in range(0, 31, 1):
            current_bit = value & (1 << i);
            if current_bit in self._flags:
                print(self._flags[current_bit])


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('bitmask_definition_file',
                        #type=argparse.FileType('r', encoding='utf-8'),
                        help='The path to the bitmask definition file, with each line defining a bit position and its value, e.g. `SUPER_COOL_FEATURE_ENABLED 0x1\nLESS_COOL_FEATURE_PATH 0x2\nSOMETHING_ELSE_FLAG 0x4`. Comment lines start with a `#` character.')

    parser.add_argument('--hex',
                        nargs=1,
                        type=str,
                        help='The bitmask value to decompose into its constituent flags as a hexadecimal value.')

    parser.add_argument('--dec',
                        type=str,
                        nargs=1,
                        help='The bitmask value to decompose into its constituent flags as a decimal value.')

    args = parser.parse_args()


    value = None
    if args.hex: # Parse hex input
        try:
            value = int(args.hex[0], 16)
        except ValueError:
            print(f"Invalid hexadecimal number: {args.hex}")
    elif args.dec: # Parse dec input
        try:
            value = int(args.dec[0])
        except ValueError:
            print(f"Invalid decimal number: {args.dec}")
    else: # Neither dec nor hex is passed. Exit with error.
        parser.print_help()
        sys.exit(1)


    bitmask_definition = BitmaskDefinition(args.bitmask_definition_file)
    bitmask_definition.show_flags(value)

    print("------------------------")

if __name__ == "__main__":
    main()
