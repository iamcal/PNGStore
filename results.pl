#!/usr/bin/perl

use warnings;
use strict;

my @files;

opendir D, "perl_images" or die $!;
while (my $file = readdir D){

	if ($file =~ /\.png$/){

		push @files, $file;
	}
}
closedir D;

my $gzip = 24281;

print<<OUT
<table border="1">
	<tr>
		<th>File</th>
		<th>Dimensions</th>
		<th>Type</th>
		<th>ImageMagick</th>
		<th>pngcrush</th>
		<th>OptiPNG</th>
		<th>PNGOUT</th>
		<th>Savings over GZip</th>
	</tr>
OUT
;

for my $file(sort @files){
	my $a = &size("perl_images/$file");
	my $b = &size("perl_images_pngcrush/$file");
	my $c = &size("perl_images_optipng/$file");
	my $d = &size("perl_images_pngout/$file");

	my $max = $gzip * 10;
	if ($a && $a < $max){ $max = $a; }
	if ($b && $b < $max){ $max = $b; }
	if ($c && $c < $max){ $max = $c; }
	if ($d && $d < $max){ $max = $d; }

	open F, "perl_images/$file" or die $!;
	my $junk;
	my $buffer;
	read F, $junk, 16;
	read F, $buffer, 10;
	my ($w, $h, $depth, $type) = unpack('NNCC', $buffer);
	close F;

	print "\t<tr>\n";
	print "\t\t<td>$file</td>\n";
	print "\t\t<td>$w x $h</td>\n";
	print "\t\t<td>Type $type, $depth bit</td>\n";
	print "\t\t<td align=\"right\"".&colorize($a, $max).">$a</td>\n";
	print "\t\t<td align=\"right\"".&colorize($b, $max).">$b</td>\n";
	print "\t\t<td align=\"right\"".&colorize($c, $max).">$c</td>\n";
	print "\t\t<td align=\"right\"".&colorize($d, $max).">$d</td>\n";

	if ($max < $gzip){
		my $saved = $gzip - $max;
		print "\t\t<td align=\"center\" style=\"background-color: #0f0\">$saved</td>\n";
	}else{
		print "\t\t<td align=\"center\">-</td>\n";
	}

	print "\t</tr>\n";
	#print "$file $a $b $c $d\n";
}

print "</table>\n";

sub size {
	my @temp = stat $_[0];
	return $temp[7] || 0;
}

sub colorize {
	my ($this, $max) = @_;

	if ($this && $this < $gzip){ return ' style="background-color: #0f0"'; }
	if ($this && $this <= $max){ return ' style="background-color: #cfc"'; }
	return '';
}
