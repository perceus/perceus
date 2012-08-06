
#
# Copyright (c) 2006-2009, Greg M. Kurtzer, Arthur A. Stevens and
# Infiscale, Inc. All rights reserved
#


package Perceus::Vnfs;
use strict;
use warnings;

BEGIN {

   use Exporter;

   our @ISA = ('Exporter');

   our @EXPORT = qw (
        &vnfs_clone
        &vnfs_mounted
        &vnfs_exists
        &vnfs_umount
        &vnfs_mount
        &vnfs_close
        &vnfs_list
        &vnfs_configure
        &vnfs_delete
        &vnfs_export
        &vnfs_import
        &vnfs_livesync
        &vnfs2nodeid
   );

   require "/etc/perceus/Perceus_Include.pm";
   push(@INC, "$Perceus_Include::libdir");

}

use File::Basename;
use File::Path;
use File::Copy;
use Perceus::Util;
use Perceus::Debug;
use Perceus::System;


sub
vnfs_clone(@)
{
    &dprint("Entered function");

    my $Vnfs1               = shift;
    my $Vnfs2               = shift;

    if ( &vnfs_exists($Vnfs2) ) {
        &eprint("Target VNFS '$Vnfs2' exists!");
        return(1);
    }

    if ( &vnfs_exists($Vnfs1) ) {
        mkpath("$Perceus_Include::statedir/vnfs/$Vnfs2");
        chdir("$Perceus_Include::statedir/vnfs/$Vnfs1/");
        foreach ( glob("*") ) {
            my $vnfs_file;

            if ( $_ =~ /^vnfs\.img.*$/ ) {
                next;
            }
            $vnfs_file = &untaint($_);
            &dprint("->cloning file '$vnfs_file'");
            &runcmd("cp -rap $Perceus_Include::statedir/vnfs/$Vnfs1/$vnfs_file $Perceus_Include::statedir/vnfs/$Vnfs2/$vnfs_file");
        }

        &vnfs_add_nodescripts($Vnfs2);

    }

    &dprint("Returning function '0'");
    return(0);
}

sub
vnfs_list(@)
{
    &dprint("Entered function");

    my @args                = @_;
    my @list                = ();
    my @return              = ();

    chdir("$Perceus_Include::statedir/vnfs/")
        or die "Unrecoverable error, does '$Perceus_Include::statedir/vnfs/' even exist?!\n";

    if ( $#args < 0 ) {
        push(@args, "*");
    }

    foreach ( @args ) {
        push(@list, glob("$_"));
    }

    foreach ( @list ) {
        if ( -f "$Perceus_Include::statedir/vnfs/$_/config" ) {
            push(@return, $_);
        }
    }

    &dprint("Returning function with array: @return");
    return(@return);
}

sub
vnfs_mounted($)
{
    &dprint("Entered function");

    my $vnfs                = shift;
    my $retval              = 0;

    if ( -l "/mnt/$vnfs" ) {
        $retval = 1;
    }

    return($retval);
}

sub
vnfs_mount($)
{
    &dprint("Entered function");

    my $VnfsName            = shift;
    my $retval              = 0;

    if ( ! $VnfsName ) {
        return(1);
    }

    &dprint("checking for: '$Perceus_Include::statedir/vnfs/$VnfsName/mount'");
    if ( -x "$Perceus_Include::statedir/vnfs/$VnfsName/mount" ) {
        &dprint("running: $Perceus_Include::statedir/vnfs/$VnfsName/mount $VnfsName");
        $retval += system("$Perceus_Include::statedir/vnfs/$VnfsName/mount $VnfsName") >> 8;
    } else {
        &eprint("This capsule doesn't exist or has no mount utility");
    }

    &dprint("Returning function with: $retval");
    return($retval);
}

sub
vnfs_exists($)
{
    &dprint("Entered function");

    my $VnfsName            = shift;
    my $retval              = 0;

    if ( ! $VnfsName ) {
        return();
    }
   
    if ( -d "$Perceus_Include::statedir/vnfs/$VnfsName/" ) {
        &dprint("VNFS '$VnfsName' found at: $Perceus_Include::statedir/vnfs/$VnfsName");
        $retval = 1;
    }

    &dprint("Returning function with: $retval");
    return($retval);
}

sub
vnfs_umount($)
{
    &dprint("Entered function");

    my $VnfsName            = shift;
    my $retval              = 0;

    if ( -d "$VnfsName" ) {
        $VnfsName = basename($VnfsName);
        $VnfsName =~ s/\/$//g;
    }

    &dprint("checking for: '$Perceus_Include::statedir/vnfs/$VnfsName/umount'");
    if ( -x "$Perceus_Include::statedir/vnfs/$VnfsName/umount" ) {
        &dprint("running: $Perceus_Include::statedir/vnfs/$VnfsName/umount $VnfsName");
        $retval += system("$Perceus_Include::statedir/vnfs/$VnfsName/umount $VnfsName") >> 8;
    } else {
        &eprint("This capsule doesn't exist or has no umount utility");
    }

    &dprint("Returning function with: $retval");
    return($retval);
}

sub
vnfs_close($)
{
    &dprint("Entered function");

    my $VnfsName            = shift;
    my $retval              = 0;

    if ( -d "$VnfsName" ) {
        $VnfsName = basename($VnfsName);
        $VnfsName =~ s/\/$//g;
    }

    &dprint("checking for: '$Perceus_Include::statedir/vnfs/$VnfsName/close'");
    if ( -x "$Perceus_Include::statedir/vnfs/$VnfsName/close" ) {
        &dprint("running: $Perceus_Include::statedir/vnfs/$VnfsName/close $VnfsName");
        $retval += system("$Perceus_Include::statedir/vnfs/$VnfsName/close $VnfsName") >> 8;
    } else {
        &eprint("This capsule doesn't exist or has no close utility");
    }

    &dprint("Returning function with: $retval");
    return($retval);
}


sub
vnfs_configure($)
{
    &dprint("Entered function");

    my $VnfsName            = shift;
    my $retval              = 0;

    if ( -d "$VnfsName" ) {
        $VnfsName = basename($VnfsName);
        $VnfsName =~ s/\/$//g;
    }

    &dprint("checking for: '$Perceus_Include::statedir/vnfs/$VnfsName/configure'");
    if ( -x "$Perceus_Include::statedir/vnfs/$VnfsName/configure" ) {
        &dprint("running: $Perceus_Include::statedir/vnfs/$VnfsName/configure $VnfsName");
        $retval += system("$Perceus_Include::statedir/vnfs/$VnfsName/configure $VnfsName") >> 8;
    } else {
        &eprint("This capsule doesn't exist or has no configure utility");
    }

    &dprint("Returning function with: $retval");
    return($retval);
}

sub
vnfs_delete($)
{
    &dprint("Entered function");

    my $VnfsName            = shift;
    my $retval              = 0;

    if ( ! &vnfs_exists("$VnfsName") ) {
        &vprint("$VnfsName does not exist!");
        return(1);
    }

    if ( &vnfs_mounted($VnfsName) ) {
        &vprint("$VnfsName is mounted!");
        return(1);
    }

    $retval += &vnfs_del_nodescripts($VnfsName);
    $retval += &runcmd("rm -rf $Perceus_Include::statedir/vnfs/$VnfsName");

    if ( $retval ) {
        &dprint("Returning function with: $retval");
    } else {
        &dprint("Returning function undefined");
    }

    return($retval);
}

sub
vnfs_del_nodescripts($)
{
    &dprint("Entered function");

    my $VnfsName            = &untaint(shift);
    my $installdir          = "$Perceus_Include::statedir/vnfs/$VnfsName";
    my $retval              = 0;

    &dprint("VNFS installdir=$installdir");

    if ( &vnfs_exists("$VnfsName") ) {
        foreach my $script ( glob("$Perceus_Include::statedir/nodescripts/*/vnfs/$VnfsName/*") ) {
            $script = &untaint($script);
            if ( -l "$script" ) {
                &dprint("Unlinking nodescript: $script");
                unlink("$script");
            } else {
                &wprint("Not unlinking nodescript: $script");
                $retval ++;
            }
        }
    }

    &dprint("Returning function with: $retval");

    return($retval);
}


sub
vnfs_add_nodescripts($)
{
    &dprint("Entered function");

    my $VnfsName            = shift;
    my $installdir          = "$Perceus_Include::statedir/vnfs/$VnfsName";
    my $retval              = ();

    &dprint("VNFS installdir=$installdir");

    if ( &vnfs_exists("$VnfsName") ) {

        if ( -d "$installdir/nodescripts" ) {
            &dprint("Found VNFS nodescript directory at 'nodescripts/'");
            foreach my $statedir ( glob("$installdir/nodescripts/*") ) {
                if ( $statedir =~ /^(.+)$/ ) {
                    $statedir = $1;
                    my $state = basename($statedir);
                    &dprint("Linking $statedir/* to $Perceus_Include::statedir/nodescripts/$state/vnfs/$VnfsName/");
                    mkpath("$Perceus_Include::statedir/nodescripts/$state/vnfs/$VnfsName/");
                    &runcmd("ln -sf $statedir/* $Perceus_Include::statedir/nodescripts/$state/vnfs/$VnfsName/");
                }
            }
        } elsif ( -d "$installdir/init" ) {
            &dprint("Found VNFS nodescript directory at 'init/'");
            &dprint("Linking $installdir/init/* to $Perceus_Include::statedir/nodescripts/init/vnfs/$VnfsName/");
            mkpath("$Perceus_Include::statedir/nodescripts/init/vnfs/$VnfsName/");
            &runcmd("ln -sf $installdir/init/* $Perceus_Include::statedir/nodescripts/init/vnfs/$VnfsName/");
        } else {
            &dprint("No VNFS nodescript directories were found!");
            &eprint("$VnfsName is not of the right format for this version of Perceus");
            $retval = 1;
        }

    } else {
        &eprint("$VnfsName is not installed");
        $retval = 1;

    }

    if ( $retval ) {
        &dprint("Returning function with: $retval");
    } else {
        &dprint("Returning function undefined");
    }

    return($retval);
}

sub
vnfs_import($)
{
    &dprint("Entered function");

    my $VnfsFile            = shift;
    my $VnfsName            = basename($VnfsFile);
    my $installdir          = ();
    my $retval              = 0;

    if ( ! -f "$VnfsFile" ) {
        &eprint("$VnfsFile does not exist!");
        exit 1;
    }

    if ( $VnfsName =~ /^(.+).vnfs$/ ) {
        $VnfsName = $1;
    } else {
        &eprint("$VnfsName is not a valid Perceus VNFS capsule (*.vnfs)");
        return(1);
    }

    $installdir = "$Perceus_Include::statedir/vnfs/$VnfsName";

    &dprint("VNFS installdir=$installdir");

    if ( &vnfs_exists("$VnfsName") ) {
        &eprint("$VnfsName is already installed");
        return(1);
    }

    &dprint("making path: $Perceus_Include::statedir/vnfs/$VnfsName");
    mkpath("$Perceus_Include::statedir/vnfs/$VnfsName");

    &dprint("Expanding $VnfsFile");
    open(OUT, "tar xjf $VnfsFile -C $installdir |");
    while(<OUT>) {
        &vprint("$_");
    }
    close OUT;
    $retval += $? >> 8;

    $retval += &vnfs_add_nodescripts($VnfsName) || 0;

    if ( $retval == 0 ) {

        if ( -x "$installdir/install" ) {
            &dprint("Running: $installdir/install $VnfsName");
            system("$installdir/install $VnfsName");
        }

        if ( -x "$installdir/configure" ) {
            &dprint("Running: $installdir/configure $VnfsName");
            system("$installdir/configure $VnfsName");
        }
    } else {
        &vnfs_delete($VnfsName);
        &eprint("Expanding VNFS failed, removed leftover contents...");
    }

    &dprint("Returning function undefined");
    return($retval);
}

sub
vnfs_export(@)
{
    &dprint("Entered function");

    my $VnfsName         = shift;
    my $VnfsExport       = shift;

    if ( ! $VnfsName ) {
        &eprint("VNFS name paramater not passed!");
        return(1);

    } elsif ( &vnfs_mounted($VnfsName) ) {
        &eprint("You must un-mount the VNFS before it can be exported!");
        return(1);

    } elsif ( ! $VnfsExport ) {
        $VnfsExport = "$ENV{HOME}/vnfs-backups/$VnfsName.vnfs";
        &vprint("Export file name not passed, using $VnfsExport");

    } elsif ( ! $VnfsExport =~ /.*\.vnfs$/ ) {
        &vprint("Appending 'vnfs' suffix to file name");
        $VnfsExport .= ".vnfs";

    }

    my $dir = dirname($VnfsExport);

    &dprint("Checking for existing dirname: $dir");
    if ( ! -d "$dir" ) {
        &vprint("Creating directory: $dir");
        mkpath("$dir");
    }

    &vprint("Exporting to $VnfsExport.part");
    if ( ! system("(cd $Perceus_Include::statedir/vnfs/$VnfsName; tar cf - --exclude=vnfs.img\\* .) | bzip2 -z > $VnfsExport.part") ) {

        &vprint("Export Succeeded");
        &vprint("renaming: $VnfsExport.part, $VnfsExport");
        rename("$VnfsExport.part", "$VnfsExport");

    } else {

        unlink("$VnfsExport.part");
        &eprint("Failed to export VNFS capsule '$VnfsName' to $VnfsExport");
        return(1);

    }

    &dprint("Returning function '0'");
    return(0);
}

sub
vnfs_livesync($)
{
    &dprint("Entered function");

    my $VnfsName            = shift;
    my @nodes_list          = @_;
    my $retval              = 0;

    if ( ! $VnfsName ) {
        &vprint("VNFS name paramater not passed!");
        return(1);
    }

    my $nodes = &untaint(join(" ", @nodes_list)) || "";

    &dprint("checking for: '$Perceus_Include::statedir/vnfs/$VnfsName/livesync'");
    if ( -x "$Perceus_Include::statedir/vnfs/$VnfsName/livesync" ) {
        &dprint("running: $Perceus_Include::statedir/vnfs/$VnfsName/livesync $nodes");
        $retval += system("$Perceus_Include::statedir/vnfs/$VnfsName/livesync $nodes") >> 8;
    } else {
        &eprint("This capsule doesn't exist or has no livesync utility");
    }

    &dprint("Returning function with: $retval");
    return($retval);
}

sub
vnfs2nodeid(@)
{
    &dprint("Entered function");

    my $db              = shift;
    my @arguments       = @_;
    my @nodeids         = ();

    # convert list of groupnames to nodeid's
    my %vnfs            = $db->hash_keys();

    foreach my $nodeid (keys(%vnfs)) {
        if (scalar(grep {$_ eq $vnfs{$nodeid}} @arguments)) {
            &dprint("NodeID using '@arguments' $nodeid");
            push(@nodeids, $nodeid);
        }
    }

    return(@nodeids);
}



1;
