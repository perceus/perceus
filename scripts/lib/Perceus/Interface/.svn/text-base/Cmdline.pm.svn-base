
#
# Copyright (c) 2006-2008, Greg M. Kurtzer, Arthur A. Stevens and
# Infiscale, Inc. All rights reserved
#


package Perceus::Interface::Cmdline;
use strict;
use warnings;

BEGIN {

    use Exporter;

    our @ISA = ('Exporter');

    our @EXPORT = qw (
        &UI_NodeList
        &UI_NodeStatus
        &UI_NodeDelete
        &UI_NodeAdd
        &UI_NodeSet
        &UI_NodeShow
        &UI_NodeSummary
        &UI_NodeReplace
        &UI_GroupDelete
        &UI_GroupList
        &UI_GroupNodelist
        &UI_GroupSet
        &UI_GroupStatus
        &UI_GroupSummary
        &UI_GroupShow
        &UI_VnfsClone
        &UI_VnfsList
        &UI_VnfsMount
        &UI_VnfsUmount
        &UI_VnfsClose
        &UI_VnfsConfigure
        &UI_VnfsDelete
        &UI_VnfsImport
        &UI_VnfsExport
        &UI_VnfsLivesync
        &UI_VnfsRebuild
        &UI_ModuleList
        &UI_ModuleImport
        &UI_ModuleSummary
        &UI_ModuleStates
        &UI_ModuleEnable
        &UI_ModuleDisable
        &UI_ModuleDelete
        &UI_About
        &UI_Config
        &UI_System
        &UI_Init
        &UI_InitDB
        &UI_ConfigureApache
        &UI_ConfigureNfs
        &UI_ConfigureSshKeys
        &UI_ConfigureDhcpd
        &UI_ConfigureHosts
        &UI_ContactSupport
        &UI_ContactRegister
    );

    require "/etc/perceus/Perceus_Include.pm";
    push(@INC, "$Perceus_Include::libdir");

}

use Perceus::Util;
use Perceus::Debug;
use Perceus::Nodes;
use Perceus::DB;
use Perceus::Groups;
use Perceus::Vnfs;
use Perceus::Modules;
use Perceus::About;
use Perceus::Config;
use Perceus::Configure;
use Perceus::System;
use Perceus::Contact;
use File::Basename;
use Fcntl;

sub
UI_NodeList(@)
{
    &dprint("Entered function");

    my @nodes            = @_;
    my $retval           = 0;
    my @list             = ();
    my $db               = &opendb("hostname");

    if ( ! defined($nodes[0]) ) {
        push(@nodes, "*");
    }

    @list = &list_node_by_hostname($db, @nodes);

    if ( @list ) {

        foreach my $node ( @list ) {
            print "$node\n";
        }

    } else {

        &wprint("No nodes found");
        $retval = 1;

    }

    $db->closedb();

    &dprint("Returning function with: $retval");
    return($retval);
}

sub
UI_NodeStatus($)
{
    &dprint("Entered function");

    my @arguments       = @_;
    my $retval          = 0;
    my @list            = ();
    my @databases       = qw(hostname group status ipaddr lastcontact);
    my %db              = ();

    foreach my $db ( @databases ) {
        $db{"$db"} = &opendb($db);
    }

    if ( ! defined($arguments[0]) ) {
        push(@arguments, "*");
    }

    @list = &nodename2nodeid($db{"hostname"}, &list_node_by_hostname($db{"hostname"}, @arguments));

    if ( @list ) {

        &iprint("HostName             Status         IP Address             Last Contact\n");
        &iprint("-------------------------------------------------------------------------------\n");

        foreach my $nodeid (&sortnodeids($db{"group"}, @list)) {
            my $contact = $db{"lastcontact"}->get($nodeid);
            my $ipaddr = $db{"ipaddr"}->get($nodeid);
            my $status = $db{"status"}->get($nodeid);
            if ( $contact ) {
                $contact = &time_h(time() - $contact);
            } else {
                $contact = "(undefined)";
            }
            if ( $ipaddr ) {
                $ipaddr = &bin2addr($ipaddr);
            } else {
                $ipaddr = "(undefined)";
            }
            if ( ! $status ) {
                $status = "(undefined)";
            }
            printf("%-20.20s %-14.14s %-22.22s %-17.17s\n",
                $db{"hostname"}->get($nodeid),
                $status,
                $ipaddr,
                $contact,
            );
        }

    } else {

        &wprint("No nodes found");
        $retval = 1;

    }

    foreach my $db ( @databases ) {
        $db{"$db"}->closedb();
    }

    return($retval);
}

sub
UI_NodeDelete(@)
{

    &dprint("Entered function");

    my @arguments       = @_;
    my $retval          = 0;
    my $count           = 0;
    my @list            = ();
    my %db              = ();

    my @databases       = &list_databases();

    foreach my $db ( @databases ) {
        $db{"$db"} = &opendb($db, O_RDWR);
    }

    my @nodeids = &nodename2nodeid($db{"hostname"}, &list_node_by_hostname($db{"hostname"}, @arguments));

    foreach my $nodeid ( &sortnodeids($db{"group"}, @nodeids) ) {
        my $show = sprintf("%-20s %-20s %s",
            $db{"hostname"}->get("$nodeid") || "(undefined)",
            $db{"group"}->get("$nodeid")    || "(undefined)",
            $nodeid
        );
        push(@list, $show);
    }

    if ( @list ) {

        &iprint("   Hostname             Group                NodeID");
        &iprint("-------------------------------------------------------------------------------\n");

        my $message = "Are you sure you wish to delete ". scalar(@nodeids) ." nodes from Perceus?";
        if ( &confirm_list($message, @list)) {
            $count = &node_delete(@nodeids);
            print "'$count' nodes have been deleted\n";
        }

    } else {

        &wprint("No nodes found\n");
        $retval = 1;

    }

    foreach my $db ( @databases ) {
        $db{"$db"}->closedb();
    }

    &dprint("Returning function with: $retval");
    return($retval);

}

sub
UI_NodeAdd(@)
{
    my $nodeid          = shift;
    my $nodename        = shift || "";

    my $retval          = 0;

    if ( $nodeid ) {
        $nodename           = &node_add($nodeid, $nodename);
        if ( $nodename ) {
            &iprint("Node '$nodename' has been added to Perceus");
        } else {
            &eprint("Node not added to database");
            $retval ++;
        }
    } else {
        &eprint("USAGE: $0 node add [NODE ID]");
    }

    return($retval);
}

sub
UI_NodeSet(@)
{

    &dprint("Entered function");

    my $Set             = shift;
    my $Value           = shift;
    my @arguments       = @_;
    my $retval          = 0;
    my $count           = 0;
    my @list            = ();
    my %db              = ();
    my $message         = ();

    my @databases       = &list_databases();

   if ( $Set =~ /(.+)=(.+)/ ) {
      &wprint("Rewriting obsolete syntax (group=value)\n");
      push(@arguments, $Value);
      $Set = $1;
      $Value = $2;
   }

    if ( ! defined($Set) or ! defined($Value) ) {
        &eprint("USAGE: node set [key] [value] [node(s)...]", 1);
        $retval = 255;

    } else {
        if ( lc($Set) eq "status" or
             lc($Set) eq "ipaddr" or
             lc($Set) eq "lastcontact" ) {

            $message .= "\nWARNING: This database field is used for logging by the Perceus daemon. Setting\n";
            $message .= "it to a value won't have any affect on the node itself and will be overwritten.\n\n";

        }

        if ( $Set eq "vnfs" ) {
            if ( ! &vnfs_exists("$Value") ) {
                &eprint("VNFS '$Value' does not exist!");
                exit 1;
            }
        }

        foreach my $db ( @databases ) {
            $db{"$db"} = &opendb($db, O_RDWR);
        }

        my @nodeids = &nodename2nodeid($db{"hostname"}, &list_node_by_hostname($db{"hostname"}, @arguments));

        foreach my $nodeid ( @nodeids ) {
            my $show = sprintf("%-20s %-20s %s",
                $db{"hostname"}->get("$nodeid") || "(undefined)",
                $db{"group"}->get("$nodeid")    || "(undefined)",
                $nodeid
            );
            push(@list, $show);
        }

        if ( $#list >= 0 ) {
            &iprint("   Hostname             Group                NodeID");
            &iprint("-------------------------------------------------------------------------------\n");

            $Set = lc($Set);
            $message .= "Are you sure you wish to set '$Set=$Value' on #COUNT# nodes?";
            if ( &confirm_list($message, @list)) {
                foreach my $nodeid ( @nodeids ) {
                    if ( $Set eq "boot" ) {
                        if ( &pxenodeconf($Value, $nodeid) ) {
                            $count++;
                        }
                    } else {
                        if ( exists($db{"$Set"}) ) {
                            $db{"$Set"}->set($nodeid, $Value);
                            $count++;
                        }
                    }
                }
                print "'$count' nodes set $Set='$Value'\n";
            }
        } else {
            &wprint("No nodes found\n");
            $retval = 1;
        }

        foreach my $DB ( @databases ) {
            $db{"$DB"}->closedb();
        }

    }

    &dprint("Returning function with: $retval");
    return($retval);

}

sub
UI_NodeShow(@)
{
    &dprint("Entered function");

    my @arguments       = @_;
    my $retval          = 0;
    my @list            = ();
    my @nodes           = ();
    my %db              = ();

    if ( ! defined($arguments[0]) ) {
        push(@arguments, "*");
    }

    my @databases       = &list_databases();

    foreach my $DB ( @databases ) {
        $db{"$DB"} = &opendb($DB);
    }

    @list = &nodename2nodeid($db{"hostname"}, &list_node_by_hostname($db{"hostname"}, @arguments));

    if ( @list ) {

        foreach my $nodeid (&sortnodeids($db{"group"}, @list)) {
            my $node = $db{"hostname"}->get($nodeid) || "";
            print "$node: nodeid=$nodeid\n";
            foreach my $DB ( @databases ) {
                print "$node: $DB=". $db{"$DB"}->get($nodeid) ."\n";
            }
        }

    } else {

        &wprint("No nodes found");
        $retval = 1;

    }

    foreach my $DB ( @databases ) {
        $db{"$DB"}->closedb();
    }


    &dprint("Returning function with: $retval");
    return($retval);
}

sub
UI_NodeSummary($)
{
    &dprint("Entered function");

    my @arguments       = @_;
    my $retval          = 0;
    my @list            = ();
    my $enabled         = ();
    my %db              = ();
    my @databases       = qw(hostname group enabled vnfs);

    foreach my $DB ( @databases ) {
        $db{"$DB"} = &opendb($DB);
    }

    if ( ! defined($arguments[0]) ) {
        push(@arguments, "*");
    }

    @list = &nodename2nodeid($db{"hostname"}, &list_node_by_hostname($db{"hostname"}, @arguments));

    if ( @list ) {

        &iprint("HostName             GroupName    Enabled   Vnfs\n");
        &iprint("-------------------------------------------------------------------------------\n");

        foreach my $nodeid (&sortnodeids($db{"group"}, @list)) {
            if ( $db{"enabled"}->get($nodeid) eq "1" ) {
                $enabled = "yes";
            } else {
                $enabled = "no";
            }
            printf("%-20.20s %-16.16s %-3.3s   %s\n",
                $db{"hostname"}->get($nodeid) || "(undefined)",
                $db{"group"}->get($nodeid) || "(undefined)",
                $enabled,
                $db{"vnfs"}->get($nodeid) || "(undefined)",
            );
        }

    } else {

        &wprint("No nodes found");
        $retval = 1;

    }

    foreach my $DB ( @databases ) {
        $db{"$DB"}->closedb();
    }

    return($retval);
}

sub
UI_NodeReplace(@)
{

    &dprint("Entered function");

    my $oldnode         = shift;
    my $newnode         = shift;
    my $retval          = 0;
    my %db              = ();
    my $yes             = ();
    my @list            = ();

    my @databases       = &list_databases();

    foreach my $db ( @databases ) {
        $db{"$db"} = &opendb($db, O_RDWR);
    }

    my $oldnodeid       = $db{"hostname"}->get_key($oldnode);
    my $newnodeid       = $db{"hostname"}->get_key($newnode);

    if ( ! $oldnodeid ) {
        &eprint("Could not identify node to replace: $oldnode\n");
    }
    if ( ! $newnodeid ) {
        &eprint("Could not identify replacement node: $newnode\n");
    }

    push(@list, sprintf("%-20s %-20s %s",
        $db{"hostname"}->get("$oldnodeid")  || "(undefined)",
        $db{"group"}->get("$oldnodeid")     || "(undefined)",
        $oldnodeid
    ));
    push(@list, sprintf("%-20s %-20s %s",
        $db{"hostname"}->get("$newnodeid")  || "(undefined)",
        $db{"group"}->get("$newnodeid")     || "(undefined)",
        $newnodeid
    ));

    &iprint("   Hostname             Group                NodeID");
    &iprint("-------------------------------------------------------------------------------\n");

    my $message = "Are you sure you wish to replace '$oldnode' with '$newnode'?";
    if ( &confirm_list($message, @list)) {
        foreach my $DB ( @databases ) {
            $db{"$DB"}->set($newnodeid, $db{"$DB"}->get($oldnodeid));
            &dprint("Copied Database ($DB) configuration from $oldnodeid to $newnodeid");
            $db{"$DB"}->delete($oldnodeid);
            &dprint("Deleted Database ($DB) entry for $oldnodeid");
        }
        &iprint("Node '$oldnode' has been replaced.");
    }


    foreach my $db ( @databases ) {
        $db{"$db"}->closedb();
    }

    &dprint("Returning function with: $retval");
    return($retval);
}

sub
UI_GroupDelete(@)
{
    &dprint("Entered function");

    my @arguments       = @_;
    my $retval          = 0;
    my $count           = 0;
    my @list            = ();
    my %db              = ();

    my @databases       = &list_databases();

    foreach my $db ( @databases ) {
        $db{"$db"} = &opendb($db, O_RDWR);
    }

    my @nodeids = &groupname2nodeid($db{"group"}, @arguments);

    foreach my $nodeid ( &sortnodeids($db{"group"}, &sortnodeids($db{"hostname"}, @nodeids)) ) {
        my $show = sprintf("%-20s %-20s %s",
            $db{"hostname"}->get("$nodeid") || "(undefined)",
            $db{"group"}->get("$nodeid")    || "(undefined)",
            $nodeid
        );
        push(@list, $show);
    }

    if ( @list ) {

        &iprint("   Hostname             Group                NodeID");
        &iprint("-------------------------------------------------------------------------------\n");

        my $message = "Are you sure you wish to delete ". scalar(@nodeids) ." nodes from Perceus?";
        if ( &confirm_list($message, @list)) {
            foreach my $nodeid ( @nodeids ) {
                foreach my $db ( @databases ) {
                    $db{"$db"}->delete($nodeid);
                }
                $count++;
            }
            print "'$count' nodes have been deleted\n";
        }

    } else {

        &wprint("No nodes found\n");
        $retval = 1;

    }

    foreach my $db ( @databases ) {
        $db{"$db"}->closedb();
    }

    &dprint("Returning function with: $retval");
    return($retval);

}
sub
UI_GroupList(@)
{
    &dprint("Entered function");

    my @groups          = @_;
    my $retval          = 0;
    my @list            = ();
    my %db              = ();

    $db{"group"}        = &opendb("group");

    @list = $db{"group"}->list_unique_values();

    if ( @list ) {

        foreach my $group (sort @list) {
            print "$group\n";
        }

    } else {

        &wprint("No groups found");
        $retval = 1;

    }

    $db{"group"}->closedb();

    &dprint("Returning function with: $retval");
    return($retval);
}


sub
UI_GroupNodelist(@)
{
    &dprint("Entered function");

    my @groups          = @_;
    my $retval          = 0;
    my @list            = ();
    my %db              = ();

    $db{"hostname"}     = &opendb("hostname");
    $db{"group"}        = &opendb("group");

    my %groups          = $db{"group"}->hash_keys();

    if ( %groups ) {

        my @groups = keys %groups;
        my $lastgroup = "";

        foreach my $nodeid (&sortnodeids($db{"group"}, &sortnodeids($db{"hostname"}, @groups))) {
            my $group = $groups{"$nodeid"} || "(undefined)";
            my $node = $db{"hostname"}->get($nodeid) || "(undefined)";
            unless ( $group eq $lastgroup ) {
                print "$group:\n";
            }
            print "   $node\n";
            $lastgroup = $group;
        }

    } else {

        &wprint("No nodes found");
        $retval = 1;

    }

    $db{"hostname"}->closedb();
    $db{"group"}->closedb();

    &dprint("Returning function with: $retval");
    return($retval);
}

sub
UI_GroupSet(@)
{

    &dprint("Entered function");

    my $Set             = shift;
    my $Value           = shift;
    my @arguments       = @_;
    my $retval          = 0;
    my $count           = 0;
    my @list            = ();
    my %db              = ();
    my $message         = ();

    my @databases       = &list_databases();

   if ( $Set =~ /(.+)=(.+)/ ) {
      &wprint("Rewriting obsolete syntax (group=value)\n");
      push(@arguments, $Value);
      $Set = $1;
      $Value = $2;
   }

    if ( ! defined($Set) or ! defined($Value) ) {
        &eprint("USAGE: node set [key] [value] [node(s)...]", 1);
        $retval = 255;

    } else {

        if ( lc($Set) eq "status" or
             lc($Set) eq "ipaddr" or
             lc($Set) eq "lastcontact" ) {

            $message .= "\nWARNING: This database field is used for logging by the Perceus daemon. Setting\n";
            $message .= "it to a value won't have any affect on the node itself and will be overwritten.\n\n";

        }

        if ( $Set eq "vnfs" ) {
            if ( ! &vnfs_exists("$Value") ) {
                &eprint("That VNFS image name does not exist!");
                exit 1;
            }
        }

        foreach my $db ( @databases ) {
            $db{"$db"} = &opendb($db, O_RDWR);
        }

        my @nodeids = &groupname2nodeid($db{"group"}, @arguments);

        foreach my $nodeid ( @nodeids ) {
            my $show = sprintf("%-20s %-20s %s",
                $db{"hostname"}->get("$nodeid") || "(undefined)",
                $db{"group"}->get("$nodeid")    || "(undefined)",
                $nodeid
            );
            push(@list, $show);
        }

        if ( $#list >= 0 ) {
            &iprint("   Hostname             Group                NodeID");
            &iprint("-------------------------------------------------------------------------------\n");

            $Set = lc($Set);
            $message .= "Are you sure you wish to set '$Set=$Value' on #COUNT# nodes?";
            if ( &confirm_list($message, @list)) {
                foreach my $nodeid ( @nodeids ) {
                    if ( $Set eq "boot" ) {
                        if ( &pxenodeconf($Value, $nodeid) ) {
                            $count++;
                        }
                    } else {
                        if ( exists($db{"$Set"}) ) {
                            $db{"$Set"}->set($nodeid, $Value);
                            $count++;
                        }
                    }
                }
                print "'$count' nodes set $Set='$Value'\n";
            }
        } else {
            &wprint("No nodes found\n");
            $retval = 1;
        }

        foreach my $DB ( @databases ) {
            $db{"$DB"}->closedb();
        }

    }

    &dprint("Returning function with: $retval");
    return($retval);

}

sub
UI_GroupStatus($)
{
    &dprint("Entered function");

    my @arguments       = @_;
    my $retval          = 0;
    my @list            = ();
    my %db              = ();
    my @databases       = qw(hostname group status ipaddr lastcontact);

    foreach my $db ( @databases ) {
        $db{"$db"} = &opendb($db, O_RDWR);
    }

    @list = &groupname2nodeid($db{"group"}, @arguments);

    if ( @list ) {

        &iprint("HostName             Status         IP Address             Last Contact\n");
        &iprint("-------------------------------------------------------------------------------\n");

        foreach my $nodeid (&sortnodeids($db{"group"}, &sortnodeids($db{"hostname"}, @list)) ) {
            my $contact = $db{"lastcontact"}->get($nodeid);
            my $ipaddr = $db{"ipaddr"}->get($nodeid);
            my $status = $db{"status"}->get($nodeid);
            if ( $contact ) {
                $contact = &time_h(time() - $contact);
            } else {
                $contact = "(undefined)";
            }
            if ( $ipaddr ) {
                $ipaddr = &bin2addr($ipaddr);
            } else {
                $ipaddr = "(undefined)";
            }
            if ( ! $status ) {
                $status = "(undefined)";
            }
            printf("%-20.20s %-14.14s %-22.22s %-17.17s\n",
                $db{"hostname"}->get($nodeid),
                $status,
                $ipaddr,
                $contact,
            );
        }

    } else {

        &wprint("No nodes found");
        $retval = 1;

    }

    foreach my $db ( @databases ) {
        $db{"$db"}->closedb();
    }

    return($retval);
}

sub
UI_GroupSummary($)
{
    &dprint("Entered function");

    my @arguments       = @_;
    my $retval          = 0;
    my @list            = ();
    my $enabled         = ();
    my %db              = ();
    my @databases       = qw(hostname group enabled vnfs);

    foreach my $DB ( @databases ) {
        $db{"$DB"} = &opendb($DB);
    }

    @list = &groupname2nodeid($db{"group"}, @arguments);

    if ( @list ) {

        &iprint("HostName             GroupName    Enabled   Vnfs\n");
        &iprint("-------------------------------------------------------------------------------\n");

        foreach my $nodeid (&sortnodeids($db{"group"}, &sortnodeids($db{"hostname"}, @list)) ) {
            if ( $db{"enabled"}->get($nodeid) eq "1" ) {
                $enabled = "yes";
            } else {
                $enabled = "no";
            }
            printf("%-20.20s %-16.16s %-3.3s   %s\n",
                $db{"hostname"}->get($nodeid) || "(undefined)",
                $db{"group"}->get($nodeid) || "(undefined)",
                $enabled,
                $db{"vnfs"}->get($nodeid) || "(undefined)",
            );
        }

    } else {

        &wprint("No nodes found");
        $retval = 1;

    }

    foreach my $DB ( @databases ) {
        $db{"$DB"}->closedb();
    }

    return($retval);
}

sub
UI_GroupShow(@)
{
    &dprint("Entered function");

    my @arguments       = @_;
    my $retval          = 0;
    my @list            = ();
    my @nodes           = ();
    my %db              = ();

    if ( ! defined($arguments[0]) ) {
        push(@arguments, "*");
    }

    my @databases       = &list_databases();

    foreach my $DB ( @databases ) {
        $db{"$DB"} = &opendb($DB);
    }


    @list = &groupname2nodeid($db{"group"}, @arguments);

    if ( @list ) {

        foreach my $nodeid (&sortnodeids($db{"group"}, &sortnodeids($db{"hostname"}, @list)) ) {
            my $node = $db{"hostname"}->get($nodeid);
            print "$node: nodeid=$nodeid\n";
            foreach my $DB ( @databases ) {
                print "$node: $DB=". $db{"$DB"}->get($nodeid) ."\n";
            }
        }

    } else {

        &wprint("No nodes found");
        $retval = 1;

    }

    foreach my $DB ( @databases ) {
        $db{"$DB"}->closedb();
    }


    &dprint("Returning function with: $retval");
    return($retval);
}


sub
UI_VnfsClone(@)
{
    &dprint("Entered function");

    my $Vnfs_orig           = shift;
    my $Vnfs_clone          = shift;
    my $vnfs_orig_untainted = ();
    my $vnfs_clone_untainted = ();
    my $retval              = 0;

    if ( ! $Vnfs_orig or ! $Vnfs_clone ) {
        &eprint("USAGE: perceus vnfs clone [source name] [copy name]");
        return(1);
    }

    if ( $Vnfs_orig =~ /^([a-zA-Z0-9\-_\.]+)$/ ) {
        $vnfs_orig_untainted = $1;
        &dprint("Untaintained vnfs_orig_untainted: $vnfs_orig_untainted");
    } else {
        &eprint("VNFS original name contains illegal characters!");
        exit 1;
    }

    if ( $Vnfs_clone =~ /^([a-zA-Z0-9\-_\.]+)$/ ) {
        $vnfs_clone_untainted = $1;
        &dprint("Untaintained vnfs_clone_untainted: $vnfs_clone_untainted");
    } else {
        &eprint("VNFS clone name contains illegal characters!");
        exit 1;
    }

    if ( -d "$Perceus_Include::statedir/vnfs/$vnfs_clone_untainted" ) {
        &eprint("Can not overwrite an existing VNFS ('$vnfs_clone_untainted')");
        return(1);
    }

    &iprint("Creating a working VNFS copy '$vnfs_orig_untainted' to '$vnfs_clone_untainted'...");

    $retval += &vnfs_clone($vnfs_orig_untainted, $vnfs_clone_untainted);

    return($retval);

}

sub
UI_VnfsList(@)
{
    &dprint("Entered function");

    my @arguments           = @_;
    my $retval              = 0;

    foreach my $vnfs ( sort &vnfs_list(@arguments) ) {
        if ( &vnfs_mounted($vnfs)) {
            print "$vnfs (mounted)\n";
        } else {
            print "$vnfs\n";
        }
    }

    return($retval);

}

sub
UI_VnfsMount($)
{
    &dprint("Entered function");

    my $vnfs                = shift;
    my $vnfs_name           = ();
    my $retval              = 0;

    if ( ! $vnfs ) {
        &eprint("USAGE=> perceus vnfs mount [vnfs name]");
        return(1);
    }

    if ( $vnfs =~ /^([a-zA-Z0-9\-_\.]+)$/ ) {
        $vnfs_name = $1;
        &dprint("Untaintained vnfs_name: $vnfs_name");
    } else {
        &eprint("VNFS name contains illegal characters!");
        exit 1;
    }

    if ( ! &vnfs_exists("$vnfs_name") ) {
        &eprint("VNFS '$vnfs' does not exist!");
        return(1);
    }

    if ( &vnfs_mounted($vnfs_name) ) {
        &eprint("VNFS '$vnfs' is already mounted!");
        return(1);
    }

    $retval += &vnfs_mount($vnfs_name);

    return($retval);
}

sub
UI_VnfsUmount($)
{
    &dprint("Entered function");

    my $vnfs                = shift;
    my $vnfs_name           = ();
    my $retval              = 0;

    if ( ! $vnfs ) {
        &eprint("USAGE: perceus vnfs umount [vnfs name]");
        return(1);
    }

    if ( $vnfs =~ /^([a-zA-Z0-9\-_\.\/]+)$/ ) {
        $vnfs_name = $1;
        &dprint("Untaintained vnfs_name: $vnfs_name");
    } else {
        &eprint("VNFS name contains illegal characters!");
        exit 1;
    }

    if ( ! &vnfs_exists("$vnfs_name") ) {
        &eprint("VNFS '$vnfs' does not exist!");
        return(1);
    }

    if ( ! &vnfs_mounted($vnfs_name) ) {
        &eprint("VNFS '$vnfs' is not mounted!");
        return(1);
    }

    $retval += &vnfs_umount($vnfs_name);

    if ( $retval == 0 ) {
        &iprint("VNFS '$vnfs_name' has been successfully un-mounted and updated.");
    } else {
        &iprint("There was an error un-mounting the VNFS '$vnfs_name'!");
    }

    return($retval);
}

sub
UI_VnfsRebuild($)
{
    &dprint("Entered function");

    my $vnfs                = shift;
    my $vnfs_name           = ();
    my $retval              = 0;

    if ( ! $vnfs ) {
        &eprint("USAGE: perceus vnfs rebuild [vnfs name]");
        return(1);
    }

    if ( $vnfs =~ /^([a-zA-Z0-9\-_\.\/]+)$/ ) {
        $vnfs_name = $1;
        &dprint("Untaintained vnfs_name: $vnfs_name");
    } else {
        &eprint("VNFS name contains illegal characters!");
        exit 1;
    }

    if ( ! &vnfs_exists("$vnfs_name") ) {
        &eprint("VNFS '$vnfs' does not exist!");
        return(1);
    }

    if ( &vnfs_mounted($vnfs_name) ) {
        &eprint("VNFS '$vnfs' is already mounted!");
        return(1);
    }

    $retval += &vnfs_mount($vnfs_name);
    if ( $retval == 0 ) {
        $retval += &vnfs_umount($vnfs_name);
    }

    if ( $retval == 0 ) {
        &iprint("VNFS '$vnfs_name' has been successfully rebuilt and updated.");
    } else {
        &iprint("There was an error rebuilding the VNFS '$vnfs_name'!");
    }

    return($retval);
}

sub
UI_VnfsClose($)
{
    &dprint("Entered function");

    my $vnfs                = shift;
    my $vnfs_name           = ();
    my $retval              = 0;

    if ( ! $vnfs ) {
        &eprint("USAGE: perceus vnfs close [vnfs name]");
        return(1);
    }

    if ( $vnfs =~ /^([a-zA-Z0-9\-_\.\/]+)$/ ) {
        $vnfs_name = $1;
        &dprint("Untaintained vnfs_name: $vnfs_name");
    } else {
        &eprint("VNFS name contains illegal characters!");
        exit 1;
    }

    if ( ! &vnfs_exists("$vnfs_name") ) {
        &eprint("VNFS '$vnfs' does not exist!");
        return(1);
    }

    if ( ! &vnfs_mounted($vnfs_name) ) {
        &eprint("VNFS '$vnfs' is not mounted!");
        return(1);
    }

    $retval += &vnfs_close($vnfs_name);

    if ( $retval == 0 ) {
        &iprint("VNFS '$vnfs_name' has been successfully un-mounted.");
    } else {
        &iprint("There was an error un-mounting the VNFS '$vnfs_name'!");
    }


    return($retval);
}

sub
UI_VnfsConfigure($)
{
    &dprint("Entered function");

    my $vnfs                = shift;
    my $vnfs_name           = ();
    my $retval              = 0;

    if ( ! $vnfs ) {
        &eprint("USAGE: perceus vnfs configure [vnfs name]");
        return(1);
    }

    if ( $vnfs =~ /^([a-zA-Z0-9\-_\.]+)$/ ) {
        $vnfs_name = $1;
        &dprint("Untaintained vnfs_name: $vnfs_name");
    } else {
        &eprint("VNFS name contains illegal characters!");
        exit 1;
    }

    if ( ! &vnfs_exists("$vnfs_name") ) {
        &eprint("VNFS '$vnfs' does not exist!");
        return(1);
    }

    if ( &vnfs_mounted($vnfs_name) ) {
        &eprint("VNFS '$vnfs' is mounted!");
        return(1);
    }

    $retval += &vnfs_configure($vnfs_name);

    if ( $retval == 0 ) {
        &iprint("VNFS '$vnfs' has been successfully reconfigured.");
    } else {
        &iprint("There was an error reconfiguring the VNFS '$vnfs'!");
    }


    return($retval);
}

sub
UI_VnfsDelete($)
{
    &dprint("Entered function");

    my $vnfs                = shift;
    my $vnfs_name           = ();
    my $retval              = 0;

    if ( ! $vnfs ) {
        &eprint("USAGE: perceus vnfs delete [vnfs name]");
        return(1);
    }

    if ( $vnfs =~ /^([a-zA-Z0-9\-_\.]+)$/ ) {
        $vnfs_name = $1;
        &dprint("Untaintained vnfs_name: $vnfs_name");
    } else {
        &eprint("VNFS name contains illegal characters!");
        exit 1;
    }

    if ( ! &vnfs_exists("$vnfs_name") ) {
        &eprint("VNFS '$vnfs' does not exist!");
        return(1);
    }

    if ( &vnfs_mounted($vnfs_name) ) {
        &eprint("VNFS '$vnfs' is mounted!");
        return(1);
    }

    my $message = "Are you sure you wish to delete VNFS '$vnfs_name'?";
    if ( &confirm_list($message, $vnfs_name)) {

        $retval += &vnfs_delete($vnfs_name);

        if ( $retval == 0 ) {
            &iprint("VNFS '$vnfs_name' has been successfully deleted.");
        } else {
            &iprint("There was an error deleting the VNFS '$vnfs_name'!");
        }

    }

    return($retval);
}

sub
UI_VnfsImport($)
{
    &dprint("Entered function");

    my $vnfs                = shift;
    my $name                = basename($vnfs);
    my $vnfs_file           = ();
    my $retval              = 0;

    if ( $vnfs =~ /^([a-zA-Z0-9\-_\.\/]+)$/ ) {
        $vnfs_file = $1;
        &dprint("Untaintained vnfs_file: $vnfs_file");
    } else {
        &eprint("VNFS file name contains illegal characters!");
        exit 1;
    }

    if ( ! -f "$vnfs_file" ) {
        &eprint("USAGE: perceus vnfs import [path to VNFS file]");
        return(1);
    }

    if ( $name =~ /^(.+).vnfs$/ ) {
        $name = $1;
        &iprint("Importing '$name'\n");
    } else {
        &eprint("$vnfs is not a valid Perceus VNFS capsule (*.vnfs)");
        return(1);
    }

    if ( &vnfs_exists("$name") ) {
        &eprint("VNFS '$name' is already installed!");
        return(1);
    }

    $retval += &vnfs_import($vnfs_file);

    if ( $retval == 0 ) {
        &iprint("VNFS '$name' has been successfully imported.");
    } else {
        &iprint("There was an error importing the VNFS '$name'!");
    }

    return($retval);
}

sub
UI_VnfsExport(@)
{
    &dprint("Entered function");

    my $vnfs                = shift;
    my $file                = shift;
    my $vnfs_name           = ();
    my $vnfs_file           = ();
    my $retval              = 0;

    if ( ! $vnfs ) {
        &eprint("USAGE: perceus vnfs export [vnfs name] (exported file name)");
        return(1);

    } elsif ( ! $file ) {
        $file = "$ENV{HOME}/vnfs-exports/$vnfs.vnfs";
        &vprint("Export file name not passed, using $file");

    } elsif ( ! $file =~ /.*\.vnfs$/ ) {
        &dprint("appending 'vnfs' suffix to name");
        $file .= ".vnfs";

    }

    if ( $vnfs =~ /^([a-zA-Z0-9\-_\.]+)$/ ) {
        $vnfs_name = $1;
        &dprint("Untaintained vnfs_name: $vnfs_name");
    } else {
        &eprint("VNFS name contains illegal characters!");
        exit 1;
    }

    if ( $file =~ /^([a-zA-Z0-9\-_\.\/]+)$/ ) {
        $vnfs_file = $1;
        &dprint("Untaintained vnfs_file: $vnfs_file");
    } else {
        &eprint("VNFS file name contains illegal characters!");
        exit 1;
    }

    &iprint("Exporting: $vnfs_name");
    &iprint("Creating:  $vnfs_file");

    $retval += &vnfs_export($vnfs_name, $vnfs_file);

    if ( $retval == 0 ) {
        &iprint("VNFS '$vnfs_name' has been successfully exported.");
    } else {
        &iprint("There was an error exporting the VNFS '$vnfs_name'!");
    }

    return($retval);
}

sub
UI_VnfsLivesync(@)
{
    &dprint("Entered function");

    my $vnfs                = shift;
    my @nodes_req           = @_;
    my @nodes               = ();
    my %db                  = ();
    my $retval              = 0;
    my @databases           = qw(hostname vnfs);

    foreach my $db ( @databases ) {
        $db{"$db"} = &opendb($db);
    }

    if ( ! $vnfs ) {
        &eprint("USAGE: perceus vnfs livesync [vnfs name] (list of nodes...)");
        return(1);
    }

    if ( $vnfs =~ /^([a-zA-Z0-9\-_\.]+)$/ ) {
        $vnfs = $1;
        &dprint("Untaintained vnfs name: $vnfs");
    } else {
        &eprint("VNFS name contains illegal characters!");
    }

    if ( ! &vnfs_exists("$vnfs") ) {
        &eprint("VNFS '$vnfs' does not exist!");
        return(1);
    }

    if ( @nodes_req ) {
        foreach my $node ( @nodes_req ) {
            if ( $node =~ /^([a-zA-Z0-9\-_\.]+)$/ ) {
                $node = $1;
                &dprint("Untaintained node name: $node");
                push(@nodes, $node);
            } else {
                &eprint("Node name '$node' contains illegal characters!");
            }
        }
    } else {
        @nodes = &nodeid2nodename($db{"hostname"}, &vnfs2nodeid($db{"vnfs"}, $vnfs));
    }

    $retval += &vnfs_livesync($vnfs, &sortnodeids($db{"hostname"}, @nodes));

    foreach my $DB ( @databases ) {
        $db{"$DB"}->closedb();
    }

    return($retval);
}

sub
UI_ModuleList(@)
{
    &dprint("Entered function");

    my @arguments           = @_;
    my $retval              = 0;

    foreach my $module ( sort &module_list(@arguments) ) {
        print "$module\n";
    }

    return($retval);

}

sub
UI_ModuleImport($)
{
    &dprint("Entered function");

    my $module              = shift;
    my $module_file         = ();
    my $retval              = 0;
    my $name                = basename($module);

    if ( ! -f "$module" ) {
        &eprint("USAGE: perceus module import [path to module]");
        return(1);
    }

    if ( $module =~ /^([a-zA-Z0-9\-_\.\/]+)$/ ) {
        $module_file = $1;
        &dprint("Untaintained module_file: $module_file");
    } else {
        &eprint("Module file name contains illegal characters!");
        exit 1;
    }

    if ( $name =~ /^(.+).pmod$/ ) {
        $name = $1;
        &iprint("Importing '$name'\n");
    } else {
        &eprint("$module is not a valid Perceus Module (*.pmod)");
        return(1);
    }

    if ( &module_exists($name) ) {
        &eprint("Perceus Module '$name' is already installed!");
        return(1);
    }

    $retval += &module_import($module_file);

    if ( $retval == 0 ) {
        &iprint("Perceus Module '$name' has been successfully imported.");
    } else {
        &iprint("There was an error importing the Perceus Module '$name'!");
    }

    return($retval);
}

sub
UI_ModuleSummary(@)
{
    &dprint("Entered function");

    my @modules             = @_;
    my @roles               = ();
    my $role                = ();
    my $mod                 = ();

    foreach $mod ( sort &module_list(@modules) ) {
        print "$mod:\n";
        foreach $role ( sort &module_list_active("$mod")) {
            print "\t$role\n";
        }
    }

    &dprint("Returning function");
    return(0);
}

sub
UI_ModuleStates(@)
{
    &dprint("Entered function");

    my @glob             = @_;
    my %roles            = ();
    my $role             = ();
    my $mod              = ();

    foreach $mod ( sort &module_list(@glob) ) {
        foreach $role ( sort &module_list_active("$mod")) {
            push(@{$roles{$role}}, $mod);
        }
    }
    foreach $role ( sort keys %roles ) {
        print "$role:\n";
        foreach $mod ( sort @{$roles{$role}} ) {
            print "   $mod\n";
        }
    }

    &dprint("Returning function");
    return(0);
}

sub
UI_ModuleEnable(@)
{
    &dprint("Entered Function");

    my $module_req      = shift;
    my @roles_req       = @_;
    my @activated       = ();
    my @roles           = ();
    my $retval          = 0;
    my $module          = ();

    if ( $module_req =~ /^([a-zA-Z0-9\-_\.]+)$/ ) {
        &dprint("untainted '$module_req'");
        $module = $1;
    } else {
        &wprint("Inappropriate module name: $module_req");
    }

    foreach my $r ( @roles_req ) {
        if ( $r =~ /^([a-zA-Z0-9]+(\/[a-zA-Z0-9]+)+)$/ ) {
            &dprint("Adding '$r' to untainted roles to activate");
            push(@roles, $1);
        } else {
            &wprint("Inappropriate role name: $r");
        }
    }

    if ( ! &module_exists("$module") ) {
        &eprint("Perceus Module '$module' is not installed!");
        return(1);
    }

    @activated = &module_enable($module, @roles);

    if ( @activated ) {
        foreach my $Role ( @activated ) {
            &iprint("Perceus Module '$module' has been enabled in '$Role'");
        }
    } else {
        &wprint("Perceus Module '$module' was not enabled in any additional provisionary states!");
        $retval += 1;
    }

    &dprint("Returning function with: $retval");
    return($retval);
}

sub
UI_ModuleDisable(@)
{
    &dprint("Entered Function");

    my $module_req      = shift;
    my @roles_req       = @_;
    my $module          = ();
    my @roles           = ();
    my @deactivated     = ();
    my $retval          = 0;

    if ( $module_req =~ /^([a-zA-Z0-9\-_\.]+)$/ ) {
        &dprint("untainted '$module_req'");
        $module = $1;
    } else {
        &wprint("Inappropriate module name: $module_req");
    }

    foreach my $r ( @roles_req ) {
        if ( $r =~ /^([a-zA-Z0-9]+(\/[a-zA-Z0-9]+)+)$/ ) {
            &dprint("Adding '$r' to untainted roles to deactivate");
            push(@roles, $1);
        } else {
            &eprint("Inappropriate role name: $r");
            return(1);
        }
    }

    if ( ! &module_exists("$module") ) {
        &eprint("Perceus Module '$module' is not installed!");
        return(1);
    }

    @deactivated = &module_disable($module, @roles);

    if ( @deactivated ) {
        foreach my $Role ( @deactivated ) {
            &iprint("Perceus Module '$module' has been disabled in '$Role'");
        }
    } else {
        &wprint("Perceus Module '$module' was not disabled in any provisionary states!");
        $retval += 1;
    }

    &dprint("Returning function with: $retval");
    return($retval);
}

sub
UI_ModuleDelete(@)
{
    &dprint("Entered Function");

    my $module_req      = shift;
    my $module          = ();
    my $retval          = 0;

    if ( $module_req =~ /^([a-zA-Z0-9\-_\.]+)$/ ) {
        &dprint("untainted '$module_req'");
        $module = $1;
    } else {
        &wprint("Inappropriate module name: $module_req");
    }

    if ( ! &module_exists("$module") ) {
        &eprint("Perceus Module '$module' is not installed!");
        return(1);
    }

    my $message = "Are you sure you wish to delete the given Perceus Module(s)?";
    if ( &confirm_list($message, $module)) {
        $retval = &module_delete($module);
        print "Perceus Module '$module' has been deleted\n";
    }

    &dprint("Returning function with: $retval");
    return($retval);
}

sub
UI_About()
{
    &dprint("Entered Function");

    print &about;

    return(0);
}

sub
UI_Config()
{
    &dprint("Entered Function");

    my $output              = &get_config(@ARGV);

    if ( $output ) {
        print "$output\n";
    } else {
        &wprint("That configuration key does not exist\n");
    }

    return(0);
}

sub
UI_System()
{
    &dprint("Entered Function");

    print &perceus_info();
    print &perceus_status();
    print &system_info();

    return(0);
}

sub
UI_Init()
{
    &dprint("Entered Function");

    &init_all();

    return(0);
}

sub
UI_ConfigureApache
{
    &dprint("Entered Function");
    my $retval              = ();

    $retval = &configure_apache();

    return($retval);
}

sub
UI_ConfigureDhcpd
{
    &dprint("Entered Function");
    my $retval              = ();

    $retval = &configure_dhcpd();

    return($retval);
}

sub
UI_ConfigureNfs
{
    &dprint("Entered Function");
    my $retval              = ();

    $retval = &configure_nfs();

    return($retval);
}

sub
UI_ConfigureSshKeys
{
    &dprint("Entered Function");
    my $retval              = ();

    $retval = &configure_sshkeys();

    return($retval);
}

sub
UI_ConfigureHosts
{
    &dprint("Entered Function");
    my $retval              = ();

    $retval = &configure_hosts();

    return($retval);
}

sub
UI_ContactRegister
{
    &dprint("Entered Function");
    my $retval              = ();

    $retval = &contact_register();

    return($retval);
}

sub
UI_ContactSupport
{
    &dprint("Entered Function");
    my $retval              = ();

    $retval = &contact_support();

    return($retval);
}










1;
