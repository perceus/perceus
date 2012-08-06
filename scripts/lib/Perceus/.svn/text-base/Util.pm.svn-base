
#
# Copyright (c) 2006-2009, Greg M. Kurtzer, Arthur A. Stevens and
# Infiscale, Inc. All rights reserved
#

package Perceus::Util;
use strict;
use warnings;

BEGIN {

   use Exporter;

   our @ISA = ('Exporter');

   our @EXPORT = qw (
      &time_h
      &addr2bin
      &bin2addr
      &rand_string
      &expand_bracket_range
      &get_local_devs
      &get_ipaddr
      &get_netmask
      &network
      &default_node_addr_start
      &default_node_addr_stop
      &default_dhcp_addr_start
      &network_end
      &confirm_list
      &array_untaint
      &untaint
      &getarg
      &getargs
      &getargc
      &pxenodeconf
   );

   require "/etc/perceus/Perceus_Include.pm";
   push(@INC, "$Perceus_Include::libdir");

}

use Socket;
use IO::Socket;
use IO::Interface;
use Perceus::CUI;
use Perceus::DB;
use Perceus::Debug;
use Perceus::System;
use File::Path;
use File::Basename;
use DB_File;


sub
addr2bin($)
{
    &dprint("Entered function");

    my $addr            = shift();
    my $return          = ();

    if ( $addr =~ /^\d+\.\d+\.\d+\.\d+$/ ) {
        $return         = unpack("N", inet_aton($addr));
    } else {
        $return         = "0";
        &vprint("Can not convert '$addr' to binary address format!\n");
    }

    if ( $return ) {
        &dprint("Returning function with: $return");
    } else {
        &dprint("Returning function undefined");
    }
    return($return);;
}

sub
bin2addr($)
{
    &dprint("Entered function");

    my $bin             = shift();
    my $return          = ();

    &dprint("Input: $bin");

    if ( $bin =~ /^\d+$/ ) {
        $return         = inet_ntoa(pack('N',$bin));
    } else {
        $return         = "0.0.0.0";
        &vprint("Can not convert '$bin' to IP address format!\n");
    }

    if ( $return ) {
        &dprint("Returning function with: $return");
    } else {
        &dprint("Returning function undefined");
    }
    return($return);
}

sub
time_h($)
{
    &dprint("Entered function");

    my $seconds         = shift;
    my $hours           = ();
    my $minutes         = ();
    my $tmp             = ();
    my $return          = ();

    if ( $seconds =~ /^\d+$/ ) {

        if ( $seconds >= 0 ) {
            $hours = sprintf("%d", $seconds / 3600);
            $tmp = $seconds - ( $hours*3600);
            $minutes = sprintf("%d", $tmp / 60);
            $tmp = $tmp - ( $minutes*60);
            $return = sprintf("%2.2d:%2.2d:%2.2d", $hours, $minutes, $tmp );
        } else {
            $return = "unknown";
        }
    } else {
        &dprint("Non numeric seconds param: '$seconds'");
        $return = "xx:xx:xx";
    }

    return($return);
}



sub getargc {
   my $arg_array_ptr    = shift;

   return(scalar @{$arg_array_ptr});
}

sub getarg {
   my $arg_array_ptr    = shift;
   my $caller           = ();
   my $return           = ();

   $return = shift(@{$arg_array_ptr});

   (undef, undef, undef, $caller) = caller(1);

   if ( defined($return) ) {
      &dprint("Processed argument for $caller: '$return'");
   } else {
      &dprint("Processed argument for $caller: undef");
   }

   return($return);
}

sub getargs {
   my $arg_array_ptr    = shift;
   my $caller           = ();
   my @return           = ();

   push(@return, @{$arg_array_ptr});

   (undef, undef, undef, $caller) = caller(1);

   if ( defined($return[0]) ) {
      &dprint("Processed argument for $caller: '@return'");
   } else {
      &dprint("Processed argument for $caller: undef");
   }

   return(@return);
}

sub array_untaint {
   &dprint("Entered function");

   my @array            = &getargs(\@_);
   my @return           = ();

   foreach ( @array ) {
      push(@return, &untaint($_));
   }

   &dprint("Returning function with array: @return");
   return(@return);
}

sub untaint {
   &dprint("Entered function");

   my $scalar           = &getarg(\@_);
   my $return           = ();

   if ( $scalar ) {

      if ( $scalar =~ /^([^;\|\{\}\(\)\!\`\$]+)$/ ) {
         $return = $1;
      } else {
         &iprint("Refusing to process the string: '$scalar'!");
         exit 1;
      }
   }

   if ( $return ) {
      &dprint("Returning function with: $return");
   } else {
      &dprint("Returning function undefined");
   }
   return($return);
}

sub confirm_list {
   &dprint("Entered function");

   my $message          = &getarg(\@_);
   my @list             = &getargs(\@_);
   my $out              = ();
   my $return           = ();
   my $count            = $#list+1;

   chomp $message;

   foreach ( @list ) {
      print "   $_\n";
   }

   $message =~ s/#COUNT#/$count/g;

   print "\n$message\n";
   
   if ( $main::opt_yes ) {
      return(1);
   } elsif ( $main::opt_no ) {
      return();
   }

   while (1) {
      $out = &getinput("Please Confirm [yes/no]> ");

      if ( $out eq "yes" or $out eq "y" ) {
         $return = 1;
         last;
      } elsif ( $out eq "no" or $out eq "n" ) {
         last;
      }
   }

   if ( $return ) {
      &dprint("Returning function with: $return");
   } else {
      &dprint("Returning function undefined");
   }
   return($return);
}

sub get_local_devs {
   &dprint("Entered function");

   my @return           = ();
   my $s                = IO::Socket::INET->new(Proto => 'udp');

   foreach ( $s->if_list ) {
      next if ( $_ eq 'lo' );
      next if ( $_ eq 'sit0' );
      next if ( ! &get_ipaddr($_) );
      push(@return,$_);
   }

   if ( @return ) {
      &dprint("Returning function with: @return");
   } else {
      &dprint("Returning function undefined");
   }
   return(@return);
}

sub get_ipaddr {
   &dprint("Entered function");

   my $device           = &getarg(\@_);
   my $s                = IO::Socket::INET->new(Proto => 'udp');
   my $return           = $s->if_addr($device);

   if ( $return ) {
      &dprint("Returning function with: $return");
   } else {
      &dprint("Returning function undefined");
   }
   return($return);
}

sub get_netmask {
   &dprint("Entered function");

   my $device           = &getarg(\@_);
   my $s                = IO::Socket::INET->new(Proto => 'udp');
   my $return           = $s->if_netmask($device);

   if ( $return ) {
      &dprint("Returning function with: $return");
   } else {
      &dprint("Returning function undefined");
   }
   return($return);
}

sub network {
   &dprint("Entered function");

   my $network          = &getarg(\@_);
   my $mask             = &getarg(\@_);
   my $net_bin          = unpack("N", inet_aton("$network"));
   my $mask_bin         = unpack("N", inet_aton("$mask"));
   my $addr             = ( $net_bin & $mask_bin ) | ( 0 & ~$mask_bin );
   my $return           = inet_ntoa(pack('N',$addr));

   if ( $return ) {
      &dprint("Returning function with: $return");
   } else {
      &dprint("Returning function undefined");
   }
   return($return);
}

sub network_end {
   &dprint("Entered function");

   my $network          = &getarg(\@_);
   my $mask             = &getarg(\@_);
   my $net_bin          = unpack("N", inet_aton("$network"));
   my $mask_bin         = unpack("N", inet_aton("$mask"));
   my $addr             = ( $net_bin & $mask_bin ) | ( ~$mask_bin & 0xffffffff );
   my $return           = inet_ntoa(pack('N',$addr-1));

   if ( $return ) {
      &dprint("Returning function with: $return");
   } else {
      &dprint("Returning function undefined");
   }
   return($return);
}

sub default_node_addr_start {
   &dprint("Entered function");

   my ($network, $mask, @null) = &getargs(\@_);
   my $net_bin          = unpack("N", inet_aton("$network"));
   my $mask_bin         = unpack("N", inet_aton("$mask"));
   my $twiddle          = ((~$mask_bin & 0xffffffff) + 1) >> 2;
   if ( $twiddle > 256 ) {
      $twiddle = 256;
   }
   my $addr             = ( $net_bin & $mask_bin ) | ( ( $twiddle ) & ~$mask_bin );
   $addr                = inet_ntoa(pack('N',"$addr"));

   if ( $addr ) {
      &dprint("Returning function with: $addr");
   } else {
      &dprint("Returning function undefined");
   }
   return $addr;
}

sub default_node_addr_stop {
   &dprint("Entered function");

   my ($network, $mask, @null) = &getargs(\@_);
   my $net_bin          = unpack("N", inet_aton("$network"));
   my $mask_bin         = unpack("N", inet_aton("$mask"));
   my $twiddle          = ((~$mask_bin & 0xffffffff)) >> 2;
   if ( $twiddle > 256 ) {
      $twiddle = 256;
   }
   my $addr             = ( $net_bin & $mask_bin ) | ( ~$mask_bin ) - $twiddle -1 ;
   $addr                = inet_ntoa(pack('N',"$addr"));

   if ( $addr ) {
      &dprint("Returning function with: $addr");
   } else {
      &dprint("Returning function undefined");
   }
   return $addr;
}

sub default_dhcp_addr_start {
   &dprint("Entered function");

   my ($network, $mask, @null) = &getargs(\@_);
   my $net_bin          = unpack("N", inet_aton("$network"));
   my $mask_bin         = unpack("N", inet_aton("$mask"));
   my $twiddle          = ((~$mask_bin & 0xffffffff)) >> 2;
   if ( $twiddle > 256 ) {
      $twiddle = 256;
   }
   my $addr             = ( $net_bin & $mask_bin ) | ( ~$mask_bin ) - $twiddle;
   $addr                = inet_ntoa(pack('N',"$addr"));

   if ( $addr ) {
      &dprint("Returning function with: $addr");
   } else {
      &dprint("Returning function undefined");
   }
   return $addr;
}

sub expand_bracket_range {
   &dprint("Entered function");

   my @arguments        = &getargs(\@_);
   my @ret              = ();
   my $prefix           = ();
   my $arg              = ();
   my $r1               = ();
   my $r2               = ();
   my $rl1              = ();
   my $rl2              = ();
   my $len              = ();
   my $suffix           = ();
   my @l                = ();

   foreach $arg ( @arguments ) {
      if ( $arg =~ /^(.*)\[(.+)\](.*)$/ ) {
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
                  push(@ret, sprintf("%s%.${len}d%s", $prefix, $r1, $suffix));
               }
            } elsif ( $_ =~ /^(\d+)$/ ) {
               $len = length($_);
               push(@ret, sprintf("%s%.${len}d%s", $prefix, $_, $suffix));
            }
         }
      } else {
         push(@ret, $arg);
      }
   }

   if ( @ret ) {
      &dprint("Returning function with: @ret");
   } else {
      &dprint("Returning function undefined");
   }
   return(@ret);
}


sub rand_string {
   &dprint("Entered function");

   my $size             = &getarg(\@_);
   my @alphanumeric     = ('a'..'z', 'A'..'Z', 0..9);
   my $randstring       = join '', map $alphanumeric[rand @alphanumeric], 0..$size;

   if ( $randstring ) {
      &dprint("Returning function with: $randstring");
   } else {
      &dprint("Returning function undefined");
   }
   return $randstring;
}


sub
pxenodeconf(@)
{
    &dprint("Entered function");
    
    my $boot            = shift;
    my $nodeid          = lc(shift);
    my $return          = 0;

    if ( $nodeid =~ /^(01:)?(([0-9a-z]{2}:){5}[0-9a-z]{2})$/ ) {
        my $pxelinux_addr = "01-$2";
        $pxelinux_addr =~ s/:/-/g;

        if ( $boot eq "default" ) {
            if ( -f "$Perceus_Include::statedir/tftp/pxelinux.cfg/$pxelinux_addr") {
                if ( unlink("$Perceus_Include::statedir/tftp/pxelinux.cfg/$pxelinux_addr") ) {
                    $return = 1;
                }
            } else {
                $return = 1;
            }

        } elsif ( $boot eq "perceus" ) {
            my $entry;
            my $found;
            my $default = "default perceus\n";
            open(DEFAULT, "$Perceus_Include::statedir/tftp/pxelinux.cfg/default");
            while(<DEFAULT>) {
               chomp;
                if ( $_ =~ /^label perceus/ ) {
                    $entry = 1;
                    $found = 1;
                } elsif ( $_ =~ /^label / ) {
                    $entry = ();
                }
                if ( defined($entry) ) {
                    $default .= "$_\n";
                }
            }
            close DEFAULT;
            if ( defined($found) ) {
                if ( open(CFG, "> $Perceus_Include::statedir/tftp/pxelinux.cfg/$pxelinux_addr") ) {
                    print CFG $default;
                    close CFG;
                    $return = 1;
                }
            } else {
                &eprint("Could not find perceus boot template in default pxelinux.cfg!");
            }
        } elsif ( $boot eq "cloud" ) {
            my $entry;
            my $found;
            my $default = "default cloud\n";
            open(DEFAULT, "$Perceus_Include::statedir/tftp/pxelinux.cfg/default");
            while(<DEFAULT>) {
               chomp;
                if ( $_ =~ /^label cloud/ ) {
                    $entry = 1;
                    $found = 1;
                } elsif ( $_ =~ /^label / ) {
                    $entry = ();
                }
                if ( defined($entry) ) {
                    $default .= "$_\n";
                }
            }
            close DEFAULT;
            if ( defined($found) ) {
                if ( open(CFG, "> $Perceus_Include::statedir/tftp/pxelinux.cfg/$pxelinux_addr") ) {
                    print CFG $default;
                    close CFG;
                    $return = 1;
                }
            } else {
                &eprint("Could not find perceus boot template in default pxelinux.cfg!");
            }
        } elsif ( $boot eq "local" ) {

            if ( open(CFG, "> $Perceus_Include::statedir/tftp/pxelinux.cfg/$pxelinux_addr") ) {
                print CFG "default local\n";
                print CFG "label local\n";
                print CFG "kernel chain.c32\n";
                print CFG "append hd0\n";
                close CFG;
                $return = 1;
            }
        } else {
            &eprint("Valid boot options are: 'perceus', 'cloud', 'local' or 'default'");
        }
    } else {
        &wprint("Bad hardware address ($nodeid)");
    }

    &dprint("Returning function with: $return");
    return($return);
}

1;
