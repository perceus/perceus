#!/bin/sh
#
# Copyright (c) 2006-2008, Greg M. Kurtzer, Arthur A. Stevens and
# Infiscale, Inc. All rights reserved
# Copyright (c) 2009-2010 Bernard Li <bernard@vanhpc.org>
# All rights reserved
#

CHROOT=$1
CREATE_IMAGE=$2
TMPDIR=`mktemp -d /var/tmp/XXXXXXXXXXX`
STARTDIR=`pwd`

if [ -z "$CHROOT" ]; then
   echo "USAGE: $0 [path to chroot] (IMAGE)"
   exit 1
fi

if [ ! -f "$CHROOT/sbin/init" ]; then
   echo "The chroot given doesn't appear to be valid!"
   exit 1
fi

if [ -z "$CREATE_IMAGE" ]; then
   NAME=`basename $CHROOT`
   NAME="$NAME.vnfs"
   CREATE_IMAGE=$NAME
else
   NAME=`basename $CREATE_IMAGE`
fi

echo "Creating VNFS capsule '$NAME'"

cd $CHROOT

KERNEL=`ls boot/vmlinuz* | sort | tail -n 1`
KNAME=`basename $KERNEL`
KVERSION=`echo $KNAME | sed -e 's/vmlinuz-//'`
INITRD=`ls boot/initrd* | sort | tail -n 1`
INAME=`basename $INITRD`

echo "Setting default kernel to $KNAME"
echo "Setting default initrd to $INAME"

# Assume that this is a relocatable kernel if it is not a boot sector
if grep -q "^CONFIG_RELOCATABLE=y" /boot/config-$KVERSION >/dev/null 2>&1; then
   echo "Kernel is relocatable..."
   DEFAULT_KEXEC_ARGS="--args-linux"
elif ! file $KERNEL | grep -q "x86 boot"; then
   echo "Kernel seems to be relocatable..."
   DEFAULT_KEXEC_ARGS="--args-linux"
fi

mkdir -p $TMPDIR/$NAME/nodescripts/init

# This is a placeholder for legacy Perceus installs that check for this file.
echo "This file is only here for legacy Perceus compatibility... The real kernel" > $TMPDIR/$NAME/vmlinuz
echo "is at 'rootfs/$KERNEL'." >> $TMPDIR/$NAME/vmlinuz

echo "Building rootfs ..."
mkdir -p $TMPDIR/$NAME/rootfs
cp -rap . $TMPDIR/$NAME/rootfs

cat <<EOF >$TMPDIR/$NAME/rootfs/etc/fstab
# Don't touch the following macro unless you really know what your doing!
%{root entry}
%{boot entry}
none            /dev/pts                devpts  gid=5,mode=620  0 0
none            /dev/shm                tmpfs   defaults        0 0
none            /proc                   proc    defaults        0 0
%{swap entry}
EOF

echo "Creating additional devices ..."
test -c $TMPDIR/$NAME/rootfs/dev/null || mknod $TMPDIR/$NAME/rootfs/dev/null c 1 3
test -c $TMPDIR/$NAME/rootfs/dev/random || mknod $TMPDIR/$NAME/rootfs/dev/random c 1 8
test -c $TMPDIR/$NAME/rootfs/dev/urandom || mknod $TMPDIR/$NAME/rootfs/dev/urandom c 1 9
test -c $TMPDIR/$NAME/rootfs/dev/zero|| mknod $TMPDIR/$NAME/rootfs/dev/zero c 1 5

touch $TMPDIR/$NAME/vnfs.img

echo "Creating VNFS capsule scripts"
cat <<DNE > $TMPDIR/$NAME/livesync
#!/bin/sh
# This script was built by Perceus:chroot2stateful.sh

if [ -f "\$1" ]; then
   # Backwards compat with earlier vnfs capsule methods
   shift
fi
NODES=\$*
VNFSDIR=\`dirname \$0\`
VNFS=\$VNFSDIR/vnfs.img
VNFSNAME=\`basename \$VNFS\`

if [ -f "\$VNFSDIR/config" ]; then
   . \$VNFSDIR/config
fi

if [ "x\$LIVESYNCSKIP_FILE" = "x" ]; then
   LIVESYNCSKIP_FILE="\$VNFSDIR/livesync.skip"
elif [ ! -f "\$LIVESYNCSKIP_FILE" ]; then
   LIVESYNCSKIP_FILE="\$VNFSDIR/livesync.skip"
fi

if [ "x\$HYBRIDIZE_FILE" = "x" ]; then
   HYBRIDIZE_FILE="\$VNFSDIR/hybridize"
elif [ ! -f "\$HYBRIDIZE_FILE" ]; then
   HYBRIDIZE_FILE="\$VNFSDIR/hybridize"
fi

if [ -f "\$LIVESYNCSKIP_FILE" ]; then
   SYSFILES=\`grep -v "^#" \$LIVESYNCSKIP_FILE | sed -e 's/^\///g'\`
fi

HYBRIDIZE=\`grep -v "^#" \$HYBRIDIZE_FILE\`

EXCLUDES=\`for i in \$SYSFILES \$HYBRIDIZE; do echo "--exclude=\$i "; done\`

if [ ! -d "\$VNFSDIR" ]; then
   echo "VNFS '\$VNFS' doesn't seem to exist!"
   exit 1
fi

cd \$VNFSDIR/rootfs

for host in \$NODES; do
   echo -ne "Syncing live file system on '\$host': ";
   if OUT=\`rsync -qxaHu -e ssh \$EXCLUDES . \$host:/ 2>&1\`; then
      echo " done"
   else
      echo " ERROR"
      echo \$OUT
   fi
done
DNE

cat <<DNE > $TMPDIR/$NAME/livesync.skip
# This file specifies which files should be skipped when a
# 'perceus vnfs livesync' is done.

# Depending on your configuration you may wish to (un)comment the following:
/etc/passwd
/etc/group
/etc/shadow
/etc/hosts
/etc/resolv.conf

# These are the default files/directories to always skip
/srv
/home
/opt
/usr/local
/usr/cports
/etc/mtab
/proc
/sys
#/var/log
#/var/run
#/var/lock
#/var/lib/dhcp
#/var/lib/nfs
#/var/lib/perceus
/dev
/tmp
/var/tmp
/data/*
/scratch/*
DNE

cat <<DNE > $TMPDIR/$NAME/config
#!/bin/sh
# This config was created by Perceus:chroot2stateful.sh
#

# LOADBIN: Assuming that you have installed the initbins-x86 perceus
# module, you can list a given set of utilities to load into the
# initramfs if you don't already have them compiled in (e.g. to save
# space). Check into the initbins-x86 perceus module for more
# information.

LOADBIN=""

# KEXEC: Whic kexec version do you want to use? Sometimes one kexec
# version works better then the other dependening on the hardware
# and kernel. By default perceus has kexec and kexec-1.101 available.

KEXEC="kexec"

# COMPRESSION: What level of VNFS image compression do you want? The
# tradeoff is the lower the compression the faster the compression and
# expansion of the image, but the longer the transfer. Options are
# 'high' for high compression ratio or anything else for low.

COMPRESSION=low

# BACKUP: This will cause VNFS images to be backed up when they are
# unmounted. The backups will exist in the primary VNFS directory.
# note: Any files that are hybridized are not backed up!!!

BACKUP=no

# HYBRIDIZE_FILE: Set a global hybridization file. The default hybridize
# file is /etc/perceus/hybridize but if that isn't found or if this
# entry isn't defined then it defaults to the hybridize file in this VNFS
# capsule.

HYBRIDIZE_FILE="/etc/perceus/hybridize"

# LIVESYNCSKIP_FILE: Set a global livesync.skip file. The default
# livesync.skip file is /etc/perceus/livesync.skip but if that isn't found
# or if this entry isn't defined then it defaults to the livesync.skip file
# in this VNFS capsule.

LIVESYNCSKIP_FILE="/etc/perceus/livesync.skip"

# KERNEL: Set the kernel that will be configured to boot this VNFS. The
# full path relative to the mounted VNFS is required.

KERNEL="/boot/$KNAME"

# KERNEL_ARGS: Supply any additional kernel arguments for the kexec'ed
# kernel. Some options to consider are:
#   noapic      Helps if your having problems with hardware not being
#               recognized.
#   pci=forced  Another good one to try with hardware recognition problems
#   quiet       Suppress the standard kernel boot messages
#   console=ttyS0,115200 Send console information to the serial device

KERNEL_ARGS="ramdisk_blocksize=1024"

# KEXEC_ARGS: Any additional arguments that need to be set for the call to
# kexec (e.g. RHEL 5 uses a relocatable kernel thus it requires '--args-linux'
# to be used.

KEXEC_ARGS="$DEFAULT_KEXEC_ARGS"

# XEN_KERNEL: Set the Xen kernel that will be configured to boot this VNFS.
# The full path relative to the mounted VNFS is required. Leave this blank
# if you don't need to boot a Xen-enabled kernel.

XEN_KERNEL=""

# INITRD: Set the initrd that will be configured to boot this VNFS. The
# full path relative to the mounted VNFS is required.

INITRD="/boot/$INAME"

# RAID: RAID Level. Valid options are 0, 1. Leave blank if not using RAID.
# When using RAID, make sure that mdadm is installed in your VNFS image.
# The boot partition will always be in RAID1 regardless of what is selected
# here.

RAID=""

# TARGETS: Storage target device(s), valid entries are /dev/sda, /dev/hdc, etc.
# If using RAID, delimit the devices (exactly 2) with a white space.

TARGETS="/dev/sda"

# FILESYSTEM: Filesystem to be used for root and boot partitions. Supported
# filesystems are ext3, ext4, and xfs. Since most distributions still ship
# with GRUB 0.9x (GRUB Legacy) which does not support ext4, if ext4 is
# selected here, ext3 will be used for the boot partition regardless.
# Make sure that the corresponding *fsprogs are installed in the image,
# eg. xfsprogs for xfs.

FILESYSTEM="ext3"

# BOOT_SIZE: Size of the /boot partition to be created in MegaBytes.

BOOT_SIZE="100"

# SWAP_SIZE: Size of swap partition to be created in Megabytes. If RAID0 is
# selected, the actual size of swap will be twice this value.

SWAP_SIZE="2048"

# GRUB: Whether or not to install GRUB boot loader onto target device's MBR
# and generate grub.conf/menu.lst in /boot/grub. Can be used as a fail-safe to
# boot up nodes in case there are problems contacting Perceus master.

GRUB=yes

# INCLUDE: Include any other config scripts that maybe relevant for the
# engaged system

if [ -f "/etc/perceus/global-vnfs.config" ]; then
   . /etc/perceus/global-vnfs.config
fi
if [ -f "/etc/perceus/nodes/\$NODENAME/vnfs.config" ]; then
   . /etc/perceus/nodes/\$NODENAME/vnfs.config
fi
if [ -f "/etc/perceus/groups/\$GROUPNAME/vnfs.config" ]; then
   . /etc/perceus/groups/\$GROUPNAME/vnfs.config
fi

DNE

cat <<DNE > $TMPDIR/$NAME/nodescripts/init/10-vnfsinit.sh
#!/bin/sh
# This script was built by Perceus:chroot2stateful.sh

if [ -f "\$STATEDIR/vnfs/\$VNFS/config" ]; then
   . \$STATEDIR/vnfs/\$VNFS/config
fi

cat <<EOF
if [ -f /error ]; then
   echo
   if [ -n "\\\$INIT" ]; then
      echo "ERROR: There was an error performing stateful provisioning"
   else
      echo "ERROR: There was an error booting the node"
   fi
   cat /error
   echo "Please correct the problem and reboot"
   if [ -z "\$DEBUG" ]; then
      echo "For more information, please increase the debug level"
   fi
   exit 1
fi
EOF

echo "echo"
echo "echo \\"     Now provisioning: \$NODENAME\\""
echo "echo \\"                 VNFS: \$VNFS\\""
echo "echo \\"                Group: \$GROUPNAME\\""
echo "echo \\"              Node ID: \$NODEID\\""

for bin in \$LOADBIN; do
   echo loadbin \$bin
done

KNAME=\`basename \$KERNEL\`
INAME=\`basename \$INITRD\`
if [ "x\$XEN_KERNEL" != "x" ]; then
   XNAME=\`basename \$XEN_KERNEL\`
fi
KVER=\`echo \$KNAME | awk -F 'vmlinuz-' {'print \$2'}\`

cat <<EOF
VNFSROOT="\\\$DESTDIR"
BOOT_PART="1"
SWAP_PART="2"
ROOT_PART="3"
FDISK_CMDS="n\\np\\n\\\${BOOT_PART}\\n1\\n+\${BOOT_SIZE}M\\nn\\np\\n\\\${SWAP_PART}\\n\\n+\${SWAP_SIZE}M\\nn\\np\\n\\\${ROOT_PART}\\n\\n\\nw\\n"

if [ \$FILESYSTEM == "ext3" ] || [ \$FILESYSTEM == "ext4" ]; then
   BOOTFS="ext3"
else
   BOOTFS="\$FILESYSTEM"
fi

xcmd() {
   \\\$1 >/tmp/out 2>&1
   RC=\\\$?

   if [ -n "\$DEBUG" ]; then
      cat /tmp/out
   fi

   if [ \\\$RC -ne 0 ]; then
      OUT=\\\`cat /tmp/out\\\`
      cat <<END > /error
Command that was executed and the output:

\\\$1
\\\$OUT

END
      exit 1
   fi
}

#
# Check to see if VNFS config file has sane variables for RAID/non-RAID configurations
#

if [ "\${FILESYSTEM}" != "ext3" ] && [ "\${FILESYSTEM}" != "ext4" ] && [ "\${FILESYSTEM}" != "xfs" ]; then
   echo "Unsupported filesystem (\${FILESYSTEM}) specified in VNFS config file" > /error
   exit 1
fi

if [ -z "\${TARGETS}" ]; then
   echo "No target(s) specified in VNFS config file" > /error
   exit 1
fi

# Determine the number of targets in a pure bash way
TARGETS_COUNT=\${TARGETS//[ ]/}
TARGETS_COUNT=\\\$((\${#TARGETS} - \\\${#TARGETS_COUNT} + 1))

if [ "x\$RAID" == "x" ]; then
   if [ \\\${TARGETS_COUNT} -gt 1 ]; then
      echo "RAID level is not set but more than one target is found in VNFS config file" > /error
      exit 1
   fi
else
   if [ "x\$RAID" != "x0" ] && [ "x\$RAID" != "x1" ]; then
      echo "Invalid RAID level set in VNFS config file" > /error
      exit 1
   else
      if [ \\\${TARGETS_COUNT} -ne 2 ]; then
         echo "Exactly two targets must be specified for RAID configuration" > /error
         exit 1
      fi
   fi
fi

mkdir -p \\\${VNFSROOT}

echo

if [ "x\$RAID" == "x" ]; then
   BOOT_DEVICE="\${TARGETS}\\\${BOOT_PART}"
   SWAP_DEVICE="\${TARGETS}\\\${SWAP_PART}"
   ROOT_DEVICE="\${TARGETS}\\\${ROOT_PART}"
else
   BOOT_MD="md0"
   SWAP_MD="md1"
   ROOT_MD="md2"

   BOOT_DEVICE="/dev/\\\${BOOT_MD}"
   SWAP_DEVICE="/dev/\\\${SWAP_MD}"
   ROOT_DEVICE="/dev/\\\${ROOT_MD}"
fi

if [ ! -z \\\$INIT ]; then
   #
   # Set up partitions on disk(s) and perform stateful provisioning
   #

   cd /
   if ! getfile vnfs/\${VNFS}/vnfs.img; then
      echo "\\\\rERROR(430): There was an error downloading required VNFS components"
      exit 1
   fi

   if [ "x\$RAID" == "x" ]; then
      echo
      echo "Partitioning \${TARGETS} for stateful provisioning..."
      echo
      xcmd "dd if=/dev/zero of=\${TARGETS} count=2"
      echo -e "\\\$FDISK_CMDS" | xcmd "fdisk \${TARGETS}"
      echo -e "t\\n\\\${SWAP_PART}\\n82\\nw\\n" | xcmd "fdisk \${TARGETS}"
   else
      BOOT_MDADM="mdadm --quiet --create --run \\\$BOOT_DEVICE --level=1 --raid-devices=2"
      SWAP_MDADM="mdadm --quiet --create --run \\\$SWAP_DEVICE --level=\$RAID --raid-devices=2"
      ROOT_MDADM="mdadm --quiet --create --run \\\$ROOT_DEVICE --level=\$RAID --raid-devices=2"
      echo
      echo "Partitioning RAID devices for stateful provisioning..."
      echo
      for dev in \$TARGETS; do
         xcmd "dd if=/dev/zero of=\\\${dev} count=2"
         echo -e "\\\$FDISK_CMDS" | xcmd "fdisk \\\$dev"
         echo -e "t\\n1\\nfd\\nt\\n2\\nfd\\nt\\n3\\nfd\\nw\\n" | xcmd "fdisk \\\$dev"
         BOOT_MDADM="\\\$BOOT_MDADM \\\${dev}\\\${BOOT_PART}"
         SWAP_MDADM="\\\$SWAP_MDADM \\\${dev}\\\${SWAP_PART}"
         ROOT_MDADM="\\\$ROOT_MDADM \\\${dev}\\\${ROOT_PART}"
      done

      echo
      echo "Creating RAID arrays..."
      \\\$BOOT_MDADM
      \\\$SWAP_MDADM
      \\\$ROOT_MDADM
   fi

   echo
   echo -n "Creating \\\$BOOTFS filesystem on boot partition... "
   if [ \\\$BOOTFS == "ext3" ]; then
      CMD="mke2fs -T \\\$BOOTFS -I 128"
   elif [ \\\$BOOTFS == "xfs" ]; then
      CMD="mkfs.xfs -f"
   fi
   xcmd "\\\$CMD -L /boot \\\$BOOT_DEVICE"
   echo "done."

   echo
   echo "Creating swap space..."
   xcmd "mkswap \\\$SWAP_DEVICE"

   echo
   echo -n "Creating \$FILESYSTEM filesystem on root partition... "
   if [ \$FILESYSTEM == "ext3" ] || [ \$FILESYSTEM == "ext4" ]; then
      CMD="mke2fs -T \$FILESYSTEM"
   elif [ \$FILESYSTEM == "xfs" ]; then
      CMD="mkfs.xfs -f"
   fi
   xcmd "\\\$CMD -L /root \\\$ROOT_DEVICE"
   echo "done."

   xcmd "mount \\\$ROOT_DEVICE \\\$VNFSROOT -t \$FILESYSTEM"
   cd \\\$VNFSROOT
   rm -rf "lost+found"

   mkdir -p \\\${VNFSROOT}/boot
   xcmd "mount \\\$BOOT_DEVICE \\\${VNFSROOT}/boot -t \\\$BOOTFS"

   echo
   echo -n "Provisioning VNFS image... "
   BEFORE=\\\`date +%s\\\`
   zcat /vnfs.img | xcmd "cpio -dim"
   AFTER=\\\`date +%s\\\`
   SECONDS=\\\$((\\\${AFTER} - \\\${BEFORE}))
   echo "done (took \\\${SECONDS}s)."   

   if [ "x\$RAID" != "x" ]; then
      echo
      echo "Writing out /etc/mdadm.conf..."
      cat <<END > \\\$VNFSROOT/etc/mdadm.conf
# mdadm.conf written out by Perceus
DEVICE partitions
MAILADDR root
END

      xcmd "eval mdadm --detail --scan >> \\\$VNFSROOT/etc/mdadm.conf"
   fi

   cp \\\$VNFSROOT/\$KERNEL \\\$VNFSROOT/\$INITRD /

   if [ "x\$XEN_KERNEL" != "x" ]; then
      cp \\\$VNFSROOT/\$XEN_KERNEL /
   fi

   if [ "x\$DEBUG" = "1x" ]; then
      echo "Building node specific specifications to file system"
   fi
else
   #
   # Do not provision system, just boot from disk
   #

   if [ "x\$XEN_KERNEL" != "x" ]; then
      getfile vnfs/\${VNFS}/rootfs/\${KERNEL} vnfs/\${VNFS}/rootfs/\${XEN_KERNEL}
      RC=\\\$?
   else
      getfile vnfs/\${VNFS}/rootfs/\${KERNEL}
      RC=\\\$?
   fi

   if [ \\\$RC -ne 0 ]; then
      echo "\\\\rERROR(430): There was an error downloading required VNFS components"
      exit 1
   fi

   if [ "x\$RAID" != "x" ]; then
      ASSEMBLE_BOOT="mdadm --quiet --assemble --run \\\$BOOT_DEVICE"
      ASSEMBLE_ROOT="mdadm --quiet --assemble --run \\\$ROOT_DEVICE"

      for dev in \$TARGETS; do
         mdadm --examine \\\${dev}\\\${BOOT_PART}
         if [ \\\$? -eq 0 ]; then
            ASSEMBLE_BOOT="\\\$ASSEMBLE_BOOT \\\${dev}\\\${BOOT_PART}"
         fi
         mdadm --examine \\\${dev}\\\${ROOT_PART}
         if [ \\\$? -eq 0 ]; then
            ASSEMBLE_ROOT="\\\$ASSEMBLE_ROOT \\\${dev}\\\${ROOT_PART}"
         fi
      done

      echo
      echo "Assembling boot RAID array..."
      xcmd "\\\$ASSEMBLE_BOOT"

      echo
      echo "Assembling root RAID array..."
      xcmd "\\\$ASSEMBLE_ROOT"
   fi

   echo
   echo "Mounting root device..."
   xcmd "mount \\\$ROOT_DEVICE \\\$VNFSROOT -t \$FILESYSTEM"

   echo
   echo "Mounting boot device..."
   xcmd "mount \\\$BOOT_DEVICE \\\${VNFSROOT}/boot -t \\\$BOOTFS"
fi

#
# The following commands are always executed, regardless of whether we are performing
# initial stateful provisioning or simply booting from disks
#

echo
echo "Updating /etc/fstab..."

sed -i -e "s|%{root entry}|\\\${ROOT_DEVICE}\\t/\\t\\t\\t\${FILESYSTEM}\\tdefaults\\t1 1|" \\
 -e "s|%{boot entry}|LABEL=/boot\\t/boot\\t\\t\\t\\\${BOOTFS}\\tdefaults\\t1 1|" \\
 -e "s|%{swap entry}|\\\${SWAP_DEVICE}\\tnone\\t\\t\\tswap\\tdefaults\\t0 0|" \\\${VNFSROOT}/etc/fstab

echo
echo "Generating /etc/modprobe.conf..."

if [ -x /sbin/modconf-generator ]; then
   /sbin/modconf-generator > \\\${VNFSROOT}/etc/modprobe.conf
fi

if [ "x\$GRUB" = "xyes" ]; then
   GRUB_CONF="\\\${VNFSROOT}/boot/grub/grub.conf"

   echo
   echo "Writing out \\\${GRUB_CONF}..."
   cat <<END > \\\${GRUB_CONF}
# Generated automatically by Perceus
default 0
timeout 5
END

   if [ "x\$RAID" == "x" ]; then
      if [ "x\$XEN_KERNEL" == "x" ]; then
         cat <<END >> \\\${GRUB_CONF}
title Perceus - \$VNFS (\${KVER})
    root (hd0,0)
    kernel /\${KNAME} masterip=\\\${MASTERIP} \$KERNEL_ARGS
    initrd /\${INAME}
END
      else
         cat <<END >> \\\${GRUB_CONF}
title Perceus - \$VNFS (\${KVER})
    root (hd0,0)
    kernel /\${XNAME} masterip=\\\${MASTERIP} \$KERNEL_ARGS
    module /\${KNAME}
    module /\${INAME}
END
      fi
   else
      i=0
      for dev in \${TARGETS}; do
         cat <<END >> \\\${GRUB_CONF}
title Perceus - \$VNFS (\\\${dev}) (\${KVER})
    root (hd\\\${i},0)
END
         if [ "x\$XEN_KERNEL" == "x" ]; then
            cat <<END >> \\\${GRUB_CONF}
    kernel /\${KNAME} masterip=\\\${MASTERIP} \$KERNEL_ARGS
    initrd /\${INAME}
END
         else
            cat <<END >> \\\${GRUB_CONF}
    kernel /\${XNAME} masterip=\\\${MASTERIP} \$KERNEL_ARGS
    module /\${KNAME}
    module /\${INAME}
END
         fi
         i=\`expr \\\${i} + 1\`
      done
   fi

   if [ ! -L \\\${VNFSROOT}/boot/grub/menu.lst ]; then
      cd \\\${VNFSROOT}/boot/grub
      ln -s grub.conf menu.lst
   fi

   echo
   echo "Copying GRUB images..."
   xcmd "chroot \\\${VNFSROOT} grub-install --just-copy"

   echo
   echo "Installing GRUB..."

   # Sleep arbitrarily instead of running xfs_freeze on mount point
   if [ \$FILESYSTEM == "xfs" ]; then
      sleep 22
   fi

   if [ "x\$RAID" == "x" ]; then
      xcmd "\\\${VNFSROOT}/sbin/grub --batch" <<END
root (hd0,0)
setup (hd0)
quit
END

      echo
      echo -n "Generating new initrd... "
    
      xcmd "chroot \\\${VNFSROOT} mkinitrd -f \${INITRD} \${KVER}"

      echo "done"
   else
      i=0
      for dev in \${TARGETS}; do
         xcmd "\\\${VNFSROOT}/sbin/grub --batch" <<END
root (hd\\\${i},0)
setup (hd\\\${i})
quit
END
         i=\`expr \\\${i} + 1\`
      done

      for md in "\\\${BOOT_DEVICE} \\\${SWAP_DEVICE} \\\${ROOT_DEVICE}"; do
         cp -a \\\${md} \\\${VNFSROOT}/dev
      done

      MKINITRD_OPTS=""
      if [ "x\$RAID" == "x0" ]; then
          MKINITRD_OPTS="\\\${MKINITRD_OPTS} --preload raid0"
      fi
 
      if [ "x\$RAID" == "x1" ]; then
          MKINITRD_OPTS="\\\${MKINITRD_OPTS} --preload raid1"
      fi

      echo
      echo -n "Generating new initrd... "
    
      xcmd "eval chroot \\\${VNFSROOT} env raiddevices=\\"\\\${BOOT_MD} \\\${SWAP_MD} \\\${ROOT_MD}\\" mkinitrd -f \\\${MKINITRD_OPTS} \${INITRD} \${KVER}"
      echo "done"
   fi
fi

cp \\\${VNFSROOT}\${INITRD} /

echo "#!/bin/sh" > \\\$DESTDIR/init
chmod +x \\\$DESTDIR/init
EOF
DNE

cat <<DNE > $TMPDIR/$NAME/nodescripts/init/89-vnfsinit.sh
#!/bin/sh
# This script was built by Perceus:chroot2stateful.sh

if [ -f "\$STATEDIR/vnfs/\$VNFS/config" ]; then
   . \$STATEDIR/vnfs/\$VNFS/config
fi

if [ "x\$COMPRESSION" = "xhigh" ]; then
   ZIP="9"
else
   ZIP="1"
fi


#if [ "x\$USE_INITRD_PROVISIOND" != "x" -a "x\$USE_INITRD_PROVISIOND" != "x0" ]; then
#   echo "mkdir \\\$DESTDIR/sbin/"
#   echo "cp /sbin/provisiond \\\$DESTDIR/sbin/provisiond-1"
#fi

cat <<EOF 
echo "test -f /sbin/hotplug.disabled && mv /sbin/hotplug.disabled /sbin/hotplug" >> \\\$DESTDIR/init
echo "rm /init" >> \\\$DESTDIR/init
echo "exec /sbin/init \\\\\\\$@" >> \\\$DESTDIR/init
EOF

KNAME=\`basename \$KERNEL\`
INAME=\`basename \$INITRD\`

if [ "x\$XEN_KERNEL" != "x" ]; then
   XNAME=\`basename \$XEN_KERNEL\`
   echo "\$KEXEC --module=/\${KNAME} --module=/\${INAME} --force --append=\\"masterip=\\\${MASTERIP} \$KERNEL_ARGS\" /\${XNAME}"
else
   echo "\$KEXEC --initrd=/\${INAME} --force --append=\\"masterip=\\\${MASTERIP} \$KERNEL_ARGS\\" \$KEXEC_ARGS /\${KNAME}"
fi
DNE

cat <<DNE > $TMPDIR/$NAME/configure
#!/bin/sh
# This script was built by Perceus:chroot2stateful.sh

if [ -n "\$NO_CONFIGURE" ]; then
   exit
fi

VNFSDIR=\`dirname \$0\`
VNFSNAME=\`basename \$VNFSDIR\`
MASTER=\`perceus -e info config "vnfs transfer master"\`

VNFSMOUNT="/mnt/\$VNFSNAME"

METHOD=\`perceus -e info config "vnfs transfer method"\`
PREFIX=\`perceus -e info config "vnfs transfer prefix"\`
STATEDIR=\`perceus -e info config "statedir"\`

if [ -x "/usr/sbin/chroot" ]; then
   CHROOT=/usr/sbin/chroot
elif [ -x "/usr/bin/chroot" ]; then
   CHROOT=/usr/bin/chroot
elif [ -x "/sbin/chroot" ]; then
   CHROOT=/sbin/chroot
elif [ -x "/bin/chroot" ]; then
   CHROOT=/bin/chroot
fi

echo "Configuring VNFS..."

perceus -e vnfs mount \$VNFSNAME

mkdir -p \$VNFSMOUNT/etc/
mkdir -p \$VNFSMOUNT/etc/ssh
mkdir -p \$VNFSMOUNT/root/.ssh

if [ -f "\$VNFSMOUNT/usr/bin/passwd" -o -f "\$VNFSMOUNT/bin/passwd" ]; then
cat <<EOF





================================================================================
VNFS Capsule root password:

Here you will need to set the root password for this VNFS capsule. This password
will be used to gain local access to the node and potentially for ssh access if
for some reason the automatic Perceus ssh keys are not used.

It is not recommended to make this password the same as the master node because
depending on your configuration, it maybe possible for a non-administrative user
to download the VNFS image and extract the password. Best practice to not use a
critical or shared password for your VNFS capsules.

EOF

\$CHROOT \$VNFSMOUNT/ passwd root
sleep 1
else
cat <<EOF





================================================================================
VNFS Capsule root password:

The root account in this VNFS has been disabled for password login. This will
not affect passwordless loging mechanisms such as SSH, but local logins via
the terminal will be disallowed.

If you wish to enable this, you must set a root password by either running the
"passwd" command from within the chroot, or copying an existing entry from
your /etc/shadow entry.

It is not recommended to make this password the same as the master node because
depending on your configuration, it maybe possible for a non-administrative user
to download the VNFS image and extract the password. Best practice to not use a
critical or shared password for your VNFS capsules.

EOF
sed -i -e 's/^root:.*/root:LOCKED:::::::/' \$VNFSMOUNT/etc/shadow
fi

echo -n "Press [ENTER] to continue: "
read foo


cat <<EOF





================================================================================
Enable NFS based file system hybridization:

This VNFS is capable of hybridizing parts of the node file system to a network
based file system (e.g. NFS) through the use of symbolic links. To do this
requires an entry in the node's /etc/fstab which will mount the file system
which will provide the targets to the symbolic links.

In its default configuration this network mount is not required for node
operation (this can be changed in the "hybridized" VNFS configuration file) but
it is useful for making the node feel more like a traditionally installed
operating system without utilizing more RAM.

Do you wish to enable NFS based hybridization support? (Default is 'no')

EOF
echo -ne "Hybridization Support [no]> "
read HYBRIDIZATION

if [ "x\${HYBRIDIZATION:-no}" = "xyes" ]; then
   echo
   echo "Creating fstab entry for hybrid NFS requirements"
   mkdir -p \$VNFSMOUNT/\$STATEDIR
   if [ "x\$PREFIX" = "x" ]; then
      echo "Will mount: \$MASTER:\$STATEDIR"
      if ! grep -q "^\$MASTER:\$STATEDIR" \$VNFSMOUNT/etc/fstab; then
         echo "\$MASTER:\$STATEDIR \$STATEDIR nfs ro,soft,bg 0 0" >> \$VNFSMOUNT/etc/fstab
      fi
   else
      echo "Will mount: \$MASTER:\$PREFIX"
      if ! grep -q "^\$MASTER:\$PREFIX" \$VNFSMOUNT/etc/fstab; then
         echo "\$MASTER:\$PREFIX \$STATEDIR nfs ro,soft,bg 0 0" >> \$VNFSMOUNT/etc/fstab
      fi
   fi
fi



cat <<EOF





================================================================================
Default console device:

The default console is where the kernel and boot messages are displayed. Usually
this is set to 'tty0' which is the traditional default video and keyboard
device. You can also set it to a serial device (e.g. 'ttyS0' or 'ttyS1' for COM1
and COM2 respectively).

If you are unsure which console device you wish to make default, just press
[ENTER] to accept the default ('tty0').

EOF
echo -ne "Console Device [tty0]> "
read CONSOLE
CONSOLE=\${CONSOLE:-tty0}
if [ \`echo \$CONSOLE | cut -c 1-4\` = "ttyS" ] && ! echo \$CONSOLE | grep -q "\$CONSOLE," ; then
   CONSOLE="\$CONSOLE,115200"
fi
echo "Setting default console to: \$CONSOLE"

sed -i -e "/^KERNEL_ARGS=/ s/ console=[^ \"]*//g; /^KERNEL_ARGS=/ s/\"$/ console=\$CONSOLE\"/" \$VNFSDIR/config

egrep -v '^s.:2345:respawn:/sbin/agetty ' \$VNFSMOUNT/etc/inittab > /tmp/_inittab.$VNFSNAME
cat /tmp/_inittab.$VNFSNAME > \$VNFSMOUNT/etc/inittab
rm -f /tmp/_inittab.$VNFSNAME

if [ -f "\$VNFSMOUNT/sbin/mingetty" ]; then
   GETTY="mingetty"
elif [ -f "\$VNFSMOUNT/sbin/agetty" ]; then
   GETTY="agetty"
fi

if [ \${CONSOLE:-tty0} = "ttyS0" ]; then
   echo "s0:2345:respawn:/sbin/\$GETTY -L 115200 ttyS0 vt100" >> \$VNFSMOUNT/etc/inittab
elif [ \${CONSOLE:-tty0} = "ttyS1" ]; then
   echo "s1:2345:respawn:/sbin/\$GETTY -L 115200 ttyS1 vt100" >> \$VNFSMOUNT/etc/inittab
elif [ \${CONSOLE:-tty0} = "ttyS2" ]; then
   echo "s2:2345:respawn:/sbin/\$GETTY -L 115200 ttyS2 vt100" >> \$VNFSMOUNT/etc/inittab
fi


cat <<EOF





================================================================================
Various Network Service Configurations:

Next you will be prompted for configurations of various services within this
VNFS capsule.

EOF

echo
echo "The Perceus services by default will manage DNS, so under almost all"
echo "circumstances you should assign this to the Perceus master server."
echo
echo -ne "Enter the IP address of the DNS server [\$MASTER]> "
read NAMESERVER

echo "# Created by vnfs import" > \$VNFSMOUNT/etc/resolv.conf
echo "nameserver \${NAMESERVER:-\$MASTER}" >> \$VNFSMOUNT/etc/resolv.conf

if [ -f "\$VNFSMOUNT/etc/init.d/provisiond" ]; then
   echo
   echo -ne "Enter the IP address of your Perceus master [\$MASTER]> "
   read PERCEUSD

   echo "MASTERIP=\"\${PERCEUSD:-\$MASTER}\"" > \$VNFSMOUNT/etc/sysconfig/provisiond.conf

   if [ -n "\$INFINIBAND" ]; then
      echo "NODEID=\"nodeid=\\\`ethinfo -aq eth0\\\`\"" >> \$VNFSMOUNT/etc/sysconfig/provisiond.conf
   fi

   ln -sf provisiond.conf \$VNFSMOUNT/etc/sysconfig/provisiond
   
fi

if [ -f "\$VNFSMOUNT/etc/init.d/wulfd" ]; then
   echo
   echo -ne "Enter the IP address of your Warewulf master [\$MASTER]> "
   read WAREWULFD

   echo "WAREWULF_MASTER=\"\${WAREWULFD:-\$MASTER}\"" > \$VNFSMOUNT/etc/sysconfig/wulfd.conf
fi


#if [ -f "\$VNFSMOUNT/sbin/syslogd" -o -f "\$VNFSMOUNT/etc/syslog.conf" ]; then
#   echo
#   echo -ne "Enter the IP address of your syslogd host [\$MASTER]> "
#   read SYSLOGD
#
#   SYSLOGD=\${SYSLOGD:-\$MASTER}
#
#   echo "*.alert @\$SYSLOGD" > \$VNFSMOUNT/etc/syslog.conf
#   echo "local7.* @\$SYSLOGD" >> \$VNFSMOUNT/etc/syslog.conf
#   echo "*.emerg @\$SYSLOGD" >> \$VNFSMOUNT/etc/syslog.conf
#fi

if [ -f "\$VNFSMOUNT/etc/ntp.conf" ]; then
   echo
   echo -ne "Enter the IP address of your NTP master [\$MASTER]> "
   read NTP

   echo "restrict default ignore"                > \$VNFSMOUNT/etc/ntp.conf
   echo "restrict 127.0.0.1"                    >> \$VNFSMOUNT/etc/ntp.conf
   echo "server \${NTP:-\$MASTER}"               >> \$VNFSMOUNT/etc/ntp.conf
   echo "restrict \${NTP:-\$MASTER} nomodify"    >> \$VNFSMOUNT/etc/ntp.conf
fi

if [ -f "\$VNFSMOUNT/var/spool/torque/mom_priv/config" ]; then
   echo
   echo -ne "Enter the IP address of the Torque master [\$MASTER]> "
   read TORQUE_MASTER

   sed -i -e "s@\\\$pbsserver.*@\\\$pbsserver \${TORQUE_MASTER:-\$MASTER}@" \
      \$VNFSMOUNT/var/spool/torque/mom_priv/config
fi

cat <<EOF

================================================================================
Finalizing VNFS configuration:

EOF



if grep -q "^/home" /etc/exports 2>/dev/null; then
   echo "Export '/home' found in exports... Adding to node's /etc/fstab"
   if ! grep -q "^\$MASTER:/home" \$VNFSMOUNT/etc/fstab; then
      echo "\$MASTER:/home/ /home nfs defaults 0 0" >> \$VNFSMOUNT/etc/fstab
   fi
   test -d \$VNFSMOUNT/home || mkdir -p \$VNFSMOUNT/home
fi

if grep -q "^/opt" /etc/exports 2>/dev/null; then
   echo "Export '/opt' found in exports... Adding to node's /etc/fstab"
   if ! grep -q "^\$MASTER:/opt" \$VNFSMOUNT/etc/fstab; then
      echo "\$MASTER:/opt /opt nfs defaults 0 0" >> \$VNFSMOUNT/etc/fstab
   fi
   test -d \$VNFSMOUNT/opt || mkdir -p \$VNFSMOUNT/opt
fi

if grep -q "^/usr/local" /etc/exports 2>/dev/null; then
   echo "Export '/usr/local' found in exports... Adding to node's /etc/fstab"
   if ! grep -q "^\$MASTER:/usr/local" \$VNFSMOUNT/etc/fstab; then
      echo "\$MASTER:/usr/local /usr/local nfs defaults 0 0" >> \$VNFSMOUNT/etc/fstab
   fi
   test -d \$VNFSMOUNT/usr/local || mkdir -p \$VNFSMOUNT/usr/local
fi

if grep -q "^/usr/cports" /etc/exports 2>/dev/null; then
   echo "Export '/usr/cports' found in exports... Adding to node's /etc/fstab"
   if ! grep -q "^\$MASTER:/usr/cports" \$VNFSMOUNT/etc/fstab; then
      echo "\$MASTER:/usr/cports /usr/cports nfs defaults 0 0" >> \$VNFSMOUNT/etc/fstab
   fi
   test -d \$VNFSMOUNT/usr/cports || mkdir -p \$VNFSMOUNT/usr/cports
fi

if grep -q "^/srv" /etc/exports 2>/dev/null; then
   echo "Export '/srv' found in exports... Adding to node's /etc/fstab"
   if ! grep -q "^\$MASTER:/srv" \$VNFSMOUNT/etc/fstab; then
      echo "\$MASTER:/srv /srv nfs defaults 0 0" >> \$VNFSMOUNT/etc/fstab
   fi
   test -d \$VNFSMOUNT/srv || mkdir -p \$VNFSMOUNT/srv
fi

if grep -q "^/private" /etc/exports 2>/dev/null; then
   echo "Export '/private' found in exports... Adding to node's /etc/fstab"
   if ! grep -q "^\$MASTER:/private" \$VNFSMOUNT/etc/fstab; then
      echo "\$MASTER:/private /private nfs defaults 0 0" >> \$VNFSMOUNT/etc/fstab
   fi
   test -d \$VNFSMOUNT/private || mkdir -p \$VNFSMOUNT/private
fi

if [ -d "/etc/slurm" ]; then
   echo "Copying master's slurm configuration"
   cp -rap /etc/slurm \$VNFSMOUNT/etc/
fi

echo "Copying master's timezone configuration"
cp -p /etc/localtime \$VNFSMOUNT/etc/localtime
echo "Copying ssh public keys";
mkdir -p \$VNFSMOUNT/root/.ssh
cat \$HOME/.ssh/*.pub 2>/dev/null > \$VNFSMOUNT/root/.ssh/authorized_keys
chmod 400 \$VNFSMOUNT/root/.ssh/authorized_keys

echo "Updating hosts file"
HOSTNAME=\`hostname\`
cat <<EOF > \$VNFSMOUNT/etc/hosts
127.0.0.1               localhost localhost.localdomain

EOF

if [ ! -f "\$VNFSMOUNT/etc/ssh/ssh_host_key" -a -d "\$VNFSMOUNT/etc/ssh" ]; then
   if [ -f "/etc/perceus/keys/ssh_host_key" ]; then
      echo "Copying ssh host keys from /etc/perceus/keys/"
      cp /etc/perceus/keys/ssh_host*key* \$VNFSMOUNT/etc/ssh/
   else
      echo -n "Creating ssh keys... "
      /usr/bin/ssh-keygen  -q -t rsa1 -f \$VNFSMOUNT/etc/ssh/ssh_host_key -C '' -N '' >&/dev/null
      echo -n "rsa1 "
      /usr/bin/ssh-keygen  -q -t rsa -f \$VNFSMOUNT/etc/ssh/ssh_host_rsa_key -C '' -N '' >&/dev/null
      echo -n "rsa "
      /usr/bin/ssh-keygen  -q -t dsa -f \$VNFSMOUNT/etc/ssh/ssh_host_dsa_key -C '' -N '' >&/dev/null
      echo -n "dsa "
      chmod 600 \$VNFSMOUNT/etc/ssh/*key*
      echo
   fi
fi

cat <<EOF

================================================================================
VNFS Configuration Complete

EOF

perceus -e vnfs umount \$VNFSNAME
DNE

cat <<DNE > $TMPDIR/$NAME/mount
#!/bin/sh
# This script was built by Perceus:chroot2stateful.sh

VNFSDIR=\`dirname \$0\`
VNFS=\$VNFSDIR/vnfs.img
VNFSNAME=\`basename \$VNFSDIR\`

if [ -L "/mnt/\$VNFSNAME" ]; then
   echo "VNFS '\$VNFSNAME' is already mounted!"
   exit 1
fi

if [ -e "/mnt/\$VNFSNAME" ]; then
   echo "ERROR: remove the file at /mnt/\$VNFSNAME"
   exit 1
fi

if [ ! -d "\$VNFSDIR" ]; then
   echo "VNFS '\$VNFSNAME' is not found!"
   exit 1
fi

echo "Mounting VNFS '\$VNFSNAME'...";

rm -rf /mnt/\$VNFSNAME
ln -s \$VNFSDIR/rootfs /mnt/\$VNFSNAME
mount -t proc none \$VNFSDIR/rootfs/proc
echo "The VNFS can be found at: /mnt/\$VNFSNAME"
DNE

cat <<DNE > $TMPDIR/$NAME/hybridize
# Hybridization can be done pending several scenerios are met. First, the
# local state directory for Perceus (typically /var/lib/perceus) must be
# exported and mountable on the node. Second the node must be configured to
# mount the exported directory in its /etc/fstab. Third, you can NOT
# hybridize the directory that you configured to be the local state
# directory when Perceus was compiled. If that directory is hybridized bad
# and somewhat unlogical things will happen. You have been warned!
#
# To activate any changes in this file you must mount and then umount this
# VNFS using Perceus:
#
#    > perceus vnfs mount $NAME
#    > perceus vnfs umount $NAME

#/usr/share
#/usr/X11R6
#/usr/lib/locale
#/usr/lib64/locale
#/usr/src
#/usr/include

DNE

cat <<DNE > $TMPDIR/$NAME/umount
#!/bin/sh
# This script was built by Perceus:chroot2stateful.sh

VNFSDIR=\`dirname \$0\`
VNFS=\$VNFSDIR/vnfs.img
VNFSNAME=\`basename \$VNFSDIR\`
TMPDIR=\`mktemp -d /var/tmp/tmp.vnfs.XXXXXXX\`
TIME=\`date +%s\`

if [ -f "\$VNFSDIR/config" ]; then
   . \$VNFSDIR/config
fi

if [ "x\$COMPRESSION" = "xhigh" ]; then
   ZIP="9"
else
   ZIP="1"
fi

if [ "x\$HYBRIDIZE_FILE" = "x" ]; then
   HYBRIDIZE_FILE="\$VNFSDIR/hybridize"
elif [ ! -f "\$HYBRIDIZE_FILE" ]; then
   HYBRIDIZE_FILE="\$VNFSDIR/hybridize"
fi

HYBRIDIZE=\`grep -v "^#" \$HYBRIDIZE_FILE | sed -e 's/^\///g'\`

EXCLUDES=\`for i in \$HYBRIDIZE; do echo "--exclude=\$i "; done\`

if [ ! -d "\$VNFSDIR" ]; then
   echo "VNFS '\$VNFS' doesn't seem to exist!"
   exit 1
fi

echo "Un-mounting VNFS '\$VNFSNAME'..."

cd \$VNFSDIR/rootfs
umount \$VNFSDIR/rootfs/proc 2>/dev/null

if grep -q "/\$VNFSNAME " /proc/mounts; then
   echo "ERROR: there are mounted file systems in /mnt/\$VNFSNAME"
   exit 1
fi

mkdir -p \$TMPDIR
rsync -qxaRSH \$EXCLUDES . \$TMPDIR

if [ -f "\$TMPDIR/sbin/hotplug" ]; then
   mv \$TMPDIR/sbin/hotplug \$TMPDIR/sbin/hotplug.disabled
fi

for i in \$HYBRIDIZE; do
   for file in \`(cd \$VNFSDIR/rootfs; find \$i -maxdepth 0 ) 2>/dev/null\`; do
      ln -s \$VNFSDIR/rootfs/\$file \$TMPDIR/\$file
   done
done

cd \$TMPDIR

echo "This will take some time as the image is updated and compressed..."
find . | cpio --quiet -o -H newc | gzip -\$ZIP > \$VNFSDIR/vnfs.img~

if [ "x\$BACKUP" = "xyes" ]; then
   if [ -f "\$VNFSDIR/vnfs.img" ]; then
      cp \$VNFSDIR/vnfs.img \$VNFSDIR/vnfs.img.\$TIME
   fi
fi

# We do this in a single atomic move trying not to break any booting
# nodes
mv \$VNFSDIR/vnfs.img~ \$VNFSDIR/vnfs.img

rm -rf \$TMPDIR

if ! rm /mnt/\$VNFSNAME; then
   echo "ERROR: Can not remove /mnt/\$VNFSNAME! Fix this by hand."
fi
DNE

cat <<DNE > $TMPDIR/$NAME/close
#!/bin/sh
# This script was built by Perceus:chroot2stateful.sh

VNFSDIR=\`dirname \$0\`
VNFS=\$VNFSDIR/vnfs.img
VNFSNAME=\`basename \$VNFSDIR\`

if [ -d "/mnt/\$VNFSNAME" ]; then
   umount \$VNFSDIR/rootfs/proc 2>/dev/null
   if ! rm /mnt/\$VNFSNAME; then
      echo "ERROR: Can not remove /mnt/\$VNFSNAME! Fix this by hand."
   fi
else
   echo "ERROR: '\$VNFS' is not mounted"
fi
DNE

chmod +x $TMPDIR/$NAME/nodescripts/*/*
chmod +x $TMPDIR/$NAME/configure
chmod +x $TMPDIR/$NAME/mount
chmod +x $TMPDIR/$NAME/umount
chmod +x $TMPDIR/$NAME/close
chmod +x $TMPDIR/$NAME/livesync

echo "Compressing capsule ..."
cd $TMPDIR/$NAME
tar cjf ../$NAME.part .

cd $STARTDIR
mv $TMPDIR/$NAME.part $CREATE_IMAGE

echo
echo "WROTE: $CREATE_IMAGE"
echo
echo "NOTE: The stateful VNFS capsule generated uses default settings for your"
echo "storage target (eg. /dev/sda). If you would like to use something else"
echo "for instance /dev/hda or a RAID configuration, please modify the VNFS"
echo "config after importing the capsule into Perceus."
echo

rm -rf $TMPDIR

