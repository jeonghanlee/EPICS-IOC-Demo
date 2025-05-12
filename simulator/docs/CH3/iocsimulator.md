# 3.2 A Simple TCP/IP Serial Server
The simple TCP server is designed to simulate a basic serial device communicating over TCP/IP. When a client sends a text message (typically ending with a newline) to this server, the server will simply return the exact same message back to the client. This "echo" functionality provides a fundamental interaction model and is incredibly useful for:

* EPICS IOC Development Training: It allows you to develop and test the TCP/IP communication parts of your EPICS IOC (using Asyn and StreamDevice) without needing actual physical hardware.
* Debugging: You can use this server to verify that your IOC is correctly sending commands and receiving expected (or echoed) data over a TCP/IP connection.
* Simulation: It provides a controllable and predictable endpoint for practicing network communication concepts within the EPICS environment.

## Lesson Overview

In this lesson, you will learn to:
* Create simple bash scripts to simulate a TCP/IP echo server.
* Run the simulator using common Linux utilities (`tcpsvd` or `socat`).
* Test the simulator using `socat`.

## Requirements

To run this server, you will need one or both of the following command-line utilities installed on your Linux system:
* `tcpsvd`: A lightweight TCP/IP service daemon that creates, binds, and listens on a socket.
* `socat`: A versatile data relay utility capable of acting as a TCP server.

These tools are often available via your distribution's package manager.
* Debian and its variant Linux Example: `apt update && sudo apt install ipsvd socat` 
* Rocky and Redhat variant Linux Note: The `ipsvd` package (providing `tcpsvd`) is not available; using `socat` (which should be installable via `dnf`) is the recommended alternative in that case.


## Build server scripts

We will create two small bash scripts: one to launch the server (`tcpserver.bash`) and one to handle individual client connections (`connection_handler.sh`).
**Recommendation**: Create these scripts in a dedicated `simulator` subdirectory within your main IOC project directory (e.g., `jeonglee-Demo/simulator/`) to keep things organized. Navigate into that directory before creating the files.

```shell
# Example: Create and enter the simulator directory
# Ensure you are in your main IOC project directory first (e.g., jeonglee-Demo)
$ mkdir simulator
$ cd simulator
```
* Create tcpserver.bash

Use your preferred text editor (vi, nano, emacs, etc.) to create the main server script:

```shell
simulator$ vi tcpserver.bash
```

Add the following content. This script checks for `tcpsvd` first, then falls back to `socat`, listening on port 9399. It robustly finds the handler script in its own directory.

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
#  Simple TCP Echo Server Launcher
#  Tries tcpsvd first, then socat. Listens on localhost:PORT.
#  Executes connection_handler.sh for each connection.
# 
#  - author : Jeong Han Lee, Dr.rer.nat.
#  - email  : jeonglee@lbl.gov

PORT="$1"  # Port matching the IOC configuration in st.cmd

if [ -z "$PORT" ]; then
    PORT=9399 
fi

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
    echo "Error: Neither tcpsvd nor socat found. Please install ucspi-tcp or socat."
    exit 1
fi
```
Save and close the `tcpserver.bash` file. Then, make it executable:

```shell
# Allow the system to execute this script
simulator$ chmod +x tcpserver.bash
```

* Create `connection_handler.sh`

Create the script that handles the actual echo logic for each individual client connection:
```shell
$ vi connection_handler.sh
```

Add the following content. This script reads input line by line using `read -r` for safety and echoes each line back using printf.

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
```

Save and close the `connection_handler.sh` file. And change it to be executable.

```shell
# Allow the system (tcpsvd/socat) to execute this script
simulator$ chmod +x connection_handler.sh
```


## How the Server Works

The `tcpserver.bash` script acts as a launcher. It uses either `tcpsvd` or `socat` to listen for incoming TCP connections on the specified port (`9399`) only on the local machine (`127.0.0.1`).

When a client connects, the listener (`tcpsvd` or `socat`) executes the `connection_handler.sh` script, redirecting the client's connection to the script's standard input and standard output. The handler script then enters a loop:

* It waits using read to receive a complete line of text (ending in a newline) sent by the client via standard input.
* It uses `printf` to send that exact line of text back to the client via standard output, adding a newline character.
* It loops back to wait for the next line from the client.

This creates a simple line-based echo server. It mimics a device that might acknowledge commands or data by simply repeating them back, line by line, which is useful for testing basic communication loops.

## Running the Server

To start the simulator, you need to execute the `tcpserver.bash` script you created.

* Open a new terminal window.
* Navigate (`cd`) to the directory where you saved `tcpserver.bash` and `connection_handler.sh` (e.g., the simulator subdirectory within your IOC project).
* Execute the server script using `./` (which tells the shell to run the script in the current directory)

```shell
simulator$ ./tcpserver.bash
```
* The script will print a message indicating which tool (`tcpsvd` or `socat`) it is using and confirming it's listening on the port (e.g., "Attempting to start tcpsvd echo server on 127.0.0.1:9399...").

* Leave this terminal window running. The server process needs to remain active in this terminal to accept connections. To stop the server later, you typically press `Ctrl+C` in this terminal window.

## Testing the Server with Socat

### Client Console

Before connecting your IOC, you can verify the server works using `socat` itself as a client. Open another new terminal window (leaving the server running in its own window). Use `socat` to connect standard input/output (`-`) to the server's TCP port:

```shell
$ socat - TCP:localhost:9399
```

Once connected, the cursor will wait. Type any line of text and press Enter:

```shell
# Example socat client interaction
$ socat - TCP:localhost:9399
First!        <-- You type this and press Enter
First!        <-- Server echoes it back
123456        <-- You type this and press Enter
123456        <-- Server echoes it back
ByeBye!       <-- You type this and press Enter
ByeBye!       <-- Server echoes it back
```

The server should immediately send the same line of text back via the socat connection, and it will appear on the next line in your terminal. To disconnect the `socat` client, press `Ctrl+C` or `Ctrl+D`.

## Server Console

While the client is connected and interacting, observe the terminal where the server (`./tcpserver.bash`) is running. You should see log messages (especially if `tcpsvd` is used) indicating connections starting and ending:

```shell
# Example Output (using tcpsvd)
simulator (master)$ bash tcpserver.bash 
Attempting to start tcpsvd echo server on 127.0.0.1:9399...
tcpsvd: info: listening on 127.0.0.1:9399, starting.

# (Client connects...)
tcpsvd: info: status 1/1
tcpsvd: info: pid 14092 from 127.0.0.1
tcpsvd: info: start 14092 localhost:127.0.0.1 ::127.0.0.1:52042

# (Client sends 'First!', '123456', 'ByeBye!', handler echoes)

# (Client disconnects...)
tcpsvd: info: end 14092 exit 0
tcpsvd: info: status 0/1
```

This confirms your echo server is working correctly and is ready to receive connections from your EPICS IOC in the next stage.
