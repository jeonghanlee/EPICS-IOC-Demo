# Chapter 5: Understanding IOC Application Configuration

An EPICS Input/Output Controller (IOC) application requires configuration to define its behavior, load databases, initialize hardware interfaces, and set various parameters. The primary file responsible for the initial setup of an IOC instance is the startup script, typically named `st.cmd`. Additionally, other files like `configure/RELEASE`, `configure/CONFIG_SITE`, and `system.dbd` play crucial roles in defining dependencies, site-specific settings, and the overall database definition.

This chapter covers the following topics:

- [Style of `st.cmd`](how-to-ioc-log1.md): Style of `st.cmd` Commands
- [`RELEASE` file](how-to-ioc-log2.md): Deep Insight on `configure/RELEASE`
- [`CONFIG_SITE` file](how-to-ioc-log3.md): `configure/CONFIG_SITE` - Controlling Application-Specific Build Options
- [`system.dbd` file](how-to-ioc-log4.md): What `system.dbd` file is
 