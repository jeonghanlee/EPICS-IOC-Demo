#!/usr/bin/env bash

PORT=9399

socat TCP-LISTEN:${PORT},reuseaddr,fork SYSTEM:'read -r command \
echo "Received $command from $SOCAT_PEERADDR:$SOCAT_PEERPORT" >&2 \
echo "$command"'
