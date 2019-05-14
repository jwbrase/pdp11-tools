#!/usr/bin/perl
#Written in 2019 by Jonathan W Brase 
#e-mail: jNoOnS.PbArMaNsOeS@PgAmMaNiOlS.PcAoMm
#Remove capitalized letters of "NOSPAM" for valid e-mail address
#The CC0 Public Domain Dedication has been applied to this script. 
#To the extent possible under law, the author(s) have dedicated all copyright 
#and related and neighboring rights to this script to the public domain worldwide. 
#This script is distributed without any warranty. If you obtained this script
#from github the text of the CC0 license can be found at the end of the "COPYING"
#file in root directory of the repository. If not, see 
#<http://creativecommons.org/publicdomain/zero/1.0/>

#Reads /opt/pidp11/systems/selections , uses it to translate switch register value
#to a system to boot First command line argument is switch setting to parse, 
#second is default system

use strict;
use warnings;
use integer;

die "No switch register values received!" unless defined $ARGV[0];

chomp $ARGV[0];

#all switch settings so far are four digit, but pidp11.sh allows up to 18-bits for selection
#of a boot system (the upper four are reserved for options), so we will allow up to
#6 octal digits.
die "First argument should be four to six octal digits!" unless $ARGV[0] =~ m/^[0-7]{4,6}$/;

open (my $selection_file, '<', "/opt/pidp11/systems/selections") or die "Can't open selections file\n";

my @selection_list = <$selection_file>;

foreach(@selection_list)
{
	chomp;
	my ($selection, $system) = split;
	if($selection =~ $ARGV[0])
	{
		print $system ."\n";
		exit;
	}
}

#if the above loop doesn't find a system to boot, print the default system

if (defined $ARGV[1])
{
	chomp $ARGV[1];
	print $ARGV[1] . "\n";
}
else
{
	print "default\n";
}
