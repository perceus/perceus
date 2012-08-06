#!/bin/sh
#
# Copyright (c) 2006-2009, Greg M. Kurtzer, Arthur A. Stevens and
# Infiscale, Inc. All rights reserved
#


CONFIG=/etc/perceus/modules/modprobe

if [ -z "$NODENAME" ]; then
   echo "echo \"ERROR(module:modprobe): NODENAME isn't defined in the envrionment!\""
   exit 1
fi

if [ -z "$STATE" ]; then
   echo "echo \"ERROR(module:modprobe): STATE isn't defined in the envrionment!\""
   exit 1
fi

if [ -z "$GROUPNAME" ]; then
   echo "echo \"ERROR(module:modprobe): GROUPNAME isn't defined in the envrionment!\""
   exit 1
fi

if [ -z "$VNFS" ]; then
   echo "echo \"ERROR(module:modprobe): VNFS isn't defined in the envrionment!\""
   exit 1
fi

MODULES=`egrep "^[$NODENAME:|$GROUPNAME:|$VNFS:|all:]" $CONFIG | sed -e "s/.*:\(.*\)/\1/"`

for string in $MODULES; do
   if [ $STATE = "init" ]; then
      echo "echo '/sbin/modprobe $string' >> ./init"
   else
      echo "/sbin/modprobe $string"
   fi
done

