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
use Perceus::Nodes;
use Getopt::Long;

GetOptions(
   'help'      => \$help,
   'debug'     => \$debug,
);

&dprint("Starting MAIN()");

print "\n";
print "This is a simple node addition script that will scan and add any system\n";
print "that makes a DHCP request that this master node responds to. It is handy\n";
print "for adding large numbers of nodes because it is faster (yet potentially\n";
print "less accurate) then adding by letting the perceus daemon do it for you.\n";
print "\n";

if ( $help ) {
   exit;
}

print "Inturrupt with [ctrl]-c when you are finished scanning...\n";

sleep 2;

print "\n";
print "Waiting for new nodes...\n";

&dprint("Scanning syslog");
open(SYSLOG, "tail -n 0 -f /var/log/messages | ");
while(<SYSLOG>) {
   chomp;
   &dprint("new syslog line: '$_'");
   @f = split(/\s+/, $_);
   if ( $f[5] eq "DHCPDISCOVER" ) {
      $tmp = uc($f[7]);
      &node_add($tmp);
   }
}
close SYSLOG;

