#!/bin/sh
#
# Copyright (c) 2006-2009, Greg M. Kurtzer, Arthur A. Stevens and
# Infiscale, Inc. All rights reserved
#


FILE=/etc/hosts

if ! egrep -q "^NodeName=.*$NODENAME[, ]" /etc/slurm/slurm.conf; then
   sed -i -e "s@^NodeName=\([^ ]*\) @NodeName=\1,$NODENAME @" /etc/slurm/slurm.conf
   RECONFIG=1
fi

if ! egrep -q "^PartitionName=.* Nodes=.*$NODENAME[, ]" /etc/slurm/slurm.conf; then
   sed -i -e "s@\(PartitionName=.*\) Nodes=\([^ ]*\) @\1 Nodes=\2,$NODENAME @" /etc/slurm/slurm.conf
   RECONFIG=1
fi

if [ "x$STATE" = "xinit" ] || [ -n "$RECONFIG" -o "x$STATE" = "xready" ]; then
cat <<END
mkdir -p \$DESTDIR/etc/slurm/
cat <<EOF > \$DESTDIR/etc/slurm/slurm.conf
`cat /etc/slurm/slurm.conf`
EOF
END
fi

if [ -n "$RECONFIG" ]; then
   scontrol reconfigure
fi
