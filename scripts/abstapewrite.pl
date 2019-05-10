#!/usr/bin/perl

#This script generates a absolute loader format paper tape image for the PDP-11
#It takes a filename on the command line, with each line in the file specifying
#a flat binary file containing one block of the image and the  octal or hexadecimal 
#address that block is to be loaded at, a second filename on the command line specifies
#the file that the image is to be written to, and a numerical argument.
#The format, from the information I can find, goes back to the original PDP-11.
#It is the file format accepted for the "load" command for the simh PDP-11
#implementation.
#
#A line in the loadfile beginning with "#" is a comment.
#
#One reference I found was somewhat unclear and lead me to code that produced
#images that simh rejected.  This script has been written for compatibility with
#simh, on the assumption that the simh implementation is correct, but I am not
#old enough to know if, for example, all historical implementations of the 
#absolute loader format were consistent with each other. Please let me know if
#this code produces tape images that fail to load on any implementation.
#
#This code assumes that all addresses supplied are binary, octal, or hexadecimal.
#If it is desired to use decimal addresses, the if statement around the statement
#"$addr = oct($addr);" can be uncommented, and a similar if statement can be
#added  for "$exec_addr = oct($exec_addr);"
#
#For each block, the script will emit the 8-bit sum of all bytes in the block,
#including the header and checksum, to stdout. If this does not equal 0, the 
#checksum is not valid and loading will fail. If any number but 0 is emitted
#on stdout, this is a bug and should be reported.
#
#If a file specified in linkfile is over 65529 bytes in length, the script will
#truncate it to that length when using it to create a block, so that the block
#field given in the block header does not wrap around (as the header length is
#added to the length of the data, and the length is a 16-bit integer). In
#practice, I anticipate that the true limit on block size is probably closer
#to 56k, given that anything longer would start writing over the I/O page on the
#PDP-11. However, I do not know if the absolute loader format was ever used, for
#instance, with memory management running to load data in to a virtual address
#space, in which case it might be possible to load a full 64k, minus the header
#length.
#
##Written in 2019 by Jonathan W Brase 
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

die "No load file specified!\n" unless defined $ARGV[0];
die "No output file specified!\n" unless defined $ARGV[1];

foreach(@ARGV)
{ 
	chomp;
}



#According to the code in simh for the PDP-11 load function, if the last block 
#has an address of 1, the address is not used to define an exec address, so
#if no exec address is defined, we use an exec address of 1 so that the loader
#will ignore it

my $exec_addr;
my $loadfile;
my $outfile;
while(@ARGV)
{
	my $arg = shift @ARGV;
	if ($arg =~ /-(h|\?)/)
	{
		print(
"Usage: abstapewrite.pl loadfile outfile [exec_addr]
		or
		abstapewrite.pl [-h?]
		
		-h
		-?
			Print this help message and exit.
		
		The arguments from the first form may be supplied with -h or -?, but
		the script will exit immediately after printing the help message, so
		no processing will be done.

This script writes a PDP-11 absolute loader format paper tape image using the 
files and  addresses specified in loadfile to the file specified by outfile. 
Each line in loadfile should specify a file containing a block of data to be 
added to the image, and the binary, octal, or hexadecimal address to which the 
block is to be loaded. If exec_addr is specified, the loader will jump to this 
address after loading the image. For the simh \"load\" command, which is 
perfomed by the emulator without actual code execution on the emulated machine,
this just means that the PC will be loaded with this address, a subsequent
\"go\" or \"continue\" command is then necessary to start execution.

#A line in the loadfile beginning with \"#\" is a comment.

For each block, the script will emit the 8-bit sum of all bytes in the block,
including the header and checksum, to stdout. If this does not equal 0, the 
checksum is not valid and loading will fail. If any number but 0 is emitted
on stdout, this is a bug and should be reported.

If a file specified in linkfile is over 65529 bytes in length, the script will
truncate it to that length when using it to create a block, so that the block
field given in the block header does not wrap around (as the header length is
added to the length of the data, and the length is a 16-bit integer). In
practice, I anticipate that the true limit on block size is probably closer
to 56k, given that anything longer would start writing over the I/O page on the
PDP-11. However, I do not know if the absolute loader format was ever used, for
instance, with memory management running to load data in to a virtual address
space, in which case it might be possible to load a full 64k, minus the header
length.

-h
-?
	Print this help message and exit.
"
		);
		exit;
	}
	elsif (not defined $loadfile)
	{
		open($loadfile, '<', $arg) or die "Can't open " . $arg. "!\n";
	}
	elsif (not defined $outfile)
	{
		open($outfile, '>:raw', $arg) or die "Can't open"  . $ARGV[1] . "!\n";
	}
	else
	{
		unless ($arg !~ /^(0[bx])?[0-9a-f]*$/)
		{
			$exec_addr = $arg;
			$exec_addr = oct($exec_addr);
		}
	}
}

$exec_addr = 1 if (not defined $exec_addr); 

my @loadlines = <$loadfile>;

my $line_number = 1;

my @infiles=();
my @load_addrs=();

foreach(@loadlines)
{
	(my $filename, my$addr) = split /\s/, $_;
	if (defined $filename and $filename =~ /^#/)
	{
		$line_number++;
		next;
	}
	unless (defined $filename and defined $addr)
	{
		die "Missing filename and or address in line " . $line_number . " of " .
		$loadfile . "!\n";
	}
	if (not $addr =~ /^(0[bx])?[0-9a-f]*$/)
	{
		die "Address is not a binary, octal, or hex integer in line " . $line_number . 
		" of " . $loadfile . "!\n";
	}
#	if ($addr =~ /^0/) 		#This if statement and the surrounding braces can be 
#	{						#uncommented if it is desired to use decimal addresses.
		$addr = oct($addr);	#As addresses are usually not represented in decimal,
#	} 						#We interpret any string not beginning with 0x or 0b
							#As octal, to avoid confusion between octal and decimal
							#if a leading zero is added/forgotten
	open(my $file, '<:raw', $filename) or die "Can't open" . $filename . "!\n";
	push(@infiles, $file);
	push(@load_addrs, $addr);
	
	$line_number++;
}

#We won't generate output if opening any of the source files fails, so we
#separate iterating over lines of the load file from iterating over blocks
#to be output

while(defined $infiles[0])
{
	my $file = shift(@infiles);
	my $addr = shift(@load_addrs);
	my $numbytes = read($file, my $contents, 65529) + 6; 	#PDP-11 address space is 64k
	my @bytes = unpack('C*', $contents);
	
	#	The block format consists of:
	#
	#	1)	A header containing the signature "0x0001",
	#		the length of the block (including the header, but not the checksum), and
	#		the load address.
	#	2)	The data payload for this block.
	#	3)	A checksum byte, such that 	#The 8-bit sum of each byte in the header 
	#		and data, plus the checksum byte is 0.
	
	my $headersum = unpack('%8C*', pack('S[3]', 1, $numbytes, $addr));
	my $datasum = unpack('%8C*', $contents);
	my $checksum = 256 - (($headersum + $datasum) % 256);
	print (($headersum + $datasum + $checksum) % 256 . "\n");
	
	my $block = pack('S<[3] C*', 1, $numbytes, $addr, @bytes, $checksum);
	
	print $outfile $block;
	close($file);

}

	#A zero length block indicates the end of the image and defines the exec 
	#address. The simh code indicates that no checksum is generated for this
	#block.

my $lastblock = pack('S<[3]', 1, 6, $exec_addr);
print $outfile $lastblock;
	
close($outfile);
