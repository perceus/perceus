
#
# Copyright (c) 2006-2009, Greg M. Kurtzer, Arthur A. Stevens and
# Infiscale, Inc. All rights reserved
#

package Perceus::Dump;
use strict;
use warnings;

BEGIN {

   use Exporter;

   our @ISA = ('Exporter');

   our @EXPORT = qw (
      &perceus_db_dump
   );

   require "/etc/perceus/Perceus_Include.pm";
   push(@INC, "$Perceus_Include::libdir");

}

use Perceus::Debug;
use Perceus::DB;

sub
perceus_db_dump
{
    &dprint("Entered function");

    my @databases       = qw(status ipaddr desc vnfs group enabled lastcontact);
    my %db              = ();
    my $return          = ();

    $db{"hostname"} = &opendb("hostname");

    foreach my $db ( @databases ) {
        $db{"$db"} = &opendb($db);
    }

    foreach my $nodeid ( $db{"hostname"}->list_keys() ) {
        my $hostname = $db{"hostname"}->get($nodeid);
        $return .= "\n### $nodeid ###\n";
        $return .= "if perceus node add $nodeid \"$hostname\"; then\n";
        foreach my $db ( @databases ) {
            $return .= "   perceus -yq node set $db \"". $db{"$db"}->get($nodeid) ."\" \"$hostname\" >/dev/null\n";
        }
        $return .= "fi\n";
    }

    foreach my $db ( @databases ) {
        $db{"$db"}->closedb();
    }

    &dprint("Returning function");
    return($return);
}

1;
