
#
# Copyright (c) 2006-2008, Greg M. Kurtzer, Arthur A. Stevens and
# Infiscale, Inc. All rights reserved
#


package Perceus::Nodes;
use strict;
use warnings;

BEGIN {

   use Exporter;

   our @ISA = ('Exporter');

   our @EXPORT = qw (
        &list_node_by_hostname
        &nodename2nodeid
        &nodeid2nodename
        &next_nodename
        &sortnodeids
        &nodescriptlist
        &node_add
        &node_delete
   );

   require "/etc/perceus/Perceus_Include.pm";
   push(@INC, "$Perceus_Include::libdir");

}

use Perceus::Util;
use Perceus::Debug;
use Perceus::Config;
use Perceus::DB;
use Perceus::Vnfs;
use File::Path;
use File::Basename;
use Fcntl qw(:DEFAULT :flock);

sub
node_delete(@)
{
    &dprint("Entered Function");

    my @nodeids         = @_;

    my %db              = ();
    my $count           = 0;
    my @databases       = &list_databases();

    foreach my $db ( @databases ) {
        $db{"$db"} = &opendb($db, O_RDWR);
    }

    foreach my $nodeid ( @nodeids ) {
        foreach my $db ( @databases ) {
            &dprint("Deleting '$nodeid' from Perceus database: '$db'");
            $db{"$db"}->delete($nodeid);
        }
        $count++;
    }

    &dprint("Returning function with: $count");
    return($count);
}

sub
node_add(@)
{
    my $nodeid          = shift;
    my $nodename        = shift || "";

    my %db              = ();
    my $added_name      = ();
    my $no_vnfs_err     = ();
    my %defaults        = &parse_config("/etc/perceus/defaults.conf");
    my @databases       = qw(hostname group vnfs enabled debug);

    if ( exists($defaults{"Vnfs Name"}[0]) and ! &vnfs_exists($defaults{"Vnfs Name"}[0]) ) {
        # If the VNFS does not exist, don't set it!
        $defaults{"Vnfs Name"}[0] = "";

        if ( ! $no_vnfs_err ) {
            &wprint("defaults.conf points to a non-existant VNFS!");
            $no_vnfs_err = 1;
        }
    }

    # Only match against proper MAC/HW addresses. The first byte is used to
    # define the string, and "01" is the hardware address.
    if ( $nodeid =~ /^(01:)?([0-9a-z]{2}:){5}[0-9a-z]{2}$/i ) {

        # As mentioned above, remove the MAC address type identifier if it
        # exists.
        $nodeid =~ s/^01://g;

        # We always capitalize incoming node IDs from ARP table, so treat manually-added
        # IDs the same.  Otherwise auto-added MAC addresses will fail to match manually-added
        # ones simply because of capitalization.  That would be a bummer.
        $nodeid = uc($nodeid);

        foreach my $db ( @databases ) {
            $db{"$db"} = &opendb($db, O_RDWR);
        }

        my %nodeids         = $db{"hostname"}->hash_keys();

        if ( ! exists($nodeids{"$nodeid"}) ) {
            if ( ! $nodename) {
                $nodename = &next_nodename($db{"hostname"});
            }
            foreach my $db ( @databases ) {
                if ( $db eq "hostname" ) {
                    $db{"$db"}->set($nodeid, $nodename);
                } elsif ( $db eq "group" ) {
                    $db{"$db"}->set($nodeid, $defaults{"Group Name"}[0]);
                } elsif ( $db eq "vnfs" ) {
                    $db{"$db"}->set($nodeid, $defaults{"Vnfs Name"}[0]);
                } elsif ( $db eq "enabled" ) {
                    $db{"$db"}->set($nodeid, $defaults{"Enabled"}[0]);
                } elsif ( $db eq "debug" ) {
                    $db{"$db"}->set($nodeid, $defaults{"Debug"}[0]);
                } else {
                    $db{"$db"}->set($nodeid, undef);
                }
            }
            $added_name = $nodename;
            &write_ethers($db{"hostname"});

        } else {
            &eprint("NodeID '$nodeid' already exists as node '$nodeids{$nodeid}'\n");
        }
        foreach my $db ( @databases ) {
            $db{"$db"}->closedb();
        }
    } else {
        &eprint("You must define the Node's ID (MAC/HW address format) to add the node!");
    }

    return($added_name);
}




sub
next_nodename($)
{

    my $db              = shift();
    my %defaults        = &parse_config("/etc/perceus/defaults.conf");
    my $startnum        = ();
    my $totalnum        = ();
    my $newnodename     = ();
    my $nameprefix      = ();
    my $namenum         = ();
    my $namesuffix      = ();

    my %nodes           = $db->hash_values();

    if ( defined $defaults{"First Node"}[0] ) {
        $startnum = $defaults{"First Node"}[0];
    }

    if ( $defaults{"Node Name"}[0] =~ /^([^#]+)([#]+)([^#]*)$/ ) {
        $nameprefix = $1;
        $namenum = length($2);
        $namesuffix = $3;
    } else {
        $nameprefix = "n";
        $namenum = "4";
        $namesuffix = ""
    }

    if ( defined $defaults{"Total Nodes"}[0] ) {
        $totalnum = $defaults{"Total Nodes"}[0] - 1;
    } else {
        $totalnum = sprintf("%d", 9 x $namenum);
    }

    # Find a free nodename. If you need it to check more then 100,000 names,xi
    # let the developers know and we can increase this number.
    for(my $i=$startnum; $i<=$totalnum+$startnum; $i++) {
        my $number = sprintf("%0.${namenum}d", $i);
        $newnodename = "$nameprefix$number$namesuffix";
#        &dprint("Checking for node name: $newnodename");
        if ( ! exists($nodes{"$newnodename"} )) {
            last;
        }
    }

    return($newnodename);
}

sub
list_node_by_hostname
{
    &dprint("Entered function");

    my $db              = shift;
    my @arguments       = @_;
    my @ret             = ();
    my @return          = ();
    my $prefix          = ();
    my $arg             = ();
    my $r1              = ();
    my $r2              = ();
    my $rl1             = ();
    my $rl2             = ();
    my $len             = ();
    my $suffix          = ();
    my @l               = ();
    my $tmp             = ();
    my %seen            = ();

    my @list            = $db->list_values();
    my %nodes           = $db->hash_values();
    my %nodeids         = $db->hash_keys();

    foreach $arg ( @arguments ) {
        if ( $main::opt_nodeid ) {
            if ( exists($nodeids{"$arg"}) ) {
                push(@ret, $arg);
            }
        } elsif ( $arg =~ /^(.*)\[(.+)\](.*)$/ ) {
            $prefix = $1;
            $suffix = $3;
            @l = split(/,/, $2);
            foreach (@l) {
                if ( $_ =~ /^(\d+)-(\d+)$/ ) {
                    $r1 = $1;
                    $r2 = $2;
                    $rl1 = length($r1);
                    $rl2 = length($r2);
                    if ( $rl1 > $rl2 ) {
                        $len = $rl1;
                    } else {
                        $len = $rl2;
                    }
                    for(;$r1<=$r2;$r1++) {
                        $tmp = sprintf("%s%.${len}d%s", $prefix, $r1, $suffix);
                        if ( exists($nodes{"$tmp"}) ) {
                            push(@ret, $tmp);
                        } else {
                            &wprint("Requested node '$tmp' does not exist!\n");
                        }
                    }
                } elsif ( $_ =~ /^(\d+)$/ ) {
                    $len = length($_);
                    $tmp = sprintf("%s%.${len}d%s", $prefix, $_, $suffix);
                    if ( exists($nodes{"$tmp"}) ) {
                        push(@ret, $tmp);
                    } else {
                        &wprint("Requested node '$tmp' does not exist!\n");
                    }
                }
            }
        } elsif ( $arg =~ /[\*|\?]/ ) {
            $arg =~ s/([^\.]?)\*/$1.*/g;
            $arg =~ s/\?/./g;
            push(@ret, grep(/^$arg$/, @list));
        } else {
            if ( exists($nodes{"$arg"}) ) {
                push(@ret, $arg);
            } else {
                &wprint("Requested node '$arg' does not exist!\n");
            }
        }
    }

    # Just in case we got any dups, here we only show unique values (looks
    # weird, but fast)
    @seen{@ret} = ();
    @return = keys %seen;

    if ( @return ) {
        &dprint("Returning function with: @return");
    } else {
        &dprint("Returning function undefined");
    }

    return(@return);
}

sub
nodename2nodeid
{
    &dprint("Entered function");

    my $db              = shift;
    my @arguments       = @_;
    my %nodes           = ();
    my @return          = ();

    if ( $main::opt_nodeid ) {
        # return list of nodeids from list of nodeids
        @return             = @arguments;
    } else {
        # convert list of hostnames to nodeid's
        %nodes              = $db->hash_values();
        @return             = @nodes{sort @arguments};
    }

    return(@return);
}

sub
nodeid2nodename
{
    &dprint("Entered function");

    my $db              = shift;
    my @arguments       = @_;

    my %nodes           = $db->hash_keys();
    my @return          = @nodes{sort @arguments};

    return(@return);
}

sub
sortnodeids
{
    &dprint("Entered function");

    my $db              = shift;
    my @arguments       = @_;
    my @nodeids         = ();

    our %sort            = $db->hash_keys();

    sub sort_function {
       if ( $a and $b ) {
          if ( exists($sort{$a}) and exists($sort{$b}) ) {
             $sort{$a} cmp $sort{$b};
          } elsif ( exists($sort{$a}) ) {
             return(-1);
          } elsif ( exists($sort{$b}) ) {
             return(1);
          } else {
             return(0);
          }
       } elsif ( $a ) {
          return(-1);
       } elsif ( $b ) {
          return(1);
       } else {
          return(0);
       }
    }

    foreach my $nodeid ( sort sort_function @arguments ) {
        push(@nodeids, $nodeid);
    }

    return(@nodeids);
}


sub nodescriptlist {
   &dprint("Entered function");

   my $NodeName         = shift;
   my $State            = shift || "";
   my $Group            = shift || "";
   my $Vnfs             = shift || "";
   my @scripts          = ();
   my @return           = ();
   my $tmp              = ();
   my %ret              = ();

   $Vnfs =~ s/\s+//g;
   $Group =~ s/\s+//g;
   $NodeName =~ s/\s+//g;
   if ( ! $NodeName ) {
      &wprint("nodescriptlist called without a NodeName");
   }
   if ( ! $State ) {
      &wprint("nodescriptlist called without a State");
   }
   if ( -d "$Perceus_Include::statedir/nodescripts/$State/vnfs/$Vnfs/" ) {
      push(@scripts, sort glob("$Perceus_Include::statedir/nodescripts/$State/vnfs/$Vnfs/*"));
   } else {
      mkpath("$Perceus_Include::statedir/nodescripts/$State/vnfs/$Vnfs/");
   }
   if ( -d "$Perceus_Include::statedir/nodescripts/$State/all/" ) {
      push(@scripts, sort glob("$Perceus_Include::statedir/nodescripts/$State/all/*"));
   } else {
      mkpath("$Perceus_Include::statedir/nodescripts/$State/all/");
   }
   if ( -d "$Perceus_Include::statedir/nodescripts/$State/group/$Group/" and defined($Group) ) {
      push(@scripts, sort glob("$Perceus_Include::statedir/nodescripts/$State/group/$Group/*"));
   } else {
      mkpath("$Perceus_Include::statedir/nodescripts/$State/group/$Group/");
   }
   if ( -d "$Perceus_Include::statedir/nodescripts/$State/node/$NodeName/" ) {
      push(@scripts, sort glob("$Perceus_Include::statedir/nodescripts/$State/node/$NodeName/*"));
   } else {
      mkpath("$Perceus_Include::statedir/nodescripts/$State/node/$NodeName/");
   }

   foreach my $nodescript (@scripts) {
      if ( -d "$nodescript" ) {
         next;
      }
      if ( $nodescript =~ /~$/ ) {
         next;
      }
      $tmp = basename("$nodescript");
      $ret{"$tmp"} = $nodescript;
   }

   foreach my $scriptname ( sort keys %ret ) {
      push(@return, $ret{"$scriptname"});
   }

   if ( @return ) {
       &dprint("Returning function with: @return");
   } else {
       &dprint("Returning function undefined");
   }
   return(@return);
}




1;
