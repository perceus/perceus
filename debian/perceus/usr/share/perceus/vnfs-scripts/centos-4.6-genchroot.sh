#!/bin/sh
#
# Copyright (c) 2006-2009, Greg M. Kurtzer, Arthur A. Stevens and
# Infiscale, Inc. All rights reserved
#

DIRNAME=`dirname $0`

if [ "x$MIRROR" = "x" ]; then
    # use the LBL mirror
    #MIRROR=http://altruistic.lbl.gov/mirrors/centos
    MIRROR=http://mirror.centos.org/centos-4
fi

VAULTMIRROR=http://vault.centos.org/

releasever=4.6
export releasever

VNFSROOT=/var/tmp/vnfs

#check for SELinux as the default policy interferes with 
#rpm scriptlets run by warewulf
[ -f /usr/sbin/selinuxenabled ] && {
	/usr/sbin/selinuxenabled
	[ $? = 0 ] && {
		echo -e "\n"
		echo "SELinux is enabled.  "
		echo "SELinux interferes with configuration of the VNFS.  Please"
		echo "disable SELinux in /etc/sysconfig/selinux, reboot and then"
		echo "run this script."
		echo -e "\n"	
		echo "Exiting..."
		exit 1
	}
}

if [ -z "$ARCH" ]; then
   ARCH=`uname -m`
fi

if [ "x$ARCH" != "xx86_64" ]; then
   ARCH=i386
fi

if [ "x$1" != "x" ]; then
   NAME=$1
else
   NAME="centos-$releasever-1.$ARCH"
fi

if [ -n "$CHROOT" ]; then
   CHROOT=$CHROOT
elif [ -x "/usr/sbin/chroot" ]; then
   CHROOT=/usr/sbin/chroot
elif [ -x "/usr/bin/chroot" ]; then
   CHROOT=/usr/bin/chroot
elif [ -x "/sbin/chroot" ]; then
   CHROOT=/sbin/chroot
elif [ -x "/bin/chroot" ]; then
   CHROOT=/bin/chroot
else
   echo "Could not find the program 'chroot'"
   exit 1
fi

echo "Building in: $VNFSROOT/$NAME/"

# Check for grsecurity restrictions
GRSEC_RESET=""
for i in chroot_deny_chmod chroot_deny_mknod chroot_deny_mount ; do
    if [ -e /proc/sys/kernel/grsecurity/$i ]; then
        VAL=`cat /proc/sys/kernel/grsecurity/$i`
        if [ "x$VAL" != "x0" ]; then
            GRSEC_RESET="$GRSEC_RESET $i"
            echo 0 > /proc/sys/kernel/grsecurity/$i
            VAL=`cat /proc/sys/kernel/grsecurity/$i`
        fi
        if [ "x$VAL" != "x0" ]; then
            echo "ERROR:  Unable to deactivate grsecurity measures."
        fi
    fi
done

mkdir -p $VNFSROOT/$NAME/etc/sysconfig
mkdir -p $VNFSROOT/$NAME/etc/yum.repos.d
mkdir -p $VNFSROOT/$NAME/var/lib/rpm
mkdir -p $VNFSROOT/$NAME/var/lock/rpm
mkdir -p $VNFSROOT/$NAME$VNFSROOT
rm -f $VNFSROOT/$NAME$VNFSROOT/$NAME
ln -s / $VNFSROOT/$NAME$VNFSROOT/$NAME
rpm --initdb --dbpath $VNFSROOT/$NAME/var/lib/rpm
cat <<EOF >$VNFSROOT/$NAME/etc/yum.conf
[main]
cachedir=/var/cache/yum
debuglevel=2
logfile=/var/log/yum.log
pkgpolicy=newest
distroverpkg=centos-release
installonlypkgs=linux linux-smp kernel kernel-smp
exactarch=1
EOF

cat <<EOF >$VNFSROOT/$NAME/etc/yum.repos.d/vnfs-centos4-base.repo
[vnfs-centos4-base]
name=CentOS-$releasever - Base
baseurl=$MIRROR/$releasever/os/$ARCH
        $VAULTMIRROR/$releasever/os/$ARCH
gpgkey=http://mirror.centos.org/centos/4/os/i386/RPM-GPG-KEY-centos4
EOF

cat <<EOF >$VNFSROOT/$NAME/etc/fstab
# Don't touch the following macro unless you really know what you're doing!
none		/			tmpfs	defaults	0 0
none            /dev/pts                devpts  gid=5,mode=620  0 0
none            /dev/shm                tmpfs   defaults        0 0
none            /proc                   proc    defaults        0 0

# To use a local disk on the nodes (make sure the mountpoints exist in
# the VNFS!!!)
#/dev/hda2      /scratch                ext3    defaults        0 0
#/dev/hda1      none                    swap    defaults        0 0

EOF

cat <<EOF >$VNFSROOT/$NAME/etc/mtab
none / ext3 rw 0 0
EOF

mkdir -p $VNFSROOT/$NAME/dev/
mknod $VNFSROOT/$NAME/dev/null c 1 3		>/dev/null 2>&1
yum -y -t -d 2 -c $VNFSROOT/$NAME/etc/yum.conf --installroot $VNFSROOT/$NAME install \
   SysVinit basesystem bash centos-release chkconfig coreutils cracklib \
   cracklib-dicts db4 e2fsprogs ethtool filesystem findutils gawk \
   glib glibc glibc-common grep initscripts iproute iputils krb5-libs \
   libacl libattr libgcc libstdc++ libtermcap mingetty mktemp ncurses \
   net-tools nfs-utils pam pcre popt portmap procps psmisc rdate rsh \
   rsh-server rsync sed setup shadow-utils sysklogd tcp_wrappers termcap \
   tzdata util-linux words xinetd zlib tar mkinitrd less gzip which \
   util-linux module-init-tools udev kernel-smp openssh-clients \
   openssh-server passwd dhclient pciutils vim-minimal shadow-utils \
   vixie-cron ntp strace grub

echo "NETWORKING=yes"	> $VNFSROOT/$NAME/etc/sysconfig/network
cp /etc/securetty	   $VNFSROOT/$NAME/etc/securetty
echo "ttyS0"		>> $VNFSROOT/$NAME/etc/securetty
echo "ttyS1"		>> $VNFSROOT/$NAME/etc/securetty
echo "127.0.0.1		localhost localhost.localdomain" \
			> $VNFSROOT/$NAME/etc/hosts
echo "s0:2345:respawn:/sbin/agetty -L 115200 ttyS0 vt100" \
			>> $VNFSROOT/$NAME/etc/inittab
echo "s1:2345:respawn:/sbin/agetty -L 115200 ttyS1 vt100" \
			>> $VNFSROOT/$NAME/etc/inittab

if [ -x "$VNFSROOT/$NAME/usr/sbin/pwconv" ]; then
   $CHROOT $VNFSROOT/$NAME /usr/sbin/pwconv >/dev/null 2>&1||:
fi
if [ -x "$VNFSROOT/$NAME/sbin/chkconfig" ]; then
   $CHROOT $VNFSROOT/$NAME /sbin/chkconfig xinetd on >/dev/null 2>&1
fi

cp $VNFSROOT/$NAME/etc/skel/.bash* $VNFSROOT/$NAME/root/

sed -i -e 's/# End of file//' $VNFSROOT/$NAME/etc/security/limits.conf
if ! grep -q "^* soft memlock " $VNFSROOT/$NAME/etc/security/limits.conf; then
   echo "* soft memlock 8388608 # 8 GB" >> $VNFSROOT/$NAME/etc/security/limits.conf
fi
if ! grep -q "^* hard memlock " $VNFSROOT/$NAME/etc/security/limits.conf; then
   echo "* hard memlock 8388608 # 8 GB" >> $VNFSROOT/$NAME/etc/security/limits.conf
fi
echo >> $VNFSROOT/$NAME/etc/security/limits.conf
echo "# End of file" >> $VNFSROOT/$NAME/etc/security/limits.conf

cat <<EOF > $VNFSROOT/$NAME/etc/ssh/ssh_config
Host *
   StrictHostKeyChecking no
   CheckHostIP yes
   UsePrivilegedPort no
   Protocol 2
EOF
chmod +r $VNFSROOT/$NAME/etc/ssh/ssh_config

$CHROOT $VNFSROOT/$NAME umount /proc	>/dev/null 2>&1
rm -rf $VNFSROOT/$NAME/var/cache/yum/*
rm -rf $VNFSROOT/$NAME/var/log/*
rm -rf $VNFSROOT/$NAME/etc/yum.repos.d/vnfs*

# Reset grsecurity measures as soon as we're done chroot'ing.
for i in $GRSEC_RESET ; do
    echo 1 > /proc/sys/kernel/grsecurity/$i
done

# add broken_shadow to pam.d/system-auth to allow users 
# to not have shadow entries fix courtesy of padowns
mv $VNFSROOT/$NAME/etc/pam.d/system-auth $VNFSROOT/$NAME/etc/pam.d/system-auth-orig
sed -e '/^account.*pam_unix\.so$/s/$/\ broken_shadow/' \
$VNFSROOT/$NAME/etc/pam.d/system-auth-orig > $VNFSROOT/$NAME/etc/pam.d/system-auth
rm -f $VNFSROOT/$NAME/etc/pam.d/system-auth-orig

# add system root password to the nodes
umask 277               # to prevent user readable files
sed -e s/root::/root:!!:/ < $VNFSROOT/$NAME/etc/shadow > $VNFSROOT/$NAME/etc/shadow.new
cp $VNFSROOT/$NAME/etc/shadow.new $VNFSROOT/$NAME/etc/shadow
rm $VNFSROOT/$NAME/etc/shadow.new
umask 0022              # set umask back to default

rm -f $VNFSROOT/$NAME/dev/log

echo 
echo "The chroot has been created at: $VNFSROOT/$NAME"
echo "Make any changes you want to it and then use 'chroot2*.sh' to create a"
echo "Perceus VNFS capsule. For example:"
echo
echo "   # ${DIRNAME}/chroot2stateless.sh $VNFSROOT/$NAME /root/centos-$releasever-1.stateless.$ARCH.vnfs"

