#!../../bin/linux-x86_64/jeonglee-Demo

< envPaths

epicsEnvSet("DB_TOP", "$(TOP)/db")

epicsEnvSet("STREAM_PROTOCOL_PATH", "$(DB_TOP)")

epicsEnvSet("PREFIX_MACRO", "jeonglee:")
epicsEnvSet("DEVICE_MACRO", "training:")


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

dbLoadRecords("$(DB_TOP)/temperature.template", "P=$(PREFIX_MACRO),R=$(DEVICE_MACRO),PORT=$(ASYN_PORT_NAME),CH=01")
dbLoadRecords("$(DB_TOP)/temperature.template", "P=$(PREFIX_MACRO),R=$(DEVICE_MACRO),PORT=$(ASYN_PORT_NAME),CH=02")
dbLoadRecords("$(DB_TOP)/temperature.template", "P=$(PREFIX_MACRO),R=$(DEVICE_MACRO),PORT=$(ASYN_PORT_NAME),CH=03")
dbLoadRecords("$(DB_TOP)/temperature.template", "P=$(PREFIX_MACRO),R=$(DEVICE_MACRO),PORT=$(ASYN_PORT_NAME),CH=04")
dbLoadRecords("$(DB_TOP)/temperature.template", "P=$(PREFIX_MACRO),R=$(DEVICE_MACRO),PORT=$(ASYN_PORT_NAME),CH=05")
dbLoadRecords("$(DB_TOP)/temperature.template", "P=$(PREFIX_MACRO),R=$(DEVICE_MACRO),PORT=$(ASYN_PORT_NAME),CH=06")
dbLoadRecords("$(DB_TOP)/temperature.template", "P=$(PREFIX_MACRO),R=$(DEVICE_MACRO),PORT=$(ASYN_PORT_NAME),CH=07")
dbLoadRecords("$(DB_TOP)/temperature.template", "P=$(PREFIX_MACRO),R=$(DEVICE_MACRO),PORT=$(ASYN_PORT_NAME),CH=08")
dbLoadRecords("$(DB_TOP)/temperature.template", "P=$(PREFIX_MACRO),R=$(DEVICE_MACRO),PORT=$(ASYN_PORT_NAME),CH=09")
dbLoadRecords("$(DB_TOP)/temperature.template", "P=$(PREFIX_MACRO),R=$(DEVICE_MACRO),PORT=$(ASYN_PORT_NAME),CH=10")
dbLoadRecords("$(DB_TOP)/temperature.template", "P=$(PREFIX_MACRO),R=$(DEVICE_MACRO),PORT=$(ASYN_PORT_NAME),CH=11")
dbLoadRecords("$(DB_TOP)/temperature.template", "P=$(PREFIX_MACRO),R=$(DEVICE_MACRO),PORT=$(ASYN_PORT_NAME),CH=12")
dbLoadRecords("$(DB_TOP)/temperature.template", "P=$(PREFIX_MACRO),R=$(DEVICE_MACRO),PORT=$(ASYN_PORT_NAME),CH=13")
dbLoadRecords("$(DB_TOP)/temperature.template", "P=$(PREFIX_MACRO),R=$(DEVICE_MACRO),PORT=$(ASYN_PORT_NAME),CH=14")
dbLoadRecords("$(DB_TOP)/temperature.template", "P=$(PREFIX_MACRO),R=$(DEVICE_MACRO),PORT=$(ASYN_PORT_NAME),CH=15")
dbLoadRecords("$(DB_TOP)/temperature.template", "P=$(PREFIX_MACRO),R=$(DEVICE_MACRO),PORT=$(ASYN_PORT_NAME),CH=16")
dbLoadRecords("$(DB_TOP)/temperature.template", "P=$(PREFIX_MACRO),R=$(DEVICE_MACRO),PORT=$(ASYN_PORT_NAME),CH=17")
dbLoadRecords("$(DB_TOP)/temperature.template", "P=$(PREFIX_MACRO),R=$(DEVICE_MACRO),PORT=$(ASYN_PORT_NAME),CH=18")
dbLoadRecords("$(DB_TOP)/temperature.template", "P=$(PREFIX_MACRO),R=$(DEVICE_MACRO),PORT=$(ASYN_PORT_NAME),CH=19")
dbLoadRecords("$(DB_TOP)/temperature.template", "P=$(PREFIX_MACRO),R=$(DEVICE_MACRO),PORT=$(ASYN_PORT_NAME),CH=20")
dbLoadRecords("$(DB_TOP)/temperature.template", "P=$(PREFIX_MACRO),R=$(DEVICE_MACRO),PORT=$(ASYN_PORT_NAME),CH=21")
dbLoadRecords("$(DB_TOP)/temperature.template", "P=$(PREFIX_MACRO),R=$(DEVICE_MACRO),PORT=$(ASYN_PORT_NAME),CH=22")
dbLoadRecords("$(DB_TOP)/temperature.template", "P=$(PREFIX_MACRO),R=$(DEVICE_MACRO),PORT=$(ASYN_PORT_NAME),CH=23")
dbLoadRecords("$(DB_TOP)/temperature.template", "P=$(PREFIX_MACRO),R=$(DEVICE_MACRO),PORT=$(ASYN_PORT_NAME),CH=24")
dbLoadRecords("$(DB_TOP)/temperature.template", "P=$(PREFIX_MACRO),R=$(DEVICE_MACRO),PORT=$(ASYN_PORT_NAME),CH=25")
dbLoadRecords("$(DB_TOP)/temperature.template", "P=$(PREFIX_MACRO),R=$(DEVICE_MACRO),PORT=$(ASYN_PORT_NAME),CH=26")
dbLoadRecords("$(DB_TOP)/temperature.template", "P=$(PREFIX_MACRO),R=$(DEVICE_MACRO),PORT=$(ASYN_PORT_NAME),CH=27")
dbLoadRecords("$(DB_TOP)/temperature.template", "P=$(PREFIX_MACRO),R=$(DEVICE_MACRO),PORT=$(ASYN_PORT_NAME),CH=28")
dbLoadRecords("$(DB_TOP)/temperature.template", "P=$(PREFIX_MACRO),R=$(DEVICE_MACRO),PORT=$(ASYN_PORT_NAME),CH=29")
dbLoadRecords("$(DB_TOP)/temperature.template", "P=$(PREFIX_MACRO),R=$(DEVICE_MACRO),PORT=$(ASYN_PORT_NAME),CH=30")
dbLoadRecords("$(DB_TOP)/temperature.template", "P=$(PREFIX_MACRO),R=$(DEVICE_MACRO),PORT=$(ASYN_PORT_NAME),CH=31")
dbLoadRecords("$(DB_TOP)/temperature.template", "P=$(PREFIX_MACRO),R=$(DEVICE_MACRO),PORT=$(ASYN_PORT_NAME),CH=32")


iocInit

ClockTime_Report


