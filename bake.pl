#!/usr/bin/perl

use strict;
use warnings;
use POSIX qw(ceil floor);
use Image::Magick;
use Data::Dumper;

&encode_file('jquery-1.4.2.min.js', 'jquery');
exit;

sub encode_file {
	my ($path, $prefix) = @_;


	#
	# read in file
	#

	my $data = '';
	open F, $path or die $!;
	while (<F>){
		$data .= $_;
	}
	close F;
	my $size = length $data;

	print "$path is $size bytes\n";


	#
	# the simplest method is to store the bytes as they are in ascii.
	# this is the least space-efficient.
	#

	my $bytes = [];
	for my $i(0..$size){
		push @{$bytes}, ord(substr($data, $i, 1));
	}

	&store_bytes($bytes, $prefix.'_ascii');
}

sub store_bytes {

	my ($bytes, $mode) = @_;
	my ($px, $w, $h);

	my $size = scalar(@{$bytes});


	#
	# type 2 (truecolor, no alpha)
	#

	#&create_type2_8bit($mode, 'wide', $bytes);
	#&create_type2_8bit($mode, 'tall', $bytes);
	#&create_type2_8bit($mode, 'square', $bytes);


	#
	# type 3 (indexed) 
	#

	#&create_type3_8bit($mode, 'square', $bytes);
	#&create_type3_4bit($mode, 'square', $bytes);
	#&create_type3_2bit($mode, 'square', $bytes);
	&create_type3_1bit($mode, 'square', $bytes);
}

sub create_type2_8bit {
	my ($mode, $shape, $bytes) = @_;
	my ($w, $h) = &get_dims($shape, scalar(@{$bytes}), 3);

	my $im = Image::Magick->new(size=>"${w}x${h}");
	$im->ReadImage('xc:white');

	my $i=0;
	for my $y(0..$h-1){
	for my $x(0..$w-1){

		my $b1 = $bytes->[($i*3)+0] || 0;
		my $b2 = $bytes->[($i*3)+1] || 0;
		my $b3 = $bytes->[($i*3)+2] || 0;
		my $color = sprintf('#%02x%02x%02x', $b1, $b2, $b3);

		$im->Set("pixel[$x,$y]" => $color);
		$i++;
	}
	}

	my $ret = $im->Write(
		filename => "png24:perl_tests/${mode}_t2_8b_${shape}.png",
		depth => 8,
	);

	print `pngcrush -n -v perl_tests/${mode}_t2_8b_${shape}.png`;
}

sub create_type3_8bit {
	my ($mode, $shape, $bytes) = @_;
	my ($w, $h) = &get_dims($shape, scalar(@{$bytes}), 1);

	my $im = Image::Magick->new(size=>"${w}x${h}");
	$im->ReadImage('xc:white');

	my $i=0;
	for my $y(0..$h-1){
	for my $x(0..$w-1){

		my $b1 = $bytes->[$i] || 0;
		my $color = sprintf('#%02x%02x%02x', $b1, 0, 0);

		$im->Set("pixel[$x,$y]" => $color);
		$i++;
	}
	}

	my $ret = $im->Write(
		filename => "png8:perl_tests/${mode}_t3_8b_${shape}.png",
	);

	print `pngcrush -n -v perl_tests/${mode}_t3_8b_${shape}.png`;
}

sub create_type3_4bit {
	my ($mode, $shape, $bytes) = @_;
	my ($w, $h) = &get_dims($shape, scalar(@{$bytes}), 2, 1);

	my $im = Image::Magick->new(size=>"${w}x${h}");
	$im->ReadImage('xc:white');

	my $i=0;
	my $c=0;
	for my $y(0..$h-1){
	for my $x(0..$w-1){

		my $b1 = $bytes->[$i] || 0;
		$b1 = $c ? 0xF & ($b1 >> 4) : 0xF & $b1;
		my $color = sprintf('#%02x%02x%02x', $b1, 0, 0);

		$im->Set("pixel[$x,$y]" => $color);

		if ($c){ $i++; }
		$c = $c ? 0 : 1;
	}
	}

	my $ret = $im->Write(
		filename => "png8:perl_tests/${mode}_t3_4b_${shape}.png",
	);

	print `pngcrush -n -v perl_tests/${mode}_t3_4b_${shape}.png`;
}

sub create_type3_2bit {
	my ($mode, $shape, $bytes) = @_;
	my ($w, $h) = &get_dims($shape, scalar(@{$bytes}), 4, 1);

	my $im = Image::Magick->new(size=>"${w}x${h}");
	$im->ReadImage('xc:white');

	my $i=0;
	my $c=0;
	for my $y(0..$h-1){
	for my $x(0..$w-1){

		my $b1 = $bytes->[$i] || 0;
		$b1 = 0x3 & ($b1 >> 0) if $c == 0;
		$b1 = 0x3 & ($b1 >> 2) if $c == 1;
		$b1 = 0x3 & ($b1 >> 4) if $c == 2;
		$b1 = 0x3 & ($b1 >> 6) if $c == 3;

		my $color = sprintf('#%02x%02x%02x', $b1, 0, 0);

		$im->Set("pixel[$x,$y]" => $color);

		$c++;
		if ($c == 4){ $c = 0; $i++; }
	}
	}

	my $ret = $im->Write(
		filename => "png8:perl_tests/${mode}_t3_2b_${shape}.png",
	);

	print `pngcrush -n -v perl_tests/${mode}_t3_2b_${shape}.png`;
}

sub create_type3_1bit {
	my ($mode, $shape, $bytes) = @_;
	my ($w, $h) = &get_dims($shape, scalar(@{$bytes}), 8, 1);

	my $im = Image::Magick->new(size=>"${w}x${h}");
	$im->ReadImage('xc:white');

	my $i=0;
	my $c=0;
	for my $y(0..$h-1){
	for my $x(0..$w-1){

		my $b1 = $bytes->[$i] || 0;
		$b1 = 0x1 & ($b1 >> $c);

		my $color = sprintf('#%02x%02x%02x', $b1, 0, 0);

		$im->Set("pixel[$x,$y]" => $color);

		$c++;
		if ($c == 8){ $c = 0; $i++; }
	}
	}

	my $ret = $im->Write(
		filename => "png8:perl_tests/${mode}_t3_1b_${shape}.png",
	);

	print `pngcrush -n -v perl_tests/${mode}_t3_1b_${shape}.png`;
}



sub get_dims {
	my ($shape, $size, $bytes_per_pixel, $inv) = @_;

        my $px = $inv ? $size * $bytes_per_pixel : ceil($size / $bytes_per_pixel);
        my $w = floor(sqrt($px));
        my $h = ceil($px / $w);

	# todo - deal with px being over 65535
	if ($shape eq 'wide'){ return ($px, 1); }
	if ($shape eq 'tall'){ return (1, $px); }
	return ($w, $h);
}



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


my $x2 = &write_png($image, 3, 4);

print "out: $x2\n";

if (!$x2){
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
