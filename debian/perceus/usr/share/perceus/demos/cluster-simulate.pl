#!/usr/bin/perl
#
# Copyright (c) 2006-2009, Greg M. Kurtzer, Arthur A. Stevens and
# Infiscale, Inc. All rights reserved
#


use IO::Socket;
#use POSIX ":sys_wait_h";
use threads;
use threads::shared;

my $hostname = $ARGV[0] || "localhost";
my $nodes = $ARGV[1] || "128";
my $time = 300;
my @alphanumeric = ('a'..'f', 0..9);
my @numeric = (0..9);
my @smallnumeric = (0..3);

if ( $nodes > 256 ) {
    print "WARNING: You may run into problems virtualizing that many node threads\n";
    print "WARNING: due to the way Perl implements threads, and that this program\n";
    print "WARNING: uses Perl threads. Watch your memory consumption!\n\n";
}

print "This will simulate a $nodes node cluster. First the nodes will get provisioned\n";
print "and then they will enter a running state. You will need to control-C to kill\n";
print "this process once you are satisified.\n";
print "\n";



for (my $i=1; $i<=$nodes; $i++) {
    threads->new( \&forkme, $i);
    sleep join '', map $smallnumeric[rand @smallnumeric], 0;
}

# endless loop....
while(1) {
    sleep 1;
}


sub
forkme($)
{
    my $num = shift();
    $| = 1;
    my $line;

    my $hwa_tmp = sprintf("%12.12x", $num);
    $hwa_tmp =~ /^(..)(..)(..)(..)(..)(..)$/;
    my $nodeid = "$1:$2:$3:$4:$5:$6";

    while(1) {

        my $ok = ();
        $sock = IO::Socket::INET->new( PeerAddr => $hostname, Proto => "tcp", PeerPort => "987")
            or warn "Connection failed for '$nodeid'\n";
        print $sock "init nodeid=$nodeid\n";
        while (my $out = <$sock> ) {
            chomp $out;
            if ( $out =~ /^# HELLO from provisiond/ ) {
                $ok = 1;
            }
            $line .= "$out\n";
        }

        close $sock;
        $sock = ();

        if ( $ok ) {
            print "*";
        }

        # Time it takes for the node to boot.
        sleep 30 + join '', map $numeric[rand @numeric], 0;

        while(1) {
            my $ok = ();
            $sock = IO::Socket::INET->new( PeerAddr => $hostname, Proto => "tcp", PeerPort => "987")
                or warn "Connection failed for '$nodeid'\n";
            print $sock "ready nodeid=$nodeid\n";
            while (my $out = <$sock> ) {
                # do nothing here...
            }
            close $sock;
            $sock = ();
            print ".";
            #sleep join '', map $numeric[rand @numeric], 0;
            sleep $time + join '', map $smallnumeric[rand @smallnumeric], 0;
            my $randreboot = join '', map $numeric[rand @numeric] , 0..3;
            if ( $randreboot == 99 ) {
                # every now and then, a node needs to be rebooted.
                last;
            }
        }
    }

}
