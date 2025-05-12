# 4.3 Managing Multiple Devices using `iocshLoad`

Now that we have learned how to create reusable configuration snippets using `.iocsh files` in [Working with `iocsh`: Script Files and Commands](iocsh_basics.md) and how to run multiple instances of our extended TCP simulator on different ports [Update the TCP Simulator](iocsimulator2.md), we can combine these concepts.

This section focuses on configuring a single IOC to communicate with multiple identical devices simultaneously. We will achieve this by leveraging the `.iocsh` snippet file developed earlier, calling it multiple times within the main `st.cmd` file using `iocshLoad`, passing different parameters (macros) for each device instance. We will focus here on managing the communication setup (like Asyn ports) efficiently using this technique.

## Recap: The Reusable `.iocsh` Snippet

Recall the `.iocsh` script file we worked with (e.g., `simulator_device.iocsh` or `training_device.iocsh` from the Section 1 exercise). It encapsulates the steps needed to configure one device connection, including setting up the Asyn port and loading associated database records. It accepts parameters via macros passed through `iocshLoad`, such as `PREFIX`, `DEVICE`, `PORT_NAME`, `PORT`, `HOST`, `DATABASE_TOP`. Assuming this snippet loads records like `Cmd` (`stringout`) and `Cmd-RB` (`stringin`) from a database file (like `training.db`), these PVs will be created relative to the `PREFIX` and `DEVICE` macros.


## Configuring Multiple Instances in `st3.cmd`

To manage multiple devices, we simply call iocshLoad multiple times in our main `st3.cmd`, providing a unique set of macro values for each call.

* Define Unique Parameters: For each device instance, define a unique set of parameters. Using `epicsEnvSet` can keep this organized. We need unique PV prefixes/device parts (e.g., `SIM1:`, `SIM2:`, `SIM3:`), unique Asyn port names (`TCP1`, `TCP2`, `TCP3`), and unique target TCP ports (`9399`, `9400`, `9401`) for each simulator.
* Call `iocshLoad` Repeatedly: Execute the `iocshLoad` command for your snippet file (`training_device.iocsh`) once per device instance, passing the specific macros.

### Example `st3.cmd` Snippet (configuring 3 simulator instances):

This example shows the relevant parts of an `st3.cmd` file for loading three instances. Note the initial setup for paths.

```bash
# Showing the relevant loading section, you will see the full example later.
#
# Define standard locations relative to the application top ($TOP)
epicsEnvSet("DB_TOP", "$(TOP)/db")
epicsEnvSet("STREAM_PROTOCOL_PATH", "$(DB_TOP)")
epicsEnvSet("IOCSH_LOCAL_TOP",      "$(TOP)/iocsh")

# --- Configuration for Simulator Instance 1 ---
epicsEnvSet("PREFIX1",         "MYDEMO:")      # Main prefix
epicsEnvSet("DEVICE1",         "SIM1:")        # Unique device part
epicsEnvSet("ASYN_PORT_NAME1", "TCP1")         # Unique Asyn Port Name
epicsEnvSet("TARGET_PORT1",    "9399")         # TCP Port for simulator 1
# Load snippet for Instance 1
iocshLoad("$(IOCSH_LOCAL_TOP)/training_device.iocsh", "PREFIX=$(PREFIX1),DEVICE=$(DEVICE1),DATABASE_TOP=$(DB_TOP),PORT_NAME=$(ASYN_PORT_NAME1), PORT=$(TARGET_PORT1)")

# --- Configuration for Simulator Instance 2 ---
epicsEnvSet("PREFIX2",         "MYDEMO:")      # Main prefix
epicsEnvSet("DEVICE2",         "SIM2:")        # Unique device part
epicsEnvSet("ASYN_PORT_NAME2", "TCP2")         # Unique Asyn Port Name
epicsEnvSet("TARGET_PORT2",    "9400")         # TCP Port for simulator 2
# Load snippet for Instance 2
iocshLoad("$(IOCSH_LOCAL_TOP)/training_device.iocsh", "PREFIX=$(PREFIX2),DEVICE=$(DEVICE2),DATABASE_TOP=$(DB_TOP),PORT_NAME=$(ASYN_PORT_NAME2), PORT=$(TARGET_PORT2)")

# --- Configuration for Simulator Instance 3 ---
epicsEnvSet("PREFIX3",         "MYDEMO:")      # Main prefix
epicsEnvSet("DEVICE3",         "SIM3:")        # Unique device part
epicsEnvSet("ASYN_PORT_NAME3", "TCP3")         # Unique Asyn Port Name
epicsEnvSet("TARGET_PORT3",    "9401")         # TCP Port for simulator 3
# Load snippet for Instance 3
iocshLoad("$(IOCSH_LOCAL_TOP)/training_device.iocsh", "PREFIX=$(PREFIX3),DEVICE=$(DEVICE3),DATABASE_TOP=$(DB_TOP),PORT_NAME=$(ASYN_PORT_NAME3), PORT=$(TARGET_PORT3), ASYNTRACE=")
...
```

## Run the simulator with three devices setup  

After creating or modifying the `st3.cmd` file as shown above, follow these steps using three separate terminals to run the simulators, start the IOC, and verify communication.

### Start Simulators (Terminal 1)

Use parallel (or run manually in three terminals) to start the simulators, each listening on its designated port and using a suitable handler (like `advanced_connection_handler.sh` from the previous section).

```bash
# Terminal 1
simulator (master)$ parallel ./tcpserver.bash {} advanced_connection_handler.sh ::: 9399 9400 9401
```
Leave this terminal running.

### Start IOC (Terminal 2)

Navigate to the IOC boot directory, ensure the EPICS environment is sourced, and run the startup script. Observe the output log, which shows the environment setup, the loading of the DBD, the `iocshLoad` commands being executed, and the contents of `training_device.iocsh` being run for each instance with the correct macro substitutions.

```
# Terminal 2

iocBoot/iocB46-182-jeonglee-Demo $ ./st3.cmd 
#!../../bin/linux-x86_64/jeonglee-Demo
< envPaths
epicsEnvSet("IOC","iocB46-182-jeonglee-Demo")
epicsEnvSet("TOP","/home/jeonglee/gitsrc/EPICS-IOC-demo")
epicsEnvSet("MODULES","/home/jeonglee/epics/1.1.1/debian-12/7.0.7/base/../modules")
epicsEnvSet("ASYN","/home/jeonglee/epics/1.1.1/debian-12/7.0.7/base/../modules/asyn")
epicsEnvSet("CALC","/home/jeonglee/epics/1.1.1/debian-12/7.0.7/base/../modules/calc")
epicsEnvSet("STREAM","/home/jeonglee/epics/1.1.1/debian-12/7.0.7/base/../modules/StreamDevice")
epicsEnvSet("PVXS","/home/jeonglee/epics/1.1.1/debian-12/7.0.7/base/../modules/pvxs")
epicsEnvSet("EPICS_BASE","/home/jeonglee/epics/1.1.1/debian-12/7.0.7/base")
epicsEnvSet("DB_TOP", "/home/jeonglee/gitsrc/EPICS-IOC-demo/db")
epicsEnvSet("STREAM_PROTOCOL_PATH", "/home/jeonglee/gitsrc/EPICS-IOC-demo/db")
epicsEnvSet("IOCSH_LOCAL_TOP",      "/home/jeonglee/gitsrc/EPICS-IOC-demo/iocsh")
epicsEnvSet("IOCNAME", "B46-182-jeonglee-Demo")
epicsEnvSet("IOC", "iocB46-182-jeonglee-Demo")
dbLoadDatabase "/home/jeonglee/gitsrc/EPICS-IOC-demo/dbd/jeonglee-Demo.dbd"
jeonglee_Demo_registerRecordDeviceDriver pdbbase
INFO: PVXS QSRV2 is loaded, permitted, and ENABLED.
cd "/home/jeonglee/gitsrc/EPICS-IOC-demo/iocBoot/iocB46-182-jeonglee-Demo"
# --- Configuration for Simulator Instance 1 ---
epicsEnvSet("PREFIX1",         "MYDEMO:")      # Main prefix
epicsEnvSet("DEVICE1",         "SIM1:")        # Unique device part
epicsEnvSet("ASYN_PORT_NAME1", "TCP1")         # Unique Asyn Port Name
epicsEnvSet("TARGET_PORT1",    "9399")         # TCP Port for simulator 1
# Load snippet for Instance 1
iocshLoad("/home/jeonglee/gitsrc/EPICS-IOC-demo/iocsh/training_device.iocsh", "PREFIX=MYDEMO:,DEVICE=SIM1:,DATABASE_TOP=/home/jeonglee/gitsrc/EPICS-IOC-demo/db,PORT_NAME=TCP1, PORT=9399")
####################################################################################################
############ START of training_device.iocsh ########################################################
drvAsynIPPortConfigure("TCP1", "127.0.0.1:9399", 0, 0, 0)
asynOctetSetInputEos("TCP1", 0, "\n")
asynOctetSetOutputEos("TCP1", 0, "\n")
dbLoadRecords("/home/jeonglee/gitsrc/EPICS-IOC-demo/db/training.db", "P=MYDEMO:,R=SIM1:,PORT=TCP1")
############ END of training_device.iocsh ##########################################################
####################################################################################################
# --- Configuration for Simulator Instance 2 ---
epicsEnvSet("PREFIX2",         "MYDEMO:")      # Main prefix
epicsEnvSet("DEVICE2",         "SIM2:")        # Unique device part
epicsEnvSet("ASYN_PORT_NAME2", "TCP2")         # Unique Asyn Port Name
epicsEnvSet("TARGET_PORT2",    "9400")         # TCP Port for simulator 2
# Load snippet for Instance 2
iocshLoad("/home/jeonglee/gitsrc/EPICS-IOC-demo/iocsh/training_device.iocsh", "PREFIX=MYDEMO:,DEVICE=SIM2:,DATABASE_TOP=/home/jeonglee/gitsrc/EPICS-IOC-demo/db,PORT_NAME=TCP2, PORT=9400")
####################################################################################################
############ START of training_device.iocsh ########################################################
drvAsynIPPortConfigure("TCP2", "127.0.0.1:9400", 0, 0, 0)
asynOctetSetInputEos("TCP2", 0, "\n")
asynOctetSetOutputEos("TCP2", 0, "\n")
dbLoadRecords("/home/jeonglee/gitsrc/EPICS-IOC-demo/db/training.db", "P=MYDEMO:,R=SIM2:,PORT=TCP2")
############ END of training_device.iocsh ##########################################################
####################################################################################################
# --- Configuration for Simulator Instance 3 ---
epicsEnvSet("PREFIX3",         "MYDEMO:")      # Main prefix
epicsEnvSet("DEVICE3",         "SIM3:")        # Unique device part
epicsEnvSet("ASYN_PORT_NAME3", "TCP3")         # Unique Asyn Port Name
epicsEnvSet("TARGET_PORT3",    "9401")         # TCP Port for simulator 3
# Load snippet for Instance 3
iocshLoad("/home/jeonglee/gitsrc/EPICS-IOC-demo/iocsh/training_device.iocsh", "PREFIX=MYDEMO:,DEVICE=SIM3:,DATABASE_TOP=/home/jeonglee/gitsrc/EPICS-IOC-demo/db,PORT_NAME=TCP3, PORT=9401, ASYNTRACE=")
####################################################################################################
############ START of training_device.iocsh ########################################################
drvAsynIPPortConfigure("TCP3", "127.0.0.1:9401", 0, 0, 0)
asynOctetSetInputEos("TCP3", 0, "\n")
asynOctetSetOutputEos("TCP3", 0, "\n")
asynSetTraceMask(TCP3, -1, ERROR|FLOW|DRIVER)
dbLoadRecords("/home/jeonglee/gitsrc/EPICS-IOC-demo/db/training.db", "P=MYDEMO:,R=SIM3:,PORT=TCP3")
############ END of training_device.iocsh ##########################################################
####################################################################################################
iocInit
Starting iocInit
############################################################################
## EPICS R7.0.7-github.com/jeonghanlee/EPICS-env
## Rev. R7.0.7-dirty
## Rev. Date Git: 2022-09-07 13:50:35 -0500
############################################################################
iocRun: All initialization complete
ClockTime_Report #-- Example site-specific utility
Program started at 2025-04-10 16:00:42.284773
#st.cmd Not comment to print out everything you write here, so you can see this comment. "How are you doing?" 
7.0.7 >
```

### 3. Verify Operation (Terminal 3)

Use CA client tools to interact with the PVs for each instance. Ensure the EPICS environment is sourced in this terminal.

```bash
# Terminal 3
# First, check the initial values (likely empty or zero)
$ caget MYDEMO:SIM{1..3}:Cmd-RB
MYDEMO:SIM1:Cmd-RB             
MYDEMO:SIM2:Cmd-RB             
MYDEMO:SIM3:Cmd-RB       

# Send a unique command to each instance using caput
$ caput MYDEMO:SIM1:Cmd "GetID?"
$ caput MYDEMO:SIM2:Cmd "GetID?"
$ caput MYDEMO:SIM3:Cmd "GetID?"

# Now, read back the replies using caget
# The simulator (using advanced_connection_handler.sh) should reply with its PID
$ caget MYDEMO:SIM{1..3}:Cmd-RB
MYDEMO:SIM1:Cmd-RB             1204665  # <-- Example PID reply for Sim 1
MYDEMO:SIM2:Cmd-RB             1204667  # <-- Example PID reply for Sim 2
MYDEMO:SIM3:Cmd-RB             1204669  # <-- Example PID reply for Sim 3


# Now, test the "GetTemp?" command for each instance
$ caput MYDEMO:SIM1:Cmd "GetTemp?"
$ caput MYDEMO:SIM2:Cmd "GetTemp?"
$ caput MYDEMO:SIM3:Cmd "GetTemp?"

# Read back the temperature replies
# The simulator should reply with a random number between 0 and 100
$ caget MYDEMO:SIM{1..3}:Cmd-RB
MYDEMO:SIM1:Cmd-RB             60       # <-- Example Temp reply for Sim 1
MYDEMO:SIM2:Cmd-RB             83       # <-- Example Temp reply for Sim 2
MYDEMO:SIM3:Cmd-RB             61       # <-- Example Temp reply for Sim 3
```

Successfully sending different commands (`GetID?`, `GetTemp?`) and receiving the expected, distinct replies for each instance confirms that the multi-device configuration loaded via `st3.cmd` and `iocshLoad` is working correctly, and the IOC is communicating independently with each simulator.

## Benefits of the `iocshLoad` Approach

Let's review why using `iocshLoad` with a reusable snippet file (`training_device.iocsh`) is generally more effective for managing multiple similar devices compared to writing all configuration commands directly in the main startup script (`st3.cmd`).

* **Reusability**: The core logic for configuring one simulator connection resides in one place (`training_device.iocsh`). This logic is reused three times simply by calling `iocshLoad` with different parameters (port, names, etc.).

* **Maintainability**: If the standard way to configure this type of simulated device needs to change (e.g., adding another Asyn command, modifying the dbLoadRecords call), you only need to edit the single snippet file (`training_device.iocsh`). All three instances will automatically use the updated configuration the next time the IOC starts. If configured directly in `st3.cmd`, you would need to find and edit the command block for all three instances, increasing effort and the risk of mistakes.

* **Readability & Clarity**: The `st3.cmd` file becomes much shorter and focuses on what devices are being configured (listing parameters) rather than the low-level details of how each is configured. The `iocshLoad` lines clearly indicate that a standard configuration block is being loaded for each instance.

* **Standardization**: This method encourages defining a standard, well-documented way (the `.iocsh` snippet) for configuring a specific type of device or connection, promoting consistency across potentially many IOCs within ALS-U.

* **Troubleshooting & Selective Disabling**: When a system with multiple devices is operational, imagine one device malfunctions. Instead of stopping the entire IOC or commenting out a large block of potentially complex direct configuration commands, you can simply add a `#` character in front of the specific `iocshLoad` line corresponding to the faulty device in `st3.cmd`. This quickly and cleanly disables that single device upon IOC restart, allowing the rest of the system to function while the issue is investigated. Furthermore, for focused debugging, you can easily uncomment that same iocshLoad line (perhaps in a separate test IOC instance) and add diagnostic flags, like the `ASYNTRACE=` option shown in the example, without altering the configuration of other devices.

While there's a small overhead in creating the initial snippet file and understanding macro substitution, the advantages for configuring multiple similar devices, especially in terms of long-term maintenance, scalability, and operational flexibility, make the `iocshLoad` method a highly effective and recommended practice in the ALS-U EPICS IOC development.

## Assignments or Questions for the further understanding.

* When you do `caget` or `caput` in Terminal 3, can you check what kind of messages you can see in `Terminal 2` (the running IOC console)? Pay attention when interacting with PVs associated with `SIM3:` (`TCP3`), as Asyn trace was enabled for that instance.