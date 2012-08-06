
#
# Copyright (c) 2006-2009, Greg M. Kurtzer, Arthur A. Stevens and
# Infiscale, Inc. All rights reserved
#

package Perceus::CUI;
use strict;
use warnings;

BEGIN {

   use Exporter;

   our @ISA = ('Exporter');

   our @EXPORT = qw (
      &getinput
   );

   require "/etc/perceus/Perceus_Include.pm";
   push(@INC, "$Perceus_Include::libdir");

}

use Perceus::Debug;
use Term::ReadLine;

sub
getinput($)
{
   &dprint("Entered function with: @_");

   my $prompt = shift || "> ";
   my $term = new Term::ReadLine("Perceus getinput");
   $term->ornaments(0);

   my $in = $term->readline($prompt) || "";

   &dprint("Returning function with: $in");
   
   return($in);
}

1;
