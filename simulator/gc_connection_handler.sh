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
#  Connection Handler for TCP Echo Server
#  Reads lines from client (stdin) and echoes them back (stdout).
#
#  - author : Jeong Han Lee, Dr.rer.nat.
#  - email  : jeonglee@lbl.gov

# Loop indefinitely 
while true; do
  # Using printf is generally safer than echo for arbitrary data
  # print the following format with randomly generator number 
  # continously, per each second
  #
  # CPS, 2, CPM, 2, uSv/hr, 0.01, SLOW
  
  cps=$((RANDOM % 1001))
  cpm=$((RANDOM % 101))
  rad=$(echo "scale=2; 1 / $cpm" | bc)
  printf "CPS, %3d, CPM, %3d, uSv/hr, %.2f, SLOW\n" "$cps" "$cpm" "$rad"
  sleep 1
done
