# Chapter 3: Second EPICS IOC and Device Simulation

This chapter builds on the previous examples by guiding you through configuring a second EPICS IOC. A key focus is simulating device communication – specifically using a TCP-based simulator to mimic interactions often performed over serial interfaces. You will learn to set up this simulation and test the communication between the IOC and the simulator.

This chapter covers the following topics:

* [Configure the Second IOC](yoursecondioc.md): Setting up and configuring a second IOC application, potentially introducing device support relevant for external communication.
* [Create the TCP Simulator](iocsimulator.md): Developing a simple TCP server application to simulate responses from a hardware device (like one communicating over serial).
* [Test IOC-Simulator Communication](secondiocwithsim.md): Testing the interaction between your second IOC and the device simulator.
