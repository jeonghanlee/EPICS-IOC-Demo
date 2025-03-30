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

# Loop indefinitely while reading lines from the client connection (stdin)
# 'IFS=' prevents stripping leading/trailing whitespace
# '-r' prevents backslash interpretation
while IFS= read -r received_text; do
  # Echo the received line back to the client (stdout), followed by a newline
  # Using printf is generally safer than echo for arbitrary data
  printf "%s\n" "$received_text"
done

# Note: This script inherently handles text terminated by a newline (\n),
# as 'read' waits for a newline by default. This matches the '\n'
# Input/Output EOS settings configured in the EPICS IOC's st.cmd.

