#!/bin/sh
#
# Copyright (c) 2006-2009, Greg M. Kurtzer, Arthur A. Stevens and
# Infiscale, Inc. All rights reserved
#


if [ "x$VNFS" = "x" ]; then
   echo "echo -ne \"\\rERROR: No configured VNFS image for $NODENAME!   \\r\""
   echo "sleep 1"
   echo "echo -ne \"\\r                                                                               \\r\""
   echo "exit 1"
fi

if [ ${DEBUG:-0} -ge 1 ]; then
   echo "echo 'Sleeping for 10 seconds, then rebooting'"
   echo "sleep 10"
fi

echo "reboot30"

