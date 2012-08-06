#!/usr/bin/perl
#
# Copyright (c) 2006-2009, Greg M. Kurtzer, Arthur A. Stevens and
# Infiscale, Inc. All rights reserved
#

BEGIN {
   require "/etc/perceus/Perceus_Include.pm";
   push(@INC, "$Perceus_Include::libdir");
}

use CGI;
use Perceus::Contact;
use Perceus::Nodes;
use Perceus::Groups;
use Perceus::Vnfs;
use Perceus::Config;
use Perceus::Configure;
use Perceus::Modules;
use Perceus::Sanity;
use Perceus::Status;
use Perceus::System;
use Perceus::Util;
use Perceus::Debug;
use Perceus::DB;
use Getopt::Long;
use File::Basename;
use Fcntl;



my $debug_html_gui = 1;


my %db              = ();
my @databases       = qw(hostname status ipaddr lastcontact group vnfs debug desc enabled);

foreach my $db ( @databases ) {
   $db{"$db"} = &opendb($db, O_RDWR);
}


my %config = &parse_config("/etc/perceus/perceus.conf");


if ( $ENV{PATH_INFO} =~ /\/(.+)[\/(.+)]?$/ ) {
   $command = $1;
   $options = $1;
}

$q = new CGI;

%params = $q->Vars;

#foreach ( keys %tmp_params ) {
#   $tmp_params{"$_"} =~ s/;/\\;/g;
##   $tmp_params{"$_"} =~ s/"/\\"/g;
#   $params{"$_"} = "$tmp_params{$_}";
#}

#foreach ( keys %params ) {
#   print "$_: $params{$_}<br>\n";
#}

open(HTML, "main.html");
while($line=<HTML>) {
   $main_html .= $line;
}
close HTML;

# Color tabs.
my $unselected = 'style="background-color:#CCCCCC"';
my $selected = 'style="background-color:#999999"';
$main_html =~ s/%%node%%/$selected/g;

#foreach ( keys %ENV ) {
#   $html .= "$_: $ENV{$_}<br>\n";
#}

if ( defined($params{"node_set"}) and defined($params{"nodeid"})) {
   if ( $params{"hostname"} =~ /.+/ ) {
      if ( ! $db{"hostname"}->get_key($params{"hostname"})) {
         $params{"hostname"} =~ s/ /_/g;
         $db{"hostname"}->set($q->param("nodeid"), $params{"hostname"});
         $redirect_url = "?nodeconfig=$params{hostname}";
      } else {
         $error .= "The node hostname '$params{hostname} already exists!";
      }
   }
   if ( $params{"vnfs"} =~ /.+/ ) {
      if ( &vnfs_exists($params{"vnfs"}) ) {
         foreach my $nodeid ( $q->param('nodeid') ) {
            $db{"vnfs"}->set($nodeid, $params{"vnfs"});
            $warning = "Changes saved";
         }
      }
   }
   if ( $params{"description"} =~ /.+/ ) {
      $db{"desc"}->set($nodeid, $params{"description"});
      $warning = "Changes saved";
   }
   if ( $params{"group"} =~ /.+/ and $params{"group"} ne "Set group" ) {
      $params{"group"} =~ s/ /_/g;
      foreach my $nodeid ( $q->param('nodeid') ) {
         $db{"group"}->set($nodeid, $params{"group"});
         $warning = "Changes saved";
      }
   }
   if ( $params{"options"} eq "debug_up" ) {
      foreach my $nodeid ( $q->param('nodeid') ) {
         $db{"debug"}->set($nodeid,  $db{"debug"}->get($nodeid) + 1);
         $warning = "Changes saved";
      }
   }
   if ( $params{"options"} eq "debug_down" ) {
      foreach my $nodeid ( $q->param('nodeid') ) {
         my $debug = $db{"debug"}->get($nodeid);
         if ( $debug > 0 ) {
            $db{"debug"}->set($nodeid, $debug - 1);
            $warning = "Changes saved";
         }
      }
   }
   if ( $params{"options"} eq "enable_on" ) {
      foreach my $nodeid ( $q->param('nodeid') ) {
         $db{"enabled"}->set($nodeid, "1");
         $warning = "Changes saved";
      }
   }
   if ( $params{"options"} eq "enable_off" ) {
      foreach my $nodeid ( $q->param('nodeid') ) {
         $db{"enabled"}->set($nodeid, "0");
         $warning = "Changes saved";
      }
   }
} elsif ( defined($params{"nodedescription_set"}) and defined($params{"nodeid"})) {
   $db{"desc"}->set($params{"nodeid"}, $params{"description"});
   $redirect_url = "$params{referrer}";
} elsif ( defined($params{"node_set"}) and ! defined($params{"nodeid"})) {
   $error .= "You must select some nodes to operate on!";
}

if ( exists($params{"nodedesc"}) ) {
   $nodeid = $db{"hostname"}->get_key($params{"nodedesc"});

   if ( $nodeid ) {
      $html .= "<div id=title><a href='?nodeconfig=$params{nodedesc}'>$params{nodedesc}</a></div><br/>\n";

      $html .= "<form method=post>\n";
      $html .= "<input type=hidden name=nodedescription_set value=true>\n";
      $html .= "<input type=hidden name=nodeid value=$nodeid>\n";
      $html .= "<input type=hidden name=referrer value=$ENV{HTTP_REFERER}>\n";
      $html .= "<center>\n";
      $html .= "<textarea class=big name=description autofocus=true>";
      $html .= $db{"desc"}->get($nodeid);
      $html .= "</textarea>\n";

      $html .= "<table width=35% border=0><tr><td align=center>\n";
      $html .= "<input type=submit value=\"Save\">\n";
      $html .= "</td><td align=center>\n";
      $html .= "</form>\n";
      $html .= "<form method=post>\n";
      $html .= "<input type=hidden name=nodedescription_set value=true>\n";
      $html .= "<input type=hidden name=nodeid value=$nodeid>\n";
      $html .= "<input type=hidden name=referrer value=$ENV{HTTP_REFERER}>\n";
      $html .= "<input type=hidden name=description value=''>\n";
      $html .= "<input type=submit value=\"Delete\">\n";
      $html .= "</form>\n";
      $html .= "</td></tr></table>\n";
      $html .= "</center>\n";
   } else {
      $html .= "<p><center><font size=+3 color=red align=center>Unknown node!</font></center></p>\n";
   }

} elsif ( exists($params{"nodeconfig"}) ) {

   $nodeid = $db{"hostname"}->get_key($params{"nodeconfig"});

   if ( $nodeid ) {
      $comments = $db{"desc"}->get($nodeid);
      $vnfs = $db{"vnfs"}->get($nodeid);
      $group = $db{"group"}->get($nodeid);
      $ipaddr = &bin2addr($db{"ipaddr"}->get($nodeid));
      $status = $db{"status"}->get($nodeid);
      $lastcontact = $db{"lastcontact"}->get($nodeid);
      $enabled = $db{"enabled"}->get($nodeid);
      $nodedebug = $db{"debug"}->get($nodeid);
   
      if ( $lastcontact ) {
         $nodecontact = time() - $lastcontact;
         if ( defined $config{"node timeout"}[0] and $nodecontact >= $config{"node timeout"}[0] ) {
            $nodestatus = "timed out";
         } elsif ( $enabled > 0 ) {
            $nodestatus = $status;
         } else {
            $nodestatus = "($status)";
         }
         $hours = sprintf("%d", $nodecontact / 3600);
         $tmpcontact = $nodecontact - ( $hours*3600);
         $minutes = sprintf("%d", $tmpcontact / 60);
         $tmpcontact = $tmpcontact - ( $minutes*60);
         $lastcontact = sprintf("%2.2d:%2.2d:%2.2d", $hours, $minutes, $tmpcontact);
      } else {
         $lastcontact = "n/a";
         $nodestatus = "Unknown";
      }
   
      if ( ! $enabled ) {
         $enabled = "0";
      }
      if ( ! $nodedebug ) {
         $nodedebug = "0";
      }
   
      $html .= "<div id=title><font size=+2><a href='?nodeconfig=$params{nodeconfig}'>$params{nodeconfig}</a></font></div><br/>\n";
   
      $html .= "<table border=0 width=100%>\n";
      $html .= "<tr>\n";
      $html .= "<td class=body>";
      $html .= "Node ID\n";
      $html .= "</td><td class=body>\n";
      $html .= "$nodeid\n";
      $html .= "</td></tr><tr><td class=body>\n";
      $html .= "Hostname\n";
      $html .= "</td><td class=body>\n";
      $html .= "<form method=post>\n";
      $html .= "<input type=hidden name=nodeid value='$nodeid'>\n";
      $html .= "<input type=hidden name=node_set value=true>\n";
      $html .= "<input type=hidden name=nodeconfig value=$params{nodeconfig}>\n";
      $html .= "<input type=text name=hostname value='$params{nodeconfig}'>\n";
      $html .= "</form>\n";
      $html .= "</td></tr><tr><td class=body>\n";
      $html .= "Node enabled\n";
      $html .= "</td><td class=body>\n";
      $html .= "<form method=post>\n";
      $html .= "<input type=hidden name=nodeid value='$nodeid'>\n";
      $html .= "<input type=hidden name=node_set value=true>\n";
      $html .= "<input type=hidden name=nodeconfig value=$params{nodeconfig}>\n";
      if ( $enabled > 0 ) {
         $html .= "<input type=hidden name=options value=enable_off>\n";
         $html .= "<input type=submit value='Enabled'>\n";
      } else {
         $html .= "<input type=hidden name=options value=enable_on>\n";
         $html .= "<input type=submit value='Disabled'>\n";
      }
      $html .= "</form>\n";
      $html .= "</td></tr><tr><td class=body>\n";
      $html .= "Node debuging\n";
      $html .= "</td><td class=body>\n";
      $html .= "<table border=0 width=100% cellpadding=0 cellspacing=0><tr><td align=left width=50%>\n";
      $html .= "$nodedebug";
      $html .= "</td><td align=right width=50%>\n";
      $html .= "(<a href=\"?nodeid=$nodeid&options=debug_down&node_set=true&nodeconfig=$params{nodeconfig}\">down</a> / <a href=\"?nodeid=$nodeid&options=debug_up&node_set=true&nodeconfig=$params{nodeconfig}\">up</a>)\n";
      $html .= "</td></tr></table>\n";
      $html .= "</td></tr><tr><td class=body>\n";
   
      $html .= "VNFS\n";
      $html .= "</td><td class=body>\n";
      $html .= "<form method=post>\n";
      $html .= "<input type=hidden name=nodeid value='$nodeid'>\n";
      $html .= "<input type=hidden name=node_set value=true>\n";
      $html .= "<input type=hidden name=nodeconfig value=$params{nodeconfig}>\n";
      $html .= "<select name=vnfs onchange='this.form.submit()'>\n";
      $html .= "<option value=''>$vnfs</option>\n";
      $html .= "<option value='' disabled>------</option>\n";
      foreach (&vnfs_list()) {
         if ( $vnfs ne $_ ) {
            $html .= "<option value=$_>$_</option>\n";
         }
      }
      $html .= "</select>\n";
      $html .= "</form>\n";
      $html .= "</td></tr><tr><td class=body>\n";
      $html .= "Group:\n";
      $html .= "</td><td class=body>\n";
      $html .= "<form method=post>\n";
      $html .= "<input type=hidden name=nodeid value='$nodeid'>\n";
      $html .= "<input type=hidden name=node_set value=true>\n";
      $html .= "<input type=hidden name=nodeconfig value=$params{nodeconfig}>\n";
      $html .= "<input type=text name=group value='$group'>\n";
      $html .= "</form>\n";
      $html .= "</td></tr><tr><td class=body>\n";
      $html .= "Last known IP address\n";
      $html .= "</td><td class=body>\n";
      $html .= "$ipaddr\n";
      $html .= "</td></tr><tr><td class=body>\n";
      $html .= "Last contact from node\n";
      $html .= "</td><td class=body>\n";
      $html .= "$lastcontact\n";
      $html .= "</td></tr><tr><td class=body>\n";
      $html .= "Node status\n";
      $html .= "</td><td class=body>\n";
      $html .= "$nodestatus\n";
      $html .= "</td>\n";
      $html .= "</tr>\n";
      $html .= "</table>\n";
   
      $html .= "<center>\n";
      $html .= "<pre class=desc onclick=\"window.location='?nodedesc=$params{nodeconfig}'\">\n";
      if ( $comments ) {
         $html .= $comments;
      } else {
         $html .= "Click in box to insert comments";
      }
      $html .= "</pre>\n";
      $html .= "</center>\n";

   } else {
      $html .= "<p><center><font size=+3 color=red align=center>Unknown node!</font></center></p>\n";
   }


} else {
   $node_limit = $q->cookie('node_limit');
   if ( defined($params{"node_limit"}) ) {
      if ( $params{"node_limit"} =~ /.+/ ) {
         push(@cookies, $q->cookie(-name=>'node_limit', -value=>$params{"node_limit"},-expires=>'+1h'));
         $node_limit = $params{"node_limit"};
      } else {
         push(@cookies, $q->cookie(-name=>'node_limit', -value=>'', ,-expires=>'+1h'));
         $node_limit = ();
      }
   }
   $group_limit = $q->cookie('group_limit');
   if ( defined($params{"group_limit"}) ) {
      if ( $params{"group_limit"} =~ /.+/ ) {
         push(@cookies, $q->cookie(-name=>'group_limit', -value=>$params{"group_limit"},-expires=>'+1h'));
         $group_limit = $params{"group_limit"};
      } else {
         push(@cookies, $q->cookie(-name=>'group_limit', -value=>'', ,-expires=>'+1h'));
         $group_limit = ();
      }
   }

   $status_limit = $q->cookie('status_limit');
   if ( defined($params{"status_limit"}) ) {
      if ( $params{"status_limit"} =~ /.+/ ) {
         push(@cookies, $q->cookie(-name=>'status_limit', -value=>$params{"status_limit"},-expires=>'+1h'));
         $status_limit = $params{"status_limit"};
      } else {
         push(@cookies, $q->cookie(-name=>'status_limit', -value=>'', ,-expires=>'+1h'));
         $status_limit = ();
      }
   }

   $html .= "<table border=0 cellpadding=0 cellspacing=0 width=100%><tr><td align=left valign=bottom>\n";
   $html .= "<div id=subheader>\n";
   $html .= "Select: <a href='?check=all'>All</a>, <a href='?check=none'>None</a>\n";
   $html .= "</div>\n";
   $html .= "</td><td align=right>\n";

   $html .= "<table border=0 cellpadding=1 cellspacing=0><tr><td>Filter by: </td><td>\n";
   $html .= "<form method=post>\n";
   if ( $node_limit =~ /.+/ ) {
      $html .= "<input class=textual type=text name=node_limit value='$node_limit'>\n";
   } else {
      $html .= "<input class=textual onblur='if(!/\S/.test(this.value))this.value=this.defaultValue' onfocus=\"if(this.value==this.defaultValue)this.value=''\" type=text name=node_limit value='Node name'>\n";
   }
   $html .= "</form></td>\n";
   $html .= "<td><form method=post>\n";
   $html .= "<select name=group_limit onchange='this.form.submit()'>\n";
   $group_default = $group_limit || "Group name";
   $html .= "<option value=''>$group_default</option>\n";
   $html .= "<option value=''>Show all</option>\n";
   $html .= "<option value='' disabled>------</option>\n";
   foreach ($db{group}->list_unique_values() ) {
      $html .= "<option value=$_>$_</option>\n";
   }
   $html .= "</select>\n";
   $html .= "</form></td>\n";
   $html .= "<td><form method=post>\n";
   $html .= "<select name=status_limit onchange='this.form.submit()'>\n";
   $status_default = $status_limit || "Current Status";
   $html .= "<option value=''>$status_default</option>\n";
   $html .= "<option value=''>Show all</option>\n";
   $html .= "<option value='' disabled>------</option>\n";
   foreach ($db{status}->list_unique_values() ) {
      $html .= "<option value=$_>". ucfirst($_) ."</option>\n";
   }
   $html .= "<option value='timed out'>Timed out</option>\n";
   $html .= "</select>\n";
   $html .= "</form>\n";
   $html .= "</td></tr><tr><td>\n";

   $html .= "<form method=post>\n";
   $html .= "</td><td>\n";
   $html .= "<input class=textual onblur='if(!/\S/.test(this.value))this.value=this.defaultValue' onfocus=\"if(this.value==this.defaultValue)this.value=''\" type=text name=group value='Set group'>\n";
   $html .= "</td><td>\n";
   $html .= "<input type=hidden name=node_set value=true>\n";
   $html .= "<select name=vnfs onchange='this.form.submit()'>\n";
   $html .= "<option value=''>Set VNFS</option>\n";
   $html .= "<option value='' disabled>------</option>\n";
   foreach (&vnfs_list()) {
      $html .= "<option value=$_>$_</option>\n";
   }
   $html .= "</select>\n";


   $html .= "</select>\n";
   $html .= "</td><td>\n";
   $html .= "<select name=options onchange='this.form.submit()'>\n";
   $html .= "<option value=''>More options...</option>\n";
   $html .= "<option value='' disabled>------</option>\n";
   $html .= "<option value='enable_on'>   Enable</option>\n";
   $html .= "<option value='enable_off'>   Disable</option>\n";
   $html .= "<option value='debug_up'>   Increase Debugging</option>\n";
   $html .= "<option value='debug_down'>  Decrease Debugging</option>\n";
   $html .= "</select>\n";
   $html .= "</td></tr></table>\n";
   $html .= "</td></tr></table>\n";
   if ( $node_limit =~ /.+/ ) {
      my @nodes;
      $filtering = 1;
      push(@nodes, split(/[ |,]/, $node_limit));
      @list = &nodename2nodeid($db{"hostname"}, &list_node_by_hostname($db{"hostname"}, @nodes));

   } else {
      my @nodes;
      push(@nodes, "*");
      @list = &nodename2nodeid($db{"hostname"}, &list_node_by_hostname($db{"hostname"}, @nodes));
   }
   if ( $group_limit =~ /.+/ ) {
      my @list_tmp = @list;
      $filtering = 1;
      @list = ();
      foreach my $nodeid ( @list_tmp ) {
         if ( $group_limit eq $db{group}->get($nodeid) ) {
            push (@list, $nodeid);
         }
      }
   }
   if ( $status_limit =~ /.+/ ) {
      my @list_tmp = @list;
      $filtering = 1;
      @list = ();
      foreach my $nodeid ( @list_tmp ) {
         $nodecontact = time() - $db{lastcontact}->get($nodeid);
         if ( defined $config{"node timeout"}[0] and $nodecontact >= $config{"node timeout"}[0] ) {
            $status = "timed out";
         } else {
            $status = $db{status}->get($nodeid);
         }
         if ( $status_limit eq $status ) {
            push (@list, $nodeid);
         }
      }
   }

   if ( @list ) {

      foreach ( $q->param('nodeid') ) {
         $selected_nodeids{"$_"} = '1';
      }
      $trcount =1;

      $html .= "<table cellpadding=0 cellspacing=1 width=100% align=center class=body>\n";
      $html .= "<tr><td width=1>&nbsp;</td>";
      $html .= "<td align=center><div id=thead>Node Name</div></td>";
      $html .= "<td align=center><div id=thead>Status</div></td>";
      $html .= "<td align=center><div id=thead>Group Name</div></td>";
      $html .= "<td align=center width=225><div id=thead>VNFS</div></td>";
      $html .= "<td align=center width=200><div id=thead>Description/Comments</div></td>";
      $html .= "<td align=center><div id=thead>Last Contact</div></td>";
      $html .= "<td align=center><div id=thead>Enabled</div></td>";
      $html .= "<td align=center><div id=thead>Node Debug</div></td>";
      $html .= "</tr>\n";
      foreach (&sortnodeids($db{"hostname"}, @list)) {
         %node_warning = ();
         %node_error = ();
         $nodeid = $_;
         $nodename = $db{"hostname"}->get($_);
         $group = $db{"group"}->get($_);
         $vnfs = $db{"vnfs"}->get($_);
         $nodedebug = $db{"debug"}->get($_);
         $short_desc = $db{"desc"}->get($_);
         $enabled = $db{"enabled"}->get($_);
         $status = $db{"status"}->get($_);
         $lastcontact = $db{"lastcontact"}->get($_);

         if ( $lastcontact ) {
            $nodecontact = time() - $lastcontact;
            if ( defined $config{"node timeout"}[0] and $nodecontact >= $config{"node timeout"}[0] ) {
               $status = "timed out";
            } elsif ( $enabled > 0 ) {
               $status = $status;
            } else {
               $status = "($status)";
            }
            $lastcontact = &time_h(time() - $lastcontact);
         } else {
            $lastcontact = "n/a";
            $status = "Unknown";
         }
   
         if ( $enabled > 0 ) {
            $enabled = "yes";
         } else {
            $enabled = "no";
            $node_warning{"enabled"} = 1;
         }
         if ( $nodedebug > 0 ) {
            $nodedebug = "yes ($nodedebug)";
         } else {
            $nodedebug = "no";
         }
   
         if ( $short_desc ) {
            $short_desc =~ s/^(.{0,50})\b.*$/<a href='?nodedesc=$nodename'>$1...<\/a>/s;
         } else {
            $short_desc = "<a href='?nodedesc=$nodename'><font class=tiny><i>(click to add content)</i></div><a>";
         }
   
         $trcount++;
         if ( defined($selected_nodeids{"$nodeid"}) or $params{"check"} eq "all" ) {
            $html .= "<tr class='trselected' id='cell$trcount'>";
            $html .= "<td class=body><input type=checkbox name=nodeid value=$nodeid onclick=\"toggle(this,'cell$trcount')\" checked /></td>";
         } else {
            $html .= "<tr class='trunselected' id='cell$trcount'>";
            $html .= "<td class=body><input type=checkbox name=nodeid value=$nodeid onclick=\"toggle(this,'cell$trcount')\" /></td>";
         }
         $html .= "<td align=center class=body nowrap><a href='?nodeconfig=$nodename'>$nodename</a></td>";
         $html .= "<td align=center class=body nowrap>$status</td>";
         $html .= "<td align=center class=body nowrap>$group</td>";
         $html .= "<td align=center class=body nowrap>$vnfs</td>";
         $html .= "<td align=center class=body nowrap>$short_desc</td>";
         $html .= "<td align=center class=body nowrap>$lastcontact</td>";
         if ( defined($node_warning{"enabled"}) ) {
            $html .= "<td align=center class=warning>$enabled&nbsp;</td>";
         } else {
            $html .= "<td align=center class=body>$enabled&nbsp;</td>";
         }
         $html .= "<td align=center class=body>$nodedebug&nbsp;</td>";
         $html .= "</tr>\n";
      }
      $html .= "</table>\n";
      $html .= "</form>\n";

   } else {
      if ( $filtering ) {
         $html .= "<p><center><font size=+3 color=red align=center>No Nodes Found! (perhaps clear filters)</font></center></p>\n";
      } else {
         $html .= "<p><center><font size=+3 color=red align=center>No Nodes Found!</font></center></p>\n";
      }
   }

}

#if ( ! exists($config{"vnfs transfer master"}[0]) ) {
#   $html .= ("You need to set 'vnfs transfer master' in the config!");
#   exit 1;
#}

$html .= "</tr></table>\n";

$infobox .= "<table border=0 width=100% cellpadding=0 cellspacing=0>\n";
$infobox .= "<tr><td>Logged in as:</td><td>$ENV{REMOTE_USER}</td></tr>\n";
if (! &daemon_ping()) {
   $infobox .= "<tr><td>Perceus status:</td><td><font color=green>RUNNING</font></td></tr>\n";
} else {
   $infobox .= "<tr><td>Perceus status:</td><td><font color=red>ERROR</font></td></tr>\n";
}
$infobox .= "</table>\n";


if ( $redirect_url ) {
   $html = ();
   $redirect_html = "<META http-equiv=\"refresh\" content=\"0;$redirect_url\"";
}

$main_html =~ s/<!--breadcrumbs-->/$breadcrumbs/g;
$main_html =~ s/<!--searchbox-->/$search_html/g;
$main_html =~ s/<!--title-->/$title/g;
$main_html =~ s/<!--redirect-->/$redirect_html/g;
$main_html =~ s/<!--infobox-->/$infobox/g;
$main_html =~ s/<!--body-->/$html/g;
$main_html =~ s/<!--notification-->/<div id="notice" style="display: none"><\/div>/g;

if ( $debug_html_gui > 0 ) {
   $main_html =~ s/<!--debug-->/<pre>$debug_html<\/pre>/g;
}
if ( $warning ) {
   $main_html =~ s/<!--warning-->/<div id=warning>$warning<\/div>/g;
}
if ( $error ) {
   $main_html =~ s/<!--error-->/<div id=error>$error<\/div>/g;
}


print $q->header(-cookie=>[@cookies]);
print $main_html;



#foreach ( keys %ENV ) {
#   print "$_:$ENV{$_}<BR>\n";
#}
