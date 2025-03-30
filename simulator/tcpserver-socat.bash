
#!/usr/bin/env bash
#
#  The program is free software: you can redistribute
#  it and/or modify it under the terms of the GNU General Public License
#  as published by the Free Software Foundation, either version 2 of the
#  License, or any newer version.
#
#  This program is distributed in the hope that it will be useful, but WITHOUT
#  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
#  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
#  more details.
#
#  You should have received a copy of the GNU General Public License along with
#  this program. If not, see https://www.gnu.org/licenses/gpl-2.0.txt
#
#  Connection Handler for TCP Echo Server
#  Reads lines from client (stdin) and echoes them back (stdout).
#
#  - author : Jeong Han Lee, Dr.rer.nat.
#  - email  : jeonglee@lbl.gov

PORT=9399

socat TCP-LISTEN:${PORT},reuseaddr,fork SYSTEM:'read -r command \
echo "Received $command from $SOCAT_PEERADDR:$SOCAT_PEERPORT" >&2 \
echo "$command"'
