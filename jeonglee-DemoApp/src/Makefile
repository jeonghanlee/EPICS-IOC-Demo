TOP=../..

include $(TOP)/configure/CONFIG
#----------------------------------------
#  ADD MACRO DEFINITIONS AFTER THIS LINE
#=============================

#=============================
# Build the IOC application

PROD_IOC = jeonglee-Demo
# jeonglee-Demo.dbd will be created and installed
DBD += jeonglee-Demo.dbd

Common_DBDs += base.dbd
Common_DBDs += system.dbd

Common_SRCs +=

ifneq ($(ASYN),)
Common_DBDs += asyn.dbd
Common_DBDs += drvAsynIPPort.dbd
Common_DBDs += drvAsynSerialPort.dbd
Common_LIBs += asyn
endif

ifneq ($(MODBUS),)
Common_DBDs += modbusSupport.dbd
Common_LIBs += modbus
endif

ifneq ($(SNMP),)
Common_DBDs += devSnmp.dbd
Common_LIBs += devSnmp
SYS_PROD_LIBS += netsnmp
endif

ifneq ($(STD),)
Common_DBDs += stdSupport.dbd
Common_LIBs += std
endif

ifneq ($(CALC),)
Common_DBDs += calcSupport.dbd
Common_LIBs += calc
endif


#ifneq ($(IOCSTATS),)
#Common_DBDs += devIocStats.dbd
#Common_LIBs += devIocStats
#endif


ifneq ($(SNCSEQ),)
# sncExample_SNCFLAGS += +r
## Common_DBDs += sncExample.dbd
## A .stt sequence program is *not* pre-processed:
## Common_SRCs += sncExample.stt
#
Common_LIBs += seq pv
endif

ifneq ($(STREAM),)
Common_DBDs += stream.dbd
Common_LIBs += stream
endif

ifneq ($(RETOOLS),)
Common_DBDs += retools.dbd
Common_LIBs += retools
endif

ifneq ($(MEASCOMP),)
Common_DBDs += measCompSupport.dbd
Common_LIBs += measComp
jeonglee-Demo_SYS_LIBS += uldaq
endif

ifneq ($(SSCAN),)
Common_DBDs += sscanSupport.dbd
Common_LIBs += sscan
endif

ifneq ($(BUSY),)
Common_DBDs += busySupport.dbd
Common_LIBs += busy
endif

ifneq ($(SCALER),)
Common_DBDs += scalerSupport.dbd
Common_LIBs += scaler
endif

ifneq ($(MCA),)
Common_DBDs += mcaSupport.dbd
Common_LIBs += mca
endif

ifneq ($(ETHER_IP),)
Common_DBDs += ether_ip.dbd
Common_LIBs += ether_ip
endif

ifneq ($(AUTOSAVE),)
Common_DBDs += asSupport.dbd
Common_LIBs += autosave
endif

ifneq ($(devIocStats),)
Common_DBDs += devIocStats.dbd
Common_LIBs += devIocStats
endif

ifneq ($(RECCASTER),)
Common_DBDs += reccaster.dbd
Common_LIBs += reccaster
endif

ifneq ($(CAPUTLOG),)
Common_DBDs += caPutLog.dbd
Common_LIBs += caPutLog
endif

## VACUUM
ifneq ($(RGAMV2),)
Common_DBDs += rgamv2Include.dbd
Common_LIBs += rgamv2
endif

ifneq ($(UNIDRV),)
Common_DBDs += unidrv.dbd mks.dbd
Common_LIBs += unidrv mks re2
endif

# QPC doesn't have any libs and dbd files
ifneq ($(QPC),)
Common_DBDs +=
Common_LIBs +=
endif


## Instrumentation
ifneq ($(EVENTGENERATORSUP),)
Common_DBDs += eventGeneratorSup.dbd
Common_LIBs += eventGeneratorSup
endif

ifneq ($(BPMSUP),)
Common_DBDs += bpmSup.dbd
Common_LIBs += bpmSup
endif

## LLRF 
ifneq ($(FEED),)
Common_DBDs += feed.dbd
Common_LIBs += feed
endif

## PSC
ifneq ($(PSCDRV),)
Common_DBDs += pscCore.dbd
Common_LIBs += pscCore
endif


## Motion
ifneq ($(PMAC),)
Common_DBDs += drvAsynPowerPMACPort.dbd
Common_DBDs += pmacAsynIPPort.dbd
Common_DBDs += pmacAsynMotorPort.dbd
Common_LIBs += pmacAsynIPPort
Common_LIBs += pmacAsynMotorPort
Common_LIBs += powerPmacAsynPort
endif

# https://epics.anl.gov/tech-talk/2024/msg00460.php
# QSRV2
ifdef PVXS_MAJOR_VERSION # prefer QSRV2 :)
Common_DBDs += pvxsIoc.dbd
Common_LIBs += pvxsIoc pvxs
else
ifdef EPICS_QSRV_MAJOR_VERSION # fallback to QSRV1
Common_LIBs += qsrv
Common_LIBs += $(EPICS_BASE_PVA_CORE_LIBS)
Common_DBDs += PVAServerRegister.dbd
Common_DBDs += qsrv.dbd
endif
endif

# Include dbd files from all support applications:
jeonglee-Demo_DBD  += $(Common_DBDs)
jeonglee-Demo_LIBS += $(Common_LIBs)
jeonglee-Demo_SRCS += $(Common_SRCs)
jeonglee-Demo_SRCS += jeonglee-Demo_registerRecordDeviceDriver.cpp

# System Libraries
jeonglee-Demo_SYS_LIBS +=
jeonglee-Demo_SYS_LIBS_Linux +=

# Build the main IOC entry point on workstation OSs.
jeonglee-Demo_SRCS_DEFAULT += jeonglee-DemoMain.cpp
jeonglee-Demo_SRCS_vxWorks += -nil-

jeonglee-Demo_OBJS_vxWorks += $(EPICS_BASE_BIN)/vxComLibrary
jeonglee-Demo_LIBS += $(EPICS_BASE_IOC_LIBS)

#===========================

include $(TOP)/configure/RULES
#----------------------------------------
#  ADD RULES AFTER THIS LINE

