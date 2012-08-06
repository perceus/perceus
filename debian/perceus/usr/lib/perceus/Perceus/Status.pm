
#
# Copyright (c) 2006-2009, Greg M. Kurtzer, Arthur A. Stevens and
# Infiscale, Inc. All rights reserved
#

package Perceus::Status;
use strict;
use warnings;

BEGIN {
   use Exporter;

   our @ISA = ('Exporter');

   our @EXPORT = qw (
      &daemon_ping
   );

   require "/etc/perceus/Perceus_Include.pm";
   push(@INC, "$Perceus_Include::libdir");

}

use Perceus::Debug;
use Perceus::Config;
use Perceus::Util;
use IO::Socket;


sub
daemon_ping(@)
{

   my $buff;
   my $sock;
   my $return           = 0;
   my $rand             = &rand_string("16");
   my %config           = &parse_config("/etc/perceus/perceus.conf");
   my $eth              = $config{"master network device"}[0];


   &dprint("Creating TCP socket at port 987");
   $sock = IO::Socket::INET->new( Proto     => 'tcp',
                                  PeerPort  => 987,
                                  PeerAddr  => &get_ipaddr($eth),
                                  Timeout   => 1);


   if ( $sock ) {
      &dprint("Connection open, sending 'ping $rand'");
      print $sock "ping $rand\n";

      &dprint("Reading incoming data");
      read($sock, $buff, 35);

      # Take last line as the response, since first line is "# PERCEUSD START"
      $buff = (split('\n', $buff))[-1];

      if ( $buff eq "$rand" ) {
         &dprint("Response was good!");
      } else {
         &dprint("Response did not match ($buff)!");
         $return = 1;
      }

   } else {
      &dprint("Could not open socket to daemon");
      $return = 1;
   }

   &dprint("Returning function with: $return");
   return($return);

}



1;
