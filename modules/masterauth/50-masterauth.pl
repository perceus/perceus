#!/usr/bin/perl
#
# Copyright (c) 2006-2009, Greg M. Kurtzer, Arthur A. Stevens and
# Infiscale, Inc. All rights reserved
#

use strict;

my $passwd = ();
my $group = ();
my $passwd_chksum = ();
my $group_chksum = ();

my $dir = "/etc";

while(my @pw = getpwent()) {
    $passwd .= "$pw[0]:x:$pw[2]:$pw[3]:$pw[6]:$pw[7]:$pw[8]\n";
}
#$passwd_chksum = unpack("%32C*", $passwd) % ( 2 ** 16 );
$passwd_chksum = &sum($passwd);

while(my @gr = getgrent()) {
    my $users = join(",", split(/\s+/, $gr[3]));
    $group .= "$gr[0]:x:$gr[2]:$users\n";
}
#$group_chksum = unpack("%32C*", $group) % ( 2 ** 16 ) ;
$group_chksum = &sum($group);

# First check to see if sum is present on this host, and if so then
# go ahead and be smart about when/how to update the files.
print "if which sum >/dev/null 2>&1; then\n";
print "SUM=\`sum -r $dir/passwd | cut -d \" \" -f 1\`\n";
print "if [ \"x\$SUM\" != \"x$passwd_chksum\" ]; then\n";
print "cat <<EOF > $dir/.perceus_passwd\n";
print "$passwd";
print "EOF\n";
print "chmod --reference $dir/passwd $dir/.perceus_passwd\n";
print "mv $dir/.perceus_passwd $dir/passwd\n";
print "fi\n";
print "SUM=\`sum -r $dir/group | cut -d \" \" -f 1\`\n";
print "if [ \"x\$SUM\" != \"x$group_chksum\" ]; then\n";
print "cat <<EOF > $dir/.perceus_group\n";
print "$group";
print "EOF\n";
print "chmod --reference $dir/group $dir/.perceus_group\n";
print "mv $dir/.perceus_group $dir/group\n";
print "fi\n";
# So sum didn't exist, so now its brute force time.
print "else\n";
print "cat <<EOF > $dir/passwd\n";
print "$passwd";
print "EOF\n";
print "cat <<EOF > $dir/group\n";
print "$group";
print "EOF\n";
print "fi\n";


sub sum {
    my($string) = shift;
    my($crc) = my($len) = 0;
    my($num,$i);

    $num = length($string);
    for($len = ($len+$num), $i = 0; $i<$num; $i++) {
        $crc |= 0x10000 if ( $crc & 1 ); # get ready for rotating the 1 below
        $crc = (($crc>>1)+ord(substr $string, $i, 1)) & 0xffff; # keep to 16-bit
    }
    
    return $crc;
}
