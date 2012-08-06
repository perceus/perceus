
#
# Copyright (c) 2006-2009, Greg M. Kurtzer, Arthur A. Stevens and
# Infiscale, Inc. All rights reserved
#

package Perceus::Sanity;
use strict;
use warnings;

BEGIN {

   use Exporter;

   our @ISA = ('Exporter');

   our @EXPORT = qw (
      &sanity_check
      &check_registered
   );

   require "/etc/perceus/Perceus_Include.pm";
   push(@INC, "$Perceus_Include::libdir");

}

use Perceus::Debug;
use Perceus::Util;
use Perceus::DB;
use Perceus::Config;
use Perceus::Contact;
use Perceus::CUI;


sub
check_registered()
{
   &dprint("Entered function");
   my $retval;

   if ( $main::opt_embeded ) {
      # bypass registration
   } elsif ( ! -f "$Perceus_Include::statedir/.registered" ) {
      if ( $> != 0 ) {
         return;
      }
      &iprint("Jumping into automatic Perceus registration...\n");
      sleep 2;
      if ( ! &contact_register() ) {
         &iprint("Registration successful!\n");
      } else {
         &eprint("There was a problem registering Perceus!\n");
      }
      &getinput("\nPress [ENTER] to continue: ");
   }
   return();
}

sub sanity_check {
   &dprint("Entered function");

   my %config           = &parse_config("/etc/perceus/perceus.conf");
   my $error            = ();

   if ( ! exists($config{"master network device"}[0]) ) {
      &eprint("You need to set 'master network device' in /etc/perceus/perceus.conf!");
      $error = 1;
   }
   if ( ! exists($config{"vnfs transfer method"}[0]) ) {
      &eprint("You need to set 'vnfs transfer method' in /etc/perceus/perceus.conf!");
      $error = 1;
   }
   if ( ! exists($config{"database type"}[0]) ) {
      &eprint("You need to set 'database type' in /etc/perceus/perceus.conf!");
      $error = 1;
   }

   if ( $error ) {
      exit(1);
   }

   my $eth              = $config{"master network device"}[0];
   my $ipaddr           = &get_ipaddr($eth);

   if ( ! $ipaddr ) {
      &wprint("The defined master network device '$eth' is unconfigured!");
   }

   &dprint("Returning function");
   return();
}


1;
