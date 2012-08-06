#!/usr/bin/perl
#
# Copyright (c) 2006-2009, Greg M. Kurtzer, Arthur A. Stevens and
# Infiscale, Inc. All rights reserved
#

BEGIN {
   require "/etc/perceus/Perceus_Include.pm";
   push(@INC, "$Perceus_Include::libdir");
}

use Perceus::DB;
use Perceus::Debug;
use Perceus::System;
use Perceus::Nodes;
use Getopt::Long;

GetOptions(
   'help'      => \$help,
   'debug'     => \$debug,
);

&dprint("Starting MAIN()");

my $database = $ARGV[0];
my $db;

if ( ! -f $database or $help ) {
   warn "This script will import the contents of an existing ISC dhcpd.conf file into\n";
   warn "Perceus. It will assume the defaults specified in /etc/perceus/defaults.conf\n";
   warn "but will assign the hostname defined in the dhcpd.conf file itself.\n\n";
   warn "To use this utility simply point it to your dhcpd.conf file. For example:\n\n";
   warn "   # $0 /etc/dhcpd.conf\n\n";
   warn "This will automatically import the data from the dhcpd.conf file into the\n";
   warn "Perceus installation\n";
   exit;
}


open(DHCP, "$ARGV[0]");
while(<DHCP>) {
   chomp;
   if ( $_ =~ /^\s*host\s+([^\s]+)\s*{?\s*$/ ) {
      $hostname = $1;
   } elsif ( $_ =~ /^\s*hardware ethernet\s+([^\s]+)\s*;\s*$/ ) {
print "Adding: $1, $hostname\n";
      &node_add($1, $hostname);
   }
}
close DHCP;

&dprint("Ending MAIN()");
