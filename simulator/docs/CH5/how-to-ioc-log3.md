# 5.3 `configure/CONFIG_SITE` - Controlling Application-Specific Build Options

While `configure/RELEASE` defines where your application finds its dependencies (EPICS Base and other modules), `configure/CONFIG_SITE` controls how your application is built. This file allows you to override default build settings defined in standard EPICS configuration files, including those from EPICS Base, support modules, and site-specific configurations (`configure/CONFIG`, `configure/os/CONFIG.*` files). The settings in `CONFIG_SITE` influence aspects like compiler flags, optimization levels, enabled features, and installation locations.

Let's examine the typical contents of a CONFIG_SITE file, broken down into logical areas:

```makefile
# Make any application-specific changes to the EPICS build
#   configuration variables in this file.
#
# Host/target specific settings can be specified in files named
#   CONFIG_SITE.$(EPICS_HOST_ARCH).Common
#   CONFIG_SITE.Common.$(T_A)
#   CONFIG_SITE.$(EPICS_HOST_ARCH).$(T_A)

### AREA 1
# CHECK_RELEASE controls the consistency checking of the support
#   applications pointed to by the RELEASE* files.
# Normally CHECK_RELEASE should be set to YES.
# Set CHECK_RELEASE to NO to disable checking completely.
# Set CHECK_RELEASE to WARN to perform consistency checking but
#   continue building even if conflicts are found.
CHECK_RELEASE = NO

# Set this when you only want to compile this application
#   for a subset of the cross-compiled target architectures
#   that Base is built for.
#CROSS_COMPILER_TARGET_ARCHS = vxWorks-ppc32


### AREA 2
# To install files into a location other than $(TOP) define
#   INSTALL_LOCATION here.
#INSTALL_LOCATION=</absolute/path/to/install/top>

# Set this when the IOC and build host use different paths
#   to the install location. This may be needed to boot from
#   a Microsoft FTP server say, or on some NFS configurations.
#IOCS_APPL_TOP = </IOC's/absolute/path/to/install/top>


### AREA 3
# For application debugging purposes, override the HOST_OPT and/
#   or CROSS_OPT settings from base/configure/CONFIG_SITE
#HOST_OPT = NO
#CROSS_OPT = NO

# USR_CPPFLAGS += -fPIC
# USR_CPPFLAGS += -DUSE_TYPED_RSET
#
# USR_CFLAGS += `net-snmp-config --cflags`
# USR_CFLAGS += -DNETSNMP_NO_INLINE
#
# USR_LDFLAGS += `net-snmp-config --libs`

### AREA 4
# These allow developers to override the CONFIG_SITE variable
# settings without having to modify the configure/CONFIG_SITE
# file itself.
-include $(TOP)/../CONFIG_SITE.local
-include $(TOP)/configure/CONFIG_SITE.local
```

## **AREA 1:** Build Checks and Target Architectures

This area contains settings that affect the build process's checks and the target platforms.
* `CHECK_RELEASE`: Controls how strictly the build verifies the paths and dependencies defined in your `RELEASE` files. You can set it to `YES`, `NO`, or `WARN`. For the ALS-U environment, we have the clear paths and dependencies. Therefore, we use NO as the default option.

* `CROSS_COMPILER_TARGET_ARCHS`: If you are cross-compiling for multiple architectures, this lets you specify which subset of those architectures this particular application should be built for. For ALS-U IOC application, it is rare to use this option for our typical application.


## **AREA 2:** Installation Paths
Settings here relate to where the built components of your application will be installed.

```makefile
#INSTALL_LOCATION=</absolute/path/to/install/top>
#IOCS_APPL_TOP = </IOC's/absolute/path/to/install/top>
```

* `INSTALL_LOCATION`: Overrides the default installation path, which is typically a subdirectory within your application's source tree (`$(TOP)`). Useful for installing to a shared or deployment directory. This is a significant option, however, currently we don't typically use this option. For your own local IOC, you don't need to set this, then your built IOC application will stay in the same folder where your source files will be.

* `IOCS_APPL_TOP`: This is used in more complex deployment scenarios, particularly with network booting (like NFS or FTP) or when the path to the installed application differs between the build machine and the target IOC. It sets a variable used by the `envPaths` script to tell the running IOC where to find the installed application files, even if that path is different from the path used during the build (`INSTALL_LOCATION` if set, or `$(TOP)` by default). You don't need to define this option as well.


## **AREA 3:** Compiler and Linker Options
This area controls flags passed to the compiler and linker, affecting optimization, debugging, and feature flags.

* `HOST_OPT` / `CROSS_OPT`: Control compiler optimization levels for host and cross-compiled builds. `HOST_OPT` determines if compiler optimization is desired for host builds, while `CROSS_OPT` does the same for cross-compiled targets. These typically default to no optimization (`NO`). You can set them to `YES` here to enable optimization. You can leave these commented out to use the default behavior. 

* `USR_CPPFLAGS` / `USR_CFLAGS` / `USR_LDFLAGS`: Allow adding custom flags to the preprocessor, C compiler, and linker respectively. Using `+=` appends your flags to existing ones. This is where you'd add things like `-fPIC` or link against external libraries using backticks. Configuring these flags here allows you to apply them consistently across your application's source files without needing to modify the individual Makefile in each `*App/src` directory.


## **AREA 4:** Local Overrides

This crucial area includes local `CONFIG_SITE.local` files. The `-include` directive (with the preceding hyphen) attempts to include these files, but the build does not fail if they are missing. Definitions in these local files override settings in the main `CONFIG_SITE`, allowing developers or site administrators to customize build options without modifying the shared `configure/CONFIG_SITE` file.

Similar to `configure/RELEASE`, `configure/CONFIG_SITE` supports including local override files.

```makefile
-include $(TOP)/../CONFIG_SITE.local
-include $(TOP)/configure/CONFIG_SITE.local
```

These lines mean that if `CONFIG_SITE.local` files exist in the parent directory `$(TOP)/..` or within the application's configure directory `$(TOP)/configure`, their contents will be included. Any variable definitions in these local files will override definitions made earlier in the main `CONFIG_SITE`.

Just like `RELEASE.local`, these `CONFIG_SITE.local` files are added to `.gitignore` within the ALS-U EPICS Environment, to keep local build customizations out of the shared version control repository.


## Assignment

### 1. `INSTALL_LOCATION`

Please add `INSTALL_LOCATION` into `configure/CONFIG_SITE.local`, and build your IOC. Please check your installation location about the directory structure, and what kind of files you can see during `make`, `make clean`, `make install` and `make distclean`.

```bash
$ echo "INSTALL_LOCATION=${HOME}/new_location" > configure/CONFIG_SITE.local
$ make
$ tree ~/new_location
$ make distclean
$ tree ~/new_location
$ make install
$ tree ~/new_location
$ make clean
$ tree ~/new_location
$ make
```

Even with `make distclean`, the installation folder will not be removed. Thus, you should remove it manually if you don't need it. Please check `TOP` definition in `envPaths`:
```shell
$ cat iocBoot/*/envPaths 
```

## 2. `iocBoot`
You observe that the `iocBoot` folder and its contents are not automatically installed to the `INSTALL_LOCATION`. With this fact, can you develop your own deployment plan for each IOC application? The answer is typically "it depends". However, please think and develop an architecture by yourself. The ALS-U EPICS Environment doesn't currently have such an architecture design, since at this moment we will not use `INSTALL_LOCATION` at the IOC application level. Please check `TOP` definition in `envPaths` under the `iocBoot` folder:

```shell
$ cat iocBoot/*/envPaths 
```

## 3. `IOCS_APPL_TOP`
Okay, we can use `IOCS_APPL_TOP`. Note the use of `>>` during creating `CONFIG_SITE.local` to append to the file:

```shell
$ echo "INSTALL_LOCATION=${HOME}/new_location" > configure/CONFIG_SITE.local
$ echo "IOCS_APPL_TOP=${HOME}/new_location2" >> configure/CONFIG_SITE.local
$ ls ~/ |grep new_location
$ ls ~/new_location*
$ tree ~/new_location
$ make install
$ tree ~/new_location
$ make clean
$ tree ~/new_location
```
Please check the `TOP` definition in the `envPaths` file located in your source directory's `iocBoot` folder again:

```shell
$ cat iocBoot/*/envPaths 
```
Can you explain what difference you see in the `envPaths` file compared to before?

## 4. `IOC`
For both cases (after Part 2 and after Part 3), try running the IOC executable from the source location, the installation location, or elsewhere, and observe what happens. In what way can you make the IOC run correctly in both cases?
