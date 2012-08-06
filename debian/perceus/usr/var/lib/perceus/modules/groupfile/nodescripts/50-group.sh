#!/bin/sh
#
# Copyright (c) 2006-2009, Greg M. Kurtzer, Arthur A. Stevens and
# Infiscale, Inc. All rights reserved
#


if [ ! -d "/etc/perceus/modules/groupfile/node" ]; then
   mkdir -p /etc/perceus/modules/groupfile/node
fi
if [ ! -d "/etc/perceus/modules/groupfile/group" ]; then
   mkdir -p /etc/perceus/modules/groupfile/group
fi
if [ ! -d "/etc/perceus/modules/groupfile/vnfs" ]; then
   mkdir -p /etc/perceus/modules/groupfile/vnfs
fi

cat <<END
mkdir -p \$DESTDIR/etc
cat <<EOL >\$DESTDIR/etc/group
END

if [ -s "/etc/perceus/modules/groupfile/all" ]; then
   cat /etc/perceus/modules/groupfile/all
elif [ ! -f "/etc/perceus/modules/groupfile/all" ]; then
   touch /etc/perceus/modules/groupfile/all
fi
if [ -n "$VNFS" -a -s "/etc/perceus/modules/groupfile/vnfs/$VNFS" ]; then
   cat /etc/perceus/modules/groupfile/vnfs/$VNFS
elif [ ! -f "/etc/perceus/modules/groupfile/vnfs/$VNFS" ]; then
   touch /etc/perceus/modules/groupfile/vnfs/$VNFS
fi
if [ -n "$GROUPNAME" -a -s "/etc/perceus/modules/groupfile/group/$GROUPNAME" ]; then
   cat /etc/perceus/modules/groupfile/group/$GROUPNAME
elif [ ! -f "/etc/perceus/modules/groupfile/group/$GROUPNAME" ]; then
   touch /etc/perceus/modules/groupfile/group/$GROUPNAME
fi
if [ -n "$NODENAME" -a -s "/etc/perceus/modules/groupfile/node/$NODENAME" ]; then
   cat /etc/perceus/modules/groupfile/node/$NODENAME
elif [ ! -f "/etc/perceus/modules/groupfile/node/$NODENAME" ]; then
   touch /etc/perceus/modules/groupfile/node/$NODENAME
fi

cat <<END
EOL
END

