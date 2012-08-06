
#
# Copyright (c) 2006-2009, Greg M. Kurtzer, Arthur A. Stevens and
# Infiscale, Inc. All rights reserved
#


package Perceus::Debug;
use strict;
use warnings;

BEGIN {

   use Exporter;

   our @ISA = ('Exporter');

   our @EXPORT = qw (
      &wprint
      &dprint
      &eprint
      &iprint
      &vprint
      &backtrace
      &perceus_die
   );

   require "/etc/perceus/Perceus_Include.pm";
   push(@INC, "$Perceus_Include::libdir");

}

use Unix::Syslog qw(:macros);
use Unix::Syslog qw(:subs);

sub
backtrace()
{
    my $file             = ();
    my $line             = ();
    my $subroutine       = ();
    my $i                = ();
    my @tmp              = ();

    print STDERR "STACK TRACE:\n";
    print STDERR "------------\n";
    for ($i = 0; @tmp = caller($i); $i++) {
        $subroutine = $tmp[3];
        (undef, $file, $line) = caller($i);
        $file =~ s/^.*\/([^\/]+)$/$1/;
        print STDERR '      ', ' ' x $i, "$subroutine() called at $file:$line\n";
    }
    print STDERR "\n";
}

sub
perceus_die($)
{
    my $string           = shift;
    my $f                = ();
    my $l                = ();
    my $s                = ();

    if ( defined($main::daemon) ) {
        openlog("perceus", LOG_PID,  LOG_LOCAL7);
    }

    chomp($string);

    if ( defined($main::debug) ) {
        (undef, undef, undef, $s) = caller(1);
        if (!defined($s)) {
            $s = "MAIN";
        }
        (undef, $f, $l) = caller(0);
        $f =~ s/^.*\/([^\/]+)$/$1/;
        $s =~ s/\w+:://g;
        $s .= "()" if ($s =~ /^\w+$/);
        $f = "" if (!defined($f));
        $l = "" if (!defined($l));
        $s = "" if (!defined($s));
        print STDERR "ERROR:  [$f/$l/$s]: $string\n";
        &backtrace();
    } elsif ( defined($main::opt_verbose) ) {
        print STDERR "ERROR: $string\n";
        &backtrace();
    } else {
        if ( defined($main::daemon) ) {
            syslog(LOG_INFO, "ERROR: $string");
        } else {
            print STDERR "ERROR: $string\n";
        }
    }

    if ( defined($main::daemon) ) {
        closelog;
    }

    exit 1;

    return();
}



sub
eprint($)
{
    my $string           = shift;
    my $f                = ();
    my $l                = ();
    my $s                = ();

    if ( defined($main::daemon) ) {
        openlog("perceus", LOG_PID,  LOG_LOCAL7);
    }

    chomp($string);

    if ( defined($main::debug) ) {
        (undef, undef, undef, $s) = caller(1);
        if (!defined($s)) {
            $s = "MAIN";
        }
        (undef, $f, $l) = caller(0);
        $f =~ s/^.*\/([^\/]+)$/$1/;
        $s =~ s/\w+:://g;
        $s .= "()" if ($s =~ /^\w+$/);
        $f = "" if (!defined($f));
        $l = "" if (!defined($l));
        $s = "" if (!defined($s));
        print STDERR "ERROR   [$f/$l/$s]: $string\n";
        &backtrace();
    } else {
        if ( defined($main::daemon) ) {
            syslog(LOG_INFO, "ERROR: $string");
        } else {
            print STDERR "ERROR: $string\n";
        }
    }

    if ( defined($main::daemon) ) {
        closelog;
    }

    return();
}

sub
wprint($)
{
    my $string           = shift;
    my $f                = ();
    my $l                = ();
    my $s                = ();

    if ( defined($main::daemon) ) {
        openlog("perceus", LOG_PID,  LOG_LOCAL7);
    }

    chomp($string);

    if ( defined($main::debug) ) {
        (undef, undef, undef, $s) = caller(1);
        if (!defined($s)) {
            $s = "MAIN";
        }
        (undef, $f, $l) = caller(0);
        $f =~ s/^.*\/([^\/]+)$/$1/;
        $s =~ s/\w+:://g;
        $s .= "()" if ($s =~ /^\w+$/);
        $f = "" if (!defined($f));
        $l = "" if (!defined($l));
        $s = "" if (!defined($s));
        print STDERR "WARN    [$f/$l/$s]: $string\n";
    } elsif ( defined($main::opt_verbose) or defined($main::verbose) ) {
        print STDERR "WARN: $string\n";
    } elsif ( defined($main::opt_quiet) or defined($main::quiet) ) {
        # Don't do anything when asked to be quiet
    } else {
        if ( defined($main::daemon) ) {
            syslog(LOG_INFO, "WARN: $string");
        } else {
            print STDERR "WARNING: $string\n";
        }
    }

    if ( defined($main::daemon) ) {
        closelog;
    }

    return();
}

sub
vprint($)
{
    my $string           = shift;
    my $f                = ();
    my $l                = ();
    my $s                = ();

    if ( defined($main::daemon) ) {
        return();
    }

    chomp($string);

    if ( defined($main::debug) ) {
        (undef, undef, undef, $s) = caller(1);
        if (!defined($s)) {
            $s = "MAIN";
        }
        (undef, $f, $l) = caller(0);
        $f =~ s/^.*\/([^\/]+)$/$1/;
        $s =~ s/\w+:://g;
        $s .= "()" if ($s =~ /^\w+$/);
        $f = "" if (!defined($f));
        $l = "" if (!defined($l));
        $s = "" if (!defined($s));
        print STDERR "VERBOSE [$f/$l/$s]: $string\n";
    } elsif ( defined($main::opt_verbose) or defined($main::verbose) ) {
        print "$string\n";
    }
    return();
}

sub
iprint($)
{
    my $string           = shift;
    my $f                = ();
    my $l                = ();
    my $s                = ();

    if ( defined($main::daemon) ) {
        openlog("perceus", LOG_PID,  LOG_LOCAL7);
    }

    chomp($string);

    if ( defined($main::debug) ) {
        (undef, undef, undef, $s) = caller(1);
        if (!defined($s)) {
            $s = "MAIN";
        }
        (undef, $f, $l) = caller(0);
        $f =~ s/^.*\/([^\/]+)$/$1/;
        $s =~ s/\w+:://g;
        $s .= "()" if ($s =~ /^\w+$/);
        $f = "" if (!defined($f));
        $l = "" if (!defined($l));
        $s = "" if (!defined($s));
        print "INFO    [$f/$l/$s]: $string\n";
    } elsif ( defined($main::opt_verbose) or defined($main::verbose) ) {
        print "INFO: $string\n";
    } elsif ( defined($main::opt_quiet) or defined($main::quiet) ) {
        # Don't do anything when asked to be quiet
    } else {
        if ( defined($main::daemon) ) {
            syslog(LOG_INFO, "$string");
        } else {
            print "$string\n";
        }
    }

    if ( defined($main::daemon) ) {
        closelog;
    }

    return();
}

sub
dprint($)
{
    my $string           = shift;
    my $f                = ();
    my $l                = ();
    my $s                = ();

    if ( defined($main::daemon) ) {
        return();
    }

    chomp($string);

    if ( defined($main::debug)) {
        (undef, undef, undef, $s) = caller(1);
        if (!defined($s)) {
            $s = "MAIN";
        }
        (undef, $f, $l) = caller(0);
        $f =~ s/^.*\/([^\/]+)$/$1/;
        $s =~ s/\w+:://g;
        $s .= "()" if ($s =~ /^\w+$/);
        $f = "" if (!defined($f));
        $l = "" if (!defined($l));
        $s = "" if (!defined($s));
        print STDERR "DEBUG   [$f/$l/$s]: $string\n";
    }

    return();
}

1;
