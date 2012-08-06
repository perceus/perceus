#!/usr/bin/perl
#
# Copyright (c) 2006-2009, Greg M. Kurtzer, Arthur A. Stevens and
# Infiscale, Inc. All rights reserved
#


use IO::Socket;
use Time::HiRes qw(gettimeofday);
use POSIX ":sys_wait_h";


print "Perceus daemon benchmark will make 512 virtual node connections spread over\n";
print "16 parallel processes. First it will simulate an initial boot, then all nodes\n";
print "will reply as if in a ready state, and then a reboot, and another ready. All\n";
print "connections will be run as fast as the daemon can go.\n";
print "\n";
print "Test will begin in 5 seconds...\n";
sleep 5;

$| = 1;

$hostname = $ARGV[0] || "localhost";

my $size = 16;

my @alphanumeric = ('a'..'f', 0..9);

for (my $i=1; $i<=32; $i++) {
    my $pid = &forkme($i);
    push(@pids, $pid);
}

foreach ( @pids ) {
    waitpid($_, 0);
}



sub
forkme($)
{
    my $threadnum           = shift;
    my @nodeids;

    if ( my $pid = fork() ) {
        return($pid);

    } else {

        print "[thread $threadnum] Starting test....\n";

        for($i=1; $i <= $size; $i++) {
            my $randstring = join '', map $alphanumeric[rand @alphanumeric], 0..7;
            $randstring =~ /^(..)(..)(..)(..)$/;
            my $hwaddr = "00:00:$1:$2:$3:$4";
            push(@nodeids, $hwaddr);
        }

        $initstart = gettimeofday();

        foreach my $nodeid ( @nodeids ) {
            my $ok = ();
            $sock = IO::Socket::INET->new( PeerAddr => $hostname, Proto => "tcp", PeerPort => "987")
                or warn "Connection failed for '$nodeid'\n";
            print $sock "init nodeid=$nodeid\n";
            while (my $out = <$sock> ) {
                chomp $out;
                if ( $out =~ /^# PROVISIOND END/ ) {
                    $ok = 1;
                    last;
                }
            }
            if ( ! $ok ) {
                print "[thread $threadnum] ERROR on $nodeid\n";
            }
            close $sock;
        }


        $initstop = gettimeofday();
        $inittime = sprintf("%.2f", $initstop - $initstart);

        print "[thread $threadnum] Simulated boot on $size NEW nodes took: $inittime seconds\n";
    
        $initstart = gettimeofday();

        for ( my $i=0; $i<=5; $i++ ) {
    
            foreach my $nodeid ( @nodeids ) {
                my $ok = ();
                $sock = IO::Socket::INET->new( PeerAddr => $hostname, Proto => "tcp", PeerPort => "987")
                    or warn "Connection failed for '$nodeid'\n";
                print $sock "ready nodeid=$nodeid\n";
                while (my $out = <$sock> ) {
                    last;
                }
                close $sock;
            }
        }

        $initstop = gettimeofday();
        $inittime = sprintf("%.2f", $initstop - $initstart);

        print "[thread $threadnum] Simulated ready on $size nodes (6 times) took: $inittime seconds\n";
    
        $initstart = gettimeofday();
    
        foreach my $nodeid ( @nodeids ) {
            my $ok = ();
            $sock = IO::Socket::INET->new( PeerAddr => $hostname, Proto => "tcp", PeerPort => "987")
                or warn "Connection failed for '$nodeid'\n";
            print $sock "init nodeid=$nodeid\n";
            while (my $out = <$sock> ) {
                chomp $out;
                if ( $out =~ /^# PROVISIOND END/ ) {
                    $ok = 1;
                    last;
                }
            }
            if ( ! $ok ) {
                print "ERROR on $nodeid\n";
            }
            close $sock;
        }
    

        $initstop = gettimeofday();
        $inittime = sprintf("%.2f", $initstop - $initstart);

        print "[thread $threadnum] Simulated reboot on $size nodes took: $inittime seconds\n";
    
        $initstart = gettimeofday();
    
#        for ( my $i=0; $i<=5; $i++ ) {
    
            foreach my $nodeid ( @nodeids ) {
                my $ok = ();
                $sock = IO::Socket::INET->new( PeerAddr => $hostname, Proto => "tcp", PeerPort => "987")
                    or warn "Connection failed for '$nodeid'\n";
                print $sock "ready nodeid=$nodeid\n";
                while (my $out = <$sock> ) {
                    last;
                }
                close $sock;
            }
#        }

        $initstop = gettimeofday();
        $inittime = sprintf("%.2f", $initstop - $initstart);

        print "[thread $threadnum] Simulated ready on $size nodes took: $inittime seconds\n";

        exit;
    }
}
