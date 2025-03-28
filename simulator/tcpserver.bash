#!/usr/bin/env bash
#
#  author  : Jeong Han Lee
#  email   : jeonghan.lee@gmail.com
#  version : 0.0.1

declare -g SC_RPATH;
#declare -g SC_NAME;
declare -g SC_TOP;

SC_RPATH="$(realpath "$0")";
#SC_NAME=${0##*/};
SC_TOP="${SC_RPATH%/*}"

PORT=9399

if command -v tcpsvd &> /dev/null; then
    # Only one connection is allowed
    # Concurrency -c 1 (default 30)
    printf "A simple TCP server on port $PORT..."
    tcpsvd -c 1 -vvE 127.0.0.1 "$PORT" ./connection_handler.sh
    printf "\n"
elif command -v socat &> /dev/null; then
    socat TCP-LISTEN:${PORT},reuseaddr,fork SYSTEM:'./connection_handler.sh'
else
    printf "Please install either of socat or tcpsvd in your system\n"
fi

