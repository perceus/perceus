#!/bin/sh
#
# Copyright (c) 2006-2009, Greg M. Kurtzer, Arthur A. Stevens and
# Infiscale, Inc. All rights reserved
#


cat <<END
if [ ! -d "/var/state/perceus/" ]; then
   mkdir -p /var/state/perceus/
fi
if [ -f "/var/state/perceus/vnfs" ]; then
   if [ \`cat /var/state/perceus/vnfs\` != "$VNFS" ]; then
      if [ -z "\`find /proc/ -maxdepth 1 -uid +499\`" ]; then
         /sbin/shutdown -r now "Rebooting to activate new VNFS capsule"
      else
         wall "syncnode: VNFS capsule has changed, waiting for users to log off to reboot."
      fi
   fi
else
   echo $VNFS > /var/state/perceus/vnfs
fi
END

if [ $ENABLED -eq 0 ]; then
echo 'if [ -z "`find /proc/ -maxdepth 1 -uid +499`" ]; then'
echo '   /sbin/shutdown -r now "Rebooting to disable this node"'
echo 'else'
echo '   wall "syncnode: Node has been disabled, waiting for users to log off to reboot."'
echo 'fi'
fi

