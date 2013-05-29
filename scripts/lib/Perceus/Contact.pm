
#
# Copyright (c) 2006-2009, Greg M. Kurtzer, Arthur A. Stevens and
# Infiscale, Inc. All rights reserved
#

package Perceus::Contact;
use strict;
use warnings;

BEGIN {

   use Exporter;

   our @ISA = ('Exporter');

   our @EXPORT = qw (
      &contact_register
      &contact_support
   );

   require "/etc/perceus/Perceus_Include.pm";
   push(@INC, "$Perceus_Include::libdir");

}

use Perceus::System;
use Perceus::Debug;
use Perceus::CUI;
use IO::Socket;

sub contact_register {
# And for the "Perl'ers" who simply comment out the code in order not to
# register, this is here for a reason! All we ask for is a notification
# that someone is using it

   &dprint("Entered function");

   my $name             = ();
   my $email            = ();
   my $company          = ();
   my $title            = ();
   my $node_count       = ();
   my $comments         = ();
   my $sock             = ();
   my $retval           = 0;

   chomp (my $hostname = `hostname`);

   print "Perceus registration:\n\n";
   print "Here we will ask several basic questions about you (the user) that will be\n";
   print "sent to the developers of Perceus.\n\n";
   print "The following questions will only take a moment, and are very helpful\n";
   print "to the developers of this software and will never be shared or sold:\n\n";
   while ( ! $name ) {
      $name = &getinput("(1/6) Name:          ");
      if ( $name eq "infiscale" ) {
         return(0);
      }
   }

   while ( ! $email ) {
      $email = &getinput("(2/6) Email address: ");
   }
   while ( ! $company ) {
      $company = &getinput("(3/6) Company name:  ");
   }
   while ( ! $title ) {
      $title = &getinput("(4/6) Your role:     ");
   }
   while ( ! $node_count ) {
      $node_count = &getinput("(5/6) Node Count:    ");
   }
   $comments = &getinput("(6/6) Comments:      ");

   if ( $sock = IO::Socket::INET->new( PeerAddr => "perceus.org", Proto => "tcp", PeerPort => "25", Timeout => "15" ) ) {

      print $sock "HELO perceus.org\n";
      print $sock "MAIL FROM: $email\n";
      print $sock "RCPT TO: registration\@perceus.org\n";
      print $sock "DATA\n";
      print $sock "To: registration\@perceus.org\n";
      print $sock "From: $name <$email>\n";
      print $sock "Subject: Perceus registration @ $company\n";
      print $sock "\n";
      print $sock "Name:\t\t$name\n";
      print $sock "Email:\t\t$email\n";
      print $sock "Company:\t$company\n";
      print $sock "Role:\t\t\t$title\n\n";
      print $sock "Hostname:\t$hostname\n";
      print $sock "Nodes:\t\t$node_count\n";
      print $sock "Version:\t$Perceus_Include::version\n";
      print $sock "Build:\t\t$Perceus_Include::build\n\n";
      print $sock "Comments:\t$comments\n";

      print $sock "\n-------------------------------------------------------------------------------\n";
      print $sock &perceus_info();

      print $sock "\n.\n";
      close $sock;

   } else {
      &wprint("There was an error making an SMTP connection to register your Perceus install.");
      &wprint("Registration is not needed to continue, but the developers use installation");
      &wprint("statistics and information for presentations and reports. The registration");
      &wprint("content has been written to a file ('/root/perceus-registration.txt'). Please");
      &wprint("email this information to registration\@perceus.org at your first availability.");
      &wprint("\nThank you.\n\n");
      open(FD, ">/root/perceus-registration.txt");
      print FD "Name:\t\t$name\n";
      print FD "Email:\t\t$email\n";
      print FD "Company:\t$company\n";
      print FD "Title:\t\t$title\n\n";
      print FD "Hostname:\t$hostname\n";
      print FD "Nodes:\t\t$node_count\n";
      print FD "Comments:\n";
      print FD "$comments\n";

      print FD "\n-------------------------------------------------------------------------------\n";
      print FD &perceus_info();

      close FD;
   }

   open(REG, "> $Perceus_Include::statedir/.registered")
      or &eprint("Could not save registration state!\n");
   print REG "$Perceus_Include::version-$Perceus_Include::build";
   close REG;

   &dprint("Returning function with: $retval");
   return($retval);
}

sub contact_support {
   &dprint("Entered function");

   my $name             = ();
   my $email            = ();
   my $company          = ();
   my $title            = ();
   my $node_count       = ();
   my $comments         = ();
   my $sock             = ();
   my $problem          = ();
   my $rand             = ();

   print "This utility will contact the Perceus support team with a description of\n";
   print "your problem and your system configuration.\n\n";
   print "Please answer the questions:\n";

   while ( ! $name ) {
      $name = &getinput("(1/4) Name:          ");
   }

   while ( ! $email ) {
      $email = &getinput("(2/4) Email:         ");
   }

   while ( ! $company ) {
      $company = &getinput("(3/4) Company:       ");
   }

   while ( ! $problem ) {
      $problem = &getinput("(4/4) Problem:       ");
   }

   $sock = IO::Socket::INET->new( PeerAddr => "perceus.org", Proto => "tcp", PeerPort => "25", Timeout => "15")
            || &eprint("Unable to Connect!");

   $rand = &rand_string("24");
   my $db = &open_db();
   my @nodelist = &globnodename($db, "node", "*");
   my $nodecount = $#nodelist + 1;


   print $sock "HELO perceus.org\n";
   print $sock "MAIL FROM: $email\n";
   print $sock "RCPT TO: support\@perceus.org\n";
   print $sock "DATA\n";
   print $sock "To: support\@perceus.org\n";
   print $sock "From: $name <$email>\n";
   print $sock "Subject: Perceus support ID: $rand\n";
   print $sock "\n";
   print $sock "Name:\t\t$name\n";
   print $sock "Email:\t\t$email\n";
   print $sock "Company:\t$company\n";
   print $sock "Problem:\n";
   print $sock "\n$problem\n";

   print $sock "\n-------------------------------------------------------------------------------\n";
   print $sock &perceus_info();
   print $sock &perceus_status();
   print $sock &system_info();

   print $sock "\n.\n";
   close $sock;

   print "\n";
   print "Give the Perceus support team several days to respond to this request.\n";
   print "Your ticket ID is: '$rand'\n";
   print "\n";
   print "You can contact the support team directly at <support\@perceus.org> and be\n";
   print "sure to include your ticket ID in the subject line of the email.\n";

   &dprint("Returning function undefined");
   return(0);
}

1;
