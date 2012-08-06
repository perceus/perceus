#!/bin/sh
#
# Copyright (c) 2006-2009, Greg M. Kurtzer, Arthur A. Stevens and
# Infiscale, Inc. All rights reserved
#


if [ ! -d "/etc/perceus/modules/passwdfile/node" ]; then
   mkdir -p /etc/perceus/modules/passwdfile/node
fi
if [ ! -d "/etc/perceus/modules/passwdfile/group" ]; then
   mkdir -p /etc/perceus/modules/passwdfile/group
fi
if [ ! -d "/etc/perceus/modules/passwdfile/vnfs" ]; then
   mkdir -p /etc/perceus/modules/passwdfile/vnfs
fi

cat <<END
mkdir -p \$DESTDIR/etc
cat <<EOL >\$DESTDIR/etc/passwd
END

if [ -s "/etc/perceus/modules/passwdfile/all" ]; then
   cat /etc/perceus/modules/passwdfile/all
elif [ ! -f "/etc/perceus/modules/passwdfile/all" ]; then
   touch /etc/perceus/modules/passwdfile/all
fi
if [ -n "$VNFS" -a -s "/etc/perceus/modules/passwdfile/vnfs/$VNFS" ]; then
   cat /etc/perceus/modules/passwdfile/vnfs/$VNFS
elif [ ! -f "/etc/perceus/modules/passwdfile/vnfs/$VNFS" ]; then
   touch /etc/perceus/modules/passwdfile/vnfs/$VNFS
fi
if [ -n "$GROUPNAME" -a -s "/etc/perceus/modules/passwdfile/group/$GROUPNAME" ]; then
   cat /etc/perceus/modules/passwdfile/group/$GROUPNAME
elif [ ! -f "/etc/perceus/modules/passwdfile/group/$GROUPNAME" ]; then
   touch /etc/perceus/modules/passwdfile/group/$GROUPNAME
fi
if [ -n "$NODENAME" -a -s "/etc/perceus/modules/passwdfile/node/$NODENAME" ]; then
   cat /etc/perceus/modules/passwdfile/node/$NODENAME
elif [ ! -f "/etc/perceus/modules/passwdfile/node/$NODENAME" ]; then
   touch /etc/perceus/modules/passwdfile/node/$NODENAME
fi

cat <<END
EOL
END

