
#
# Copyright (c) 2006-2009, Greg M. Kurtzer, Arthur A. Stevens and
# Infiscale, Inc. All rights reserved
#


package Perceus::DB::Hash;
use strict;
use warnings;

BEGIN {

   require "/etc/perceus/Perceus_Include.pm";
   push(@INC, "$Perceus_Include::libdir");

}

use Perceus::Util;
use Perceus::Debug;
use File::Basename;
use DB_File;
use Fcntl;
use File::Path;

sub
check_database(@)
{
    &dprint("Entered Function");

    my $proto               = shift;
    my @databases           = @_;
    my @default_databases   = ();
    my %tmp;

    @default_databases = qw(
        hostname
        vnfs
        group
        status
        desc
        enabled
        debug
        ipaddr
        lastcontact
        hwaddr
    );

    if ( @databases ) {
        push(@default_databases, @databases);
    }

    if ( -f "$Perceus_Include::database" ) {
        &eprint("Location '$Perceus_Include::database' should be a directory, not a file!");
    } elsif ( ! -d "$Perceus_Include::database" ) {
        &dprint("Creating database directory: $Perceus_Include::database");
        mkpath("$Perceus_Include::database");
    }

    foreach my $DB ( @default_databases ) {
        if ( ! -f "$Perceus_Include::database/$DB.db" ) {
            &vprint("Creating new database: $DB");
            tie(%tmp, "DB_File", "$Perceus_Include::database/$DB.db", O_CREAT, 0644, $DB_HASH) or
                &eprint("Could not create Berkeley Hash Database '$DB.db': $!\n");
            %tmp = ();
            untie %tmp;
        }
    }

    return();
}

sub
list_databases(@)
{
    &dprint("Entered Function");

    my $proto               = shift;
    my @databases           = ();
    my %tmp                 = ();

    foreach my $file ( glob("$Perceus_Include::database/*.db") ) {
        my $tmp = basename($file);
        $tmp =~ s/\.db$//;
        push(@databases, $tmp);
    }

    return(@databases);
}

sub
opendb(@)
{
    my $proto               = shift;
    my $class               = ref($proto) || $proto;
    my $DB                  = shift;
    my $FLAGS               = shift || O_RDONLY;
    my $self                = ();

    %{$self} = ();

    $self->{obj} = tie(%{$self->{db}}, "DB_File", "$Perceus_Include::database/$DB.db", $FLAGS, 0644, $DB_HASH) or
        &perceus_die("Could not attach to Berkeley Hash Database '$DB.db': $!\n");

    bless($self, $class);

    return $self;
}

sub
flush($)
{
    my $self                = shift;

    $self->{obj}->sync();

    return $self;
}

sub
closedb($)
{
    my $self                = shift;

    undef $self->{obj};
    untie %{$self->{db}};

    return();
}

sub
list_values($)
{
    my $self                = shift;

    return(values %{$self->{db}});
}

sub
list_unique_values($)
{
    my $self                = shift;
    my @values              = values %{$self->{db}};
    my %seen                = ();
    my @ret                 = ();

    @seen{@values} = ();
    @ret = keys %seen;

    return(@ret);
}

sub
list_keys($)
{
    my $self                = shift;

    return(keys %{$self->{db}});
}

sub
hash_keys($)
{
    my $self                = shift;

    return(%{$self->{db}});
}

sub
hash_values($)
{
    my $self                = shift;

    return(reverse %{$self->{db}});
}

sub
get(@)
{
    &dprint("Entered Function");

    my $self                = shift;
    my $key                 = shift;
    my $value               = $self->{db}{$key} || "";

    return($value);
}

sub
get_key(@)
{
    my $self                = shift;
    my $key                 = shift;
    my %hash                = $self->hash_values();

    return($hash{$key} || "");
}

sub
delete(@)
{
    my $self                = shift;
    my $key                 = shift;

    delete($self->{db}{$key});

    return();
}

sub
set(@)
{
    &dprint("Entered function");

    my $self                = shift;
    my $key                 = shift;
    my $value               = shift;
    my %hash                = ();

    if ( $key ) {

        if ( defined($value) ) {
            &dprint("Adding database key: $key, value: $value");
            $self->{db}{"$key"} = "$value";
        } else {
            &dprint("Adding database key: $key, value: (undefined)");
            $self->{db}{"$key"} = undef;
        }

        $self->{obj}->sync();
      
    } else { 
   
        &dprint("Skipping DB add due to undef'ed key");

    }

    &dprint("Returning function undefined");
    return();
}


1;
