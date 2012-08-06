#
# Copyright (c) 2006-2009, Greg M. Kurtzer, Arthur A. Stevens and
# Infiscale, Inc. All rights reserved
#

# Do not edit or change anything in this file. It is automatically generated
# at Perceus build time to reflect the paths of the configured installation.
# Any changes to this file will break things if you don't know exactly what
# your doing! You have been warned. :)

package Perceus_Include;

our $prefix = "/usr";
our $localstatedir = "${prefix}/var";
our $sysconfdir = "/etc/";
our $libdir = "$prefix/lib/perceus/";
our $libexecdir = "$prefix/libexec/perceus/";
our $initdir = "$sysconfdir/init.d/";
our $statedir = "$localstatedir/lib/perceus/";
our $version = "1.6.0";
our $build = "0.2402M";
our $database = "$statedir/database";
our $service_start = "/etc/init.d/{service} start";
our $service_stop = "/etc/init.d/{service} stop";
our $service_on= "/sbin/rc-update add {service} default";
our $service_off= "/sbin/rc-update del {service} default";
our $inetd_restart = "killall -HUP xinetd inetd 2>/dev/null";
our $operating_system = "Debian";
our $distribution_release_file = "/etc/debian_version";
our $enable_gpxe = "";

1;
