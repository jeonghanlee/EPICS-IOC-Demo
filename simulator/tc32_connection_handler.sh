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
# - author : Jeong Han Lee, Dr.rer.nat.
# - email  : jeonglee@lbl.gov
#
#

while true; do
    for (( i=1; i<=32; i++ ))
    do
        Tc=$(tr -cd 0-9 < /dev/urandom | head -c 2)
        printf "%s " "$Tc"
    done
    printf "\n"
    sleep 1

done &


