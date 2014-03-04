#!/bin/sh

##
# Allow the kernel to supply the amount of memory to be requested by postgres
#

sysctl -w kernel.shmmax=268435456
