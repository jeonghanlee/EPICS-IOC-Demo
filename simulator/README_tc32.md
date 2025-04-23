# Training: Simulating a TC-32 Temperature Controller

This lesson introduces the `tc32_emulator.bash` script, designed to simulate the data output of a simple 32-channel temperature controller. Unlike a server that waits for commands, this emulator continuously pushes simulated data over a network connection, mimicking devices that stream readings. This is valuable for testing EPICS IOCs or other clients that need to parse such a data stream.

## Lesson Overview

In this lesson, you will learn to:

* Understand the purpose and function of the `tc32_emulator.bash` script.
* Identify the requirements and dependencies for running the script.
* Run the emulator, specifying default or custom ports.
* Observe the simulated data stream using tools like `socat` or `netcat`.
* Understand the data format and update cycle of the emulator.
* Manually run multiple instances on different ports.

## Requirements Recap

This lesson assumes you have:

* Access to a Linux environment with standard shell tools (bash).
* `socat` installed (for creating the TCP-PTY bridge).
* `bc` installed (for floating-point temperature simulation).
* `mktemp` installed (part of coreutils, usually present).

## The TC-32 Emulator Script (`tc32_emulator.bash`)

This script uses `socat` to create a network endpoint (TCP port) that emulates a serial device sending continuous temperature readings for 32 channels.

### Here is the code for `tc32_emulator.bash`:

```bash
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
#         ./tc_emulator.bash --port 12345   (uses 12345 port)
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

# Parse command-line arguments for custom port
while [[ $# -gt 0 ]]; do
  case $1 in
    --port)
        PORT="$2";
        shift 2
        ;;
    *)
        printf "Unknown option: %s\nUsage: %s [--port PORT]\n" "$1" "$0";
        exit 1
        ;;
  esac
done

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
  temps[$i]=$(echo "scale=1; 10 + ($RANDOM/32767)*80" | bc)
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

# Main loop: update and send temperature readings forever
while true; do
  for i in $(seq 1 32); do
    val=$(generate_temp $((i - 1)))
    printf "CH%02d: %s\n" "$i" "$val" > "$SERIAL_DEV"
  done
  sleep 2
done
```


### Make the script executable:

```
chmod +x tc32_emulator.bash
```

### How the Emulator Works

1. TCP-PTY Bridge (socat): The script starts socat to listen on a specific TCP port (default 9399). When a client connects, socat creates a pseudo-terminal (PTY) device (e.g., /dev/pts/5) and connects the TCP session to it. This makes the TCP connection look like a serial port to the rest of the system.

2. Temperature Simulation (bc):

* An internal array holds 32 temperature values.
* Temperatures are initialized randomly between 10.0 and 90.0.
* In each cycle, every temperature is updated with a small random change (±0.75), ensuring values stay within the 10.0-90.0 range.

3. Data Streaming:

* The script enters an infinite loop.
* It iterates through channels 1 to 32.
* For each channel, it gets the latest simulated temperature.
* It formats the data as CH<XX>: <TEMP>\n (e.g., CH01: 45.2\n).
* Crucially, it writes this string directly to the PTY device ($SERIAL_DEV).
* socat automatically forwards this data from the PTY to any connected TCP client.
* Timing: After writing all 32 channel readings, the script pauses for 2 seconds (sleep 2) before generating and sending the next batch.
* Cleanup: When you stop the script (Ctrl+C), it automatically kills the background socat process thanks to the trap command.

## Running the Emulator

Navigate to the directory containing the script in a terminal.

```bash
# Option 1: Run with default port (9399)
$ ./tc32_emulator.bash

# Option 2: Run with a custom port (e.g., 10001)
$ ./tc32_emulator.bash --port 10001
```

The script will print the port it's listening on and the PTY device path (e.g., /dev/pts/X). Leave the emulator running in this terminal.

## Testing / Observing the Emulator Output

Since this emulator sends data continuously, you connect to it to receive that data. Open another terminal window and use socat or netcat (nc).

### Using socat:

```shell
# Connect to the emulator running on localhost:9399
$ socat - TCP:localhost:9399
```

### Using netcat (nc):

```shell
# Connect to the emulator running on localhost:9399
nc localhost 9399
```

You should see the stream of CHXX: TEMP data appearing in your terminal, with a new block of 32 lines appearing every 2 seconds:

```
CH01: 17.9643
CH02: 26.4624
CH03: 17.4912
...
CH21: 49.5205
CH22: 34.6579
CH23: 66.5088
CH24: 58.4350
...
CH30: 82.5187
CH31: 33.3783
CH32: 10.5070
...
```

Disconnect the client (socat or nc) with Ctrl+C. Stop the emulator itself with Ctrl+C in its own terminal.


## Running Multiple Emulator Instances

While the underlying socat command uses fork (allowing multiple clients to connect and see the same data stream), the script itself manages only one stream of simulated data directed to the single PTY it detected. To simulate multiple independent TC-32 devices, you need to run multiple instances of the tc32_emulator.bash script, ensuring each uses a different TCP port.

1. Open multiple terminal windows. Navigate to the script directory in each.

2. Run the emulator in each terminal, specifying a unique port for each instance:

```shell
    # Terminal 1
    ./tc32_emulator.bash --port 10001

    # Terminal 2
    ./tc32_emulator.bash --port 10002
    ```shell
    # Terminal 3
    ./tc32_emulator.bash --port 10003
```

3. Test Each Instance: Use separate socat or nc terminals to connect to ports 10001, 10002, and 10003 respectively to observe their independent data streams.
4. Stopping Emulators: Use Ctrl+C in each terminal where an emulator instance is running.

## Conclusion

The `tc32_emulator.bash` script provides a convenient way to simulate a device that continuously streams data over a network connection. By using socat to bridge TCP to a PTY and having the script write simulated data to that PTY, it effectively mimics the behavior of certain types of hardware, making it a useful tool for testing and developing client applications like EPICS IOCs that need to parse specific data formats arriving periodically. Remember that unlike command-response servers, clients

