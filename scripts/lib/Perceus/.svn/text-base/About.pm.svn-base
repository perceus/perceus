
#
# Copyright (c) 2006-2009, Greg M. Kurtzer, Arthur A. Stevens and
# Infiscale, Inc. All rights reserved
#

package Perceus::About;
use strict;
use warnings;

BEGIN {

   use Exporter;

   our @ISA = ('Exporter');

   our @EXPORT = qw (
      &about
   );

   require "/etc/perceus/Perceus_Include.pm";
   push(@INC, "$Perceus_Include::libdir");

}

use Perceus::Debug;

sub
about
{
    &dprint("Entered function");

    my $about               = ();

    $about .= "\n";
    $about .= "Perceus solves many of the scalability problems that occur when managing\n";
    $about .= "multiple similar or groups of similar systems. Facilitating uniformity,\n";
    $about .= "Perceus takes the lessons learned from one of the most widely used cluster\n";
    $about .= "management software toolkits (Warewulf), multiple industries and the\n";
    $about .= "flexibility required by most organizations and has implemented the next\n";
    $about .= "generation, massively scalable systems provisioning toolkit.\n";
    $about .= "\n";
    $about .= "For help on specific perceus options, type: 'perceus help'\n";
    $about .= "\n";
    $about .= "For documentation, questions, problems or support please visit the Perceus\n";
    $about .= "web site at http://www.perceus.org.\n";
    $about .= "\n";
    $about .= "To support Perceus, support the organization that makes Perceus possible,...\n";
    $about .= "\n";
    $about .= "                            Infiscale.com\n";
    $about .= "\n";

    &dprint("Returning function");
    return($about);
}

1;
