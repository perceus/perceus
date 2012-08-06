
#
# Copyright (c) 2006-2009, Greg M. Kurtzer, Arthur A. Stevens and
# Infiscale, Inc. All rights reserved
#

package Perceus::System;
use strict;
use warnings;

BEGIN {
   use Exporter;

   our @ISA = ('Exporter');

   our @EXPORT = qw (
      &runcmd
      &service
      &chkconfig
      &inetd
      &check_process
      &perceus_info
      &perceus_status
      &system_info
   );

   require "/etc/perceus/Perceus_Include.pm";
   push(@INC, "$Perceus_Include::libdir");

}

use Perceus::Nodes;
use Perceus::Util;
use Perceus::Vnfs;
use Perceus::Modules;
use Perceus::Debug;
use Perceus::Config;
use Perceus::DB;
use Switch;


sub runcmd {
   &dprint("Entered function");

   my $cmd              = &untaint(&getarg(\@_));
   my $verbosity        = &getarg(\@_);
   my @output           = ();
   my $retval           = 0;

   if ( ! defined($verbosity) ) {
      $verbosity = 1;
   }

   if ( $verbosity >= 2 ) {
      &iprint("Running: $cmd");
   } else {
      &dprint("Running: $cmd");
   }
   open(OUT, "$cmd 2>&1 |");
   while(<OUT>) {
      chomp;
      $_ =~ s/^[^\s]+: //;
      &dprint("output: $_");
      push(@output, $_);
   }
   if ( close OUT ) {
      &dprint("Command exited correctly");
      foreach (@output) {
         if ( $verbosity >= 1 ) {
            &iprint("$_");
         } else {
            &dprint("$_");
         }
      }
      $retval = 0;
   } else {
      if ( $verbosity >= 1 ) {
         &eprint("$cmd");
      }
      if ( $verbosity >= 0 ) {
         foreach (@output) {
            &eprint("$_");
         }
      }
      $retval = 1;
   }

   &dprint("Returning function with: $retval");
   return $retval;
}

sub check_process {
   &dprint("Entered function");

   my $service          = &getarg(\@_);
   my $pid              = ();

   if ( -x "/bin/pidof" ) {
      chomp ($pid = `/bin/pidof -sx $service`);
   } elsif ( -x "/sbin/pidof" ) {
      chomp ($pid = `/sbin/pidof -sx $service`);
   } elsif ( -x "/usr/bin/pidof" ) {
      chomp ($pid = `/usr/bin/pidof -sx $service`);
   } elsif ( -x "/usr/sbin/pidof" ) {
      chomp ($pid = `/usr/sbin/pidof -sx $service`);
   } else {
      &wprint("I can not check services without the shell command 'pidof'!");
      return(1);
   }

   if ( $pid ) {
      &dprint("Returning function with: $pid");
   } else {
      &dprint("Returning function undefined");
   }
   return $pid;
}

sub chkconfig {
   &dprint("Entered function");

   my $service          = &getarg(\@_);
   my $command          = &getarg(\@_);
   my $retval           = 0;

   if ( $command eq "start" or $command eq "on" ) {
      my $command = $Perceus_Include::service_on;
      $command =~ s/{service}/$service/g;
      $retval += &runcmd($command, 0);
   } elsif ( $command eq "stop" or $command eq "off" ) {
      my $command = $Perceus_Include::service_off;
      $command =~ s/{service}/$service/g;
      $retval += &runcmd($command, 0);
   }

   if ( $retval ) {
      &dprint("Returning function with: $retval");
   } else {
      &dprint("Returning function undefined");
   }
   return($retval);
}

sub service {
   &dprint("Entered function");

   my $service          = &getarg(\@_);
   my $command          = &getarg(\@_);
   my $retval           = 0;

   if ( $command eq "start" or $command eq "on" ) {
      my $command = $Perceus_Include::service_start;
      $command =~ s/{service}/$service/g;
      $retval += &runcmd($command, 0);
   } elsif ( $command eq "stop" or $command eq "off" ) {
      my $command = $Perceus_Include::service_stop;
      $command =~ s/{service}/$service/g;
      $retval += &runcmd($command, 0);
   } elsif ( $command eq "restart" ) {
      my $command = $Perceus_Include::service_stop;
      $command =~ s/{service}/$service/g;
      $retval += &runcmd($command, 0);
      $command = $Perceus_Include::service_start;
      $command =~ s/{service}/$service/g;
      $retval += &runcmd($command, 0);
   }

   if ( $retval ) {
      &dprint("Returning function with: $retval");
   } else {
      &dprint("Returning function undefined");
   }
   return($retval);
}

sub inetd {
   &dprint("Entered function");

   my $service          = &getarg(\@_);
   my $command          = &getarg(\@_);
   my $retval           = 0;

   if ( $command eq "start" or $command eq "on" ) {
      my $command = $Perceus_Include::service_on;
      $command =~ s/{service}/$service/g;
      $retval += &runcmd($command, 1);
   } elsif ( $command eq "stop" or $command eq "off" ) {
      my $command = $Perceus_Include::service_off;
      $command =~ s/{service}/$service/g;
      $retval += &runcmd($command, 1);
   }
   my $inetd_restart = $Perceus_Include::inetd_restart;
   $inetd_restart =~ s/{service}/$service/g;
   $retval += &runcmd($inetd_restart, 1);

   if ( $retval ) {
      &dprint("Returning function with: $retval");
   } else {
      &dprint("Returning function undefined");
   }
   return($retval);
}

sub perceus_info {
   &dprint("Entered function");

   my $out              = ();
   my $conf             = ();
   my %config           = &parse_config("/etc/perceus/perceus.conf");

   $out .= "Perceus Information:\n";
   $out .= "\n";
   $out .= "  Perceus Version:             $Perceus_Include::version\n";
   $out .= "  Perceus Build:               $Perceus_Include::build\n\n";
   $out .= "  Perceus Database:            $Perceus_Include::database\n";
   $out .= "  Perceus Configuration:\n";
   $out .= "     prefix:                   $Perceus_Include::prefix\n";
   $out .= "     statedir:                 $Perceus_Include::statedir\n";
   $out .= "     libdir:                   $Perceus_Include::libdir\n";
   $out .= "  System:\n";
   $out .= "     service start:            $Perceus_Include::service_start\n";
   $out .= "     service stop:             $Perceus_Include::service_stop\n";
   $out .= "     inetd restart:            $Perceus_Include::inetd_restart\n";
   $out .= "     operating system:         $Perceus_Include::operating_system\n";
   $out .= "     distribution release:     $Perceus_Include::distribution_release_file\n";

   foreach $conf ( sort keys %config ) {
      $out .= sprintf("     %-25s %s\n", "$conf:", join(", ", @{$config{$conf}}));
   }

   $out .= "\n";

   &dprint("Returning function with blob of text");
   return($out);
}

sub perceus_status {
   &dprint("Entered function");

   my $nodecount        = ();
   my $out              = ();
   my $mod              = ();
   my $role             = ();
   my %roles            = ();
   my $db               = &opendb("hostname");
   my @nodes            = &list_node_by_hostname($db, "*");

   $nodecount = $#nodes + 1;

   $out .= "Perceus Status:\n";
   $out .= "\n";
   $out .= "   Nodes configured:           $nodecount\n";
   $out .= "   Imported VNFS capsules:\n";
   foreach (sort &vnfs_list()) {
      $out .= "      $_\n";
   }
   $out .= "   Module Summary:\n";
   foreach $mod ( sort &module_list("*") ) {
      foreach $role ( sort &module_list_active("$mod")) {
         push(@{$roles{$role}}, $mod);
      }
   }
   foreach $role ( sort keys %roles ) {
      $out .= "      $role:\n";
      foreach $mod ( sort @{$roles{$role}} ) {
         $out .= "         $mod\n";
      }
   }
   $out .= "\n";

   &dprint("Returning function with blob of text");
   return($out);
}


sub system_info {
   &dprint("Entered function");

   my $arch             = ();
   my $out              = ();

   $out .= "System Configuration:\n";
   $out .= "\n";

   $out .= "   Distribution Release File: $Perceus_Include::distribution_release_file\n";
   open(REL, "$Perceus_Include::distribution_release_file");
   while(<REL>){
      chomp;
      $out .= "     $_\n";
   }

   $out .= "\n";

   foreach ( &get_local_devs()) {
      $out .= sprintf("   %-28s %s/%s\n", "Network device $_:", &get_ipaddr($_), &get_netmask($_));
   }

   open(ARCH, "uname -m |");
   while (<ARCH>) {
      chomp;
      $arch .= "$_";
   }
   close ARCH;
   my $release;
   open(ARCH, "uname -r |");
   while (<ARCH>) {
      chomp;
      $release .= "$_";
   }
   close ARCH;

   $out .= "   Architecture:                $arch\n";
   $out .= "   Kernel Release:              $release\n";

   &dprint("Returning function with blob of text");
   return($out);
}


1;
