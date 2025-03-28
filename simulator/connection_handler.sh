#!/usr/bin/env bash
#
# Connection Handler for TCP Echo Server
# Reads lines from client (stdin) and echoes them back (stdout).
#
# author  : Jeong Han Lee (Han)
# email   : jeonglee@lbl.gov
# version : 0.0.1

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
