#!/bin/sh
#
# Copyright (c) 2006-2008, Greg M. Kurtzer, Arthur A. Stevens and 
# Infiscale, Inc. All rights reserved
#
# February 2010, Darin Perusich <darin.perusich@cognigencorp.com>
# Port to openSuSE/zypper
#

# set the SuSE name and version
#
#SUSE_NAME=`awk 'NR < 2 {print $1}' /etc/SuSE-release` 
#SUSE_VERSION=`awk '/^VERSION/ {print $3}' /etc/SuSE-release`
SUSE_NAME=openSUSE
SUSE_VERSION=11.2
export SUSE_VERSION SUSE_NAME

# Network installation sources
#
MIRROR=http://download.opensuse.org/distribution/11.2/repo/oss/

# For additions zypper repositories
#
REPOS=""

# Set the system arch
#
if [ -z "$ARCH" ]; then
   ARCH=`uname -m`
fi

if [ "x$ARCH" != "xx86_64" ]; then
   ARCH=i386
fi

# default VNFS image name
NAME="$SUSE_NAME-$SUSE_VERSION-1.$ARCH"

# temporary location to build the VNFS image
#
VNFSROOT=/var/tmp/vnfs

# usage
usage() {
printf "Usage: $0 [OPTION]... [pkg1 pkg2...pkg#]
Generate a Perceus VNFS root file system image.

  -h			This help message
  -f alt_pkg_file	File containing alternative base packages to install
  -m http://url		URL to the Mirror, default: $MIRROR
  -n image_name		Alternate name for the image, default: ${NAME}
  -r file.repo		Add zypper repository in addition to the default
  -v /var/tmp/vnfs	Alternate temporary location to build the image
  [pkg1 pkg2...pkg#]	Packages in addition to the base packages to be installed
"
}

# parse command-line args
while getopts "hf:m:n:r:v:" options
do
	case $options in
		h) usage; exit 0;;
		f) PKG_FILE=$OPTARG
			if [ ! -f $PKG_FILE ]; then
				printf "Alternative package installation file $PKG_FILE does not exist\n"
				exit 1
			fi
		;;
		m) MIRROR=$OPTARG;;
		n) NAME=$OPTARG;;
		r) REPOS=$OPTARG;;
		v) VNFSROOT=$OPTARG
			if [ ! -d $VNFSROOT ]; then
				printf "Directory $VNFSROOT does not exist\n"
				exit 1
			fi
		;;
		?) usage; exit 255;;
	esac
done
shift $(($OPTIND - 1))

# We need this so lets make sure it's set
#
if [ "x$MIRROR" = "x" ]; then
 printf "A network installation source is required for VNFS creation to continue!
Uncomment/set the value in this script, use to -m option of this script, or set the
environment variable MIRROR to continue!
For example: export MIRROR=http://download.opensuse.org/distribution/11.2/repo/oss/\n"
exit 1
fi

# Package required for a "usable" system
#
BASE_PKGS="ConsoleKit PolicyKit PolicyKit-doc aaa_base aria2 audit-libs augeas-lenses bash bash-doc bundle-lang-common-en bzip2 coreutils cpio cracklib cracklib-dict-full crda cron cyrus-sasl dbus-1 dbus-1-glib desktop-translations dhcpcd diffutils dirmngr e2fsprogs elfutils file filesystem fillup findutils gawk gdbm glib2 glib2-branding-openSUSE glibc gpg2 grep gzip hal info insserv iproute2 kernel-pae keyutils-libs klogd krb5 libacl libadns1 libasm1 libattr libaugeas0 libblkid1 libbz2-1 libcap2 libcom_err2 libcurl4 libdb-4_5 libdw1 libeggdbus-1-0 libelf1 libevent-1_4-2 libexpat1 libext2fs2 libgcc44 libgcrypt11 libgio-2_0-0 libglib-2_0-0 libgmodule-2_0-0 libgobject-2_0-0 libgpg-error0 libgssglue1 libgthread-2_0-0 libidn libksba libldap-2_4-2 libltdl7 liblua5_1 liblzma0 libncurses5 libnl libnscd libopenct1 libopensc2 libopenssl0_9_8 libpcre0 libpolkit0 libpopt0 libpth20 libreadline6 librpcsecgss libselinux1 libstdc++44 libtirpc1 libusb-0_1-4 libusb-1_0-0 libuuid1 libxcrypt libxml2 libzio libzypp licenses login logrotate mailx mingetty mkinitrd module-init-tools ncurses-utils net-tools netcfg nfs-client nfsidmap ntp openSUSE-release openSUSE-release-ftp openldap2-client openssh openssl openssl-certs pam pam-config pam-modules pciutils pciutils-ids pcre perl perl-Bootloader perl-base perl-doc perl-gettext permissions pinentry pm-utils polkit polkit-default-privs postfix procps psmisc pwdutils readline-doc rpcbind rpm rsyslog satsolver-tools sed setserial sudo sysconfig sysvinit tcpd terminfo-base timezone udev util-linux vim vim-base vim-data wireless-regdb xinetd zlib zypper"

# Override the default base packages
#
[ "x$PKG_FILE" != "x" ] && BASE_PKGS=`cat $PKG_FILE`

# check for existing capsule
#
if [ -d $VNFSROOT/$NAME ]; then
 printf "Existing capsule at $VNFSROOT/$NAME, remove or rename to continue\n"
 exit 1
fi

# 
printf "Building VNFS capsule in: $VNFSROOT/$NAME/\n"

mkdir -p $VNFSROOT/$NAME/etc/sysconfig
mkdir -p $VNFSROOT/$NAME/etc/zypp/
mkdir -p $VNFSROOT/$NAME/etc/zypp/repos.d
mkdir -p $VNFSROOT/$NAME/var/lib/rpm
mkdir -p $VNFSROOT/$NAME/var/log
mkdir -p $VNFSROOT/$NAME/var/lock/rpm
mkdir -p $VNFSROOT/$NAME$VNFSROOT
rm -f $VNFSROOT/$NAME$VNFSROOT/$NAME
ln -s / $VNFSROOT/$NAME$VNFSROOT/$NAME
rpm --initdb --dbpath $VNFSROOT/$NAME/var/lib/rpm

# primary zypper repository
#
cat <<EOF >$VNFSROOT/$NAME/etc/zypp/repos.d/vnfs-opensuse-oss.repo
[$SUSE_NAME-$SUSE_VERSION]
name=$SUSE_NAME-$SUSE_VERSION
baseurl=$MIRROR/
enabled=1
autorefresh=1
type=yast2
keeppackages=0
gpgcheck=0
EOF

# add addition zypper repositories
#
if [ "x$REPOS" != "x" ]; then
 if [ -f $REPOS ]; then
  zypper --root $VNFSROOT/$NAME addrepo -f -r $REPOS
 else
  printf "Repository file $REPOS does not exist, not adding additional repositories\n"
 fi
fi

# fstab and mtab
#
cat <<EOF >$VNFSROOT/$NAME/etc/fstab
# Don't touch the following macro unless you really know what your doing!
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
mknod $VNFSROOT/$NAME/dev/zero c 1 5		>/dev/null 2>&1

# install the system
#
zypper --non-interactive --no-gpg-checks --root $VNFSROOT/$NAME \
	install --auto-agree-with-licenses \
	$BASE_PKGS $*

# Make sure install was successful
#
RETVAL=$?
if [ $RETVAL != 0 ]; then
 printf "
Installation of the capsule was not successful! Review the above output
and see EXIT CODES in zypper(8) for details.
zypper exit code $RETVAL
"
exit 1
fi

# primary network interface
#
printf "Setting up eth0 for DHCP\n"
cat <<EOF >$VNFSROOT/$NAME/etc/sysconfig/network/ifcfg-eth0
BOOTPROTO='dhcp'
MTU=''
REMOTE_IPADDR=''
STARTMODE='auto'
USERCONTROL='no'
EOF

cp /etc/securetty	   $VNFSROOT/$NAME/etc/securetty
printf "ttyS0\n"	>> $VNFSROOT/$NAME/etc/securetty
printf "ttyS1\n"	>> $VNFSROOT/$NAME/etc/securetty
printf "127.0.0.1	localhost localhost.localdomain\n" \
			> $VNFSROOT/$NAME/etc/hosts

# set hostname via dhcp
#
printf "Setting DHCLIENT_SET_HOSTNAME="yes" in /etc/sysconfig/network/dhcp\n"

sed -i 's/DHCLIENT_SET_HOSTNAME="no"/DHCLIENT_SET_HOSTNAME="yes"/' \
		$VNFSROOT/$NAME/etc/sysconfig/network/dhcp

# disable NFSv4 or things fail
#
printf "Disabling NFSv4 Support, required to hybridize /usr\n"
sed -i 's/NFS4_SUPPORT="yes"/NFS4_SUPPORT="no"/' \
	$VNFSROOT/$NAME/etc/sysconfig/nfs

# so fsck isn't attempted on /
#
touch $VNFSROOT/$NAME/fastboot

# so rpc.statd doesn't start as root
#
[ -d $VNFSROOT/$NAME/var/lib/nfs/sm ] && chown nobody:nobody $VNFSROOT/$NAME/var/lib/nfs/sm

# enable services
#
for ii in syslog rpcbind network nfs sshd
do
printf "Enabling network service: $ii\n"
chroot $VNFSROOT/$NAME /sbin/insserv -f $ii
done

# clean up
#
chroot $VNFSROOT/$NAME umount /proc	>/dev/null 2>&1
rm -rf $VNFSROOT/$NAME/var/cache/zypp/*
rm -rf $VNFSROOT/$NAME/var/log/*

# set root password on the nodes
printf "
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!                                                                                 !
! Setting root password to 'perceus', it is strongly recommend that it be changed !
!                                                                                 !
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
"

echo root:perceus | chpasswd -c md5 -P $VNFSROOT/$NAME/etc

rm -f $VNFSROOT/$NAME/dev/log

printf " 
The chroot has been created at: $VNFSROOT/$NAME
Make any changes you want to it and then use 'chroot2*.sh' to create a
Perceus VNFS capsule. For example:

   # /usr/share/perceus/vnfs-scripts/chroot2stateless.sh $VNFSROOT/$NAME /root/$NAME.vnfs

"
exit 0
