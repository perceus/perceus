
#
# Copyright (c) 2006-2009, Greg M. Kurtzer, Arthur A. Stevens and
# Infiscale, Inc. All rights reserved
#


package Perceus::DB;
use strict;
use warnings;
use vars qw(@DB_Files);

BEGIN {

   use Exporter;

   our @ISA = ('Exporter');

   our @EXPORT = qw (
        &opendb
        &list_databases
        &check_database
   );

   require "/etc/perceus/Perceus_Include.pm";
   push(@INC, "$Perceus_Include::libdir");

}

use Perceus::Config;
use Perceus::Util;
use Perceus::Debug;
use Perceus::DB::Hash;
use Perceus::DB::BTree;
use Perceus::DB::MySQL;
use File::Path;
use File::Basename;
use DB_File;
use Fcntl;


sub
opendb($)
{
    &dprint("Entered Function");

    my $DB                  = shift;
    my $FLAGS               = shift;
    my %config              = &parse_config("/etc/perceus/perceus.conf");
    my $defaultdb           = $config{"database type"}[0] || "hash";

    &dprint("Default database set to: '$defaultdb'");

    if ( $defaultdb eq "btree" ) {
        &dprint("Handing off to BTree open function");
        return Perceus::DB::BTree->opendb($DB, $FLAGS);
    } elsif ( $defaultdb eq "hash" ) {
        &dprint("Handing off to Hash open function");
        return Perceus::DB::Hash->opendb($DB, $FLAGS);
    } elsif ( $defaultdb eq "mysql" ) {
        &dprint("Handing off to Mysql open function");
        return Perceus::DB::MySQL->opendb($DB,
                $config{"database server"}[0] || "localhost",
                $config{"database name"}[0],
                $config{"database user"}[0],
                $config{"database pass"}[0]);
    } else {
        &eprint("Configuration option 'database type = $defaultdb' not understood!");
        exit(1);
    }

}

sub
check_database(@)
{
    &dprint("Entered Function");

    my @databases           = @_;
    my %config              = &parse_config("/etc/perceus/perceus.conf");
    my $defaultdb           = $config{"database type"}[0] || "hash";

    &dprint("Default database set to: '$defaultdb'");

    if ( $defaultdb eq "btree" ) {
        &dprint("Handing off to BTree open function");
        return Perceus::DB::BTree->check_database(@databases);
    } elsif ( $defaultdb eq "hash" ) {
        &dprint("Handing off to Hash open function");
        return Perceus::DB::Hash->check_database(@databases);
    } elsif ( $defaultdb eq "mysql" ) {
        &dprint("Handing off to Mysql open function");
        return Perceus::DB::MySQL->check_database(
                $config{"database server"}[0] || "localhost",
                $config{"database name"}[0],
                $config{"database user"}[0],
                $config{"database pass"}[0],
                @databases);
    } else {
        &eprint("Configuration option 'database type = $defaultdb' not understood!");
        exit(1);
    }

}

sub
list_databases
{

    my @return              = ();
    my $tmp                 = ();
    my %config              = &parse_config("/etc/perceus/perceus.conf");
    my $defaultdb           = $config{"database type"}[0] || "hash";
    my $dbsuffix            = ();

    if ( $defaultdb eq "btree" ) {
        return Perceus::DB::BTree->list_databases();
    } elsif ( $defaultdb eq "hash" ) {
        return Perceus::DB::Hash->list_databases();
    } elsif ( $defaultdb eq "mysql" ) {
        return Perceus::DB::MySQL->list_databases(
                $config{"database server"}[0] || "localhost",
                $config{"database name"}[0],
                $config{"database user"}[0],
                $config{"database pass"}[0]);
    } else {
        &eprint("Configuration option 'database type = $defaultdb' not understood!");
        exit(1);
    }

    foreach my $file ( glob("$Perceus_Include::database/*.$dbsuffix") ) {
        my $tmp = basename($file);
        $tmp =~ s/\.bbd$//;
        push(@return, $tmp);
    }

    return(@return);
}

1;
