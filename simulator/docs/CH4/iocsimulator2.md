# 4.2 An Extended TCP/IP Serial Server

Building upon the simple echo server concept, this section introduces an enhanced version of the launcher script (`tcpserver.bash`) paired with a more sophisticated advanced connection handler. This combination allows simulating devices that respond specifically to certain commands (rather than just echoing) and provides the flexibility needed for more complex testing scenarios. We will also cover how to easily run multiple simulator instances using GNU Parallel.

## Lesson Overview

In this lesson, you will learn to:

* Understand the enhanced argument handling and logging features of the extended `tcpserver.bash` script.
* Create and understand an advanced handler script (`advanced_connection_handler.sh`) that simulates specific device commands.
* Run the server specifying custom ports and the advanced handler script.
* Test the specific command responses using socat.
* Use GNU Parallel to launch multiple server instances.

## Requirements Recap

This section assumes you have:

* Access to a Linux environment with standard shell tools (bash).
* `tcpsvd` OR `socat` installed.
* `parallel` (GNU Parallel) installed if you want to run multiple instances easily.
* Familiarity with the concepts from the "A Simple TCP/IP Serial Server" section.

## The Extended TCP/IP Server (`tcpserver.bash`)

The primary change is in the launcher script, `tcpserver.bash`. This new version intelligently parses command-line arguments to allow specifying the port, the handler script, or both, falling back to defaults if arguments are omitted.

Here is the code for the extended tcpserver.bash:

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
if command -v tcpsvd > /dev/null 2>&1; then
    printf "%s Attempting to start using tcpsvd on 127.0.0.1:%s...\n" "$LOG_PREFIX" "$PORT"
    # tcpsvd: -c 1 limits concurrency, -vvE logs verbosely to stderr
    SERVER_CMD="tcpsvd -c 1 -vvE 127.0.0.1 \"$PORT\" \"$HANDLER_SCRIPT\""
elif command -v socat >/dev/null 2>&1; then
    printf "%s tcpsvd not found. Attempting to start using socat on port %s...\n" "$LOG_PREFIX" "$PORT"
    # socat: TCP-LISTEN, reuseaddr, fork, SYSTEM execution
    # Note the quoting for SYSTEM command with variable path
    SERVER_CMD="socat TCP-LISTEN:${PORT},reuseaddr,fork SYSTEM:'\"$HANDLER_SCRIPT\"'"
else
    printf "%s Error: Neither tcpsvd nor socat found. Please install ucspi-tcp (ipsvd) or socat.\n" "$LOG_PREFIX"
    exit 1
fi

# Execute the selected server command
eval "$SERVER_CMD"
EXIT_CODE=$? # Capture exit code of tcpsvd/socat

# --- Normal Exit Logging ---
printf "%s Server command exited with code %d.\n" "$LOG_PREFIX" "$EXIT_CODE"
exit $EXIT_CODE
```

Make the launcher script executable:
```shell
chmod +x tcpserver.bash
```

## Creating an Advanced Handler Script

To simulate more than just an echo, we create a handler script with specific logic. This example responds uniquely to `GetID?` and `GetTemp?` commands.

Save the following code as `advanced_connection_handler.sh` (e.g., in your simulator directory):

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
#  Advanced Connection Handler for TCP Server
#  Simulates specific commands: GetID?, GetTemp?
#  Echoes back any other received commands.
#
#  - author : Jeong Han Lee, Dr.rer.nat.
#  - email  : jeonglee@lbl.gov


# Function to process received commands
function sub_cmds
{
    local cmd="$1"; shift
    local response=""

    # Check the command and prepare a specific response
    if [[ "$cmd" == "GetID?" ]]; then
        # Respond with the Process ID of this handler instance
        response="$$"
    elif [[ "$cmd" == "GetTemp?" ]]; then
        # Respond with a random integer between 0 and 100
        response=$((RANDOM % 101))
    else
        # For any other command, just echo it back
        response="$cmd"
    fi

    # Send the response back to the client, followed by a newline
    printf "%s\n" "$response"
}

# Main loop: Read lines from client (stdin) and process them
# 'IFS=' prevents stripping leading/trailing whitespace
# '-r' prevents backslash interpretation
while IFS= read -r received_text; do
  # Call the function to handle the received command/text
  sub_cmds "$received_text"
done

# Note: This script inherently handles text terminated by a newline (\n),
# matching typical IOC EOS settings.
```

Save and close the file and make it executable:

```shell
simulator$ chmod +x advanced_connection_handler.sh
```

### How this Handler Works:

* It defines a function sub_cmds to check the received command.
* If the command is `GetID?`, it replies with its own unique Process ID (`$$`).
* If the command is `GetTemp?`, it replies with a random number between 0 and 100.
* For any other input, it simply echoes the input back.
* The main `while read` loop calls this function for every line received from the client.


## Running the Server

With the enhanced `tcpserver.bash` and potentially multiple handler scripts available (like `connection_handler.sh` and `advanced_connection_handler.sh`), you can launch the simulator in various ways. Navigate to your simulator directory in a dedicated terminal and use one of the following invocation methods:

```shell
# Option 1: Run with all defaults
# Uses default port (9399) and default handler (connection_handler.sh)
simulator$ ./tcpserver.bash

# Option 2: Specify only the port (uses default handler)
# Runs default handler on port 8888
simulator$ ./tcpserver.bash 8888

# Option 3: Specify only the handler (uses default port)
# Runs advanced handler on port 9399
simulator$ ./tcpserver.bash advanced_connection_handler.sh

# Option 4: Specify both port and handler
# Runs advanced handler on port 8888
simulator$ ./tcpserver.bash 8888 advanced_connection_handler.sh
```

The script will print which port and handler it is starting with, including a Process ID (PID) in the log prefix (`[Server PORT PID]:`). Leave the chosen server running in its terminal for testing. Use Ctrl+C to stop it (the trap should log an exit message).

## Testing the Advanced Handler with Socat

Let's test the server when running the `advanced_connection_handler.sh`. Open another new terminal window and use `socat` to connect (use the correct port if you chose one other than 9399).

```shell
# Connect to the server (assuming it's running on port 9399 with the advanced handler)
$ socat - TCP:localhost:9399

# --- Interaction ---
GetID?               <-- You type this and press Enter
16254                <-- Server responds with a Process ID (will vary)
GetTemp?             <-- You type this and press Enter
81                   <-- Server responds with a random number (0-100)
GetTemp?             <-- You type this again
33                   <-- Server responds with a different random number
WhatIsThis?          <-- You type this and press Enter
WhatIsThis?          <-- Server echoes unknown command back
```
Disconnect `socat` with Ctrl+C or Ctrl-D.

## Running Multiple Simulators with GNU Parallel

GNU Parallel remains a useful tool for launching multiple instances, now with the added flexibility of specifying handlers if needed.

1. Ensure parallel is installed.
2. Run the command: From your simulator directory:

```shell
# Start servers on ports 9399, 9400, 9401 using the ADVANCED handler for all
simulator$ parallel ./tcpserver.bash {} advanced_connection_handler.sh ::: 9399 9400 9401
# Or, start servers using the DEFAULT echo handler for all
simulator$ parallel ./tcpserver.bash ::: 9399 9400 9401
```
3. Test Each Instance: Use separate socat terminals to connect to ports 9399, 9400, and 9401 as needed. 

4. Stopping Parallel Servers: Use Ctrl+C in the parallel terminal. If processes linger, use `ps`/`pgrep` and `kill`.

## Running Multiple Simulators without GNU Parallel

1. Ensure you have to open three different terminals

2. Run the following commands in three different terminals

```shell
# Terminal 1
simulator$ ./tcpserver.bash 9399 advanced_connection_handler.sh
```

```shell
# Terminal 2
simulator$ ./tcpserver.bash 9400 advanced_connection_handler.sh
```

```shell
# Terminal 3
simulator$ ./tcpserver.bash 9401 advanced_connection_handler.sh
```
3. Test Each Instance: Use separate socat terminals to connect to ports 9399, 9400, and 9401 as needed. 

4. Stopping Servers: Use Ctrl+C in the each terminal.


## Conclusion

By separating the server launching logic (`tcpserver.bash`) from the connection handling logic (e.g., `connection_handler.sh`, `advanced_connection_handler.sh`), you gain significant flexibility. This allows you to easily create and test different simulated device behaviors, making the simulator a much more powerful tool for developing and debugging EPICS IOCs. The robust launcher script also facilitates running and managing multiple instances concurrently.
