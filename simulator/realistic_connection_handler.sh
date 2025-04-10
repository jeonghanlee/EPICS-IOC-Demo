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
# - author : Jeong Han Lee, Dr.rer.nat.
# - email  : jeonglee@lbl.gov
#
#  This single script acts as a connection handler launched by tcpserver.bash.
#  IMPORTANT: It launches TWO independent loops in the background:
#  1. A loop that reads client input and sends back responses (Query/Response).
#  2. A loop that continuously streams simulated Geiger counter data.
#  Because both loops write to standard output concurrently, the connected
#  client will receive an INTERLEAVED mixture of both types of messages.

# --- Function for Query/Response Handling ---
# This function processes a single command received from the client
# and determines the appropriate response.
function sub_cmds
{
    local cmd="$1"; shift
    local response="";
    if [[ $cmd == "GetID?" ]]; then
        # If command is "GetID?", respond with the script's Process ID ($$).
        response="$$"
    elif [[ $cmd == "GetTemp?" ]]; then
        # If command is "GetTemp?", respond with a random integer 0-100.
        # RANDOM is a Bash variable; % 101 gives the remainder (0-100).
        response=$((RANDOM % 101))
    else
        # For any other command, simply echo the received command back.
        response=$cmd
    fi
    # Send response back to client
    printf "%s\n" "$response"
}

# --- Background Loop 1: Query/Response Input Handling ---
# This loop reads input from the client (stdin) line by line.
while IFS= read -r received_text; do
  # Echo the received line back to the client (stdout), followed by a newline
  # Using printf is generally safer than echo for arbitrary data
  sub_cmds "$received_text"
  # 'done <&0' explicitly redirects stdin (file descriptor 0) to the loop,
  # which is default for 'read' anyway.
  # The trailing '&' LAUNCHES THIS ENTIRE 'while read' LOOP IN THE BACKGROUND.
  # It will run concurrently with the code that follows.
done <&0 &


# --- Geiger Counter (GC) Simulation Setup ---
# The main script execution continues here IMMEDIATELY after launching the first loop.

# --- Configuration ---
lower_bound=0            # Minimum simulated CPS
upper_bound=10           # Maximum simulated CPS (Adjusted down for more realistic background)
GC_TUBE_FACTOR="0.0057"  # Conversion factor (uSv/h) / CPM for SBM-20 tube
sec_per_min=60           # Number of seconds in a minute, for CPM calculation.

# --- Initialization ---
sum_total_counts=0       # Running total of all simulated counts since start.
count_total_seconds=0    # Running total of seconds elapsed since start.
counts_this_minute=0     # Accumulator for counts within the current 60-second window.
cpm=0                    # Holds the Counts Per Minute calculated for the *last completed* minute.
# Calculate the range size for the RANDOM calculation once.
range_size=$((upper_bound - lower_bound + 1))


while true ; do

    # 1. Simulate Counts Per Second for this second
    # Generate a random number between 0 and range_size-1, then add lower_bound.
    cps=$(( (RANDOM % range_size) + lower_bound ))

    # 2. Update counters
    count_total_seconds=$((count_total_seconds + 1)) # Increment seconds counter.
    sum_total_counts=$((sum_total_counts + cps))     # Add current CPS to total counts.
    counts_this_minute=$((counts_this_minute + cps)) # Add current CPS to this minute's accumulator.

    # 3. Check if a full minute has passed to calculate CPM
    # Use modulo operator (%) to check if total seconds is a multiple of 60.
    if (( count_total_seconds > 0 && count_total_seconds % sec_per_min == 0 )); then
        # If a minute has passed, the accumulated counts IS the CPM for that minute.
        cpm=$counts_this_minute
        # Reset the accumulator for the next minute's calculation.
        counts_this_minute=0
    fi

    ######  Warning
    # This fomular IS NOT completely right, since I don't care it seriously
    # these numbers, so please don't use this information as "source of truth".
    #
    # Our goal is to make a simulator to generate a similar data format, which we can
    # handle through EPICS Asyn and StreamDevice within our training IOC.
    ######  Warning
    # 4. Calculate Dose Rate (uSv/hr)
    # Uses the 'cpm' value from the *last completed minute*.
    # 'bc' command is used for floating-point arithmetic (Bash handles integers only).
    # 'scale=4' sets precision for bc.
    uSv=$(echo "scale=4; $cpm * $GC_TUBE_FACTOR" | bc)

    # 5. Print the formatted data string to the client (stdout)
    # %3d: integer, padded to 3 spaces. %.2f: float, 2 decimal places. \n: newline.
    printf "CPS, %3d, CPM, %3d, uSv/hr, %.2f, SLOW\n" "$cps" "$cpm" "$uSv"

    # 6. Wait for 1 second before the next iteration.
    sleep 1
# The trailing '&' LAUNCHES THIS ENTIRE 'while true' LOOP IN THE BACKGROUND.
# It runs concurrently with the first background loop (and the main script finishes).
done &

# The main script execution ends here almost immediately after launching both background loops.
# The actual work is done by the background processes writing to/reading from
# the standard input/output streams managed by tcpserver.bash (tcpsvd/socat).

