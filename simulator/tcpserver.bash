#!/usr/bin/env bash
#
# Simple TCP Echo Server Launcher
# Tries tcpsvd first, then socat. Listens on localhost:PORT.
# Executes connection_handler.sh for each connection.
#
# author  : Jeong Han Lee (Han)
# email   : jeonglee@lbl.gov
# version : 0.0.1

PORT=9399 # Port matching the IOC configuration in st.cmd

# Determine the directory where this script resides to reliably find the handler script
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
HANDLER_SCRIPT="${SCRIPT_DIR}/connection_handler.sh"

# Check if the handler script exists
if [[ ! -f "$HANDLER_SCRIPT" ]]; then
    echo "Error: Cannot find connection_handler.sh in the script directory: ${SCRIPT_DIR}"
    exit 1
fi
# Check if the handler script is executable
if [[ ! -x "$HANDLER_SCRIPT" ]]; then
    echo "Error: connection_handler.sh is not executable. Please run: chmod +x ${HANDLER_SCRIPT}"
    exit 1
fi


if command -v tcpsvd > /dev/null 2>&1; then
    # tcpsvd: -c 1 limits to 1 concurrent connection (simulates some serial devices)
    # -vvE logs verbose messages and errors to stderr
    printf "Attempting to start tcpsvd echo server on 127.0.0.1:%s...\n" "$PORT"
    tcpsvd -c 1 -vvE 127.0.0.1 "$PORT" "$HANDLER_SCRIPT"
    printf "tcpsvd server exited.\n"
elif command -v socat >/dev/null 2>&1; then
    # socat: TCP-LISTEN listens on the port
    # reuseaddr allows quick restarts if the port was recently used
    # fork handles each connection in a new process
    # SYSTEM executes the handler script, passing connection via stdin/stdout
    printf "tcpsvd not found. Attempting to start socat echo server on port %s...\n" "$PORT"
    socat TCP-LISTEN:${PORT},reuseaddr,fork SYSTEM:"'$HANDLER_SCRIPT'"
    printf "socat server exited.\n"
else
    # Error if neither required tool is found
    echo "Error: Neither tcpsvd nor socat found. Please install ipsvd or socat."
    exit 1
fi
