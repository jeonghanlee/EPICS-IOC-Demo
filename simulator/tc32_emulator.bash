#!/usr/bin/env bash
#
#  The program is free software: you can redistribute
#  it and/or modify it under the terms of the GNU General Public License
#  as published by the Free Software Foundation, either version 2 of the
#  License, or any newer version.
#
#  This program is distributed in the hope that it will be useful, but WITHOUT
#  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
#  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
#  more details.
#
#  You should have received a copy of the GNU General Public License along with
#  this program. If not, see https://www.gnu.org/licenses/gpl-2.0.txt
#
#  Usage: ./tc_emulator.bash                (uses default port)
#         ./tc_emulator.bash --port 9399    (uses 9399 port)
#
# - author : Jeong Han Lee, Dr.rer.nat.
# - email  : jeonglee@lbl.gov
#

set -e  # Exit immediately if a command exits with a non-zero status

declare -a temps  # Declare an array to hold temperature values

# Check required commands are available
for cmd in socat bc mktemp; do
  command -v $cmd >/dev/null 2>&1 || { printf "%s is required\n" "$cmd"; exit 1; }
done

DEFAULT_PORT="9399"
PORT=""

# Parse command-line arguments for custom port
while [[ $# -gt 0 ]]; do
  case $1 in
    --port)
        if [[ -z "$2" || "$2" =~ ^-- ]]; then
            printf "Error: --port requires a value.\nUsage: %s [--port PORT]\n" "$0"
            exit 1
        fi
        PORT="$2";
        shift 2
        ;;
    *)
        printf "Unknown option: %s\nUsage: %s [--port PORT]\n" "$1" "$0";
        exit 1
        ;;
  esac
done

PORT="${PORT:-$DEFAULT_PORT}"

SOCAT_LOG=$(mktemp)

# Start socat in the background to create a PTY and listen on TCP port
socat -d -d PTY,raw,echo=0 TCP-LISTEN:$PORT,reuseaddr,fork 2>&1 | tee "$SOCAT_LOG" &
SOCAT_PID=$!  # Store the PID of the socat process

function cleanup
{
  kill "$SOCAT_PID" 2>/dev/null
  rm -f "$SOCAT_LOG"
}
trap cleanup EXIT

# Wait for the PTY device to appear (poll every second, up to 20 times)
SERIAL_DEV=""  # Initialize variable for PTY device path
for i in {1..20}; do
  SERIAL_DEV=$(grep -o '/dev/pts/[0-9]*' "$SOCAT_LOG" | tail -1)  # Search for PTY path in socat log
  [ -n "$SERIAL_DEV" ] && break  # Break if PTY device found
  sleep 1  # Wait 1 second before retrying
done

# If PTY device was not found, print error and exit
if [ -z "$SERIAL_DEV" ]; then
  printf "Failed to detect PTY device from socat.\n"
  if kill -0 "$SOCAT_PID" 2>/dev/null; then
    kill "$SOCAT_PID"
  fi
  exit 1
fi

printf "Emulator running on port %s\n" "$PORT"
printf "Serial emulated at: %s\n" "$SERIAL_DEV"

# Initialize temperature array with random values between 10 and 90
# $RANDOM generates a new random number in the range [0, 32767]
for i in $(seq 0 31); do
  #temps[$i]=$(echo "scale=1; 10 + ($RANDOM/32767)*80" | bc)
  temps[$i]=$(echo "scale=1; 10+$(($i % 4))*25+($RANDOM/32767)" | bc)
done

# Function to generate a new temperature or error for a channel
function generate_temp
{
  local idx=$1  # Channel index (0-based)
  # Generate a random float between 0 and 1
  local rand=$(echo "scale=4; $RANDOM/32767" | bc)
  local change;
  local current_temp;
  local new_temp;

  # Generate a small random change between -0.75 and 0.75
  change=$(echo "scale=4; ($RANDOM/32767 - 0.5) * 1.5" | bc)
  current_temp=${temps[$idx]}
  #new temp between 10 and 90
  new_temp=$(echo "scale=1; t=$current_temp+$change; if (t<10) t=10; if (t>90) t=90; t" | bc)
  temps[$idx]=$new_temp
  printf "%s\n" "$new_temp"
}

previous_time=$(date +%s.%N)
# Main loop: update and send temperature readings forever
#
while true; do
  for i in $(seq 1 32); do
#    Each generate_temp takes around between 0.006 sec and 0.015 seconds
#    Each Channel should be updated around between 0.192 and 0.48 seconds
#    So, we expect to see that time difference will be between +0.2 and +0.5 via
#    camonitor -t sI PVNAME
#    PVNAME         +0.410798 17.5535
#    PVNAME         +0.366885 18.2611
#    PVNAME         +0.346312 17.7282
#    PVNAME         +0.413986 18.1144
#
    current_time=$(date +%s.%N)
    time_diff=$(echo "$current_time - $previous_time" | bc)
    val=$(generate_temp $((i - 1)))
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    printf "CH%02d: %s\n" "$i" "$val" > "$SERIAL_DEV"
#    printf "Δt=%ss CH%02d: %s\n" "$time_diff" "$i" "$val" > "$SERIAL_DEV"
    previous_time=$current_time
  done
done
