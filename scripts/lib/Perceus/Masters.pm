
#
# Copyright (c) 2006-2009, Greg M. Kurtzer, Arthur A. Stevens and
# Infiscale, Inc. All rights reserved
#

package Perceus::Masters;
use strict;
use warnings;

BEGIN {

   use Exporter;

   our @ISA = ('Exporter');

   our @EXPORT = qw (
      &masterscriptlist
   );

   require "/etc/perceus/Perceus_Include.pm";
   push(@INC, "$Perceus_Include::libdir");

}

use File::Basename;
use Perceus::Util;

sub masterscriptlist {

   my $db               = &getarg(\@_);
   my $NodeID           = &getarg(\@_);
   my $State            = &getarg(\@_);
   my $NodeName         = $nodeid2nodename($db, $NodeID);
   my @scripts          = ();
   my @return           = ();
   my $tmp              = ();
   my %ret              = ();

   if ( -d "$Perceus_Include::statedir/masterscripts/$State/" ) {
      push(@scripts, glob("$Perceus_Include::statedir/masterscripts/$State/*.sh"));
   } else {
      mkpath("$Perceus_Include::statedir/masterscripts/$State/");
   }
   foreach (@scripts) {
      $tmp = basename("$_");
      $ret{"$tmp"} = $_;
   }
   foreach ( sort keys %ret ) {
      push(@return, $ret{"$_"});
   }
   return(@return);
}  


1;
