#!/bin/sh
#
# Copyright (c) 2006-2009, Greg M. Kurtzer, Arthur A. Stevens and
# Infiscale, Inc. All rights reserved
#

if [ $STATE == "init" ]; then
cat <<END
mkdir -p \$DESTDIR/etc/sysconfig
cat <<EOL > \$DESTDIR/etc/sysconfig/network
NETWORKING=yes
HOSTNAME=$NODENAME
EOL
END
else
   echo "hostname $NODENAME"
fi
