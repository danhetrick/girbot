#!/usr/bin/perl
#
# girbot.pl
# Gir IRC Bot
#
# Author: Wraithnix (wraithnix@riotmod.com)
# Version: 0.1
# Web: http://www.riotmod.com
#
# This script is released under the
# GNU General Public License.
# More information on the GPL can be found
# at http://www.gnu.org/copyleft/gpl.html
#
# Usage: perl girbot.pl <config file, optional>
#
# Description:
# GirBot is an IRC bot written to Perl to be
# a "skeleton" for other Perl IRC bots.  That
# is to say, all of the hard work (connection,
# configuration, etc.) is already done, but not
# much else.  Unchanged, all GirBot does is connect
# to an IRC server and print any data it receives to
# STDOUT.
# GirBot uses configuration files to store all of
# its settings.  These are basically like INI files
# w/o sections.  They are formatted like this:
#
# <setting>=<value>
#
# Any lines that start with a hash mark ("#") are
# considered comments and are ignored.
# A GirBot config file must have at least 5 settings:
# nick, altnick, ident, port, and server.
#
# People wanting to use GirBot as a base for their
# own bots are going to want to look at modifying
# two subroutines:  on_public() and on_msg().
# These two subs handle public (channel) messages
# and private messages respectively, and are called
# every time a bot receives a message.
#
use strict;
use Net::IRC;

# ============
# SUPPORT CODE
# ============

# GetSetting
# Arguments: setting to retrieve,configuration file
# Returns: The setting value, or "" if it doesn't exist
# Description: Use this sub to load values
#              from a configuration file.
#              Settings are stored in this format:
#              <setting>=<value>
sub GetSetting
{
  my ($setting,$config_file)=@_;
  open(CFGFILE,"<$config_file")
    or die "Can't open configuration file ($config_file)";
  my @slist=<CFGFILE>;
  foreach my $selem (@slist)
  {
    if (index($selem,"#")==0) { next; }
    my @ln=split("=",$selem);
    if ($ln[0] =~ /$setting/i)
    {
        chomp $ln[1];
        return $ln[1];
    }
  }
  close CFGFILE;
}

# =============
# MAIN BOT CODE
# =============

# Set our configuration file
my $configuration_file = "gir.cfg";
# You can start the bot with a config file as a
# commandline argument.  Without the argument,
# the bot loads its settings from "gir.cfg", in
# the same directory as the bot.
if($#ARGV==0) { $configuration_file=$ARGV[0]; }
# Now, we can load in our script's settings
my $cfg_nick=GetSetting("nick",$configuration_file);
my $cfg_altnick=GetSetting("altnick",$configuration_file);
my $cfg_ident=GetSetting("ident",$configuration_file);
my $cfg_port=GetSetting("port",$configuration_file);
my $cfg_server=GetSetting("server",$configuration_file);
# Just about all of the settings are "strings", except
# for the "port".  Let's make sure that that setting
# is numerical, and if not, set it to the most common
# port, 6667:
if($cfg_port=~/\D/) { $cfg_port=6667; }

# Now that all of our settings are loaded in,
# let's create the IRC object
my $irc = new Net::IRC;
print "Creating connection to IRC server...";
my $conn = $irc->newconn(Server   => "$cfg_server",
             Port     => $cfg_port,
             Nick     => "$cfg_nick",
             Ircname  => "$cfg_ident",
             Username => "$cfg_ident")
    or die "Can't connect to IRC server.";
print "done!\n";

# With that out of the way, let's create
# some subs for our object handlers

# What our bot will do when it finishes
# connecting to the IRC server
sub on_connect {
    my $self = shift;
  print "*** Connected to IRC.\n";
}
# This sub will print various
# incoming date while we're still
# connecting to IRC
sub on_init {
    my ($self, $event) = @_;
    my (@args) = ($event->args);
    shift (@args);

    print "*** @args\n";
}
# This sub will handle what happens when the
# bot receives public (channel) text.
sub on_public {
    my ($self, $event) = @_;
    my @to = $event->to;
    my ($nick, $mynick) = ($event->nick, $self->nick); # Sender text, 
+Bot nick
    my $host=$event->host; # Sender's hostname
    my ($arg) = ($event->args); # The message
    
    # Here's where we want to "parse" channel text
    print "<$nick> $arg\n";
    
}
# This sub will handle what happens when the
# bot receives private message text
sub on_msg {
    my ($self, $event) = @_;
    my ($nick) = $event->nick; # Message Sender
    my ($arg) = ($event->args); # Message Text
    my $host=$event->host;
    
    # Here's where we want to "parse" message text
    print " - $nick -  $arg\n";
    
}
# This sub will get triggered if our bot's nick
# is taken, setting it to our alternate nick.
sub on_nick_taken {
    my ($self) = shift;

    $self->nick($cfg_altnick);
}
# Now that all of our handler subs are created,
# let's install them
print "Installing local handlers...";
$conn->add_handler('public', \&on_public);
$conn->add_handler('msg',    \&on_msg);
print "done!\nInstalling global handlers...";
$conn->add_global_handler([ 251,252,253,254,302,255 ], \&on_init);
$conn->add_global_handler(376, \&on_connect);
$conn->add_global_handler(433, \&on_nick_taken);
print "done!\n";
# Everything's installed, so there's nothing
# holding up back from starting up!
$irc->start;
