#!/bin/sh
#
# Copyright (c) 2006-2009, Greg M. Kurtzer, Arthur A. Stevens and
# Infiscale, Inc. All rights reserved
#


if ! PERCEUS_BIN=`which perceus 2>/dev/null`; then
   echo "ERROR: Could not find the Perceus interface!"
   exit 1
fi

if ! MKELF_BIN=`which mkelfImage 2>/dev/null`; then
   echo "ERROR: Could not find the mkelfImage interface!"
   exit 1
fi

STATEDIR=`$PERCEUS_BIN info config statedir`


if [ ! -f "$STATEDIR/tftp/pxelinux.cfg/default" ]; then
   echo "ERROR: Is Perceus configured?"
   exit 1
fi

if [ ! -f "$STATEDIR/tftp/kernel" ]; then
   echo "ERROR: Could not find the Perceus kernel!"
   exit 1
fi

if [ ! -f "$STATEDIR/tftp/initramfs.img" ]; then
   echo "ERROR: Could not find the Perceus stage1 bootstrap image!"
   exit 1
fi

if [ -f "$STATEDIR/tftp/perceus.elf" ]; then
   EPOCH=`date +%s`
   echo "Saving previous perceus.elf as perceus.elf.$EPOCH"
   mv $STATEDIR/tftp/perceus.elf $STATEDIR/tftp/perceus.elf.$EPOCH
fi

APPEND=`grep "^append " $STATEDIR/tftp/pxelinux.cfg/default | sed -e 's/append //'`

$MKELF_BIN --append="$APPEND" \
   --initrd=$STATEDIR/tftp/initramfs.img \
   --kernel=$STATEDIR/tftp/kernel \
   --output=$STATEDIR/tftp/perceus.elf

if [ $? -eq 0 ]; then
   echo "perceus.elf has been created!"

   echo "Updating local configuration"
   grep -q "^dhcp-option=vendor:Etherboot,60,\"Etherboot\"" /etc/perceus/dnsmasq.conf || \
      echo "dhcp-option=vendor:Etherboot,60,\"Etherboot\"" >> /etc/perceus/dnsmasq.conf
   grep -q "^dhcp-vendorclass=pxe,PXEClient" /etc/perceus/dnsmasq.conf || \
      echo "dhcp-vendorclass=pxe,PXEClient" >> /etc/perceus/dnsmasq.conf
   grep -q "^dhcp-vendorclass=etherboot,Etherboot" /etc/perceus/dnsmasq.conf || \
      echo "dhcp-vendorclass=etherboot,Etherboot" >> /etc/perceus/dnsmasq.conf
   grep -q "^dhcp-boot=net:pxe,pxelinux.0" /etc/perceus/dnsmasq.conf || \
      echo "dhcp-boot=net:pxe,pxelinux.0" >> /etc/perceus/dnsmasq.conf
   grep -q "^dhcp-boot=net:etherboot,perceus.elf" /etc/perceus/dnsmasq.conf || \
      echo "dhcp-boot=net:etherboot,perceus.elf" >> /etc/perceus/dnsmasq.conf

   echo "Reloading configuration files"
   /sbin/service perceus reload

   echo "Done."
fi


