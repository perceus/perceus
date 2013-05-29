
#
# Copyright (c) 2006-2013, Infiscale
# astevens@infiscale.com
#


package Perceus::Configure;
use Perceus::Util;
use strict;
use warnings;

BEGIN {

   use Exporter;

   our @ISA = ('Exporter');

   our @EXPORT = qw (
      &configure_nfs
      &configure_apache
      &configure_sshkeys
      &configure_dhcpd
      &configure_hosts
      &init_all
   );

   require "/etc/perceus/Perceus_Include.pm";
   push(@INC, "$Perceus_Include::libdir");

}

use Perceus::CUI;
use Perceus::Debug;
use Perceus::DB;
use Perceus::Util;
use Perceus::Config;
use Perceus::System;
use Perceus::Contact;
use Perceus::Sanity;
use Perceus::Nodes;
use File::Path;
use IO::Socket;


sub init_all {
   &dprint("Entered function");

   while (1) {
      my $tmp;
      if ( $main::opt_quiet ) {
         $tmp = "yes";
      } else {
         $tmp = &getinput("Do you wish to have Perceus do a complete system initialization (yes/no)? ");
      }
      if ( $tmp eq "yes" ) {
         &configure_dhcpd();
         &configure_sshkeys();
         &check_database();
         &configure_nfs();
         if ( $main::config{"vnfs transfer method"}[0] eq "http" ) {
            &configure_apache();
         }
         &iprint("\nPerceus is now ready to begin provisioning your cluster!");
         exit;
         last;
      } elsif ( $tmp eq "no" ) {
         &eprint("Perceus was not configured!");
         exit(1);
      }
   }

   &dprint("Returning function");
   return(0);
}

sub configure_apache {
   &dprint("Entered function");

   my $httpd_conf       = ();
   my $ipaddr           = ();
   my $netmask          = ();
   my $network          = ();
   my %config           = &parse_config("/etc/perceus/perceus.conf");
   my $vnfsdir          = $config{"vnfs transfer prefix"}[0];
   my $eth              = $config{"master network device"}[0];
   my $vnfsmaster       = $config{"vnfs transfer master"}[0];

   if ( ! $vnfsmaster ) {
      $ipaddr = &get_ipaddr($eth);
   }
   $netmask = &get_netmask($eth);
   $network = &network($ipaddr, $netmask);

   if ( -d "/etc/httpd/conf.d" ) {
      $httpd_conf = "/etc/httpd/conf.d/perceus.conf";
   } else {
      &eprint("Couldn't locate where to write the perceus.conf for Apache!");
   }

   open(CONF, "> $httpd_conf");
   print CONF "# HTTPD configuration file for Perceus\n\n";
   print CONF "Alias $vnfsdir/perceus \"$Perceus_Include::statedir\"\n";
   print CONF "<Directory $Perceus_Include::statedir>\n";
   print CONF "    Order deny,allow\n";
   print CONF "    Deny from all\n";
   print CONF "    Allow from $network/$netmask\n";
   print CONF "</Directory>\n";
   close CONF;

   &iprint("Wrote apache configuration for Perceus: $httpd_conf");
   
   &dprint("Returning function");
   return(0);
}


sub configure_dhcpd {
   &dprint("Entered function");

   my $start            = ();
   my $end              = ();
   my $domain           = ();
   my $domainname       = ();
   my $ethdef           = ();
   my $master           = ();
   my $console          = ();
   my %config           = &parse_config("/etc/perceus/perceus.conf");
   my $eth              = $config{"master network device"}[0];
   my $ipaddr           = &get_ipaddr($eth);
   my $netmask          = &get_netmask($eth);
   my $network          = &network($ipaddr, $netmask);
   my $range_start      = &default_dhcp_addr_start($network, $netmask);
   my $range_end        = &network_end($network, $netmask);

   if ( ! $main::opt_quiet ) {
      &iprint("\nWhat IP address should the node boot address range start at?");
      $start = &getinput("($range_start)> ");
   }
   if ( ! $start ) {
      $start = $range_start;
   }
   if ( ! $main::opt_quiet ) {
      &iprint("\nWhat IP address should the node boot address range end at?");
      $end = &getinput("($range_end)> ");
   }
   if ( ! $end ) {
      $end = $range_end;
   }

   &dprint("trying to figure out default domainname");
   if ( `/bin/hostname` =~ /^[^\.]+\.(.+)$/ ) {
      $domainname = $1;
      &dprint("used output of '/bin/hostname'");
   } elsif ( `/bin/hostname -d` =~ /^(.+)$/ ) {
      $domainname = $1;
      &dprint("used output of '/bin/hostname -d'");
   } elsif ( `/bin/hostname -f` =~ /^[^\.]+\.(.+)$/ ) {
      $domainname = $1;
      &dprint("used output of '/bin/hostname -f'");
   } else {
      $domainname = "cluster";
      &dprint("Invented default domainname 'cluster'");
   }

   if ( ! $main::opt_quiet ) {
      &iprint("\nWhat domain name should be appended to the DNS records for each entry in DNS?");
      &iprint("This won't require you to specify the domain for DNS lookups, but it prevents");
      &iprint("conflicts from other non-local hostnames.");
      $domain = &getinput("($domainname)> ");
   }
   if ( ! $domain ) {
      $domain = $domainname;
   }

   if ( ! $main::opt_quiet ) {
      &iprint("\nWhat device should the booting node direct its console output to? Typically");
      &iprint("this would be set to 'tty0' unless you are monitoring your nodes over the");
      &iprint("serial port. A typical serial port option might be 'ttyS0,115200'.");
      &iprint("note: This is a global option which will affect all booting nodes.");
      $console = &getinput("(tty0)> ");
   }
   if ( ! $console ) {
      $console = "tty0";
   }

   open(DHCPD, "> /etc/perceus/dnsmasq.conf");
   print DHCPD "interface=$eth\n";
   print DHCPD "enable-tftp\n";
   print DHCPD "tftp-root=$Perceus_Include::statedir/tftp\n";
   print DHCPD "dhcp-option=vendor:Etherboot,60,\"Etherboot\"\n";
   if ( $Perceus_Include::enable_gpxe eq "yes" ) {
      print DHCPD "dhcp-boot=gpxelinux.0\n";
   } else {
      print DHCPD "dhcp-boot=pxelinux.0\n";
   }
   print DHCPD "local=//\n";
   print DHCPD "domain=$domain\n";
   print DHCPD "expand-hosts\n";
   print DHCPD "dhcp-range=$start,$end\n";
   print DHCPD "dhcp-lease-max=21600\n";
   print DHCPD "read-ethers\n";
   close DHCPD;
   
   mkpath("$Perceus_Include::statedir/tftp/pxelinux.cfg");
   open(TFTP, "> $Perceus_Include::statedir/tftp/pxelinux.cfg/default")
      or &wprint("ERROR: Could not open $Perceus_Include::statedir/tftp/pxelinux.cfg/default for writing!");

   print TFTP "menu color border   36;40      #80ffffff #00000000 std\n";
   print TFTP "menu color title    37;40      #80c74a34 #00000000 std\n";
   print TFTP "menu color unsel     37;40     #80ffffff #00000000 std\n";
   print TFTP "menu color sel      7;40;34     #80ffffff #00000000 std\n";
   print TFTP "menu color disabled  37;40     #80ffffff #00000000 std\n";
   print TFTP "\n";
   print TFTP "default menu.c32\n";
   print TFTP "prompt 0\n";
   print TFTP "\n";
   print TFTP "menu title Welcome to the Perceus boot loader!\n";
   print TFTP "menu autoboot Booting to Perceus in # seconds\n";
   print TFTP "menu rows 6\n";
   print TFTP "menu cmdlinerow 12\n";
   print TFTP "menu timeoutrow -1\n";
   print TFTP "menu helpmsgrow 11\n";
   print TFTP "menu helpmsgendrow -2\n";
   print TFTP "\n";
   print TFTP "timeout 100\n";
   print TFTP "\n";
   print TFTP "label perceus\n";
   print TFTP "menu label Perceus: High performance cluster management\n";
   print TFTP "kernel /kernel\n";
   print TFTP "append rw initrd=initramfs.img root=/dev/root ramdisk_blocksize=1024 noapic masterip=$ipaddr console=tty0 quiet\n";
   print TFTP "text help\n";
   print TFTP "Perceus: High performance cluster management\n";
   print TFTP "\n";
   print TFTP "Perceus solves many of the scalability problems that occur when managing\n";
   print TFTP "multiple similar or groups of similar systems.  \n";
   print TFTP "\n";
   print TFTP "endtext\n";
   print TFTP "\n";
   print TFTP "label local\n";
   print TFTP "menu label Boot from local disk\n";
   print TFTP "kernel chain.c32\n";
   print TFTP "append hd0\n";
   print TFTP "text help\n";
   print TFTP "Boot on your local disk\n";
   print TFTP "\n";
   print TFTP "If you have a local disk, this option will bypass the Perceus provisioning\n";
   print TFTP "and will attempt to boot this system from the primary local drive.\n";
   print TFTP "\n";
   print TFTP "endtext\n";
   print TFTP "\n";
   print TFTP "menu separator\n";
   print TFTP "\n";
   print TFTP "label memtest\n";
   print TFTP "menu label Memory test\n";
   print TFTP "kernel memtest\n";
   print TFTP "append hd0\n";
   print TFTP "text help\n";
   print TFTP "System memory test\n";
   print TFTP "\n";
   print TFTP "This option will search for memory errors and report findings using\n";
   print TFTP "Memtest86+ (enhanced version of the original Memtest86).\n";
   print TFTP "endtext\n";
   print TFTP "\n";
   print TFTP "label cloud\n";
   print TFTP "menu label Perceus cloud provisioning\n";
   print TFTP "kernel /kernel\n";
   print TFTP "append rw initrd=initramfs.img root=/dev/root ramdisk_blocksize=1024 noapic masterip=cloud console=tty0 quiet\n";
   print TFTP "text help\n";
   print TFTP "Perceus provisioning via the \"Cloud\"\n";
   print TFTP "\n";
   print TFTP "Perceus has the ability to provision this system via VNFS and application\n";
   print TFTP "hosting providers over the internet. Select this option to enable this\n";
   print TFTP "feature.\n";
   print TFTP "endtext\n";
   print TFTP "\n";
   print TFTP "label perceus-debug\n";
   print TFTP "menu label Boot into Perceus with debugging enabled\n";
   print TFTP "kernel /kernel\n";
   print TFTP "append rw initrd=initramfs.img root=/dev/root ramdisk_blocksize=1024 noapic masterip=$ipaddr console=tty0 enable-debug=1\n";
   print TFTP "text help\n";
   print TFTP "Boot into Perceus with debugging enabled.\n";
   print TFTP "\n";
   print TFTP "Selecting this option to boot into Perceus with a local master with debugging\n";
   print TFTP "enabled.\n";
   print TFTP "endtext\n";

   &dprint("Returning function");
   return(0);
}

sub configure_nfs {
   &dprint("Entered function");

   my $local_nfs        = ();
   my $noupdate_needed  = ();
   my %config           = &parse_config("/etc/perceus/perceus.conf");
   my $eth              = $config{"master network device"}[0];
   my $ipaddr           = &get_ipaddr($eth);
   my $netmask          = &get_netmask($eth);
   my $network          = &network($ipaddr, $netmask);
   my $vnfsdir          = $config{"vnfs transfer prefix"}[0];

   if ( ! exists($config{"vnfs transfer master"}[0]) or $config{"vnfs transfer master"}[0] eq $ipaddr ) {
      if ( ! $vnfsdir ) {
         $vnfsdir = $Perceus_Include::statedir;
      }
      open(EXPORTS, "/etc/exports");
      while (<EXPORTS>) {
         chomp;
         $_ =~ s/\/\//\//g;
         $_ =~ s/\/$//g;
         my $tmp = $vnfsdir;
         $tmp =~ s/\/\//\//g;
         $tmp =~ s/\/$//g;
         if ( $_ =~ /^\Q$tmp\E/ ) {
            &iprint("No update to /etc/exports done... (export already present)");
            $noupdate_needed = 1;
            last;
         }
      }
      if ( ! $noupdate_needed ) {
         close EXPORTS;
         open(EXPORTS, ">>/etc/exports");
         print EXPORTS "$vnfsdir $network/$netmask(ro,no_root_squash,async)\n";
         close EXPORTS;
      }

   } else {
      &iprint("No local NFS server required for Perceus (as defined by perceus.conf)");
   }

   &dprint("Returning function");
   return(0);
}

sub configure_sshkeys {
   &dprint("Entered function");

   mkpath("/root/.ssh");

   if ( ! -f "/root/.ssh/perceus" ) {
      &iprint("Creating Perceus ssh keys");
      &runcmd("ssh-keygen -t dsa -f /root/.ssh/perceus -N ''");
      if ( -f "/root/.ssh/config" ) {
         system("grep -q 'IdentityFile /root/.ssh/perceus' /root/.ssh/config 2>/dev/null");
         if ( $? != "0" ) {
            system("grep -q '^Host *' ~/.ssh/config 2>/dev/null");
            if ( $? == "0" ) {
               open(CONF, ">> /root/.ssh/config");
               print CONF "   IdentityFile ~/.ssh/identity\n";
               print CONF "   IdentityFile ~/.ssh/id_rsa\n";
               print CONF "   IdentityFile ~/.ssh/id_dsa\n";
               print CONF "   IdentityFile ~/.ssh/perceus\n";
               close CONF;
            } else {
               open(CONF, ">> /root/.ssh/config");
               print CONF "Host *\n";
               print CONF "   IdentityFile ~/.ssh/identity\n";
               print CONF "   IdentityFile ~/.ssh/id_rsa\n";
               print CONF "   IdentityFile ~/.ssh/id_dsa\n";
               print CONF "   IdentityFile ~/.ssh/perceus\n";
               close CONF;
            }
         }
      } else {
         open(CONF, ">> /root/.ssh/config");
         print CONF "Host *\n";
         print CONF "   IdentityFile ~/.ssh/identity\n";
         print CONF "   IdentityFile ~/.ssh/id_rsa\n";
         print CONF "   IdentityFile ~/.ssh/id_dsa\n";
         print CONF "   IdentityFile ~/.ssh/perceus\n";
         close CONF;
      }
   } else {
      &iprint("Perceus ssh keys are already present at /root/.ssh/perceus");
   }

   if ( ! -d "/etc/perceus/keys" ) {
      mkpath("/etc/perceus/keys");
   }

   if ( ! -f "/etc/perceus/keys/ssh_host_key" ) {
      &runcmd("/usr/bin/ssh-keygen  -q -t rsa1 -f /etc/perceus/keys/ssh_host_key -C '' -N ''", 0);
      &iprint("Created Perceus ssh host keys");
   } else {
      &iprint("Perceus ssh host keys are already present");
   }
   if ( ! -f "/etc/perceus/keys/ssh_host_rsa_key" ) {
      &runcmd("/usr/bin/ssh-keygen  -q -t rsa -f /etc/perceus/keys/ssh_host_rsa_key -C '' -N ''", 0);
      &iprint("Created Perceus ssh rsa host keys");
   } else {
      &iprint("Perceus ssh host rsa keys are already present");
   }
   if ( ! -f "/etc/perceus/keys/ssh_host_dsa_key" ) {
      &runcmd("/usr/bin/ssh-keygen  -q -t dsa -f /etc/perceus/keys/ssh_host_dsa_key -C '' -N ''", 0);
      &iprint("Created Perceus ssh dsa host keys");
   } else {
      &iprint("Perceus ssh host dsa keys are already present");
   }

   &dprint("Returning function");
   return(0);
}

sub
configure_hosts()
{
    my %config                  = &parse_config("/etc/perceus/perceus.conf");
    my $eth                     = $config{"master network device"}[0];
    my %defaults                = &parse_config("/etc/perceus/defaults.conf");
    my $ipaddr                  = &get_ipaddr($eth);
    my $netmask                 = &get_netmask($eth);
    my $network                 = &network($ipaddr, $netmask);
    my $node_range_start        = &default_node_addr_start($network, $netmask);
    my $node_range_stop         = &default_node_addr_stop($network, $netmask);
    my $node_range_start_bin    = &addr2bin($node_range_start);
    my $node_range_stop_bin     = &addr2bin($node_range_stop);
    my $startnum                = ();
    my $totalnum                = ();
    my $newnodename             = ();
    my $nameprefix              = ();
    my $namenum                 = ();
    my $namesuffix              = ();
    my @hosts                   = ();

    my $dhcp_range_start        = &default_dhcp_addr_start($network, $netmask);



    if ( defined $defaults{"First Node"}[0] ) {
        $startnum = $defaults{"First Node"}[0];
    }

    if ( defined $defaults{"Total Nodes"}[0] ) {
        $totalnum = $defaults{"Total Nodes"}[0] - 1;
    } else {
        $totalnum = sprintf("%d", 9 x $namenum);
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

    open(HOSTS, "/etc/hosts");
    @hosts = <HOSTS>;
    close HOSTS;

    for(my $i=$startnum; $i<=$totalnum+$startnum; $i++) {
        my $number = sprintf("%0.${namenum}d", $i);
        my $address_bin = $node_range_start_bin + $i;
        my $address = &bin2addr($address_bin);
        my $update;

        if ( $address_bin+1 >= $node_range_stop_bin ) {
            &wprint("Defined range larger then network allows. Stopping at $i nodes");
            last;
        }

        $newnodename = "$nameprefix$number$namesuffix";
        for(my $a=0;$a<scalar(@hosts);$a++) {
            if ( $hosts[$a] =~ / $newnodename( |\n$)/ ) {
                $hosts[$a] = "$address\t\t$newnodename\n";
                $update = 1;
                last;
            }
        }
        if ( ! $update ) {
            push(@hosts, "$address\t\t$newnodename\n");
        }
    }

    open(HOSTS, "> /etc/hosts");
    foreach (@hosts) {
        print HOSTS "$_";
    }
    close HOSTS;

}

1;
