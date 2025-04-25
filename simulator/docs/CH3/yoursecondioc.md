# Your Second ALS-U EPICS IOC
In the previous lesson, you created a basic IOC structure. Now, we'll add functionality to communicate with external hardware, specifically a device connected via a serial communication (serial over `TCP/IP`). We'll use two most popular EPICS modules:

* Asyn: Provides a generic, layered approach to hardware communication (serial, GPIB, IP, etc.). We'll use it to manage the serial port itself.
* StreamDevice: Builds on Asyn to allow communication with text-based (ASCII) command/response devices using simple protocol files, avoiding the need to write custom C/C++ device support for many common cases.

We will later simulate the serial device using a TCP listening utility (like socat, or tcpsvd), allowing you to test the IOC without needing physical hardware that speaks TCP/IP.

## Lesson Overview
In this lesson, you will learn to:

* Add and configure EPICS modules for device communication (e.g., `Asyn`, `StreamDevice`).
* Define and implement device interaction logic using `StreamDevice` protocol file (`proto`) and database records file (`db`).
* Modify IOC build (`RELEASE`, `Makefile`) and startup (`st.cmd`) configurations for the device communication
* Build the IOC and examine its results.

## Step 1: Generate the IOC Structure
First, ensure your EPICS environment is set up, then use the template generator script to create a new IOC structure. We'll use `jeonglee-Demo` for the **APPNAME** and `B46-182` for the **LOCATION** in this example. Replace `jeonglee-Demo` with your preferred name if desired.

```shell
# 1. Set up the EPICS environment
$ source ~/epics/1.1.1/debian-12/7.0.7/setEpicsEnv.bash

# 2. Run the generator script
#    (Ensure you are NOT inside the previous 'mouse' or 'tools' directories)
$ bash tools/generate_ioc_structure.bash -l B46-182 -p jeonglee-Demo

# 3. Change into the newly created IOC directory
$ cd jeonglee-Demo

# 4. (Optional) View the top-level directory structure
jeonglee-Demo $ tree --charset=ascii -L 1
.
|-- configure
|-- docs
|-- iocBoot
|-- iocsh
|-- jeonglee-DemoApp
|-- Makefile
`-- README.md

# Note: bin, lib, db, dbd directories will be created after building.
```

## Step 2: Configure Dependencies (`configure/RELEASE`)
We need to tell the build system that our IOC depends on `Asyn`, `Calc`, and `StreamDevice`. Edit the `configure/RELEASE` file using your preferred text editor. With the ALS-U EPICS Environment, `StreamDevice` was built with support for `sCalcout` record, so you need to add `Calc` module dependency in your IOC.

```shell
jeonglee-Demo $ nano configure/RELEASE # Or vi configure/RELEASE
```

Find the module definitions section and uncomment the lines for ASYN, CALC, and STREAM by removing the leading `#`:

```makefile
# Snippet from configure/RELEASE
...
ASYN = $(MODULES)/asyn             # <-- UNCOMMENTED
...
CALC = $(MODULES)/calc             # <-- UNCOMMENTED
...
STREAM = $(MODULES)/StreamDevice   # <-- UNCOMMENTED
...

```

Save and close the `configure/RELEASE` file.

## Step 3: Understanding Dependency Handling in `jeonglee-DemoApp/src/Makefile`
After defining module dependencies in `configure/RELEASE` (Step 2), the EPICS build system uses `Makefiles` like `<APPNAME>App/src/Makefile` to determine which components to include when building the final IOC application.

You can examine this file to see how standard dependencies, like the ones you just uncommented, are typically handled automatically by the template generator.

Let's examine the `jeonglee-DemoApp/src/Makefile`:

```shell
jeonglee-Demo $ less jeonglee-DemoApp/src/Makefile
```

Inside this file, you will find standard conditional logic, often using `ifneq` blocks (meaning "if not equal" - essentially checking if the variable is defined/non-empty), similar to the snippet below:

```makefile
# Snippet from jeonglee-DemoApp/src/Makefile showing standard conditional inclusion

PROD_IOC = jeonglee-Demo
# jeonglee-Demo.dbd will be created and installed
DBD += jeonglee-Demo.dbd

Common_DBDs += base.dbd
Common_DBDs += system.dbd # Specific additions may exist

# Add custom C/C++ source files here if needed
Common_SRCs +=

# --- Automatic inclusion based on configure/RELEASE ---
ifneq ($(ASYN),)                       # If ASYN was defined (uncommented) in RELEASE
Common_DBDs += asyn.dbd                # include Asyn's dbd files
Common_DBDs += drvAsynIPPort.dbd
Common_DBDs += drvAsynSerialPort.dbd   # Note: Both IP and Serial DBDs be included by default
Common_LIBs += asyn                    #       and link against the Asyn library
endif

ifneq ($(CALC),)                       # If CALC was defined in RELEASE
Common_DBDs += calcSupport.dbd         #    include its dbd
Common_LIBs += calc                    #    and link its library
endif

ifneq ($(STREAM),)                     # If STREAM was defined in RELEASE
Common_DBDs += stream.dbd              #    include its dbd
Common_LIBs += stream                  #    and link its library
endif

...
```

Because of these standard `ifneq` blocks within `Makefile`, the necessary database definitions (`Common_DBDs`) and libraries (`Common_LIBs`) for modules like `ASYN`, `CALC`, and `STREAM` are included automatically by the build system when you uncomment them in `configure/RELEASE`.

Therefore, **no manual editing** of `jeonglee-DemoApp/src/Makefile` is required just to include these standard module dependencies configured in Step 2. You would typically only edit this file if you were adding your own C/C++ source code files to `Common_SRCs` or needed to link other non-standard libraries manually.

## Step 4: Create StreamDevice and EPICS Database Files (`jeonglee-DemoApp/Db`)
Define the communication protocol and the EPICS records database:

* Create the Protocol File (`training.proto`)

```shell
jeonglee-Demo $ nano jeonglee-DemoApp/Db/training.proto
```

Add the following content:

```coffee
# Protocol definition for basic command/query

sendRawQuery {
  ExtraInput = Ignore; # Standard setting for processing record output
  out "%s";            # Format to send: output the string from the record's OUT field
  in "%(\$1)40c";      # Format to read: read up to 40 chars (%40c) into the PV name passed as argument $1
}
```

Save and close the `training.proto` file.

* Create the EPICS Database File (`training.db`)

```shell
jeonglee-Demo $ emacs jeonglee-DemoApp/Db/training.db
```

Add the following record definitions:

```c
# Database file for StreamDevice TCP communication example

# Record to send the query string via StreamDevice
record(stringout, "$(P)$(R)Cmd")
{
    field(DESC, "Raw Query")      # Description of the record
    field(SCAN, "Passive")        # Record only processes when explicitly written to
    field(DTYP, "stream")         # Use StreamDevice device support
    field( OUT, "@training.proto sendRawQuery($(P)$(R)Cmd-RB.VAL) $(PORT)")
	  # Specify protocol file, protocol name, target PV for reply ($1), and Asyn Port name
}

# Record to receive the reply string read by StreamDevice
record(stringin, "$(P)$(R)Cmd-RB")
{
    field(DESC, "Raw Query Readback")  # Description
    field(SCAN, "Passive")             # Value is written by StreamDevice, not by scanning
    field(DTYP, "Soft Channel")        # Standard software record type
}
```
Save and close the `training.db` file.

## Step 5: Check the Makefile (`jeonglee-DemoApp/Db/Makefile`)
Now that you've placed your StreamDevice source files (`training.proto`, `training.db`) in the `jeonglee-DemoApp/Db` directory (Step 4), let's look at how the build system includes them. Following EPICS conventions, the Makefile located within this same directory (`jeonglee-DemoApp/Db/Makefile`) is usually responsible for handling these types of files.

Often, this `Db/Makefile` is set up to automatically find and include any database (`.db`) and protocol (`.proto`) files placed within the `jeonglee-DemoApp/Db` directory. This means you usually don't need to manually edit this `Makefile` every time you add a new `.db` or `.proto` file. We will cover the different scenario in a more advanced topic for a separate lesson.

Furthermore, the build process takes these source files found via the `Db/Makefile` and installs them into the standard runtime database directory. By default, for development builds, this location is `$(TOP)/db`, where `$(TOP)` refers to the top-level directory of your IOC source code. (The `st.cmd` script in Step 6 correctly uses a path relative to this runtime `$(TOP)`).

**Important Note on Installation Paths**: Be aware that for production deployments, the final installation location of the IOC (including its db directory) can be controlled by setting the `INSTALL_LOCATION` variable, done in the `configure/CONFIG_SITE` file. If `INSTALL_LOCATION` is used during the build, the runtime `TOP` directory (where the IOC executable runs from and finds its `db` folder) may be different from your source `TOP` directory. How to manage `INSTALL_LOCATION` is a more advanced topic for a separate lesson, but it's useful to know that the runtime path isn't always the same as the source path, although it defaults to that for simple builds.

Let's examine the `jeonglee-DemoApp/Db/Makefile`:

```shell
jeonglee-Demo $ less jeonglee-DemoApp/Db/Makefile # Use less or your editor
```

Inside, you might find rules similar to the following (confirmed accurate for the ALS-U template), which use functions like wildcard and patsubst to achieve the automatic inclusion:

```makefile
# Snippet from jeonglee-DemoApp/Db/Makefile showing automatic inclusion mechanism
# (This specific syntax uses wildcard/patsubst to find files in parent dir and adjust path)
...
# Example mechanism (details may vary but result is automatic inclusion):
DB += $(patsubst ../%, %, $(wildcard ../*.db))
DB += $(patsubst ../%, %, $(wildcard ../*.proto))
...

```

Because the template's `Db/Makefile` is designed to automatically find `.db` and `.proto` files in the `jeonglee-DemoApp/Db` directory, **no changes are needed in this `Makefile`** for the `training.db` and `training.proto` files you created in Step 4. The build system automatically incorporates these files into the build process and handles their installation (by default to `$(TOP)/db`). This automation significantly simplifies the development workflow, especially for developers newer to EPICS or when creating less complex IOCs.

## Step 6: Configure Startup Script (iocBoot/iocB46-182-jeonglee-Demo/st.cmd)
Now, we need to configure the IOC's startup script (`st.cmd`). This script runs when the IOC starts and is responsible for setting up communication, loading database records, and initializing the system. We will modify it to:

* Define the macros (`$(P)`, `$(R)`, `$(PORT)`) used in our database (`training.db`).
* Configure an Asyn IP Port to connect to our simulated TCP device.
* Set the correct path for StreamDevice protocol files.
* Load the database records using the defined macros.
* Initialize the IOC.

Navigate to the IOC boot directory and edit the `st.cmd` file using your preferred text editor (e.g., vi, nano, emacs):

```shell
jeonglee-Demo $ cd iocBoot/iocB46-182-jeonglee-Demo
iocB46-182-jeonglee-Demo $ vi st.cmd # Or nano st.cmd
```
Modify the file to include the necessary configurations, similar to the example below. Pay close attention to the sections marked with comments like `#-- --- Define Macros ---` or `#-- --- Asyn IP Port Configuration ---`.

```shell
#!../../bin/linux-x86_64/jeonglee-Demo

#-- Load environment paths (sets TOP, EPICS_BASE etc.)
#-- It will be generated during the building process.
< envPaths

#-- Set a variable for the top-level db directory where .db and .proto files reside during runtime
#-- Note that this is the installed $(TOP)/db folder, not the source <APPNAME>App/Db folder.
epicsEnvSet("DB_TOP", "$(TOP)/db")
#-- Set the path where StreamDevice should look for protocol (.proto) files
epicsEnvSet("STREAM_PROTOCOL_PATH", "$(DB_TOP)")

#-- --- Define Macros for dbLoadRecords ---
#-- Define the Prefix macro value (substituted for $(P) in .db files)
epicsEnvSet("PREFIX_MACRO", "jeonglee:")
#-- Define the Record/Device macro value (substituted for $(R) in .db files)
epicsEnvSet("DEVICE_MACRO", "myoffice:")
#-- --- End Macros ---

#-- Standard IOCNAME and IOC settings
#-- These EPICS IOC variables were defined by the template generator,
#-- since these two variables are out-standing badly confusing variables
#-- through EPICS history, please don't change if you have the very specific reasons
#-- if your IOC within the ALS-U Controls Production Enviornment.
epicsEnvSet("IOCNAME", "B46-182-jeonglee-Demo")
epicsEnvSet("IOC", "iocB46-182-jeonglee-Demo")

#-- Load the compiled database definitions (.dbd file generated by build)
#-- Path is relative to TOP directory.
dbLoadDatabase "$(TOP)/dbd/jeonglee-Demo.dbd"
#-- Register device and driver support compiled into the IOC application
jeonglee_Demo_registerRecordDeviceDriver pdbbase

#-- Change directory to the IOC's specific boot directory (standard practice before iocInit)
cd "${TOP}/iocBoot/${IOC}"

#-- --- Asyn IP Port Configuration ---
#-- Define connection parameters for the Asyn port we will create
epicsEnvSet("ASYN_PORT_NAME", "LocalTCPServer") # Logical name for this Asyn port
epicsEnvSet("TARGET_HOST",    "127.0.0.1")      # IP address of the target device/simulator
epicsEnvSet("TARGET_PORT",    "9399")           # TCP port of the target device/simulator

#-- Configure the Asyn IP port using the parameters defined above
#-- drvAsynIPPortConfigure("portName", "host:port", priority, noAutoConnect, noProcessEos)
#-- priority=0 (default), noAutoConnect=0 (connect immediately), noProcessEos=0 (use Asyn default EOS processing)
drvAsynIPPortConfigure("$(ASYN_PORT_NAME)", "$(TARGET_HOST):$(TARGET_PORT)", 0, 0, 0)

#-- Configure End-of-String (EOS) terminators for the Asyn port layer
#-- These define how messages are delimited when reading from/writing to the port.
#-- Ensure these match the actual device/simulator protocol! (\n = newline, \r = carriage return)
#-- NOTE: While EOS can sometimes be defined within the StreamDevice protocol file (.proto),
#-- for long-term maintenance, it is often considered best practice to define port-specific
#-- behavior like EOS explicitly in the st.cmd file using Asyn commands.

#-- Input EOS (what character(s) mark the end of a message *received from* the device)
asynOctetSetInputEos("$(ASYN_PORT_NAME)", 0, "\n") # Using newline
#-- Output EOS (what character(s) should be *appended to* messages *sent to* the device)
asynOctetSetOutputEos("$(ASYN_PORT_NAME)", 0, "\n") # Using newline (Ensure simulator/device expects this!)
#-- --- End Asyn Config ---

#-- --- Load Database Records ---
#-- Load the record instances from our .db file (path relative to TOP via DB_TOP)
#-- Substitute the macros within the .db file using the values defined above:
#-- $(P) will become "jeonglee:"
#-- $(R) will become "myoffice:"
#-- $(PORT) will become "LocalTCPServer"
dbLoadRecords("$(DB_TOP)/training.db", "P=$(PREFIX_MACRO),R=$(DEVICE_MACRO),PORT=$(ASYN_PORT_NAME)")
#-- --- End Record Load ---

#-- Initialize the IOC
#-- This command starts record processing, enables Channel Access connections, etc.
#-- It MUST come *after* all hardware (Asyn port) configuration and record loading.
iocInit

#-- --- Optional Post-Initialization Commands ---
#-- Add any commands to run after the IOC is fully initialized, for example:
ClockTime_Report # Example site-specific utility
#-- --- End Post-Init ---

#-- --- st.cmd Comment ---
#-- st.cmd comment to suppress outputs when we run st.cmd, so you cannot see this comment
# st.cmd Not comment to print out everything you write here, so you can see this comment. 
# "How are you doing?" 

```

Key Points Reminder:
* Variables: Using `epicsEnvSet` makes the script easier to read and modify.
* Paths: `DB_TOP` and `STREAM_PROTOCOL_PATH` point to the runtime location of database/protocol files.
* Macros: `PREFIX_MACRO $(P)` and `DEVICE_MACRO $(R)` are defined and passed to dbLoadRecords.
* Asyn Config: `drvAsynIPPortConfigure` connects to the host/port. `asynOctetSetInput(Output)Eos` defines message terminators (set to `\n` here).
* iocInit: Must be called after configuration and record loading.
* Comments: Lines starting with `#--` are comments ignored by the IOC shell during the runtime; they are used in `st.cmd` for explanation.

After editing and saving the `st.cmd` file, return to the top-level IOC directory to prepare for the next steps:

```shell
# Command executed from: iocBoot/iocB46-182-jeonglee-Demo
iocB46-182-jeonglee-Demo $ cd ../..

# Now back in the top-level directory
jeonglee-Demo $ pwd
/path/to/your/jeonglee-Demo # Should show the top-level directory
```

## Step 7: Build the IOC and Check Structure
With the source files (`.proto`, `.db`) created and the configuration files (`RELEASE`, `st.cmd`, `Makefiles` checked/understood) in place, you can now build the IOC application executable.

The EPICS build system, invoked using the `make` command from the top-level IOC directory, orchestrates this process. It compiles necessary code, processes database definitions (`.dbd`), links required libraries (EPICS Base, Asyn, Calc, StreamDevice, PVXS, etc. based on your `RELEASE` file), and installs the resulting executable and related runtime files into standard subdirectories (`bin`, `lib`, `dbd`, `db`) respect to the runtime `${TOP}` path.

### Build the IOC:
Ensure you are in the top-level directory of your IOC (e.g., `/path/to/your/jeonglee-Demo`) and execute the `make` command:

```shell
# Prompt should show your top-level IOC directory
jeonglee-Demo $ make
```

You will see various compilation and linking messages scroll by. This might take a moment, especially the first time you build or after significant changes. Pay close attention to the end of the output to ensure there are no error messages.

### Verify Build Output and Directory Structure:
A successful build creates several important directories and files. It's crucial to verify they exist as expected.

* Check Key Directories: After make finishes, list the contents of your top-level directory. You should now see `bin`, `db`, `dbd`, and lib directories alongside the source directories (`configure`, `jeonglee-DemoApp`, `iocBoot`, etc.). There is the `iocsh` folder, which we will cover that subject in a advanced lesson later.

```shell
$ tree -L 1 --charset=ascii
.
|-- bin         #<--- Executables installed here
|-- configure
|-- db          #<--- Runtime DB/PROTO files installed here
|-- dbd         #<--- Runtime DBD files installed here
|-- iocBoot     # Contains source st.cmd script (runtime copy might be elsewhere or same)
|-- iocsh       # Source location for iocsh scripts (if any)
|-- jeonglee-DemoApp
|-- lib         #<--- Libraries (if any) installed here
|-- Makefile    # Top-level makefile
`-- README.md   # Basic readme
```

* Explicitly check if the IOC executable was created:

```shell
jeonglee-Demo $ ls -l bin/linux-x86_64/jeonglee-Demo 
-r-xr-xr-x 1 jeonglee jeonglee ... ... bin/linux-x86_64/jeonglee-Demo
```

* Check for Installed Runtime Files: Verify the files created in Step 4 were installed by the build system into the top-level db directory, and the application DBD was generated in dbd.

```shell
# Check for .db and .proto files in the runtime 'db' directory
jeonglee-Demo $ ls -l db/training.*
# Expected output should list: db/training.db and db/training.proto

# Check for the final application DBD file
jeonglee-Demo $ ls -l dbd/jeonglee-Demo.dbd
# Expected output should list: dbd/jeonglee-Demo.dbd
```

* Check Library Dependencies (Optional):

On Linux systems, the `ldd` command shows the shared libraries an executable is linked against. This is a good way to verify that the dependencies you uncommented in `configure/RELEASE` (Asyn, Calc, StreamDevice) were correctly linked into your IOC executable.

```shell
jeonglee-Demo $ ldd bin/linux-x86_64/jeonglee-Demo
```

Scan the output list for `libasyn.so`, `libcalc.so`, and `libstream.so` (along with Base and PVXS libraries):

```r
...
libasyn.so => /path/to/epics/modules/asyn/lib/linux-x86_64/libasyn.so (...)
libcalc.so => /path/to/epics/modules/calc/lib/linux-x86_64/libcalc.so (...)
libstream.so => /path/to/epics/modules/StreamDevice/lib/linux-x86_64/libstream.so (...)
# You'll also see libraries from EPICS Base (libCom, libdbCore, etc.)
# and potentially default modules like PVXS (libpvxs.so and libpvxsIoc.so)
...
```

Seeing these libraries confirms that Step 2 (editing `RELEASE`) and the Makefiles worked correctly to include the necessary code.

### Troubleshooting: If make fails with errors:
* Read the error messages carefully. They often point to the specific file and line number causing the issue.
* Common errors include:
  * Typos in `configure/RELEASE` or `Makefiles`.
  * Syntax errors in `.db` or `.proto` files.
  * Missing module dependencies (forgetting to uncomment in `RELEASE`).
  * Problems with the EPICS environment setup (`source setEpicsEnv.bash`).
* Go back through the previous steps, double-check your edits, and try running make again. You can use make clean first to remove intermediate files if you suspect an inconsistent build state.

This step covers the build process and essential checks to ensure the IOC application is ready for the next steps (simulation and testing).
