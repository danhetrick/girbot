#!/usr/bin/perl
#
# girbot.pl
# Gir IRC Bot
#
# Author: Dan Hetrick (dhetrick@gmail.com)
# Version: 0.1
# Web: https://github.com/danhetrick/girbot
#
# This script is released under the GNU General Public License.
# More information on the GPL can be found at http://www.gnu.org/copyleft/gpl.html
#
# Usage: perl girbot.pl
#
# GirBot is an IRC bot written to Perl to be a "skeleton" for other Perl IRC bots.  That
# is to say, all of the hard work (connection, configuration, etc.) is already done, but not
# much else.  Unchanged, all GirBot does is connect to an IRC server and print any data it
# receives to STDOUT.
#
# GirBot uses configuration files to store all of its settings.  These are basically like INI files
# w/o sections.  They are formatted like this:
#
# <setting>=<value>
#
# Any lines that start with a hash mark ("#") are considered comments and are ignored.
# A GirBot config file must have at least 5 settings: nick, altnick, ident, port, and server.
#
# People wanting to use GirBot as a base for their own bots are going to want to look at modifying
# two subroutines:  on_public() and on_msg(). These two subs handle public (channel) messages
# and private messages respectively, and are called  every time a bot receives a message.
#
use strict;
use Net::IRC;

# =================
# | GLOBALS BEGIN |
# =================

my $NICK;
my $ALTNICK;
my $IDENT;
my $PORT;
my $SERVER;

# ===============
# | GLOBALS END |
# ===============

# ======================
# | MAIN PROGRAM BEGIN |
# ======================

# Set our configuration file
load_config_file("gir.cfg");

my $irc = new Net::IRC;
print "Creating connection to IRC server...";
my $conn = $irc->newconn(Server   => "$SERVER",
             Port     => $PORT,
             Nick     => "$NICK",
             Ircname  => "$IDENT",
             Username => "$IDENT")
    or die "Can't connect to IRC server.";
print "done!\n";

print "Installing local handlers...";
$conn->add_handler('public', \&on_public);
$conn->add_handler('msg',    \&on_msg);
print "done!\nInstalling global handlers...";
$conn->add_global_handler([ 251,252,253,254,302,255 ], \&on_init);
$conn->add_global_handler(376, \&on_connect);
$conn->add_global_handler(433, \&on_nick_taken);
print "done!\n";

$irc->start;

# ====================
# | MAIN PROGRAM END |
# ====================

# =============================
# | SUPPORT SUBROUTINES BEGIN |
# =============================

# load_config_file()
# on_connect()
# on_init()
# on_public()
# on_msg()
# on_nick_taken()

# load_config_file()
# Arguments: configuration file
# Returns: Nothing
# Description: Use this sub to load values from a configuration file.
#              Settings are stored in this format: <setting>=<value>
sub load_config_file {
	my ($config_file)=@_;

	open(CFGFILE,"<$config_file")
	or die "Can't open configuration file ($config_file)";
	my @slist=<CFGFILE>;
	foreach my $selem (@slist) {

		# Lines beginning with "#" are comments, and ignored.
		if (index($selem,"#")==0) { next; }

		# Settings are in the format <setting>=<value>
		my @ln=split("=",$selem);
		if ($ln[0] =~ /server/i) {
		    chomp $ln[1];
		    $SERVER = $ln[1];
		} elsif ($ln[0] =~ /port/i) {
		    chomp $ln[1];
		    $PORT = $ln[1];
		} elsif ($ln[0] =~ /ident/i) {
		    chomp $ln[1];
		    $IDENT = $ln[1];
		} elsif ($ln[0] =~ /altnick/i)  {
		    chomp $ln[1];
		    $ALTNICK = $ln[1];
		} elsif ($ln[0] =~ /nick/i) {
		    chomp $ln[1];
		    $NICK = $ln[1];
		}
	}
	close CFGFILE;

	# Just about all of the settings are "strings", except
	# for the "port".  Let's make sure that that setting
	# is numerical, and if not, set it to the most common
	# port, 6667:
	if($PORT=~/\D/) { $PORT=6667; }
}

# -----------------------------
# | HANDLER SUBROUTINES BEGIN |
# -----------------------------

# on_connect()
# Arguments: Net::IRC object
# Returns: Nothing
# Description: Triggered when the bot connects to IRC.
sub on_connect {
    my $self = shift;
  print "*** Connected to IRC.\n";
}

# on_init()
# Arguments: Net::IRC object
# Returns: Nothing
# Description: Triggered when data is incoming while connecting to IRC.
sub on_init {
    my ($self, $event) = @_;
    my (@args) = ($event->args);
    shift (@args);

    print "*** @args\n";
}

# on_public()
# Arguments: Net::IRC object
# Returns: Nothing
# Description: Triggered when the bot recieves a public message.
sub on_public {
    my ($self, $event) = @_;
    my @to = $event->to;
    my ($nick, $mynick) = ($event->nick, $self->nick); # Sender text, Bot nick
    my $host=$event->host; # Sender's hostname
    my ($arg) = ($event->args); # The message
    
    # Here's where we want to "parse" channel text
    print "<$nick> $arg\n";
    
}

# on_msg()
# Arguments: Net::IRC object
# Returns: Nothing
# Description: Triggered when the bot receives a private message.
sub on_msg {
    my ($self, $event) = @_;
    my ($nick) = $event->nick; # Message Sender
    my ($arg) = ($event->args); # Message Text
    my $host=$event->host;
    
    # Here's where we want to "parse" message text
    print " - $nick -  $arg\n";
}

# on_nick_taken()
# Arguments: Net::IRC object
# Returns: Nothing
# Description: Triggered when the bot's nick is already taken.
sub on_nick_taken {
    my ($self) = shift;

    $self->nick($ALTNICK);
}

# ---------------------------
# | HANDLER SUBROUTINES END |
# ---------------------------

# ==========================
# | SUPPORT SUBROUTINES END |
# ===========================
