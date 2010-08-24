#!/usr/bin/perl

use strict;
use warnings;
use Image::Magick;
use Data::Dumper;

my $image = Image::Magick->new(size=>'1000x256');
$image->ReadImage('xc:white');

my $cols = 3;
for my $x(1..$cols){
	my $hex = sprintf('%02x', $x);
	my $color = "#$hex$hex$hex";
	$image->Set("pixel[$x,1]" => $color);
	print $color.' = '.$image->Get("pixel[$x,1]")."\n";
}

#$image->Set(option => "png:color-type=4");


my $x = &write_png($image, 3, 4);

print "out: $x\n";

if (!$x){
	#print `identify -verbose -debug coder x.png | grep color_type`;
	print `pngcrush -n -v x.png | grep '      ' | grep -v \\| | grep -v '       '`;
}



sub write_png {

	my ($im, $type, $depth) = @_;

	print "Writing Type $type, Depth $depth...\n";

	my %args;
	$args{filename} = 'x.png';

	if ($type == 0){
		$args{type} = 'Grayscale',
	}

	if ($type == 2){
		$args{filename} = 'png24:x.png';
		$args{depth} = &check_depth($depth, 8, [8, 16]);
		# depth seems to always be 8
	}

	if ($type == 3){
		$args{filename} = 'png8:x.png';
		$args{depth} = &check_depth($depth, 8, [1, 2, 4, 8]);
		# depth basically get ignored unless you have enough colors?
	}

	if ($type == 4){
		$args{type} = 'GrayscaleMatte';
		$args{depth} = &check_depth($depth, 8, [8, 16]);
	}

	if ($type == 6){
		$args{filename} = 'png64:x.png';
		$args{depth} = &check_depth($depth, 8, [8, 16]);
	}

print Dumper \%args;

	return $im->Write(%args);
}

sub check_depth {
	my ($in, $def, $allowed) = @_;

	for my $a(@{$allowed}){
		return $in if $in == $a;
	}

	return $def;
}
