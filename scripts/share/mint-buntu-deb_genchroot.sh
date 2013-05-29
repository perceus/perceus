#!/bin/bash
#
#########################################################
# This file created by Tim Copeland at
# Criterion Digital Copyright (c)
# with the hopes others will find this usefull
# and to help improve the project in general
#
# some code snipits contained within came
# by referencing and copying the works of
# Greg M. Kurtzer, Arthur A. Stevens and
# Infiscale, Inc. Copyright (c)
#
# There is no warranty of any kind implied or otherwise
#########################################################


	# do basic complience tests
#___________________________________________

# this script must be run as root
INSTALATION_USER=$( /usr/bin/whoami )

if [[ "${INSTALATION_USER}" != "root" ]]
then
	echo
	echo
	echo "This script MUST be run as root"
	echo
	echo
	exit 1
fi

CHROOT=$(which chroot)

if [[ -z "${CHROOT}" ]]
then
   echo "Could not find the program 'chroot'"
   exit 1
fi


	# setup our environment
#___________________________________________ 

MYNAME="Mint-Buntu-Deb vnfs Master Generator"
VERSION="0.6.2"
REVISIONDATE="02-1-2012"
URL="none currently"

HOSTMATCH=$(uname -m)
DIRNAME=$(dirname $0)

VNFSROOT="/var/tmp/vnfs"

##############################
# DISTRO BASE PACKS AND REPOS

DEBLINIMAGE="linux-image"
DEBIANCOMOPONENTS="main,contrib,non-free"
DEBIANINCLUDES="openssh-server,openssh-client,isc-dhcp-client,pciutils,strace,nfs-common,ethtool,iproute,iputils-ping,iputils-arping,net-tools,firmware-bnx2,ifupdown,rsync"

UBUNTUCOMOPONENTS="main,restricted,universe"
UBUNTUINCLUDES="ssh,isc-dhcp-client,pciutils,strace,nfs-common,nfs-kernel-server,ethtool,iproute,iputils-ping,iputils-arping,net-tools,linux-image-server,rsync"

FULLINSTALL="nfs-kernel-server,libpcre3,less,libpopt0,tcpd,rsync,update-inetd,libpam-cracklib,iputils-tracepath,rsh-client,wamerican,vim-tiny,cron,gawk,mingetty,psmisc,rdate,rsh-redone-server,rsyslog,dracut,ntp"

VARIANT="minbase"
VALIDDEBARCH='armel kfreebsd-i386 kfreebsd-amd64 ia64 mips mipsel powerpc sparc'

##############################


BOOTSTRAPINCLUDES=""
QEMUFILENAME=""
NEWHOSTNAME=""
OPTIONSFILE=""
RELEASEVER=""
COMPONENTS=""
FINDQEMU=""
CONTINUE=""
CODENAME=""
NEWREPOS=""
MINIMAL=""
FOREIGN=""
DISTRO=""
REPOS=""
ARCH=""

warn_msg () {
	case "${1}" in

		abort)
			echo
			echo "vnfs creation has been aborted .. fix errors and run this script again"
			echo
			;;

		wrongarch)
			echo
			echo "The distro you have requested does not support ${ARCH} architecture"
			echo
			;;

		uncharted)
			echo
			echo "It apears the host machine's architecture or the architecture you are requesting to install"
			echo "has has little or no testing with this installer. We will try to meet this request, but if it"
			echo "fails, you can first try setting a custom package list in an options file. Look here for info."
			echo "	sudo ./mint-buntu-deb_genchroot.sh --optionfile-help"
			echo
			echo "If all else fails, you are welcome to edit the code to meet your needs. It should take very"
			echo "little work to make this compatible with all debian supported architectures"
			;;

		noncomply)
			echo
			echo "Error: Failed Hardware Compliance"
			echo "You are trying to build a vnfs for an architecture that appears different from this machine"
			;;

		hw-missmatch)
			echo "Failed to determine local environment"
			echo "Make sure the requested architecture is correct"
			echo "or make sure uname is installed and in PATH"
			echo
			;;

		need_qemu)
			echo
			echo "In order to create a vnfs for non-native architecture the correct version of static"
			echo 'QEMU, such as "qemu-user-static" need to be installed on this host machine'
			echo
			echo "This package can be automatically installed from your repository"
			echo
			;;

		nofile)
			echo
			echo "unable to locate options file ${OPTIONSFILE}"
			echo
			;;

		noqemu_pack)
			echo
			echo 'Error: Failed to find the required package "qemu-user-static or qemu-kvm-extras-static"'
			echo "Install the correct static package of QEMU for your target architecture and run this again"
			echo
			;;

		foreign)
			echo
			echo "debootstrap's --foreign flag is now set making debootstrap a 2 stage install"
			echo
			;;

		missing_qemu)
			echo
			echo "The correct static qemu file required to finish stage 2 can not be found"
			echo "please install the correct ${FOREIGN}. If that is not the correct file"
			echo "name, and you know the correct qemu is installed, set the correct name"
			echo "in an options file and run this script again."
			;;

		stage2)
			echo " Stage 1 debootstrap"
			echo
			echo " Stage 2 debootstrap"
			echo
			;;

		qemu_mayfail)
			echo
			echo "You appear to be trying to create a 64 bit vnfs on a 32 bit OS."
			echo "Though this may be possible with QEMU, it is likely to fail."
			echo "It wont hurt any thing to try, but success is doubtful."
			echo
			;;
	esac

}


# the command line commands passed in
arg_set () {
	case "${1}" in

	# distro info
	#__________________
		-M|--mint)
			ARCH="${2}"
			DISTRO="mint"
			COMPONENTS="${UBUNTUCOMOPONENTS}"
			REPOS='http://archive.ubuntu.com/ubuntu'
#			REPOS=' http://packages.linuxmint.com'
			;;

		-U|--ubuntu)
			ARCH="${2}"
			DISTRO="ubuntu"
			COMPONENTS="${UBUNTUCOMOPONENTS}"
			REPOS='http://archive.ubuntu.com/ubuntu'
			;;

		-D|--debian)
			ARCH="${2}"
			DISTRO="debian"
			COMPONENTS="${DEBIANCOMOPONENTS}"
			REPOS='http://ftp.us.debian.org/debian'
			;;

		-f|--file)
			OPTIONSFILE="${2}"
			;;

		-m|--minimal)
			MINIMAL="true"
			;;

		-n|--host-name)
			NEWHOSTNAME="${2}"
			;;

		-R|--repos)
			NEWREPOS="${2}"
			;;

		-c|--codename)
			CODENAME="${2}"
			;;

		-r|--release)
			RELEASEVER="${2}"
			;;

	# standard info
	#__________________
		--create-template)
			echo
			create_template ;
			echo "genchroot-options.template created"
			exit 0
			;;

		-h|--help)
			echo
			print_help ;
			echo
			print_full_help ;
			exit 0
			;;

		-o|--optionfile-help)
			echo
			print_options_help ;
			exit 0
			;;

		-s|--show)
			echo
			print_package_info ;
			echo
			exit 0
			;;

		*)
			echo
			echo "***	---	***	---	***"
			echo 	"Error: ${1} is an invalid option."
			echo "***	---	***	---	***"
			print_help ;
			exit 1
			;;

	esac
}

arch_request () {
	if [[ ${ARCH} =~ ^(i386|i586|i686) ]]
	then
		ARCH="i386"
		PACKNAME="i386"
		QEMUARCH="i386"
		DEBLINIMAGE="${DEBLINIMAGE}-686"

	elif [[ ${ARCH} =~ ^(x86_64|amd64) ]]
	then
		ARCH="amd64"
		PACKNAME="amd64"
		QEMUARCH="x86_64"
		DEBLINIMAGE="${DEBLINIMAGE}-amd64"
	else
		if [[ "${DISTRO}" != "debian" ]]
		then
			warn_msg wrongarch ;
			exit 1
		else
			# should do some check to make sure is in
			# debian's list of valid arch's
			CONTINUE=""
			for i in ${VALIDDEBARCH}
			do
				if [[ "${i}" == "${ARCH}" ]]
				then
					CONTINUE="${i}"
				fi
			done

			if [[ -n ${CONTINUE} ]]
			then
				ARCH="${CONTINUE}"
				PACKNAME="${CONTINUE}"
				QEMUARCH="${CONTINUE}"
				warn_msg uncharted ;
			else
				warn_msg wrongarch ;
				exit 1
			fi				
		fi
	fi
}


match_host_hw () {

	if [[ -n ${HOSTMATCH} ]]
	then
		if [[ ${HOSTMATCH} =~ ^(i386|i586|i686) ]]
		then
			HOSTMATCH="i386"
		fi

		if [[ "${HOSTMATCH}" != "${QEMUARCH}" ]]
		then
			cross_hardware ;
			FOREIGN="--foreign"
			warn_msg foreign ;
		fi
	else
		warn_msg hw-missmatch ;
		exit 1
	fi
}


cross_hardware () {

	FINDQEMU=$(ls /usr/bin/qemu*)

	if [[ -z ${FINDQEMU} ]]
	then
		warn_msg need_qemu ;

		#--------
		if [[ "${HOSTMATCH}" == "i386" ]] && [[ "${QEMUARCH}" == "x86_64" ]]
		then
			warn_msg qemu_mayfail ;
		fi

		echo "Should We Auto-Install QEMU and Continue With vnfs Creation ? "
		read -p "Install and continue .. (Y/n) ? " CONTINUE

		#--------

		if [[ -z ${CONTINUE} ]] || [[ "${CONTINUE}" == "Y" ]] || [[ "${CONTINUE}" == "y" ]]
		then
			if apt-cache search qemu-user-static
			then
				apt-get install binfmt-support qemu qemu-user-static ;

			elif apt-cache search qemu-kvm-extras-static
			then
				apt-get install binfmt-support qemu qemu-kvm-extras-static ;

			else
				warn_msg noqemu_pack ;
				exit 1
			fi

		else
			warn_msg abort ;
			exit 1
		fi
	fi
}




abort_install () {

	warn_msg abort ;
	exit 1
}


##========================================================================
##			--== * MAIN * ==--				##
##========================================================================

do_main () {
	local this_cmd=""
	local this_arg=""

	if [[ ! ${1} ]] 
	then
		print_help ;
		exit 1
	fi

	while [[ ${1} ]] 
	do
		this_cmd=${1}
		this_arg=""
		shift

		# make sure the next element has a value
		if [[ -n ${1} ]] 
		then
			# then if first char of ${1} is not "-"
			# then it is our arg and not the next
			# command so assign it to this_arg
			if [[ ! ${1} =~ ^\- ]] 
			then
				this_arg="${1}"
				shift
			fi
		fi

		arg_set ${this_cmd} ${this_arg} ;
	done


	for i in "${DISTRO}" "${RELEASEVER}" "${ARCH}" "${CODENAME}" "${VNFSROOT}"
	do
		if [[ -z ${i} ]]
		then
			echo
			echo "Incomplete Options"
			echo
			print_help ;
			warn_msg abort ;
			exit 1
		fi
	done

	# this command line option overrides the default repostitories
	if [[ -n ${NEWREPOS} ]]
	then
		REPOS="${NEWREPOS}"
	fi


	# final compatability tests
  #___________________________________________________

	arch_request ;
	match_host_hw ;


	# establish the new system
  #___________________________________________________

	NAME="${DISTRO}-${RELEASEVER}-1.${ARCH}"

	echo "Building in: $VNFSROOT/$NAME/"
	mkdir -p $VNFSROOT/$NAME
	if [[ "${DISTRO}" == "debian" ]]
	then
		BOOTSTRAPINCLUDES="${DEBIANINCLUDES},${DEBLINIMAGE}"
	else
		BOOTSTRAPINCLUDES="${UBUNTUINCLUDES}"
	fi

	if [[ -z ${MINIMAL} ]]
	then
		BOOTSTRAPINCLUDES="${BOOTSTRAPINCLUDES},${FULLINSTALL}"
	fi

	if [[ -n ${OPTIONSFILE} ]]
	then
		if [[ -e ${OPTIONSFILE} ]]
		then
			source ${OPTIONSFILE} ;
		else
			print_help ;
			warn_msg nofile	;
			exit 1		
		fi
	fi

	if [[ -n ${VARIANT} ]]
	then
		VARIANT="--variant=${VARIANT}"
	fi

	if [[ -n ${BOOTSTRAPINCLUDES} ]]
	then
		BOOTSTRAPINCLUDES="--include=${BOOTSTRAPINCLUDES}"
	fi

#################
#################
	debootstrap ${FOREIGN} --arch=${ARCH} --components=${COMPONENTS} ${VARIANT} \
				${BOOTSTRAPINCLUDES} ${CODENAME} ${VNFSROOT}/${NAME} ${REPOS} || abort_install;

	if [[ -n ${FOREIGN} ]]
	then
		if [[ -n ${QEMUFILENAME} ]]
		then
			FOREIGN="/usr/bin/${QEMUFILENAME}"
		else
			FOREIGN="/usr/bin/qemu-${QEMUARCH}-static"
		fi

		if [[ -e ${FOREIGN} ]]
		then
			# do second stage debootstrap install
			warn_msg stage2 ;
			cp ${FOREIGN} ${VNFSROOT}/${NAME}/usr/bin/  
			$CHROOT $VNFSROOT/$NAME /debootstrap/debootstrap --second-stage || abort_install;
		else
			warn_msg missing_qemu ;
			exit 1
		fi
	fi
#################
#################


	# START CONFIGURING THIS VNFS
  #___________________________________________________
	if [[ -n ${NEWHOSTNAME} ]]
	then
		echo "${NEWHOSTNAME}" > $VNFSROOT/$NAME/etc/hostname
	fi


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

	echo "auto lo"			> $VNFSROOT/$NAME/etc/network/interfaces
	echo "iface lo inet loopback"	>> $VNFSROOT/$NAME/etc/network/interfaces
	echo "auto eth0"			>> $VNFSROOT/$NAME/etc/network/interfaces
	echo "iface eth0 inet dhcp"	>> $VNFSROOT/$NAME/etc/network/interfaces

	# clear out any rules that may have been created by the host system
	echo "# Automatically generated by udev" > $VNFSROOT/$NAME/etc/udev/rules.d/70-persistent-net.rules
	echo " " > $VNFSROOT/$NAME/etc/udev/rules.d/70-persistent-net.rules

	cp /etc/securetty	   $VNFSROOT/$NAME/etc/securetty
	echo "ttyS0"		>> $VNFSROOT/$NAME/etc/securetty
	echo "ttyS1"		>> $VNFSROOT/$NAME/etc/securetty
	echo "127.0.0.1		localhost localhost.localdomain" \
				> $VNFSROOT/$NAME/etc/hosts
	echo "s0:2345:respawn:/sbin/agetty -L 115200 ttyS0 vt100" \
				>> $VNFSROOT/$NAME/etc/inittab
	echo "s1:2345:respawn:/sbin/agetty -L 115200 ttyS1 vt100" \
				>> $VNFSROOT/$NAME/etc/inittab

	if [[ -x "$VNFSROOT/$NAME/usr/sbin/pwconv" ]]
	then
	   $CHROOT $VNFSROOT/$NAME /usr/sbin/pwconv >/dev/null 2>&1||:
	fi
	if [[ -x "$VNFSROOT/$NAME/usr/sbin/update-rc.d" ]]
	then
	   $CHROOT $VNFSROOT/$NAME /usr/sbin/update-rc.d xinetd defaults >/dev/null 2>&1
	fi

	sed -i -e 's/# End of file//' $VNFSROOT/$NAME/etc/security/limits.conf
	if ! grep -q "^* soft memlock " $VNFSROOT/$NAME/etc/security/limits.conf
	then
	   echo "* soft memlock 8388608 # 8 GB" >> $VNFSROOT/$NAME/etc/security/limits.conf
	fi
	if ! grep -q "^* hard memlock " $VNFSROOT/$NAME/etc/security/limits.conf
	then
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

	echo "Generate Random SSH Host Keys"
	/usr/bin/ssh-keygen -q -t rsa1 -f $VNFSROOT/$NAME/etc/ssh/ssh_host_key -C '' -N ''
	/usr/bin/ssh-keygen -q -t rsa -f $VNFSROOT/$NAME/etc/ssh/ssh_host_rsa_key -C '' -N ''
	/usr/bin/ssh-keygen -q -t dsa -f $VNFSROOT/$NAME/etc/ssh/ssh_host_dsa_key -C '' -N ''

	# add broken_shadow to pam.d/system-auth
	if [[ -f "$VNFSROOT/$NAME/etc/pam.d/system-auth" ]]
	then 
	    sed -e '/^account.*pam_unix\.so$/s/$/\ broken_shadow/' $VNFSROOT/$NAME/etc/pam.d/system-auth 
	fi 
	 
	if [[ -f "$VNFSROOT/$NAME/etc/pam.d/password-auth" ]]
	then 
	    sed -e '/^account.*pam_unix\.so$/s/$/\ broken_shadow/' $VNFSROOT/$NAME/etc/pam.d/password-auth 
	fi

	# add system root password to the nodes
	umask 277               # to prevent user readable files
	sed -e s/root::/root:!!:/ < $VNFSROOT/$NAME/etc/shadow > $VNFSROOT/$NAME/etc/shadow.new
	cp $VNFSROOT/$NAME/etc/shadow.new $VNFSROOT/$NAME/etc/shadow
	rm $VNFSROOT/$NAME/etc/shadow.new
	umask 0022              # set umask back to default

	# trim out the excess by moving them out of this capsule
	# we will keep them for reference for adding and removing
	# packages to this capsule with the mbd-packs-mgr.sh
	# first cleanup any old works
	rm -fr $VNFSROOT/$NAME.archives

	mkdir $VNFSROOT/$NAME.archives
	mv $VNFSROOT/$NAME/var/cache/apt $VNFSROOT/$NAME.archives

	if [[ -e "$VNFSROOT/$NAME/dev/log" ]]
	then
		mkdir $VNFSROOT/$NAME.archives/dev
		mv $VNFSROOT/$NAME/dev/log $VNFSROOT/$NAME.archives/dev/
	fi

	#########################################
}


# =========================================
# _____________________________________________________

print_help () {
cat <<EOF
		__________________________________________________

			$MYNAME : $VERSION
			Website : $URL			

			To view the help documentation type:

			sudo ./mint-buntu-deb_genchroot.sh --help

			sudo ./mint-buntu-deb_genchroot.sh --optionfile-help
    =============================================================================
EOF
}

# Prints to screen complete help
print_full_help () {
cat <<EOF

	This is designed to create vnfs frameworks for a wide range of distros and
	hardware. No matter what bash capable distro or hardware architecture of the
	host machine.
 
		ie. create a 32 bit vnfs on a 64 bit machine

	Building a 64 bit vnfs on a 32 operating system is likely to fail.


	Support is built in to allow for all debian supported architectures to
	be built on any machine. However, this is experimental and mostly untested.
	Individule experiences could vary greatly. See Experimental architectures below.

        Valid architectures are:
            x86_64 (defaults to amd64)
            amd64
            i386

        Experimental architectures are:
            armel
            kfreebsd-i386
            kfreebsd-amd64
            ia64 mips
            mipsel
            powerpc
            sparc

	To keep the vnfs as small as possible, the package archives have been moved out
	of the vnfs to a directory of the same name ending in .archive. This is used by
	the mbd-packs-mgr.sh script to add/remove packages from within the given vnfs making
	future maintanance and upgrading more efficient while keeping the capsule size small.

	To date these are the current releases.
	Any future releases not listed below should also be supported.

	RELEASE NUMBERS-CODE NAMES:

        Ubuntu: 9.10-Karmic , 10.04-lucid , 10.10-maverick , 11.04-natty , 11.10-oneiric , 12.04-precise

        Debian: 3.1-sarge , 4.0-etch , 5.0-lenny , 6.0-squeeze , 7.0-wheezy , sid 

          Mint: 9-Isadora , 10-Julia , 11-Katya , 12-Lisa


	TROUBLESHOOTING:

		Building a 64 bit vnfs on a 32 operating system is likely to fail. Theoretically, QEMU should
        allow the creation of 64 bit vnfs on a 32 bit OS. This may or may not be possible with a CPU
        that supports virtualization, which must also be turned on in BIOS. 

        After vnfs creation, it is posible to add additional packages in the chroot environment.

        There are times when building a vnfs for a distro different from the host machine,
        the system will fail to find the correct debootsrap build file. Many times the files
        in question are simply just links to a standard file. For instance, when trying to build
        an Ubuntu vnfs on a native Debian system, you may encounter an error as such :
			No such script: /usr/share/debootstrap/scripts/oneiric

        To remedy this, you can use option "QEMUFILENAME=" in an options file or simply create the
        required link. In this instance, the script to debootstrap an Ubuntu oneiric system is the
        same script used for the Debian gutsy release.
			sudo ln -s -T /usr/share/debootstrap/scripts/gutsy /usr/share/debootstrap/scripts/oneiric

        Errors like the following are caused by matching distro to incorrect codenames.
        This error was created by setting the distro to Debian and trying to use an
        Ubuntu codename. Debian servers do not have Ubuntu repos.
			Failed getting release file http://ftp.us.debian.org/debian/dists/oneiric/Release

        Ubuntu is at the core of Linux Mint. Even though the Mint option is available, the Ubuntu
        repositories will be used for debootstrap by default. The naming convention is all that is gained
        here. However, by using the --repos and --file options together will allow you to build most any
        disto/package combination you need.

        Since the repos are from Ubuntu, the correct code name must be used. Building a 32 bit vnfs for
        Mint12 would look like this.

			sudo ./mint-buntu-deb_genchroot.sh -M i386 -c oneiric -r 12

	Examples:
        To create a 32 bit Ubuntu vnfs from the standard repository:
			sudo ./mint-buntu-deb_genchroot.sh -U i386 -c oneiric -r 11.10

        To create an amd compatibla 64 bit debian vnfs from the standard
        repository with a custom list of packages:
			sudo ./mint-buntu-deb_genchroot.sh -D x86_64 -c squeeze -r 6.0 -f genchroot-options.template

	___________________________________________________________________________________________
	___________________________________________________________________________________________
	
        -M  --mint)           Sets the distro to LinuxMint. Takes an architecture as an argument

        -U  --ubuntu)         Sets the distro to Ubuntu. Takes an architecture as an argument

        -D  --debian)         Sets the distro to Debian. Takes an architecture as an argument

        -R  --repos)          (Optional) Change the default repository.
                              The default repositories are:
                                 Mint/Ubuntu
                                     'http://archive.ubuntu.com/ubuntu'
                                 Debian
                                     'http://ftp.us.debian.org/debian'

        -c  --codename)       Choose the code name designation for this distro.

        --create-template)    This will create an example options file in the same directory as
                              this script. 

        -f  --file)           Path to a file for additional options like source and packages

        -h  --help)           Display this help message

        -m|--minimal)         Install only the minimal system Aprox: 200M. Use option --show to see package lists

        -n|--host-name)       Change the host name of the nodes ( default is <distro>-node )

        -o|--optionfile-help) Display help about an the additional options file

        -r  --release)        Designated distro version number 

        -s  --show)           Display all default sources and packages



EOF
}

print_package_info () {
cat <<EOF

VARIANT="minbase"
______________________________________________________________________
Minimal packages to be installed.

Ubuntu:
    COMPONENTS="main,restricted,universe"

    BOOTSTRAPINCLUDES="${UBUNTUINCLUDES}"


Debian:
    COMPONENTS="main,contrib,non-free"

    BOOTSTRAPINCLUDES="${DEBIANINCLUDES},linux-image-[ARCH]"

#	[ARCH] = depends on the architechture requested at build time
______________________________________________________________________

Additional packages for a full default install.
Using the --minimal option will ommit these from the install:

    ${FULLINSTALL}


EOF
}

print_options_help () {
cat <<EOF
	It's recommended to name this file to correspond with the name
	of the vnfs it is related to. The option file is used to pass
	in custom package lists along with setting various other values
	like debootstrap variants, node host names, etc..
	___________________________________________________________

	The following command will create an example template file
	in the same directory as this script. It will be named
	example-options.template

		sudo ./mint-buntu-deb_genchroot.sh --create-template	

	___________________________________________________________

EOF
}

create_template () {
cat <<'EOF' >genchroot-options.template
# This file is an example file created by mint-buntu-deb_genchroot.sh.
# There are 2 ways to include values with this file. You can either
# include additional packages to the default install, or you can
# override the defaults using one or both options.
#
# To see a list of all default values
#	sudo ./mint-buntu-deb_genchroot.sh --show
#
# Lines starting with # are comments
#_________________________________________________________________________
# This format will add these values to the defaults

#    COMPONENTS="${COMPONENTS},source1,source-2,source_3"
#    BOOTSTRAPINCLUDES="${BOOTSTRAPINCLUDES},package1 package-2 package_3"

#_________________________________________________________________________
# This format will override the defaults and only use these values
# Is usefull for when needing specific package versions such as kernel's etc .. 

#    COMPONENTS="source1,source-2,source_3"
#    BOOTSTRAPINCLUDES="package1 package-2 package_3"
#    VARIANT="minbase"
#    NEWHOSTNAME="Deb-Nodes"
#    QEMUFILENAME="qemu-arm-static"

EOF
}

##---------

do_main $@

##---------
echo "Be sure to check the output in case of possible errors"
echo "otherwise"
echo "The chroot has been created at: ${VNFSROOT}/${NAME}"
echo "Make any changes you want to it and then use 'chroot2*.sh' to create a"
echo "Perceus VNFS capsule. For example:"
echo
echo "   # sudo ${DIRNAME}/chroot2stateless.sh ${VNFSROOT}/${NAME} /root/${DISTRO}-${RELEASEVER}-1.stateless.${ARCH}.vnfs"
##---------------------------------------------------------------------
##---------------------------------------------------------------------

exit 0
