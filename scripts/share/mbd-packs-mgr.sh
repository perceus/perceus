#!/bin/bash
#
#########################################################
# This file created by Tim Copeland at
# Criterion Digital Copyright (c)
# with the hopes others will find this usefull
# and to help improve the project in general
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

MYNAME="Mint-Buntu-Deb vnfs Package Manager"
VERSION="0.2"
REVISIONDATE="01-06-2012"
URL="none currently"

DIRNAME=$(dirname $0)
VNFSROOT="/var/tmp/vnfs"
PERCEUS=$(which perceus)

#=======================
# remove special meaning
# and stringify keywords

MOUNT="mount"
UMOUNT="umount"
INSTALL="install"
#=======================

ROOTEDSCRIPT=""
CAPSULEMOUNT=""
OPTIONSFILE=""
DELETEORIG=""
DONESHELL=""
MOREPACKS=""
ARCHIVES=""
CONTINUE=""
INSTALLS=""
LOOPSTOP=""
LOOPING=""
CAPSULE=""
REMOVES=""
BACKUP=""
SAYYES=""

warn_msg () {
	case "${1}" in

		abort)
			echo
			echo "package installation has been aborted .. fix errors and run this script again"
			echo
			;;

		backup)
			echo
			echo "============================================================================"
			echo "Having a backup copy of this vnfs can be useful in case"
			echo "something goes wrong with the intended changes. You can"
			echo "choose to make a backup at this time. Do keep in mind, this"
			echo "can take a while before continuing with the requested tasks."
			echo
			;;

		cancel)
			echo
			echo "============================================================================"
			echo "Forced vnfs capsule ${CAPSULE} to be closed"
			echo "All changes made to this vnfs are still intact."
			echo "It will simply be force closed and not re-compressed"
			echo "re-mounting will allow you to pickup where you left off"
			echo "If the backup was successful, a cloned copy of the unchanged"
			echo "original was backed up and can be found as ${CAPSULE}.back"
			;;

		cancel-nb)
			echo
			echo "============================================================================"
			echo "Forced vnfs capsule ${CAPSULE} to be closed"
			echo "It will simply be force closed and not re-compressed"
			echo "re-mounting will allow you to pickup where you left off"
			echo
			;;

		completed_with)
			echo
			echo "============================================================================"
			echo "Modifications appear succesfull. If backup succeeded, a cloned copy of"
			echo "the unmodified original was backed up and can be found as ${CAPSULE}.back"
			;;

		completed_without)
			echo
			echo "============================================================================"
			echo "Modifications appear succesfull"
			echo "The origianl vnfs ${CAPSULE} was modified. No backup created"
			;;

		error)
			echo
			echo "ERROR: Replacing the backup failed"
			;;

		existing)
			echo
			echo "Backup ${CAPSULE}.back already exists"
			echo "Should we replace it with a new backup?"
			;;

		failed)
			echo
			echo "==================================="
			echo "ERROR: Catastrophic Failure ..!"
			echo "Something has gone seriously wrong"
			;;

		failure)
			echo "FAILED: Either backup still exists or"
			echo "perceus is not responding to commands"
			;;

		finalize)
			echo
			echo "============================================================================"
			echo "Finalizing changes and recompressing vnfs"
			echo "This can take a while"
			;;

		gone)
			echo 
			echo "Previous backup was deleted ..!"
			echo "NO NEW BACKUP CREATED ..!"
			;;

		incomplete)
			echo
			echo "Incomplete Options"
			echo
			;;

		morepacks)
			echo
			echo "============================================================================"
			echo "All operations have been completed"
			echo "You had requested additional command line support"
			echo "Dropping into a shell for you to work in"
			echo
			;;

		nofile)
			echo
			echo "unable to locate options file ${OPTIONSFILE}"
			echo
			;;

		nomount)
			echo
			echo "unable to mount vnfs capsule ${CAPSULE}"
			echo
			;;

		noscript)
			echo "============================================================================"
			echo '	ERROR: Failed to run scriptlet. Clues may be found in ^ previous error ^ .. '
			echo "	Otherwise we may have been unable to locate mbd-packs-scriptlet.sh that"
			echo "	should be in our chroot environment, or not able to reach the servers."
			echo "	Either way dropping into a shell"
			echo
			;;

		shell)
			echo "NEW SHELL"
			echo "============================================================================"
			echo "		This shell is from within the CHROOT environment inside the nvfs capsule"
			echo "				${CAPSULE}"
			echo '		After finished with command line options, type the word "exit"'
			echo "		to exit command shell and continue with mbd-packs-mgr automation."
			echo
			;;

		shellopt)
			echo
			echo "======================================================="
			echo "Leaving command shell."
			echo "	yes ) If succesfully completed your"
			echo "		tasks and would like to continue."
			echo
			echo "	no ) Will exit leaving the vnfs in its current state"
			echo
			;;

		shellrun)
			echo "This apears to be a run away shell"
			echo "Something has gone horribly wrong for"
			echo "you to be seeing this message."
			echo " Exiting Program"
			;;

		success)
			echo
			echo "====================================================="
			echo "       All Management Tasks Appear Successful"
			;;

		unmount)
			echo
			echo "============================================================================"
			echo "unable to unmount vnfs capsule ${CAPSULE}"
			echo "All package removal/installation appears to have completed."
			echo "However, the vnfs is still mounted and has not been repackaged"
			echo "Suggest unmounting manually with the following command."
			echo
			echo "	sudo ${PERCEUS} vnfs umount ${CAPSULE}"
			echo
			;;

	esac
}



# the command line options passed in
arg_set () {
	case "${1}" in

		-b|--backup)
			BACKUP="true"
			;;

		-c|--capsule)
			CAPSULE="${2}"
			CAPSULEMOUNT="/mnt/${CAPSULE}"
			;;

		--create-template)
			echo
			create_template ;
			echo "example-options.template created"
			exit 0
			;;

		-f|--file)
			OPTIONSFILE="${2}"
			;;

		-d|--delete-orig)
			DELETEORIG="true"
			;;

		-h|--help)
			echo
			print_help ;
			echo
			print_full_help ;
			exit 0
			;;

		-i|--install)
			shift
			while [[ ${1} ]] 
			do
				INSTALLS="${INSTALLS} ${1}"
				shift
			done
			;;

		-m|--more-packages)
			MOREPACKS="true"
			;;

		-o|--optionfile-help)
			echo
			print_options_help ;
			exit 0
			;;

		-r|--remove)
			shift
			while [[ ${1} ]] 
			do
				REMOVES="${REMOVES} ${1}"
				shift
			done
			;;

		-y)
			SAYYES="--assume-yes"
			;;

		*)
			echo
			echo "***	---	***	---	***"
			echo 	"Error: ${1}is an invalid option."
			echo "***	---	***	---	***"
			print_help
			exit 1
			;;

	esac
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
			# then if first char of ${1}is not "-"
			# then it is our arg and not the next
			# command so assign it to this_arg
			while [[ -n ${1} ]] && [[ ! ${1} =~ ^\- ]] 
			do
				this_arg="${this_arg} ${1}"
				shift
			done
		fi

		arg_set ${this_cmd} ${this_arg} ;
	done


		# make sure we have required options
	#______________________________________________

	if [[ -z ${CAPSULE} ]]
	then
		print_help ;
		warn_msg incomplete ;
		warn_msg abort ;
		exit 1
	fi

	if [[ -n ${OPTIONSFILE} ]]
	then
		if [[ -e ${OPTIONSFILE} ]]
		then
			source ${OPTIONSFILE} ;

			REMOVES="${REMOVES} ${REMOVE}"
			INSTALLS="${INSTALLS} ${INSTALL}"
		else
			print_help ;
			warn_msg nofile	;
			exit 1		
		fi
	fi

	if [[ -z ${INSTALLS} ]] && [[ -z ${REMOVES} ]] && [[ -z ${MOREPACKS} ]]
	then
		print_help ;
		warn_msg incomplete ;
		warn_msg abort ;
		exit 1
	fi

	

		# now that we have all command line options
	#___________________________________________

	prompt_n_backup ;

	if [[ ${CAPSULE} =~ \.stateless ]]
	then
		ARCHIVES=${CAPSULE/\.stateless/}

	elif [[ ${CAPSULE} =~ \.stateful ]]
	then
		ARCHIVES=${CAPSULE/\.stateful/}
	else
		ARCHIVES=${CAPSULE}
	fi

	ARCHIVES="${VNFSROOT}/${ARCHIVES}.archives/apt"

	# mount the vnfs capsule
	if ! ${PERCEUS} vnfs ${MOUNT} ${CAPSULE}
	then
		print_help ;
		warn_msg nomount ;
		warn_msg abort ;
		exit 1
	else
		# look for archive file created by mint-buntu-deb.sh
		# and include them long enough to work with packages.
		if [[ -e ${ARCHIVES} ]]
		then
			mv ${ARCHIVES} ${CAPSULEMOUNT}/var/cache ;
		fi

		# create our chrooted script
		chroot_script ;

		# make it so
		if ! ${CHROOT} ${CAPSULEMOUNT} ./mbd-packs-scriptlet.sh
		then
			warn_msg noscript ;
			do_shell ;
		fi

		if [[ -z ${DONESHELL} ]] && [[ "${MOREPACKS}" == "true" ]]
		then
			warn_msg morepacks ;
			do_shell ;
		fi

		# if we got this far all must have finished correctly
		# unmount the vnfs capsule
		warn_msg finalize ;
		clean_up ;

		if ${PERCEUS} vnfs ${UMOUNT} ${CAPSULE}
		then
			warn_msg success ;
		else
			print_help ;
			warn_msg unmount ;
			warn_msg abort ;
			exit 1
		fi
	fi
}


########################################################################################


clean_up () {
		# now clean up behind us to prepare for repack
		if [[ -e ${CAPSULEMOUNT}/var/cache/apt/archives ]]
		then
			mv ${CAPSULEMOUNT}/var/cache/apt ${ARCHIVES} ;
		fi

		rm -f ${ROOTEDSCRIPT} ;
}


call_abort () {
	# abort all work, force close vnfs
	if [[ "${BACKUP}" == "true" ]]
	then
		warn_msg cancel ;
	else
		warn_msg cancel-nb ;
	fi

	clean_up ;
	${PERCEUS} vnfs close ${CAPSULE} ;
	warn_msg abort ;

	# after all cleanup has been done
	exit 1
}

prompt_n_backup () {

	LOOPING="true"
	LOOPSTOP=10

	if [[ -z ${BACKUP} ]]
	then
		warn_msg backup ;

		while [[ "${LOOPING}" == "true" ]] && [[ ${LOOPSTOP} > 0 ]]
		do
			LOOPSTOP=$(( ${LOOPSTOP} - 1 ))

			read -p "Would you like a cloned copy of this vnfs as a backup? (yes/no): " CONTINUE

			if [[ "${CONTINUE}" == "yes" ]]
			then
				LOOPING="continue"
				BACKUP="true"
			elif [[ "${CONTINUE}" == "no" ]]
			then
				LOOPING="abort"
				echo "NO BACKUP MADE"
			fi
		done
	fi

	if [[ "${BACKUP}" == "true" ]]
	then
		# check if one already exists
		if [[ "${CAPSULE}.back" == "$( ${PERCEUS} vnfs list ${CAPSULE}.back )" ]]
		then
			warn_msg existing;

			# if so lets delete it
			if ${PERCEUS} vnfs delete ${CAPSULE}.back
			then
				# make sure user did choose delete
				# and check if it has been deleted
				if [[ "${CAPSULE}.back" == "$( ${PERCEUS} vnfs list ${CAPSULE}.back )" ]]
				then
					warn_msg error ;
				else
					CONTINUE="success"
				fi
			else
				warn_msg failed ;
			fi
		fi

		if ${PERCEUS} vnfs clone ${CAPSULE} ${CAPSULE}.back
		then
			echo "Created Backup ${CAPSULE}.back"

		else
			if [[ "${CONTINUE}" == "success" ]]
			then
				warn_msg failed ;
				warn_msg gone ;
			else
				warn_msg failure ;
				call_abort ;
			fi
		fi
	fi
}

close_shell () {

	LOOPING="true"
	LOOPSTOP=10

	warn_msg shellopt ;

	while [[ "${LOOPING}" == "true" ]] && [[ ${LOOPSTOP} > 0 ]]
	do
		LOOPSTOP=$(( ${LOOPSTOP} - 1 ))

		read -p "Should we continue (yes/no): " CONTINUE

		if [[ "${CONTINUE}" == "yes" ]]
		then
			LOOPING="continue"
		elif [[ "${CONTINUE}" == "no" ]]
		then
			LOOPING="abort"
			call_abort ;
		fi

		if [[ ${LOOPSTOP} == 0 ]]
		then
			warn_msg shellrun ;
			LOOPING="abort"			
		fi
	done

	DONESHELL="true"
}

do_shell () {
	warn_msg shell ;
	${CHROOT} ${CAPSULEMOUNT} ;
	close_shell ;
}


chroot_script () {
	# create the script to run inside our chroot environment
	# script will do remove/install work for packages then be
	# deleted upon completion after returning back to here

	ROOTEDSCRIPT="${CAPSULEMOUNT}/mbd-packs-scriptlet.sh"

		# export our script to our chroot environment
	#___________________________________________________________

	echo '#!/bin/bash' > ${ROOTEDSCRIPT} ;
	echo '#' >> ${ROOTEDSCRIPT} ;
	echo '# this script was auto-generated by the mbd-packs-mgr.sh' >> ${ROOTEDSCRIPT} ;
	echo '# it should have deleted imediately after its use.' >> ${ROOTEDSCRIPT} ;
	echo '# the fact you are reading this means that it failed to' >> ${ROOTEDSCRIPT} ;
	echo '# clean up after itself, so you should just delete this file.' >> ${ROOTEDSCRIPT} ;
	echo '#' >> ${ROOTEDSCRIPT} ;
	echo "INSTALLS=\"${INSTALLS}\"" >> ${ROOTEDSCRIPT} ;
	echo "REMOVES=\"${REMOVES}\"" >> ${ROOTEDSCRIPT} ;
	echo "SAYYES=\"${SAYYES}\"" >> ${ROOTEDSCRIPT} ;
	echo "INSTALL=\"install\"" >> ${ROOTEDSCRIPT} ;

cat <<'EOF' >>${ROOTEDSCRIPT}
do_scriptlet () {


	if [[ -n ${REMOVES} ]]
	then
		echo
		echo "removing requested packages"
		echo

		if ! apt-get ${SAYYES} remove ${REMOVES}
		then
			echo
			echo "failed to remove packages. Dropping into shell"
			echo
			exit 1
		fi
	fi

	if [[ -n ${INSTALLS} ]]
	then
		echo
		echo "	running apt-get update"
		echo

		if ! apt-get ${SAYYES} update
		then
			echo
			echo "failed to update package lists. Dropping into shell"
			echo
			exit 1
		fi

		echo
		echo "	installing requested packages"
		echo

		if ! apt-get ${SAYYES} ${INSTALL} ${INSTALLS}
		then
			echo
			echo "failed to install requested packages. Dropping into shell"
			echo
			exit 1
		fi
	fi
}

# run scriptlet loop
do_scriptlet ;
exit 0

EOF

		# now make it executable
	#___________________________________________________________

	chmod +x ${ROOTEDSCRIPT} ;
}


# =========================================
# _____________________________________________________

print_help () {
cat <<EOF
		__________________________________________________

			$MYNAME : $VERSION
			Website : $URL			

			To view the help documentation type:

				sudo ./mbd-packs-mgr.sh --help

				sudo ./mbd-packs-mgr.sh --optionfile-help

    =============================================================================
EOF
}

# Prints to screen complete help
print_full_help () {
cat <<EOF

	This is designed to simplify adding and removing packages inside Mint-Buntu-Deb capsules that
	have been previously imported into perceus. It uses the tools built into perceus to manage the
	vnfs. The default is for perceus to mount the capsule, removes/installs packages, and then to
	repackage the vnfs into the capsule. A lists of package requests can be passed in as arguments.
	Aditional options, a file with a list of packages can be used, or simply use the --more-packages
	option to install additional packages from the terminal before finalizing.

	When using both the install and remove options, all package removal occurs before installing packages.

	TROUBLESHOOTING:

	Examples:


        -b|--backup)              Forces backup creation without prompting. Make a cloned backup of the
                                  original before beginning. This can take a considerable amount of time.

        -c|--capsule)             The name of the capsule installed in perceus you wish to manage

        --create-template)        This will create an example options file in the same directory as
                                  this script. 

        -f|--file)                The full path to the options file containing package name to be
                                  removed/installed. This is optional, but can be usefull for managing
                                  long lists of packages or for future vnfs creation without the need
                                  to retype the desired packages.

        -d|--delete-orig)         Currently unused option.

        -h|--help)                Displays this help info

        -i|--install)             Space separated list of all package to install. These will be in addition
                                  to any packages found in the optional options file. All package installation
                                  will occure after all requested package removal.

        -m|--more-packages)       This will drop you into a shell inside the chrooted vnfs to allow manual
                                  command line management before finalizing.

        -o|--optionfile-help)     Displays the detailed help pertaining to the option file format

        -r|--remove)              Space separated list of all package to remove. These will be in addition
                                  to any packages found in the optional options file. All package removal
                                  will occure before any requested package are installs.

        -y|--assume-yes)          Automatic yes to "apt-get" prompts. Assume "yes" as answer to all prompts
                                  and run non-interactively.


	___________________________________________________________________________________________

EOF
}


print_options_help () {
cat <<EOF

	The option file is used to pass in multiple packages for removal and/or installation.
	It's recommended to name this file to correspond with the name of the vnfs it is related
	to. This will allow you to create templates for specific vnfs replication.

	Each option can contain a space delinitated list of package names to process. These packages
	will be in addition to any packages that were passed in with the command line. Package removal
	precedes package installation.

	REMOVE="package1 package-2 package_3"

	INSTALL="package1 package-2 package_3"

	___________________________________________________________

	The following command will create an example template file
	in the same directory as this script and will be named
			example-options.template

		sudo ./mbd-packs-mgr.sh --create-template	

	___________________________________________________________

EOF
}


create_template () {
cat <<EOF >example-options.template
# This file is an example file created
# by mbd-packs-mgr.sh. The space deliniated
# lists should contain packages to be removed
# or installed into the specified vnfs capsule.
#
# ./mbd-packs-mgr.sh --help
#
# Lines starting with # are comments
#_______________________________________________

# REMOVE="package1 package-2 package_3"

# INSTALL="package1 package-2 package_3"

EOF
}


##---------

do_main $@ ;

##---------

exit 0
