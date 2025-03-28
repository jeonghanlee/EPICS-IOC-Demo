# A Simple TCP Serial Server for EPICS IOC Training

This simple TCP server is designed to simulate a basic serial device. When a client sends a text message to this server, the server will simply return the exact same message back to the client. This "echo" functionality provides the most fundamental interaction you might have with a serial device and is incredibly useful for:

* **EPICS IOC Development Training:** It allows you to develop and test the serial communication parts of your EPICS IOC (Input/Output Controller) without needing actual physical serial hardware.
* **Debugging:** You can use this server to verify that your IOC is correctly sending and receiving data over a TCP/IP connection as if it were communicating with a serial port.
* **Simulation:** It provides a controllable and predictable endpoint for practicing serial communication concepts within the EPICS environment.

## Requirements

To run this server, you will need one of the following command-line utilities installed on your system:

* **`tcpsvd`**: A very lightweight and simple TCP server utility, often readily available on Linux systems.
* **`socat`**: A more powerful and versatile command-line utility that can handle various types of data streams, including TCP and serial ports. We will be using its TCP server capabilities here.

## How the Server Works

This server utilizes either `tcpsvd` or `socat` to listen for incoming TCP connections on a specified port. When a client connects, the chosen utility executes a simple script (`connection_handler.sh`) for each connection. This script:

1.  **Receives Data:** Reads the text message sent by the client.
2.  **Sends Data Back:** Returns the exact same received text message to the client.

This creates a basic "echo" server, mimicking the fundamental behavior of a serial device that might simply echo commands or data sent to it.

## Running the Server

You will need to run the server in one terminal window. This setup provides flexibility by attempting to use `tcpsvd` first and falling back to `socat` if `tcpsvd` is not found. Both methods utilize the separate `connection_handler.sh` file for handling client interactions. There is also a dedicated script for running the server using only `socat`.

### Using `tcpserver.bash` (Recommended: Tries `tcpsvd` then `socat`)

```
$ bash tcpserver.bash
```


### Using `tcpserver-socat.bash` (For `socat` alone)

```
$ bash tcpserver-socat.bash
```


## Testing without EPICS IOC
 

**Server Console:**

```
$ bash tcpserver.bash
A simple TCP server on port 9399...tcpsvd: info: listening on 127.0.0.1:9399, starting.
tcpsvd: info: status 1/1
tcpsvd: info: pid 523754 from 127.0.0.1
tcpsvd: info: start 523754 :127.0.0.1 ::127.0.0.1:38282
tcpsvd: info: end 523754 exit 0
tcpsvd: info: status 0/1
tcpsvd: info: status 1/1
tcpsvd: info: pid 523765 from 127.0.0.1
tcpsvd: info: start 523765 :127.0.0.1 ::127.0.0.1:59856

```


You can test the server's basic functionality using a simple TCP client like `netcat` (`nc`) from another terminal window.

**Client Console:**

This command connects to the server running on localhost (IP address 127.0.0.1) at port 9399.

```bash
$ nc localhost 9399
test
test
1
1
Hello!
Hello!
```


