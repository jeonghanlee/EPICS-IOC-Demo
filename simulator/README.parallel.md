# Multiple TCP server

```bash
sudo apt install parallel
```


```shell
parallel ./tcpserver.bash ::: 9399 9400 9401
```

```shell
# Terminal 1
socat - TCP:localhost:9399
```

```shell
# Terminal 2
socat - TCP:localhost:9400
```

```shell
# Terminal 3
socat - TCP:localhost:9401
```
