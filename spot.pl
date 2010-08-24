#!/usr/bin/perl

use strict;
use warnings;
use Image::Magick;

my $file = "jquery_ascii_t3_4b_square.png";

print "Reading $file...\n";

my $im = Image::Magick->new;
$im->Read('perl_tests/'.$file);

print "First 8 pixels: ";

for my $x(0..7){
	my $col = $im->Get("pixel[$x,0]");
	my ($a,$b,$c,$d) = split /,/, $col;
	$a >>= 8;
	$b >>= 8;
	$c >>= 8;
	$d >>= 8;
	print "[$a $b $c $d], ";
}
print "\n";
