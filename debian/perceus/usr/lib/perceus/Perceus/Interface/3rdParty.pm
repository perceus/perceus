
#
# Copyright (c) 2006-2009, Greg M. Kurtzer, Arthur A. Stevens and
# Infiscale, Inc. All rights reserved
#


package Perceus::Interface::3rdParty;
use strict;
use warnings;

BEGIN {

    use Exporter;

    our @ISA = ('Exporter');

    our @EXPORT = qw (
        &testing
    );

    require "/etc/perceus/Perceus_Include.pm";
    use lib "$Perceus_Include::libdir/Perceus";

}

#use Perceus::Util;
#use Perceus::Debug;
#use Perceus::Nodes;
#use Perceus::DB;
#use Perceus::Groups;
#use Perceus::Vnfs;
#use Perceus::Modules;
#use Perceus::About;
#use Perceus::Config;
#use Perceus::Configure;
#use Perceus::System;
#use Perceus::Contact;
#use File::Basename;
#use Fcntl;




1;
