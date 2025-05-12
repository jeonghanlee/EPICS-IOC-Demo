# 3.3 Your Second ALS-U EPICS IOC: Testing Device Communication

We will simulate the serial device using the simulator scripts created in the previous lesson, allowing you to test the IOC without needing physical hardware that speaks TCP/IP. This final step involves running both the IOC and the simulator concurrently and using EPICS Channel Access tools to verify communication.

## Lesson Overview
In this lesson, you will learn to:

* Start the TCP echo server simulator.
* Start the EPICS IOC configured for TCP communication.
* Verify the IOC connects to the simulator.
* Use caput to send commands/queries through the IOC to the simulator.
* Use caget to read back the echoed responses received by the IOC.
* Confirm end-to-end communication via Asyn and StreamDevice.

## Prerequisites
Before starting this lesson, ensure you have:

* Successfully Built IOC: The `jeonglee-Demo` IOC application from the previous lesson must be built successfully (result of Step 7 in that lesson).
* Simulator Scripts: The `tcpserver.bash` and `connection_handler.sh` scripts (from the "Simple TCP/IP Serial Server" lesson) must be created and made executable, preferably in a known location (e.g., a `simulator` subdirectory).
* Required Tools:
    * `socat` or `tcpsvd` installed (for the server script).
    * EPICS Base setup correctly sourced (via `setEpicsEnv.bash`) so that Channel Access client tools (`caput`, `caget`) are available in your path.
* Terminal Windows: You will need **three separate terminal windows** for this lesson: one for the simulator, one for the IOC, and one for running CA client commands.

## Step 1: Run the TCP Simulator
First, start the echo server simulator. It needs to be running before the IOC starts so the IOC can connect to it.

1. Open your first terminal window.
2. Navigate (`cd`) to the directory containing `tcpserver.bash` and `connection_handler.sh` (e.g., the `simulator` subdirectory).
3. Execute the server script:
```shell
# In Terminal 1 (Simulator):
simulator$ ./tcpserver.bash
```
4. You should see a message indicating the server is listening (e.g., "Attempting to start tcpsvd echo server on 127.0.0.1:9399...").
5. Leave this terminal running. Do not close it or stop the script.


## Step 2: Run the EPICS IOC
Next, start the `jeonglee-Demo` IOC application.

1. Open your second terminal window.
2. Make sure your EPICS environment is sourced:
```shell
# In Terminal 2 (IOC):
$ source ~/epics/1.1.1/debian-12/7.0.7/setEpicsEnv.bash # Use your correct path
```
3. Navigate (`cd`) to the IOC's top-level directory, optionally run make to ensure it's up-to-date, then navigate into the IOC's specific boot directory:

```shell
# In Terminal 2 (IOC):
$ cd /path/to/your/jeonglee-Demo
# (Replace /path/to/your/ with the actual path)
$ make # Optional, but ensures the build is current
$ cd iocBoot/iocB46-182-jeonglee-Demo # <-- CRITICAL: Must change into boot directory
```
4. Execute the startup script (`st.cmd`) from within the boot directory:
```shell
# In Terminal 2 (IOC):
iocB46-182-jeonglee-Demo$ ./st.cmd
```
5. Watch the IOC startup messages. Note that the IOC shell might proceed even if there are errors during `st.cmd` execution (like failing to connect the Asyn port). It is best practice to carefully examine the startup messages for any errors or warnings, especially after changing `st.cmd`, `.db` files, or `.proto` files.

6. Check Terminal 1 (Simulator): When the IOC successfully connects, you should see a connection message appear in the simulator's terminal window (e.g., tcpsvd: info: pid ... from 127.0.0.1).

7. The IOC terminal should eventually show a prompt indicating the EPICS base version (e.g., 7.0.7>), signifying the IOC is running and ready. Leave this terminal running.

## Step 3: Test Communication with Channel Access
Now, with both the simulator and the IOC running and connected, we can use Channel Access (CA) client tools (`caput`, `caget`) to interact with the PVs defined in training.db and test the communication loop.

Recall the PVs created (using `P=jeonglee:` and `R=myoffice:` from `st.cmd`):

* `jeonglee:myoffice:Cmd` (stringout): Writing to this PV sends the string via StreamDevice's sendRawQuery protocol to the simulator (localhost:9399).
* `jeonglee:myoffice:Cmd-RB` (stringin): StreamDevice updates this PV with the reply received from the simulator (which is just an echo).

You can list all available PVs directly from the running IOC's console using the `dbl` (database list) command:

```shell
# In Terminal 2 (IOC)
7.0.7> dbl
jeonglee:myoffice:Cmd
jeonglee:myoffice:Cmd-RB
# (Other PVs might also be listed)
7.0.7>
```

Now, let's test using the CA clients:
1. Open your third terminal window.
2. Make sure your EPICS environment is sourced here as well, so `caput` and `caget` are available:
```shell
# In Terminal 3 (CA Clients):
$ source ~/epics/1.1.1/debian-12/7.0.7/setEpicsEnv.bash # Use your correct path
```
3. Send a Query: Use `caput` to write a string to the command PV. Let's query for an ID.
```shell
# In Terminal 3 (CA Clients):
$ caput jeonglee:myoffice:Cmd "DEVICE_ID?"
# Expected output:
Old : jeonglee:myoffice:Cmd          
New : jeonglee:myoffice:Cmd          DEVICE_ID?
```
4. Read the Echoed Reply: The simulator echoes "DEVICE_ID?" back. StreamDevice (using the in "%(\$1)40c" part of the sendRawQuery protocol) should read this reply and write it to the `Cmd-RB` PV. Use `caget` to read this PV:
```shell
# In Terminal 3 (CA Clients):
$ caget jeonglee:myoffice:Cmd-RB
# Expected output:
jeonglee:myoffice:Cmd-RB       DEVICE_ID?
```
5. Seeing the same string you sent confirms the entire communication loop: `caput` -> IOC Record (`Cmd`) -> StreamDevice out -> Asyn IP -> TCP -> Simulator -> TCP -> Asyn IP -> StreamDevice in -> IOC Record (`Cmd-RB`) -> `caget`.

6. Try Another Query: Send a different string.

```shell
# In Terminal 3 (CA Clients):
$ caput jeonglee:myoffice:Cmd "STATUS?"

# Read back the echo using caget
$ caget jeonglee:myoffice:Cmd-RB
# Expected output:
# jeonglee:myoffice:Cmd-RB     STATUS?
```

Success! You have verified end-to-end communication between your IOC and the TCP simulator using Asyn and StreamDevice.

### Troubleshooting
If your `caput` or `caget` commands fail with a message like Channel connect timed out: 'PVNAME' not found., it means the CA client tools cannot find your running IOC over the network.

```shell
# Example Error:
$ caget jeonglee:myoffice:Cmd-RB
Channel connect timed out: 'jeonglee:myoffice:Cmd-RB' not found.
```

When running the IOC and CA clients on the same machine (like localhost), this often happens because the default CA broadcast mechanism isn't sufficient or is blocked. You need to explicitly tell the CA clients where to find the IOC server using an environment variable:

1. Set `EPICS_CA_ADDR_LIST`: In the terminal where you run `caput`/`caget` (Terminal 3), set this variable to point to the machine running the IOC (in this case, localhost).
```shell
# In Terminal 3 (CA Clients):
$ export EPICS_CA_ADDR_LIST=localhost
```

Retry the command:
```shell
# In Terminal 3 (CA Clients):
$ caget jeonglee:myoffice:Cmd-RB
# Expected output (should now work):
# jeonglee:myoffice:Cmd-RB     STATUS?
```

If you would like to evaluate the PVA protocol, you also have to define the following EPICS environment variable `EPICS_PVA_ADDR_LIST` for PVA (Process Variable Access) protocol. We will cover PVA protocol for more advanced lesson later.

```shell
$ export EPICS_PVA_ADDR_LIST=localhost
$ pvxget jeonglee:myoffice:Cmd-RB
```

## Summary
In this lesson, you successfully:

* Ran the TCP echo server simulator.
* Ran the EPICS IOC (`jeonglee-Demo`), ensuring it connected to the simulator.
* Verified PV discoverability using `dbl` in the IOC shell.
* Used caput to send data from the IOC to the simulator via Asyn/StreamDevice over TCP.
* Used caget to read back the echoed data received by the IOC via StreamDevice.
* Troubleshot basic Channel Access connectivity issues using `EPICS_CA_ADDR_LIST`.

This confirms your IOC's basic communication infrastructure configured with Asyn and StreamDevice is working correctly. You can now stop the IOC (press `Ctrl+C` or type `exit` at the `7.0.7>` prompt in Terminal 2) and the simulator (`Ctrl+C` in Terminal 1). This provides a solid foundation for interacting with real TCP-based devices using similar techniques.
