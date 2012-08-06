
#
# Copyright (c) 2006-2009, Greg M. Kurtzer, Arthur A. Stevens and
# Infiscale, Inc. All rights reserved
#


package Perceus::DB::MySQL;
use strict;
use warnings;

BEGIN {

   #use Exporter;

   #our @ISA = ('Exporter');

   require "/etc/perceus/Perceus_Include.pm";
   push(@INC, "$Perceus_Include::libdir");

}

use Perceus::Util;
use Perceus::Debug;
use File::Path;
use DBI;

my $dbh = ();

sub
check_database(@)
{
    &dprint("Entered Function");

    my $proto               = shift;
    my $hostname            = shift;
    my $database            = shift;
    my $db_user             = shift;
    my $db_pass             = shift;
    my @databases           = @_;
    my @default_databases       = ();
    my %tmp;

    if ( ! $hostname or ! $database or ! $db_user or ! $db_pass ) {
        &eprint("Database login credentials are required!");
    }

    if ( ! defined($dbh) ) {
        $dbh = DBI->connect("DBI:mysql:$database:$hostname", $db_user, $db_pass);
    }

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

    my $sth = $dbh->prepare(qq{show tables});
    $sth->execute();
    while(my $row = $sth->fetchrow_array) {
        $tmp{"$row"} = 1;
    }
    $sth = ();

    foreach my $DB ( @default_databases ) {
        if ( ! exists($tmp{"perceus_$DB"}) ) {
            &vprint("Creating database table: $DB");
            $dbh->do(qq{create table perceus_$DB ( nodeid varchar(18) not null, value varchar(128), primary key (nodeid), unique (nodeid))});
        }
    }

    if ( ! -d "$Perceus_Include::database" ) {
        # This is needed because the existance of this directory proves that
        # Perceus has been initialized. This will get done differently shortly.
        &dprint("Creating local database directory");
        mkpath("$Perceus_Include::database");
    }

    return();
}

sub
list_databases(@)
{
    &dprint("Entered Function");

    my $proto               = shift;
    my $hostname            = shift;
    my $database            = shift;
    my $db_user             = shift;
    my $db_pass             = shift;
    my @databases           = ();

    if ( ! $hostname or ! $database or ! $db_user or ! $db_pass ) {
        &eprint("Database login credentials are required!");
    }

    if ( ! defined($dbh) ) {
        $dbh = DBI->connect("DBI:mysql:$database:$hostname", $db_user, $db_pass);
    }

    my $sth = $dbh->prepare(qq{show tables});
    $sth->execute();
    while(my $row = $sth->fetchrow_array) {
        $row =~ s/^perceus_//;
        &dprint("Located database table: $row");
        push(@databases, $row);
    }

    $dbh = ();
    $sth = ();

    return(@databases);
}

sub
opendb(@)
{
    &dprint("Entered Function");

    my $proto               = shift;
    my $class               = ref($proto) || $proto;
    my $DB                  = shift || "";
    my $hostname            = shift;
    my $database            = shift;
    my $db_user             = shift;
    my $db_pass             = shift;
    my $self                = ();

    if ( ! $hostname or ! $database or ! $db_user or ! $db_pass ) {
        &eprint("Database login credentials are required!");
    }

    &dprint("Opening MySQL database: $DB @ $hostname");

    %{$self} = ();

    if ( ! defined($dbh) ) {
        $dbh = DBI->connect("DBI:mysql:$database:$hostname", $db_user, $db_pass);
    }

    $self->{table} = $DB;

    bless($self, $class);

    return $self;
}

sub
flush($)
{
    my $self                = shift;

    return $self;
}

sub
closedb($)
{
    my $self                = shift;

    return();
}

sub
list_values($)
{
    my $self                = shift;
    my @list                = ();

    my $sth = $dbh->prepare(qq{select value from perceus_$self->{table}});
    $sth->execute();
    while(my $row = $sth->fetchrow_array) {
        push(@list, $row);
    }

    return(@list);
}

sub
list_unique_values($)
{
    my $self                = shift;

    my $sth = $dbh->prepare(qq{select distinct(value) from perceus_$self->{table}});
    $sth->execute();
    my $ref = $sth->fetchall_arrayref;

    return(@{$ref});
}

sub
list_keys($)
{
    &dprint("Entering Function");

    my $self                = shift;
    my @list                = ();

    my $sth = $dbh->prepare(qq{select nodeid from perceus_$self->{table}});
    $sth->execute();
    while(my $row = $sth->fetchrow_array) {
        push(@list, $row);
    }

    return(@list);
}

sub
hash_keys($)
{
    my $self                = shift;
    my %hash                = ();

    my $sth = $dbh->prepare(qq{select nodeid, value from perceus_$self->{table}});
    $sth->execute();
    while(my ( $nodeid, $value ) = $sth->fetchrow_array) {
        $hash{"$nodeid"} = $value;
    }

    return(%hash);
}

sub
hash_values($)
{
    my $self                = shift;
    my %hash                = ();

    my $sth = $dbh->prepare(qq{select nodeid, value from perceus_$self->{table}});
    $sth->execute();
    while(my ( $nodeid, $value ) = $sth->fetchrow_array) {
        $hash{"$value"} = $nodeid;
    }

    return(%hash);
}

sub
get(@)
{
    my $self                = shift;
    my $key                 = shift;

    my $sth = $dbh->prepare(qq{select value from perceus_$self->{table} where nodeid = ?});
    $sth->execute($key);
    my $value = $sth->fetchrow_array();

    return($value || "");
}

sub
get_key(@)
{
    my $self                = shift;
    my $value               = shift;

    my $sth = $dbh->prepare(qq{select nodeid from perceus_$self->{table} where value = ?});
    $sth->execute($value);
    my $key = $sth->fetchrow_array();

    return($key || "");
}

sub
delete(@)
{
    my $self                = shift;
    my $key                 = shift;

    my $sth = $dbh->prepare(qq{delete from perceus_$self->{table} where nodeid = ?});
    $sth->execute($key);

    return();
}

sub
set(@)
{
   &dprint("Entered function");

   my $self                 = shift;
   my $key                  = shift;
   my $value                = shift || "";
   my %hash                 = ();

   if ( $key ) {

        &dprint("Setting: $self->{table}:$key:$value");

        my $sth = $dbh->prepare(qq{insert into perceus_$self->{table} (nodeid, value) values (?, ?) on duplicate key update value = ?});
        $sth->execute($key, $value, $value);


   } else { 
   
      &dprint("Skipping DB add due to undef'ed key");

   }

   &dprint("Returning function undefined");
   return();
}



1;
