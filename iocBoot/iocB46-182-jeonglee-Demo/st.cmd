#!../../bin/linux-x86_64/jeonglee-Demo
#--
< envPaths
#--
cd "${TOP}"
#--
#--https://epics-controls.org/resources-and-support/documents/howto-documents/channel-access-reach-multiple-soft-iocs-linux/
#--if one needs connections between IOCs on one host
#--add the broadcast address of the lookback interface to each IOC setting
epicsEnvSet("EPICS_CA_ADDR_LIST","127.255.255.255")
#--epicsEnvSet("EPICS_CA_AUTO_ADDR_LIST","YES")

#-- PVXA Environment Variables
#-- epicsEnvSet("EPICS_PVA_ADDR_LIST","")
#-- epicsEnvSet("EPICS_PVAS_BEACON_ADDR_LIST","")
#-- epicsEnvSet("EPICS_PVA_AUTO_ADDR_LIST","")
#-- epicsEnvSet("EPICS_PVAS_AUTO_BEACON_ADDR_LIST","")
#-- epicsEnvSet("EPICS_PVAS_INTF_ADDR_LIST","")
#-- epicsEnvSet("EPICS_PVA_SERVER_PORT","")
#-- epicsEnvSet("EPICS_PVAS_SERVER_PORT","")
#-- epicsEnvSet("EPICS_PVA_BROADCAST_PORT","")
#-- epicsEnvSet("EPICS_PVAS_BROADCAST_PORT","")
#-- epicsEnvSet("EPICS_PVAS_IGNORE_ADDR_LIST","")
#-- epicsEnvSet("EPICS_PVA_CONN_TMO","")
#--
epicsEnvSet("DB_TOP",               "$(TOP)/db")
epicsEnvSet("STREAM_PROTOCOL_PATH", "$(DB_TOP)")
epicsEnvSet("IOCSH_LOCAL_TOP",      "$(TOP)/iocsh")
#--epicsEnvSet("IOCSH_TOP",            "$(EPICS_BASE)/../modules/soft/iocsh/iocsh")
#--
epicsEnvSet("ENGINEER",  "jeonglee")
epicsEnvSet("LOCATION",  "SoftIOC")
epicsEnvSet("WIKI", "")
#-- 
epicsEnvSet("IOCNAME", "B46-182-jeonglee-Demo")
epicsEnvSet("IOC", "iocB46-182-jeonglee-Demo")
#--
epicsEnvSet("PRE", "jeonglee:")
epicsEnvSet("REC", "myoffice:")

dbLoadDatabase "dbd/jeonglee-Demo.dbd"
jeonglee_Demo_registerRecordDeviceDriver pdbbase

#--
#--
#-- iocshLoad("$(IOCSH_TOP)/als_default.iocsh")
#-- iocshLoad("$(IOCSH_TOP)/iocLog.iocsh",    "IOCNAME=$(IOCNAME), LOG_INET=$(LOG_DEST), LOG_INET_PORT=$(LOG_PORT)")
#--# Load record instances
#-- iocshLoad("$(IOCSH_TOP)/iocStats.iocsh",  "IOCNAME=$(IOCNAME), DATABASE_TOP=$(DB_TOP)")
#-- iocshLoad("$(IOCSH_TOP)/iocStatsAdmin.iocsh",  "IOCNAME=$(IOCNAME), DATABASE_TOP=$(DB_TOP)")
#-- iocshLoad("$(IOCSH_TOP)/reccaster.iocsh", "IOCNAME=$(IOCNAME), DATABASE_TOP=$(DB_TOP)")
#-- iocshLoad("$(IOCSH_TOP)/caPutLog.iocsh",  "IOCNAME=$(IOCNAME), LOG_INET=$(LOG_DEST), LOG_INET_PORT=$(LOG_PORT)")
#-- iocshLoad("$(IOCSH_TOP)/autosave.iocsh", "AS_TOP=$(TOP),IOCNAME=$(IOCNAME),DATABASE_TOP=$(DB_TOP),SEQ_PERIOD=60")

#-- access control list
#--asSetFilename("$(DB_TOP)/access_securityB46-182-jeonglee-Demo.acf")

cd "${TOP}/iocBoot/${IOC}"

epicsEnvSet("PORT1",      "LocalTCPServer")
epicsEnvSet("PORT1_IP",   "127.0.0.1")
epicsEnvSet("PORT1_PORT", "9399")
#
drvAsynIPPortConfigure("$(PORT1)","$(PORT1_IP):$(PORT1_PORT)",0,0,0)
#
asynOctetSetInputEos($(PORT1), 0, "\n")
asynOctetSetOutputEos($(PORT1), 0, "\n")
#
dbLoadRecords("$(DB_TOP)/training.db", "P=$(PRE),R=$(REC),PORT=$(PORT1)")

#--iocshLoad("$(IOCSH_LOCAL_TOP)/jeonglee-Demo.iocsh", "P=$(PRE),R=$(REC),DATABASE_TOP=$(DB_TOP),PORT=$(PORT1),IPADDR=$(PORT1_IP),IPPORT=$(PORT1_PORT)")
#>>>>>>>>>>>>>
iocInit
#>>>>>>>>>>>>>
##
# pvasr
ClockTime_Report
##
