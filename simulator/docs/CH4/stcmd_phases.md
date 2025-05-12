# 4.6 IOC Startup Sequence (`st.cmd` Phases)

The startup script, conventionally named `st.cmd`, is the script executed when an EPICS Input/Output Controller (IOC) starts. It's a sequence of commands interpreted by the IOC shell (`iocsh`) that sets up your EPICS IOC environment, loads the necessary software components and database configurations, and ultimately brings the control system to a ready and operational state. Understanding the structure and phases of the `st.cmd` script is fundamental to developing and debugging IOC applications.

The execution flow of the `st.cmd` is critically divided by a single command: `iocInit()`. This command marks the transition from a configuration phase to an operational phase.

Before diving into the `st.cmd` script itself, it's helpful to understand the two main components that constitute an EPICS IOC application at runtime:

1.  **IOC Binary Files:** These are the executable programs and associated libraries that contain the compiled EPICS core, module support, and your application-specific code (driver support, device support, etc.).

2.  **IOC Configuration Files:** These are the data files that the IOC binary loads at startup to define its behavior, the process variables (PVs) it will manage, and how it interacts with hardware.

## Check Binary Files

The IOC executable is the program you run to start your EPICS IOC. It's typically found in the `bin/<architecture>` directory within your application's top-level directory.

You can execute the IOC directly from the command line. Without an `st.cmd` file specified as an argument, it often starts in an interactive `iocsh` mode, where you can manually enter commands:

```bash
$ ./bin/linux-x86_64/jeonglee-Demo
7.0.7 > help
7.0.7 > dbl
7.0.7 > iocInit
```

This shows the IOC shell prompt (7.0.7 >) and that basic commands like `help`, `dbl` (database list), and `iocInit` are available. Please check what you see after each command.

You can also inspect the shared libraries that your IOC executable depends on using system tools like ldd on Linux:

```
$ ldd bin/linux-x86_64/jeonglee-Demo 
	linux-vdso.so.1 (0x00007ffe787f1000)
	libasyn.so => /home/jeonglee/epics/1.1.1/debian-12/7.0.7/modules/asyn/lib/linux-x86_64/libasyn.so (0x00007f0dfd15b000)
	libcalc.so => /home/jeonglee/epics/1.1.1/debian-12/7.0.7/modules/calc/lib/linux-x86_64/libcalc.so (0x00007f0dfd116000)
	libstream.so => /home/jeonglee/epics/1.1.1/debian-12/7.0.7/modules/StreamDevice/lib/linux-x86_64/libstream.so (0x00007f0dfd0c5000)
	libpvxsIoc.so.1.3 => /home/jeonglee/epics/1.1.1/debian-12/7.0.7/modules/pvxs/lib/linux-x86_64/libpvxsIoc.so.1.3 (0x00007f0dfd04e000)
	libdbRecStd.so.3.22.0 => /home/jeonglee/epics/1.1.1/debian-12/7.0.7/base/lib/linux-x86_64/libdbRecStd.so.3.22.0 (0x00007f0dfd007000)
	libdbCore.so.3.22.0 => /home/jeonglee/epics/1.1.1/debian-12/7.0.7/base/lib/linux-x86_64/libdbCore.so.3.22.0 (0x00007f0dfcf70000)
	libCom.so.3.22.0 => /home/jeonglee/epics/1.1.1/debian-12/7.0.7/base/lib/linux-x86_64/libCom.so.3.22.0 (0x00007f0dfcefa000)
	libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007f0dfccf5000)
	libtirpc.so.3 => /lib/x86_64-linux-gnu/libtirpc.so.3 (0x00007f0dfccc5000)
	libstdc++.so.6 => /lib/x86_64-linux-gnu/libstdc++.so.6 (0x00007f0dfca00000)
	libgcc_s.so.1 => /lib/x86_64-linux-gnu/libgcc_s.so.1 (0x00007f0dfcca5000)
	libsscan.so => /home/jeonglee/epics/1.1.1/debian-12/7.0.7/modules/sscan-589eac4/lib/linux-x86_64/libsscan.so (0x00007f0dfcc73000)
	libseq.so => /home/jeonglee/epics/1.1.1/debian-12/7.0.7/modules/seq-2.2.9/lib/linux-x86_64/libseq.so (0x00007f0dfcc5f000)
	libm.so.6 => /lib/x86_64-linux-gnu/libm.so.6 (0x00007f0dfc920000)
	libpvxs.so.1.3 => /home/jeonglee/epics/1.1.1/debian-12/7.0.7/modules/pvxs/lib/linux-x86_64/libpvxs.so.1.3 (0x00007f0dfc7c4000)
	/lib64/ld-linux-x86-64.so.2 (0x00007f0dfd229000)
	libca.so.4.14.2 => /home/jeonglee/epics/1.1.1/debian-12/7.0.7/base/lib/linux-x86_64/libca.so.4.14.2 (0x00007f0dfc762000)
	libreadline.so.8 => /lib/x86_64-linux-gnu/libreadline.so.8 (0x00007f0dfc70a000)
	libgssapi_krb5.so.2 => /lib/x86_64-linux-gnu/libgssapi_krb5.so.2 (0x00007f0dfc6b7000)
	libpv.so => /home/jeonglee/epics/1.1.1/debian-12/7.0.7/modules/seq-2.2.9/lib/linux-x86_64/libpv.so (0x00007f0dfcc58000)
	libevent_core-2.1.so.7 => /lib/x86_64-linux-gnu/libevent_core-2.1.so.7 (0x00007f0dfcc22000)
	libevent_pthreads-2.1.so.7 => /lib/x86_64-linux-gnu/libevent_pthreads-2.1.so.7 (0x00007f0dfcc1d000)
	libtinfo.so.6 => /lib/x86_64-linux-gnu/libtinfo.so.6 (0x00007f0dfc684000)
	libkrb5.so.3 => /lib/x86_64-linux-gnu/libkrb5.so.3 (0x00007f0dfc5aa000)
	libk5crypto.so.3 => /lib/x86_64-linux-gnu/libk5crypto.so.3 (0x00007f0dfc57d000)
	libcom_err.so.2 => /lib/x86_64-linux-gnu/libcom_err.so.2 (0x00007f0dfc577000)
	libkrb5support.so.0 => /lib/x86_64-linux-gnu/libkrb5support.so.0 (0x00007f0dfc569000)
	libkeyutils.so.1 => /lib/x86_64-linux-gnu/libkeyutils.so.1 (0x00007f0dfc562000)
	libresolv.so.2 => /lib/x86_64-linux-gnu/libresolv.so.2 (0x00007f0dfc54f000)
```

This output shows that the `jeonglee-Demo` executable depends on various EPICS Base libraries (`libdbCore.so`, `libCom.so`, `libca.so`) and module libraries (`libasyn.so`, `libstream.so`, etc.), confirming that these components are linked into the final IOC binary.

## IOC Configuration Files

These files define the specific behavior and data points (PVs) of your IOC instance. They are typically generated during the build process and/or created manually. Key configuration file types include:

* `db` : [Build] Contains EPICS database instance (.db, .template, .substitutions) and other associated files (like StreamDevice protocol files).
* `dbd` : [Build] Contains Generated IOC Database Definition (.dbd) files.
* `iocBoot`: [Build, Template, Manual] Directory containing startup scripts (`st.cmd`, `.iocsh`) and often site-specific configuration files. Generated initially by templates but frequently updated manually.
* `iocsh` : [Build] Often contains local `.iocsh` snippet files, which are reusable portions of startup scripts.

These directories and files contain the instructions and data that the IOC binary loads at runtime to configure itself.

## Anatomy of the st.cmd

The `st.cmd` script acts as the central script that brings together the binary capabilities and the configuration data. It tells the IOC binary what definitions to load, what hardware to configure, and what records to instantiate and run. The script's structure can be broadly categorized based on the `iocInit()` command.

An EPICS IOC startup script will cover these two major components (Binary Capabilities and Configuration Files) at some level within categories such as Environment, Device / System Configuration, and Database Configuration executed before `iocInit()`.

Then the predefined EPICS core `iocInit()` command will perform the core initialization work. After this, we can add additional commands for post-initialization tasks, diagnostics, or starting other runtime components.


## The Role of `iocInit()`

The `iocInit()` command is the central pivot of the IOC startup. Its significance lies in triggering the core initialization routines of the EPICS runtime environment. Before `iocInit()`, the IOC shell is primarily loading definitions and configuring resources. After `iocInit()`, the EPICS kernel becomes fully active, starting threads for record processing, enabling Channel Access server functionality, and initializing the loaded records.

Think of it like powering up a complex machine:

* **Before `iocInit()`:** You're plugging in the components, connecting the wires, and loading the operating instructions. The system is assembled but not yet running.

* **`iocInit()`:** You press the main power button. The system boots up, performs internal checks, and gets ready to execute its tasks.

* **After `iocInit()`:** The machine is running, performing its intended operations, and responding to external commands.


## Before `iocInit()`: Configuration and Loading

The commands placed in `st.cmd` *before* the `iocInit()` call are responsible for preparing the environment and loading the foundational elements required by the IOC. This phase ensures that all necessary software support is loaded and configured before the system attempts to initialize records and interact with hardware.

Looking at your example `st.cmd`:


```c
#!../../bin/linux-x86_64/jeonglee-Demo

#-- Environment 
< envPaths

epicsEnvSet("DB_TOP", "$(TOP)/db")
epicsEnvSet("STREAM_PROTOCOL_PATH", "$(DB_TOP)")
epicsEnvSet("EPICS_DB_INCLUDE_PATH", "$(DB_TOP)")

epicsEnvSet("PREFIX_MACRO", "MYDEMO:")
epicsEnvSet("DEVICE_MACRO", "TC32:")

epicsEnvSet("IOCNAME", "training-jeonglee-Demo")
epicsEnvSet("IOC", "ioctraining-jeonglee-Demo")

dbLoadDatabase "$(TOP)/dbd/jeonglee-Demo.dbd"
jeonglee_Demo_registerRecordDeviceDriver pdbbase

cd "${TOP}/iocBoot/${IOC}"

#-- Device / System Configuration
epicsEnvSet("ASYN_PORT_NAME", "LocalTCPServer")
epicsEnvSet("TARGET_HOST",    "127.0.0.1")
epicsEnvSet("TARGET_PORT",    "9399")
drvAsynIPPortConfigure("$(ASYN_PORT_NAME)", "$(TARGET_HOST):$(TARGET_PORT)", 0, 0, 0)
asynOctetSetInputEos("$(ASYN_PORT_NAME)", 0, "\n")
asynOctetSetOutputEos("$(ASYN_PORT_NAME)", 0, "\n")

#-- Device Database Configuration
dbLoadRecords("$(DB_TOP)/TC-32.db", "P=$(PREFIX_MACRO),R=$(DEVICE_MACRO),PORT=$(ASYN_PORT_NAME)")

#-- iocInit
iocInit

#-- After iocInit, commands and others...
ClockTime_Report
```
Here are the typical types of commands found in this phase, illustrated by your example:

1. **Environment Setup:**

* `< envPaths`: This is a common convention to source the `envPaths` file. This file, usually generated during the build process (as seen in your `envPaths` example below), defines essential environment variables like `TOP`, `EPICS_BASE`, and paths to included EPICS modules.

```bash
#-- IOC Unique Identity 
epicsEnvSet("IOC","ioctraining-jeonglee-Demo")
#-- TOP : runtime TOP folder for your IOC applications
epicsEnvSet("TOP","/home/jeonglee/gitsrc/EPICS-IOC-demo")
#-- Variables defined in configure/RELEASE
epicsEnvSet("MODULES","/home/jeonglee/epics/1.1.1/debian-12/7.0.7/base/../modules")
epicsEnvSet("ASYN","/home/jeonglee/epics/1.1.1/debian-12/7.0.7/base/../modules/asyn")
epicsEnvSet("CALC","/home/jeonglee/epics/1.1.1/debian-12/7.0.7/base/../modules/calc")
epicsEnvSet("STREAM","/home/jeonglee/epics/1.1.1/debian-12/7.0.7/base/../modules/StreamDevice")
epicsEnvSet("PVXS","/home/jeonglee/epics/1.1.1/debian-12/7.0.7/base/../modules/pvxs")
epicsEnvSet("EPICS_BASE","/home/jeonglee/epics/1.1.1/debian-12/7.0.7/base")
```
* `epicsEnvSet("VAR_NAME", "value")`: Used to define additional environment variables specific to the application or IOC instance. This includes defining paths (`DB_TOP`, `STREAM_PROTOCOL_PATH`), or macro values (`PREFIX_MACRO`, `DEVICE_MACRO`, `IOCNAME`). These variables and macros make the `st.cmd` script more flexible and easier to manage.

2. **Database Definition and Support Registration:**

* `dbLoadDatabase "$(TOP)/dbd/jeonglee-Demo.dbd`": Loads the compiled database definitions (`.dbd`) file. Note that `.dbd` file contains any type of definition except record instances defined in a `.db` file. EPICS has teh following database defintionns such as `Menu`, `Record Type`, `Device`, `Driver`, `Registrar`, `Variable`, `Function`, and `Breakpoint Table`.

* `jeonglee_Demo_registerRecordDeviceDriver pdbbase`: This command (where `jeonglee_Demo` is typically derived from your application name) registers the device and driver support routines that were linked into your IOC executable with the EPICS database processing core. This is crucial so that records can find and connect to the low-level code that interacts with hardware. The source file will be generated automatically through the building procedure. You can check it in `jeonglee-DemoApp/src/O.linux-x86_64/jeonglee-Demo_registerRecordDeviceDriver.cpp` and the file is defined in `jeonglee-DemoApp/src/Makefile` as well.

3. **Changing Directory:**
* `cd "${TOP}/iocBoot/${IOC}"`: Changes the current working directory to the IOC's specific boot directory. This is a common convention and simplifies the paths used for loading subsequent configuration files.

4. **Hardware and Driver Configuration:**

* `drvAsynIPPortConfigure("LocalTCPServer", "127.0.0.1:9399", ...)`: Commands specific to hardware drivers or communication modules (like Asyn) are placed here. This configures the low-level interface used to communicate with external devices.

* `asynOctetSetInputEos(...), asynOctetSetOutputEos(...)`: Configuration specific to the communication protocol, such as setting end-of-string terminators for serial or TCP communication.

5. **Record Instance Loading:**

* `dbLoadRecords("$(DB_TOP)/TC-32.db", "P=$(PREFIX_MACRO),R=$(DEVICE_MACRO),PORT=$(ASYN_PORT_NAME)")`: 
Loads the actual record instances (the PVs) using database files (`.db`).

At the end of this phase, the IOC shell has loaded all the necessary definitions, configured the communication interfaces, and created the record instances in memory, but the records are not yet actively processing or interacting with the hardware in a real-time loop.

## `iocInit()`: Bringing the IOC to Life

The `iocInit()` command is the turning point. When executed, it performs the vital initialization steps that transition the IOC from a configured state to an active, running system. This involves initializing the EPICS *kernel*, starting background tasks, initializing loaded records (including resolving links and calling device support init routines), setting up scanning and access security, processing records with `PINI=YES`, and starting the Channel Access server.

Once `iocInit()` completes, the IOC is **"live."** Records configured for scanning will begin processing, Channel Access clients can connect and interact with the PVs, and the IOC is actively monitoring and controlling the connected hardware.

For a detailed explanation of the internal steps performed by `iocInit()`, including the distinction between `iocBuild` and `iocRun` phases and the sequence of calls to various EPICS subsystems and initialization hooks, please refer to the separate documentation on [Advanced `iocInit()`](adviocInit.md) [^note].

## After iocInit(): Post-Initialization Actions

Commands placed after `iocInit()` are executed in the context of a fully initialized and running IOC. These commands are typically used for tasks that rely on the IOC's real-time environment and the active processing of records.

In your example st.cmd, there is one command after `iocInit()`:

```shell
ClockTime_Report
```

Typical actions in this phase include:

* **Starting Sequence Programs (SNC Programs):** Sequence programs, which implement complex state machine logic using SNL, are commonly started after `iocInit()` using the `seq` command. This ensures that the PVs the sequence program interacts with are already loaded and initialized.

* **Performing Post-Startup Configuration:** While most configuration is done before `iocInit()`, sometimes specific settings or actions that depend on the IOC being live are performed here.

* **Running Diagnostic or Utility Commands:** Commands for reporting status, health checks, or other utilities that are relevant after the IOC is fully operational can be placed here, such as the `ClockTime_Report` in your example. These might provide confirmation that the IOC started successfully and is functioning as expected.

* **Setting Initial PV Values:** While initial values are often handled during record initialization via device support, in some cases, commands might be used here to set specific PVs to a desired state after startup, although this is less common than setting values before iocInit or relying on device support init.


[^note]: Based on the [EPICS Application Developer’s Guide](https://docs.epics-controls.org/en/latest/appdevguide/IOCInit.html#id1)