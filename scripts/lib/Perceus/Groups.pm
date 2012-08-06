
#
# Copyright (c) 2006-2009, Greg M. Kurtzer, Arthur A. Stevens and
# Infiscale, Inc. All rights reserved
#


package Perceus::Groups;
use strict;
use warnings;

BEGIN {

   use Exporter;

   our @ISA = ('Exporter');

   our @EXPORT = qw (
        &groupname2nodeid
   );

   require "/etc/perceus/Perceus_Include.pm";
   push(@INC, "$Perceus_Include::libdir");

}

use Perceus::Debug;
use Perceus::DB;
use Perceus::Util;
use Perceus::Nodes;
use File::Path;
use File::Basename;

sub
groupname2nodeid
{
    &dprint("Entered function");

    my $db              = shift;
    my @arguments       = @_;
    my @return          = ();

    # convert list of groupnames to nodeid's
    my %groups          = $db->hash_keys();

    foreach my $nodeid (keys(%groups)) {
        if (scalar(grep {$_ eq $groups{$nodeid}} @arguments)) {
            push @return, $nodeid;
        }
    }

    return(@return);
}



1;
