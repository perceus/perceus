#!/bin/sh
#
# Copyright (c) 2006-2009, Greg M. Kurtzer, Arthur A. Stevens and
# Infiscale, Inc. All rights reserved
#


if [ "x$DEBUG" = "x" ]; then
   DEBUG=0
else
   echo echo "Provisioning Debug level: $DEBUG"
fi

echo STARTTIME=\`date +%s\`
echo DESTDIR=/newroot
echo DIFFROOT=\$DESTDIR

if [ $DEBUG -ge 2 ]; then
   echo set -x
fi

if [ $DEBUG -ge 3 ]; then
   echo "/bin/sh >/dev/tty1 2>&1 </dev/tty1"
   echo "/bin/sh >/dev/ttyS0 2>&1 </dev/ttyS0"
   echo "/bin/sh >/dev/ttyS1 2>&1 </dev/ttyS1"
fi

if [ "x$ENABLED" = "x0" -o -z "$ENABLED" ]; then
   echo "echo -ne \"\\rERROR: Node '$NODENAME' is not Enabled!          \\r\""
   echo exit 1
fi

if [ "x$VNFSMASTER" = "x" ]; then
   echo "echo -ne \"\\rERROR: Could not obtain the IP address to transfer the VNFS!    \\r\""
   echo exit 1
fi

if [ "x$VNFSMETHOD" = "x" ]; then
   echo "echo -ne \"\\rERROR: 'vnfs transfer method' is not defined!    \\r\""
   echo exit 1
fi

echo "echo -ne \"\\r                                                                               \\r\""

if [ "x$THROTTLE" != "x" ]; then
   echo sleep $THROTTLE
fi


echo "cat <<EOF > /bin/getfile"
echo "#!/bin/sh"
if [ $DEBUG -ge 2 ]; then
   echo set -x
fi

if [ "x$VNFSMETHOD" = "xnfs" ]; then
   if [ "x$VNFSPREFIX" = "x" ]; then
      NFSDIR=$STATEDIR
   else
      NFSDIR=$VNFSPREFIX
   fi
   if [ $DEBUG -gt 0 ]; then
      echo "echo Mounting via NFS ${VNFSMASTER}:${NFSDIR}"
   fi
   echo "if ! grep -q ${VNFSMASTER}:${NFSDIR} /proc/mounts; then"
   echo "mkdir -p ${STATEDIR} >/dev/null 2>&1"
   echo "if ! mount -o nolock,ro,rsize=32768,tcp -t nfs ${VNFSMASTER}:${NFSDIR} ${STATEDIR} \\"
   echo "&& ! mount -o nolock,ro,tcp -t nfs ${VNFSMASTER}:${NFSDIR} ${STATEDIR} \\"
   echo "&& ! mount -o nolock,ro -t nfs ${VNFSMASTER}:${NFSDIR} ${STATEDIR}; then"
   echo "echo ERROR: Could not mount NFS file system!"
   echo "exit 1"
   echo "fi"
   echo "fi"
   echo "for file in \\\$@; do"
   if [ $DEBUG -gt 0 ]; then
      echo "echo \"Downloading file via NFS: \\\$file\""
   fi
   echo "if ! cp ${STATEDIR}/\\\$file .; then"
   echo "echo \"ERROR: could not download ${STATEDIR}/\\\$file\""
   echo "sleep 5"
   echo "exit 1"
   echo "fi"
   echo "done"
   echo "exit"

elif [ "x$VNFSMETHOD" = "xhttp" ]; then
   echo "for file in \\\$@; do"
   if [ $DEBUG -gt 0 ]; then
      echo "echo \"Downloading file via HTTP: \\\$file\""
   fi
   echo "if ! wget -c -q http://${VNFSMASTER}/${VNFSPREFIX}/perceus/\$file; then"
   echo "echo \"ERROR: could not download http://${VNFSMASTER}/${VNFSPREFIX}/perceus/\$file\""
   echo "sleep 5"
   echo "exit 1"
   echo "fi"
   echo "done"
   echo "exit"

else
   echo "echo 'ERROR: The configuration option \"vnfs transfer method\" was not set to a'"
   echo "echo 'ERROR: supported function. Check your configuration!'"
   echo "exit 1"
fi
echo "EOF"
echo "chmod +x /bin/getfile"


# These are some placeholders for functions that are commonly provided by
# modules. If they dont exist and are called with any level of debugging,
# we will just issue a warning.

echo "loadbin() {"
if [ $DEBUG -gt 0 ]; then
   echo "   echo \"NOTE: call to undefined function 'loadbin \$*' (provided by initbins-x86)\""
else
   echo "   true"
fi
echo "}"
