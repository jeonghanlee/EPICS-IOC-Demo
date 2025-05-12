# 5.1 Style of `st.cmd` Commands

The `st.cmd` file is a sequence of commands executed by the EPICS IOC shell during startup. These commands can call built-in EPICS functions, functions registered by loaded modules, or execute shell commands prefixed with `<`.

You might have noticed different styles of writing commands in `st.cmd`. EPICS supports variations in how arguments are passed, primarily related to the use of parentheses and commas versus simple space separation.

Let's look at the common styles:

* **Style 1: Function-like syntax with parentheses and commas**

    This style looks like a function or command call you might see in programming. You put the command name, then arguments inside parentheses, separated by commas.

    `command("arg1", "arg2", ...)`

* **Style 2: Space-separated syntax**

    This style looks more like commands you type directly into a simple computer command line. You put the command name, then the arguments with spaces between them.

    `command "arg1" "arg2" ...`

Both styles are generally accepted by the EPICS IOC shell for most commands, though specific commands might have preferences or require quotes around arguments containing spaces or special characters.


Let's look at examples you already saw:

1. **Setting up EPICS environment value (`epicsEnvSet`):**
    You can write it as:

    `epicsEnvSet("STREAM_PROTOCOL_PATH", "$(DB_TOP)")`

    Or just using spaces:

    `epicsEnvSet "STREAM_PROTOCOL_PATH" "$(DB_TOP)"`

2. **Loading the device definitions (`dbLoadRecords`):**
    This also typically uses spaces for the main parts, even though the stuff inside the quotes has commas:

    `dbLoadRecords("$(DB_TOP)/TC-32.db", "P=$(PREFIX_MACRO),R=$(DEVICE_MACRO),PORT=$(ASYN_PORT_NAME)")`

    or, less commonly seen for `dbLoadRecords`'s macro argument but technically possible for the command itself:

    `dbLoadRecords "$(DB_TOP)/TC-32.db" "P=$(PREFIX_MACRO),R=$(DEVICE_MACRO),PORT=$(ASYN_PORT_NAME)"`

Here is the comparision `st.cmd` between `st2.cmd` in `CH4/db_templates.md` and `st4.cmd` with the following style `epicsEnvSet "STREAM_PROTOCOL_PATH" "$(DB_TOP)"`

### `st2.cmd` : Mixed but more `epicsEnvSet(..,..,..) Style

```shell
#!../../bin/linux-x86_64/jeonglee-Demo

< envPaths

epicsEnvSet("DB_TOP", "$(TOP)/db")
epicsEnvSet("STREAM_PROTOCOL_PATH", "$(DB_TOP)")
epicsEnvSet("PREFIX_MACRO", "MYDEMO:")
epicsEnvSet("DEVICE_MACRO", "TC32:")
epicsEnvSet("IOCNAME", "training-jeonglee-Demo")
epicsEnvSet("IOC", "ioctraining-jeonglee-Demo")

dbLoadDatabase "$(TOP)/dbd/jeonglee-Demo.dbd"
jeonglee_Demo_registerRecordDeviceDriver pdbbase

cd "${TOP}/iocBoot/${IOC}"

epicsEnvSet("ASYN_PORT_NAME", "LocalTCPServer")
epicsEnvSet("TARGET_HOST",    "127.0.0.1")
epicsEnvSet("TARGET_PORT",    "9399")
drvAsynIPPortConfigure("$(ASYN_PORT_NAME)", "$(TARGET_HOST):$(TARGET_PORT)", 0, 0, 0)

asynOctetSetInputEos("$(ASYN_PORT_NAME)", 0, "\n")
asynOctetSetOutputEos("$(ASYN_PORT_NAME)", 0, "\n")

dbLoadRecords("$(DB_TOP)/TC-32.db", "P=$(PREFIX_MACRO),R=$(DEVICE_MACRO),PORT=$(ASYN_PORT_NAME)")

iocInit

ClockTime_Report
```
In `st2.cmd`, the `epicsEnvSet` and asyn configuration commands use the function-like syntax with parentheses and commas. `dbLoadDatabase` and `dbLoadRecords` use space separation for their primary arguments.

### `st4.cmd` : All `epicsEnvSet .. .. ..` Style

```shell
#!../../bin/linux-x86_64/jeonglee-Demo

< envPaths

epicsEnvSet "DB_TOP" "$(TOP)/db"
epicsEnvSet "STREAM_PROTOCOL_PATH" "$(DB_TOP)"
epicsEnvSet "PREFIX_MACRO" "MYDEMO:"
epicsEnvSet "DEVICE_MACRO" "TC32:"
epicsEnvSet "IOCNAME" "training-jeonglee-Demo"
epicsEnvSet "IOC" "ioctraining-jeonglee-Demo"

dbLoadDatabase "$(TOP)/dbd/jeonglee-Demo.dbd"
jeonglee_Demo_registerRecordDeviceDriver pdbbase

cd "${TOP}/iocBoot/${IOC}"

epicsEnvSet "ASYN_PORT_NAME"  "LocalTCPServer"
epicsEnvSet "TARGET_HOST"     "127.0.0.1"
epicsEnvSet "TARGET_PORT"     "9399"
drvAsynIPPortConfigure "$(ASYN_PORT_NAME)" "$(TARGET_HOST):$(TARGET_PORT)" 0 0 0

asynOctetSetInputEos "$(ASYN_PORT_NAME)" 0 "\n"
asynOctetSetOutputEos "$(ASYN_PORT_NAME)"  0  "\n"

dbLoadRecords "$(DB_TOP)/TC-32.db" "P=$(PREFIX_MACRO),R=$(DEVICE_MACRO),PORT=$(ASYN_PORT_NAME)"

iocInit

ClockTime_Report
```
`st4.cmd` consistently uses the space-separated style for `epicsEnvSet`, `drvAsynIPPortConfigure`, `asynOctetSetInputEos`, and `asynOctetSetOutputEos`. `dbLoadDatabase` and `dbLoadRecords` remain space-separated for their main arguments, which is standard.


### Which style to use?

Both styles are valid. The choice often comes down to personal preference or adhering to a consistent style within a project or laboratory. The function-like style might feel more familiar to programmers, while the space-separated style is closer to shell scripting. **Consistency** within your `st.cmd` file is generally recommended for readability.

The core purpose of `st.cmd` remains the same regardless of the chosen style: to load necessary database definitions (`.dbd` files), register drivers, configure hardware ports, load record instances (`.db` files) with appropriate macros, and finally start the IOC with `iocInit`.

### Assigment

You can run `st4.cmd` and how the IOC with `st4.cmd` works to compare it with the behavior of the IOC when using `st2.cmd`.
