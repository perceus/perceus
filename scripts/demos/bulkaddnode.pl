#!/usr/bin/perl
#
# Copyright (c) 2006-2009, Greg M. Kurtzer, Arthur A. Stevens and
# Infiscale, Inc. All rights reserved
#


BEGIN {

   require "/etc/perceus/Perceus_Include.pm";
   push(@INC, "$Perceus_Include::libdir");

}

use strict;
use warnings;
use Perceus::Interface::Cmdline;

my $a;
my $hostname;
my $hwaddr;
my $num = $ARGV[0] || "1000";

for($a=0; $a <= $num; $a++) {
    my $hwa_tmp = sprintf("%12.12x", $a);
    $hostname = sprintf("test%5.5d", $a);
    $hwa_tmp =~ /^(..)(..)(..)(..)(..)(..)$/;
    $hwaddr = "$1:$2:$3:$4:$5:$6";
    &UI_NodeAdd($hwaddr, $hostname);
}
