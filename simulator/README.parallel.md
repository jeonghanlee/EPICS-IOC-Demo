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

