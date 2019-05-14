# pdp11-tools
This repository contains tools I have written for working with pdp11 software on modern systems, particularly for use with Oscar Vermeulen's PiDP-11 project. See https://obsolescence.wixsite.com/obsolescence/pidp-11 .

The tools currently available are in the scripts directory:

1) inverse-od.pl performs an inverse octal dump, taking an input file text file containing comma-or-newline separated words of octal digits and spitting out a binary file containing those words as 16-bit little-endian integers (it will also deal with binary, decimal, and hexadecimal data, because perl makes doing that easy, but dumps for the PDP-11 are likely to be octal).

example usage:

inverse-od.pl ../example-input/bootcode.js ../example-output/bootcode

2) abstapewrite.pl creates an absolute loader format paper tape image for the PDP-11, which can, among other things,  be used by the "load" command in simh. It takes a loadfile, and output file (which the final tape image will be written to), and an optional execute address on the command line. Each non-comment line in the load file defines a block in the tape image by specifying a file to be used as the data payload for that block and a load address for the block. The format uses a block with no payload to indicate the end of the image. If an execute address is specified, the address for the final block is filled with the execute address, otherwise the address for the final block is "0x0001".

example usage:

abstapewrite.pl ../example-input/nankervis_bootloader.link ../example-output/nankervis_bootloader.ptape 140000

3) getsel.pl is a replacement for getsel.sh in Oscar Vermeulen's PiDP-11 software distribution. On boot, or when the address knob is pressed with the enable/halt switch in the "enable" position, simh is started, and a directory containing the disk images and configuration file for simh to use is selected based on the value toggled in on the front panel switches. getsel.sh is used to translate the switch value into a directory name. I was encountering an issue where switch register values of the form 0[1-9]xx were not being translated correctly, but Oscar was unable to reproduce the issue on his PiDP-11s. getsel.pl is a short Perl script that I wrote to provide the same functionality as getsel.sh, which works on my PiDP. It is meant to be called from /opt/pidp11/bin/pidp11.sh from the line beginning with $sel=... . The first argument should be the $lo variable that contains the low 18 bits of the switch register value, the second should be the default system name to use if no line in /opt/pidp11/systems/selections matches the switch register value.

Example usage:

replace the line in pidp11.sh beginning with "sel=" with:

sel = `./getsel.pl $lo idled`


Jon Brase, 2019
