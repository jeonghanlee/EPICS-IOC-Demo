# 5.4 What `system.dbd` file is

The `system.dbd` file is a specific type of database definition file within the EPICS framework. Its primary function is to enable the system command within the IOC shell. This command grants the capability to execute arbitrary commands on the underlying operating system where the IOC is running. It's an important point that this feature is not available on all operating systems.

The mechanism by which `system.dbd` enables this is by including the necessary directive, typically `registrar(iocshSystemCommand)`, which registers the function that provides the system command functionality with the IOC shell during startup.


## How to use it

In the ALS-U EPICS environment, the use of `system.dbd` is standardized and largely automated through the application template generator.


1. **Inclusion in the Build:** For each IOC application, the `xxxApp/src/Makefile` automatically includes the line:

```makefile
Common_DBDs += system.dbd
```
This line makes sure that the `system.dbd` file is included in the list of database definition files that are processed when the IOC application is built. This processing is what generates the necessary `C/C++` code to incorporate the system command functionality into the final IOC executable.

2. **Automatic Availability:** Because `system.dbd` is included by default via the Makefile template, the system command is automatically available within your IOC's iocsh environment once the IOC starts.

3. **Purpose in ALS-U:** The decision to make `system.dbd` a default inclusion in ALS-U is strategic. As you pointed out, it is frequently necessary to execute system commands from within the IOC during its operation for various tasks, such as:

* Integrating with the autosave module to trigger saving or restoring configuration.
* Performing file system operations.
* Interacting with other system-level utilities or scripts.

Since ALS-U standardizes on the Linux OS architecture, where the system command support is available in EPICS Base, enabling this functionality by default across all IOC applications provides a consistent and necessary capability for common control system tasks.

## Assignment

1. **Check your IOC application `makefile`:** Can you find the `system.dbd` defintion in `xxxApp/src/Makefile`?

This step verifies the build configuration discussed above. You should look for the line `Common_DBDs += system.dbd` or an include statement that leads to its inclusion, confirming that your application is set up to use the system command functionality provided by `system.dbd`.

2. **Check `system` command:**  Can you see what different you can see in your IOC console (you can use `softIoc`, since `softIoc` contains `system.dbd` file as a default):

* `pwd` or `system pwd` or `system(pwd)` or `system("pwd")`

 This explores how the system command works. The versions like system `pwd`, `system(pwd)`, and `system("pwd")` explicitly tell the IOC to execute the standard operating system's pwd command. You should see the current working directory of the IOC process printed to the console. Typing just pwd might behave differently; it could either be an internal iocsh command or fail if the system command is the only way to access external commands. Note the syntax variations, especially the use of quotes, which are important for commands with spaces or special characters.


3. **Check additional system command:** 

* `mkdir test_folder` or `system mkdir testfolder` or `system(mkdir testfolder)` or `system("mkdir testfolder")`

Similar to the previous point, this demonstrates using the system command for a different OS command (`mkdir`). The versions using system will attempt to create a directory named `testfolder` in the IOC's current working directory by calling the OS `mkdir` command. After executing these, you should verify outside the IOC (using your regular terminal or file explorer) that the `testfolder` directory was indeed created in the location where you launched softIoc. Again, observe how typing `mkdir` without the explicit system command behaves.
