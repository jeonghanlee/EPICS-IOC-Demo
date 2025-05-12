# 5.2 Deep Insight on `configure/RELEASE`

The `configure/RELEASE` file is a critical configuration file for the EPICS build system (which uses GNU Make). Its primary role is to tell the build system *where* to find EPICS Base and any external support modules your application depends on. While the syntax might look a bit unusual if you're not familiar with Makefiles, its function is straightforward: defining paths. The ALS-U EPICS environment uses a specific folder structure relative to `EPICS_BASE`, which is reflected in how module locations are defined here.

Let's look at the example `RELEASE` file divided into areas:


```makefile
### AREA 1 
MODULES = $(EPICS_BASE)/../modules

ASYN = $(MODULES)/asyn
CALC = $(MODULES)/calc
STREAM = $(MODULES)/StreamDevice

### ALS-U Default Module
PVXS=$(MODULES)/pvxs

# EPICS_BASE should appear last so earlier modules can override stuff:
EPICS_BASE = /home/jeonglee/epics/1.1.1/debian-12/7.0.7/base

### AREA 2
#-- https://epics.anl.gov/tech-talk/2024/msg00460.php
#-- When PVXS is included in RELEASE, then PVXS_MAJOR_VERSION will be defined
#-- Here, we use the installed ALS-U EPICS Environment PVXS Version
-include $(PVXS)/configure/CONFIG_PVXS_VERSION

### AREA 3
#-- These lines allow developers to override these RELEASE settings
#-- without having to modify this file directly.
-include $(TOP)/../RELEASE.local
-include $(TOP)/../RELEASE.$(EPICS_HOST_ARCH).local
-include $(TOP)/configure/RELEASE.local

```

## **AREA 1:** Modules and `EPICS_BASE` Definitions

This section defines Make variables like `EPICS_BASE`, `MODULES`, `ASYN`, `CALC`, etc. The value assigned to each variable is the path to the top-level directory of that module or EPICS Base installation. These paths tell the build system where to find the necessary files (headers, libraries) for compiling and linking your application.

The `MODULES` variable is a common convention to simplify paths when many modules reside in a common parent directory relative to `EPICS_BASE` in the ALS-U EPICS environment. 

The line defining `EPICS_BASE` is intentionally placed last. This is a standard Makefile practice. If any of the other module's configuration files (which your build might include later) define a variable that is also defined in `EPICS_BASE`'s Makefiles, defining `EPICS_BASE` last ensures that the module's definition of that variable takes precedence within that module's build context. More importantly, placing it here allows it to be easily overridden by the `RELEASE.local` files included in AREA 3.

```makefile
### AREA 1
MODULES = $(EPICS_BASE)/../modules

ASYN = $(MODULES)/asyn
CALC = $(MODULES)/calc
STREAM = $(MODULES)/StreamDevice

### ALS-U Default Module
PVXS=$(MODULES)/pvxs

# EPICS_BASE should appear last so earlier modules can override stuff:
EPICS_BASE = /home/jeonglee/epics/1.1.1/debian-12/7.0.7/base
```

## **AREA 2:** Optional Module Includes

This area uses the `-include` directive to pull in additional configuration files from specific modules, if they exist. The hyphen `-` before include is crucial. It tells GNU Make not to stop the build with an error if the specified file is not found. This is useful for optional components or files that might only exist in certain versions or configurations of a module. For example, `CONFIG_PVXS_VERSION` likely defines Make variables indicating the version of the PVXS library only within the ALS-U EPICS enviornment or your own PVXS location, which your application's Makefiles might use for version-specific build logic.

If there is the location of the `PVXS` and `CONFIG_PVXS_VERSION` in your EPICS environment, it will include your EPICS IOC application. However, they cannot find it, it will ignore it without returning error messages. For ALS-U EPICS environment, this is the default module, so you can ignore it.

```makefile
### AREA 2
-include $(PVXS)/configure/CONFIG_PVXS_VERSION
```
## **AREA 3:** Local Overrides 

This is a very important area for development and user-specific configuration. The `-include` directives here bring in local files (`RELEASE.local` and `RELEASE.$(EPICS_HOST_ARCH).local`). Because Make processes instructions sequentially, any variable definitions in these local files will override definitions made earlier in the main `configure/RELEASE` file (like the `EPICS_BASE` definition in AREA 1). We also ignore `.local` files within our git environment.

* `$(TOP)/../RELEASE.local`: Includes a `RELEASE.local` file located one directory level above your application's top directory (`$(TOP)`). This is a common place for site-wide or user-specific overrides that apply to multiple IOC applications within a larger development area.

* `$(TOP)/../RELEASE.$(EPICS_HOST_ARCH).local`: Similar to the above, but specific to the target architecture (`$(EPICS_HOST_ARCH)`) you are building for (e.g., `RELEASE.linux-x86_64.local`). This is useful for architecture-dependent settings or module versions. However, for ALS-U we don't need mostly. 

* `$(TOP)/configure/RELEASE.local`: Includes a `RELEASE.local` file directly within *this* IOC application's `configure` directory. This is typically used for overrides specific only to this particular IOC application build.

Using these local override files allows developers to, for example, switch which `EPICS_BASE` installation they build against without modifying the main `configure/RELEASE` file that everyone shares. This helps prevent merge conflicts and simplifies managing different development or deployment environments. 

```makefile
## AREA 3
-include $(TOP)/../RELEASE.local
-include $(TOP)/../RELEASE.$(EPICS_HOST_ARCH).local
-include $(TOP)/configure/RELEASE.local
```
As you demonstrated, you can easily create a `configure/RELEASE.local` file to override settings, for instance, specifying a different `EPICS_BASE` path:

```makefile
$ echo "EPICS_BASE=/path/to/your/local/epics/base" > configure/RELEASE.local
$ make
```

When you run make, the build system will read your `configure/RELEASE`, include the other local files if they exist, and because `configure/RELEASE.local` is included last, the `EPICS_BASE` path you specified in it will be used, overriding the one defined in AREA 1 of the main `configure/RELEASE` file. The paths defined in `RELEASE` ultimately determine where the build system finds components and influences where the resulting IOC executable and its dependencies are installed, which is then used by the `st.cmd` startup script at runtime (often via the `envPaths` file). 
