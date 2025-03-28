# A Simple TCP Serial Server

The `tcpsvd` or `socat` applications are required.


```
$ bash tcpserver.bash
A simple TCP server on port 9399...tcpsvd: info: listening on 127.0.0.1:9399, starting.
# or

$ bash tcpserver-socat.bash
```

### Test without EPICS IOC

* Client Console

```
$ nc localhost 9399
test
test
1   
1
Hello!
Hello!


```

* Server Console

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
