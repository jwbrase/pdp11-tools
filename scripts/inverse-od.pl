#!/usr/bin/perl
#This program is meant to perform an inverse octal dump for the PDP-11. It takes
#a text file containing a sequence of comma-separated binary, octal, decimal, or
#hexadecimal words and produces a binary file containing a sequence of 16-bit 
#little-endian words. Whitespace also separates words. The -o option 
#specifies that no decimal words are in the input file, that is, that all words 
#not beginning with 0x or 0b are to be interpreted as octal, regardless of 
#whether they begin with a 0. Words that do not match the regex 
#/^(0[bx])?[0-9a-f]*$/ are assumed to be text and discarded.
#
#Note that any number that does match the above regex that is directly adjacent
#to an expression of the form /(,|[\\r\\n]+)/ on either side (that is, is 
#adjacent to newlines or commas on either end) will be interpreted as part of 
#the data and included in the output file.
#
#Written in 2019 by Jonathan W Brase 
#e-mail: jNoOnS.PbArMaNsOeS@PgAmMaNiOlS.PcAoMm
#Remove capitalized letters of "NOSPAM" for valid e-mail address
#The CC0 Public Domain Dedication has been applied to this script. 
#See <http://creativecommons.org/publicdomain/zero/1.0/>. To the extent possible
#under law, the author(s) have dedicated all copyright and related and
#neighboring rights to this script to the public domain worldwide. This script 
#is distributed without any warranty.

use strict;
use warnings;
use integer;

use autodie;

die "No input file specified!\n" unless defined $ARGV[0];
die "No output file specified!\n" unless defined $ARGV[1];

foreach(@ARGV)
{ 
	chomp;
}

open(my $infile, '<', $ARGV[0]) or die "Can't open " . $ARGV[0] . "!\n";
open(my $outfile, '>:raw', $ARGV[1]) or die "Can't open"  . $ARGV[1] . "!\n";
my $use_decimal = 1;
my $help_shown = 0;
shift;
shift;
foreach(@ARGV)
{
	if(/-o/)
	{
		$use_decimal = 0;
	}
	if(/-(h|\?)/ and not $help_shown)
	{
		print(
"Usage: inverse-od.pl infile outfile [-oh]

Takes a list of binary, octal, decimal, or hexadecimal words in infile,
separated by commas or whitespace, and outputs them as 16-bit little endian
words in outfile. Per the usual convention, binary is indicated with a leading
\"0b\", octal with a leading \"0\", and hexadecimal with a leading \"0x\".

Words are split on the regex /(,|[\\r\\n]+)/. 

Words that do not match the regex /^(0[bx])?[0-9a-f]*\$/ are assumed to be text 
and discarded.

Note that any number that does match the above regex that is directly adjacent
to an expression of the form /(,|[\\r\\n]+)/ on either side (that is, is 
adjacent to newlines or commas on either end) will be interpreted as part of 
the data and included in the output file.

-o
	Interpret all words not beginning in \"0b\" or \"0x\" as octal, do not
	interpret any words as decimal, even if they have no leading \"0\".

-h	
	Print this help message.
"
		);
		$help_shown++;
	}
}

read($infile, my $data, 200000);
my @words = split(/(,|[\r\n]+)/, $data);
my @filtered_words=();
while(@words)
{
	my $current = shift @words;
	if ($current !~ /^(0[bx])?[0-9a-f]+$/)
	{
		next;
	}
	if ($current =~ /^0/ or not $use_decimal) 
	{
		$current = oct $current;
		push @filtered_words, $current;
	}
}
my $outdata = pack('S<*', @filtered_words);
print $outfile $outdata;
