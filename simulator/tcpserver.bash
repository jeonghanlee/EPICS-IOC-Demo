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
#  Robust TCP Server Launcher for Parallel Execution
#  Tries tcpsvd first, then socat. Listens on localhost:PORT.
#  Executes a specified or default connection handler script for each connection.
#  Includes prefixed logging and basic signal trapping.
#
#  Usage: ./tcpserver.bash [PORT] [HANDLER_SCRIPT]
#         ./tcpserver.bash [HANDLER_SCRIPT]  (uses default port)
#         ./tcpserver.bash [PORT]            (uses default handler)
#         ./tcpserver.bash                   (uses defaults for both)
#
#  - author : Jeong Han Lee, Dr.rer.nat.
#  - email  : jeonglee@lbl.gov

# --- Defaults ---
DEFAULT_HANDLER="connection_handler.sh" # Default if no handler specified
DEFAULT_PORT="9399"                   # Default if no port specified

# --- Argument Parsing ---
PORT="$1"    # First argument
HANDLER="$2" # Second argument


if [[ "$PORT" == *handler.sh ]]; then
    HANDLER="$PORT"
    PORT="" # Will be set to default later if empty
fi

# Apply defaults if arguments were not provided or shifted
if [ -z "$PORT" ]; then
  PORT="$DEFAULT_PORT"
fi

if [ -z "$HANDLER" ]; then
  HANDLER="$DEFAULT_HANDLER"
fi

# --- Logging Prefix (Defined after PORT is finalized) ---
LOG_PREFIX="[Server $PORT PID $$]:"

# --- Signal Handling ---
cleanup() {
    printf "%s Exiting on signal.\n" "$LOG_PREFIX"
    # Add any specific cleanup needed here, if necessary
    exit 1 # Indicate non-standard exit
}
trap cleanup INT TERM QUIT # Catch Ctrl+C, kill, etc.

# --- Find and Validate Handler Script ---
# Determine the directory where this launcher script resides
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
HANDLER_SCRIPT="${SCRIPT_DIR}/${HANDLER}"

printf -- "#--------------------------------------------------\n"
printf -- "# %s Starting TCP Server:\n" "$LOG_PREFIX"
printf -- "#   Port   : %s\n" "$PORT"
printf -- "#   Handler: %s\n" "$HANDLER_SCRIPT"
printf -- "#--------------------------------------------------\n"

# Check if the handler script exists
if [[ ! -f "$HANDLER_SCRIPT" ]]; then
    printf "%s Error: Cannot find handler script '%s' in the script directory: %s\n" "$LOG_PREFIX" "$HANDLER" "$SCRIPT_DIR"
    exit 1
fi
# Check if the handler script is executable
if [[ ! -x "$HANDLER_SCRIPT" ]]; then
    printf "%s Error: Handler script '%s' is not executable. Please run: chmod +x %s\n" "$LOG_PREFIX" "$HANDLER_SCRIPT" "$HANDLER_SCRIPT"
    exit 1
fi

# --- Launch Server ---
SERVER_CMD=""

if command -v socat >/dev/null 2>&1; then
    printf "%s Attempting to start using socat on port %s...\n" "$LOG_PREFIX" "$PORT"
    # socat: TCP-LISTEN, reuseaddr, fork, SYSTEM execution
    # Note the quoting for SYSTEM command with variable path
    SERVER_CMD="socat TCP-LISTEN:${PORT},reuseaddr,fork SYSTEM:'\"$HANDLER_SCRIPT\"'"
elif command -v tcpsvd > /dev/null 2>&1; then
    printf "%s Attempting to start using tcpsvd on 127.0.0.1:%s...\n" "$LOG_PREFIX" "$PORT"
    # tcpsvd: -c 1 limits concurrency, -vvE logs verbosely to stderr
    SERVER_CMD="tcpsvd -c 1 -vvE 127.0.0.1 \"$PORT\" \"$HANDLER_SCRIPT\""
else
    printf "%s Error: Neither socat nor tcpsvd socat found. Please install socat.\n" "$LOG_PREFIX"
    exit 1
fi

# Execute the selected server command
eval "$SERVER_CMD"
EXIT_CODE=$? # Capture exit code of tcpsvd/socat

# --- Normal Exit Logging ---
printf "%s Server command exited with code %d.\n" "$LOG_PREFIX" "$EXIT_CODE"
exit $EXIT_CODE
