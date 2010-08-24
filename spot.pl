#!/usr/bin/perl

use strict;
use warnings;
use Image::Magick;

my $im = Image::Magick->new;
$im->Read('perl_tests/jquery_ascii_t6_8b_square.png');

print "First 8 bytes: ";

for my $x(0..1){
	my $col = $im->Get("pixel[$x,0]");
	my ($a,$b,$c,$d) = split /,/, $col;
	$a >>= 8;
	$b >>= 8;
	$c >>= 8;
	$d >>= 8;
	print "$a $b $c $d ";
}
print "\n";
