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

## advanced_connection_handler.sh
function sub_cmds
{
    local cmd="$1"; shift
    local response="";
    if [[ $cmd == "GetID?" ]]; then
        response="$$"
    elif [[ $cmd == "GetTemp?" ]]; then
        response=$((RANDOM % 101))
    else
        response=$cmd
    fi
    printf "%s\n" "$response"
}

while IFS= read -r received_text; do
  # Echo the received line back to the client (stdout), followed by a newline
  # Using printf is generally safer than echo for arbitrary data
  sub_cmds "$received_text"
done <&0 & # Read client input in background


## gc_connection_handler.sh
# --- Configuration ---
lower_bound=0            # Minimum simulated CPS
upper_bound=10           # Maximum simulated CPS (Adjusted down for more realistic background)
GC_TUBE_FACTOR="0.0057"  # Conversion factor (uSv/h) / CPM for SBM-20 tube

# --- Initialization ---
sum_total_counts=0       # Sum of ALL counts since script start
count_total_seconds=0    # Total seconds elapsed
counts_this_minute=0     # Accumulator for counts within the current minute
cpm=0                    # Holds the CPM calculated for the *last completed* minute
sec_per_min=60
range_size=$((upper_bound - lower_bound + 1))



while true ; do
   
    # 1. Simulate Counts Per Second for this second
    cps=$(( (RANDOM % range_size) + lower_bound ))

    # 2. Update counters
    count_total_seconds=$((count_total_seconds + 1))
    sum_total_counts=$((sum_total_counts + cps))
    counts_this_minute=$((counts_this_minute + cps))
    
    # 3. Check if a full minute has passed
    if (( count_total_seconds > 0 && count_total_seconds % sec_per_min == 0 )); then
        # The total counts accumulated over the last 60 seconds IS the CPM
        cpm=$counts_this_minute
        # Reset the accumulator for the next minute
        counts_this_minute=0
    fi

    # 4. Calculate Dose Rate based on the CPM from the last completed minute
    #    Note: This value only updates once per minute when 'cpm' is updated.
    uSv=$(echo "scale=4; $cpm * $GC_TUBE_FACTOR" | bc)

    printf "CPS, %3d, CPM, %3d, uSv/hr, %.2f, SLOW\n" "$cps" "$cpm" "$uSv"

    sleep 1
done &

