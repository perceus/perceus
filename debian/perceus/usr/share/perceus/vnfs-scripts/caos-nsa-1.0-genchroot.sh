#!/bin/sh
#
# Copyright (c) 2006-2009, Greg M. Kurtzer, Arthur A. Stevens and
# Infiscale, Inc. All rights reserved
#

if [ -z "$ARCH" ]; then
    ARCH=`uname -m`
fi

cat <<EOF
This script is no longer used as the Caos developers release VNFS
capsules of their operating system already made. You can find them
at:

   http://mirror.caoslinux.org/Caos-NSA-1.0/vnfs/$ARCH/

EOF

