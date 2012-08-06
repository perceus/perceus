
#
# Copyright (c) 2006-2009, Greg M. Kurtzer, Arthur A. Stevens and
# Infiscale, Inc. All rights reserved
#


package Perceus::Modules;
use strict;
use warnings;

BEGIN {

   use Exporter;

   our @ISA = ('Exporter');

   our @EXPORT = qw (
        &module_list
        &module_import
        &module_list_active
        &module_enable
        &module_disable
        &module_exists
        &module_delete
   );

   require "/etc/perceus/Perceus_Include.pm";
   push(@INC, "$Perceus_Include::libdir");

}

use Perceus::System;
use Perceus::Debug;
use Perceus::Util;
use File::Basename;
use File::Path;


sub
module_list(@)
{
    &dprint("Entered function");

    my @glob                = @_;
    my @return              = ();
    my $f                   = ();

    if ( ! @glob ) {
        push(@glob, "*");
    }

    foreach $f ( @glob ) {
        foreach (sort glob("$Perceus_Include::statedir/modules/$f")) {
            if ( -d "$_" ) {
                &dprint("module_list: found ($_)\n");
                push(@return, basename($_));
            }
        }
    }

    &dprint("Returning function with: @return");
    return(@return);
}

sub
module_import(@)
{
    &dprint("Entered function");

    my $ModulePath          = shift;
    my $retval              = 0;
    my $ModuleName          = ();

    if ( ! "$ModulePath" ) {
        &vprint("Modulefile was not passed to function properly!");
        return(1);
    }

    my $Module = basename($ModulePath);

    if ( $Module =~ /^(.+).pmod$/ ) {
        $ModuleName = $1;
    } else {
        &eprint("That doesn't appear to be a good module name");
        return(1);
    }

    if ( &module_exists(&untaint($ModuleName)) ) {
        &eprint("'$ModuleName' is already imported");
        exit 1;
    }

    mkpath("$Perceus_Include::statedir/modules/$ModuleName");
    &runcmd("tar xjf $ModulePath -C $Perceus_Include::statedir/modules/$ModuleName");
    if ( $? == 0 ) {
        if ( -x "$Perceus_Include::statedir/modules/$ModuleName/install" ) {
            &runcmd("$Perceus_Include::statedir/modules/$ModuleName/install $ModuleName");
        }
        &vprint("$ModuleName has been imported");
    } else {
        &runcmd("rm -rf $Perceus_Include::statedir/modules/$ModuleName");
        &eprint("There was an error importing $ModuleName!");
        $retval += 1;
    }

    &dprint("Returning function");
    return($retval);
}

sub
module_exists($)
{
    &dprint("Entered function");

    my $ModuleName          = shift;
    my $retval              = 0;

    if ( -d "$Perceus_Include::statedir/modules/$ModuleName" ) {
        &dprint("Perceus Module '$ModuleName' found at: $Perceus_Include::statedir/modules/$ModuleName");
        $retval = 1;
    }

    &dprint("Returning function with: $retval");
    return($retval);
}

sub
module_list_active($)
{
    &dprint("Entered function");

    my $ModuleName          = shift;
    my @installed           = ();

    if ( -f "$Perceus_Include::statedir/modules/$ModuleName/.installed" ) {
        open(DESC, "$Perceus_Include::statedir/modules/$ModuleName/.installed");
        while(<DESC>) {
            chomp;
            push(@installed, $_);
        }
        close DESC;
    }

    &dprint("Returning function with: @installed");
    return(@installed);
}

sub
module_enable(@)
{
    &dprint("Entered function");

    my $ModuleName          = shift;
    my @Roles               = @_;
    my $Role                = ();
    my @scripts             = ();
    my @setactive           = ();

    if ( ! $ModuleName ) {
        &eprint("&module_enable called without any module name!");
        return();
    }

    if ( &module_exists("$ModuleName") ) {
        if ( ! -d "$Perceus_Include::statedir/modules/$ModuleName/nodescripts/" ) {
            &eprint("Does this module have any nodescripts?");
            return();
        }
        if ( ! @Roles and -f "$Perceus_Include::statedir/modules/$ModuleName/defaultroles" ) {
            open(DEF, "$Perceus_Include::statedir/modules/$ModuleName/defaultroles");
            while (<DEF>) {
                chomp;
                if ( $_ =~ /^([a-zA-Z0-9\-_\.\/]+)$/ ) {
                    &dprint("untainted installed role: $_");
                    push(@Roles, $1);
                } else {
                    &eprint("Could not untaint role: $_");
                }
            }
            close DEF;
        } elsif ( ! @Roles ) {
            &eprint("No default roles configured for this module");
            return();
        }

        foreach my $newRole ( @Roles ) {
            my $Role = &untaint($newRole);
            if ( $Role =~ /^[^\/]+\/all\/?$/ ) {
                # This is good
            } elsif ( $Role =~ /^[^\/]+\/group\/[^\/]+\/?$/ ) {
                # This is good
            } elsif ( $Role =~ /^[^\/]+\/node\/[^\/]+\/?$/ ) {
                # This is good
            } elsif ( $Role =~ /^[^\/]+\/vnfs\/[^\/]+\/?$/ ) {
                # This is good
            } else {
                &wprint("Provisionary state '$Role' is not valid.");
                next;
            }
            if ( -f "$Perceus_Include::statedir/modules/$ModuleName/.installed") {
                open(DESC, "$Perceus_Include::statedir/modules/$ModuleName/.installed");
                while(<DESC>) {
                    chomp;
                    if ( "$_" eq "$Role" ) {
                        &eprint("This module is already set active at '$Role'!");
                        return();
                    }
                }
                close DESC;
            }
            chdir("$Perceus_Include::statedir/modules/$ModuleName/nodescripts/");
            if ( ! -d "$Perceus_Include::statedir/nodescripts/$Role" ) {
                mkpath("$Perceus_Include::statedir/nodescripts/$Role");
            }
            @scripts = glob("*");
            foreach my $s (@scripts) {
                my $script;
                if ( $s =~ /^([a-zA-Z0-9\-_\.]+)$/ ) {
                    &dprint("untainted script: $s");
                    $script = $1;
                }
                symlink("$Perceus_Include::statedir/modules/$ModuleName/nodescripts/$script",
                    "$Perceus_Include::statedir/nodescripts/$Role/$script");
                push(@setactive, $Role);
            }
            open(DESC, ">> $Perceus_Include::statedir/modules/$ModuleName/.installed");
            print DESC "$Role\n";
            close DESC;
            #&iprint("Perceus module '$ModuleName' has been set active in '$Role'");
        }

        if ( -x "$Perceus_Include::statedir/modules/$ModuleName/activate") {
            my $states = join(" ", @Roles);
            $ENV{"STATEDIR"} = $Perceus_Include::statedir;
            $ENV{"STATES"} = $states;
            if ( system("$Perceus_Include::statedir/modules/$ModuleName/activate $states") ) {
                &dprint("command failed: $Perceus_Include::statedir/modules/$ModuleName/activate $states");
                &wprint("\nModule activation was not successful, deactivating module.");
                &module_disable($ModuleName, @Roles);
            }
            delete($ENV{"STATEDIR"});
            delete($ENV{"STATES"});
        }

    } else {
        &eprint("Module '$ModuleName' is not found!");
        return(1);
    }

    if ( @setactive ) {
        &dprint("Returning function with: @setactive");
    } else {
        &dprint("Returning function undefined");
    }
    return(@setactive);
}

sub
module_disable(@)
{
    &dprint("Entered function");

    my $ModuleName          = shift;
    my @Roles               = @_;
    my $removed             = ();
    my @scripts             = ();
    my $Role                = ();
    my $out                 = "";
    my @unsetactive         = ();

    if ( ! $ModuleName ) {
        &eprint("&module_disable called without any module name!");
        return(1);
    }

    if ( &module_exists("$ModuleName") ) {
        if ( ! -d "$Perceus_Include::statedir/modules/$ModuleName/nodescripts/" ) {
            &wprint("Does this module have any nodescripts?");
        }
        if ( ! @Roles and -f "$Perceus_Include::statedir/modules/$ModuleName/.installed" ) {
            open(ROLES, "$Perceus_Include::statedir/modules/$ModuleName/.installed");
            while(<ROLES>) {
                chomp;
                if ( $_ =~ /^([a-zA-Z0-9\-_\.\/]+)$/ ) {
                    &dprint("untainted installed role: $_");
                    push(@Roles, $1);
                } else {
                    &eprint("Could not untaint role: $_");
                }
            }
            close ROLES;
        }
        chdir("$Perceus_Include::statedir/modules/$ModuleName/nodescripts/");
        @scripts = glob("*");
        foreach my $s (@scripts) {
            my $script;
            if ( $s =~ /^([a-zA-Z0-9\-_\.]+)$/ ) {
                &dprint("untainted script: $s");
                $script = $1;
            }
            foreach $Role ( @Roles ) {
                unlink("$Perceus_Include::statedir/nodescripts/$Role/$script");
            }
        }
        foreach $Role ( @Roles ) {
            $removed = ();
            $out = ();
            open(DESC, "$Perceus_Include::statedir/modules/$ModuleName/.installed");
            while(<DESC>) {
                chomp;
                if ( $_ eq "$Role" ) {
                    $removed = 1;
                } else {
                    $out .= "$_\n";
                }
            }
            close DESC;
            if ( ! $removed ) {
                &wprint("Perceus module '$ModuleName' is not active in '$Role'");
            } else {
                #&iprint("Perceus module '$ModuleName' has been deactivated in '$Role'");
                push(@unsetactive, $Role);
            }
            open(DESC, "> $Perceus_Include::statedir/modules/$ModuleName/.installed");
            if ( $out ) {
                print DESC $out;
            } else {
                print DESC "";
            }
            close DESC;
        }
    } else {
        &eprint("Module '$ModuleName' is not found!");
        return();
    }

    &dprint("Returning function");
    return(@unsetactive);
}

sub
module_delete($)
{
    &dprint("Entered function");

    my $ModuleName          = shift;
    my @Roles               = ();

    if ( ! $ModuleName ) {
        &eprint("Need module name to delete!");
        return(1);
    }

    &module_disable($ModuleName);

    &runcmd("rm -rf $Perceus_Include::statedir/modules/$ModuleName");

    &dprint("Returning function");
    return(0);
}


1;
