#!/usr/bin/perl

use strict;
use warnings;
use POSIX qw(ceil floor);
use Image::Magick;
use Data::Dumper;

&encode_file('jquery-1.4.2.min.js', 'jquery');
`cp -r perl_tests /var/www/cal/scrumjax.com/`;
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
	# type 0 : grayscale
	#

	#&create_type0_8bit($mode, 'square', $bytes);
	#&create_type0_4bit($mode, 'square', $bytes);
	#&create_type0_2bit($mode, 'square', $bytes);
	#&create_type0_1bit($mode, 'square', $bytes);


	#
	# type 2 : truecolor, no alpha
	#

	&create_type2_8bit($mode, 'square', $bytes);


	#
	# type 3 : indexed
	#

	#&create_type3_8bit($mode, 'square', $bytes);
	#&create_type3_4bit($mode, 'square', $bytes);
	#&create_type3_2bit($mode, 'square', $bytes);
	#&create_type3_1bit($mode, 'square', $bytes);


	#
	# type 4: greyscale & alpha
	#

	#&create_type4_8bit($mode, 'square', $bytes);


	#
	# type 6: turecolor & alpha
	#

	#&create_type6_8bit($mode, 'square', $bytes);
}

#########################################################################################

sub create_type0_8bit { return &create_type0($_[0], $_[1], $_[2], 8); }
sub create_type0_4bit { return &create_type0($_[0], $_[1], $_[2], 4); }
sub create_type0_2bit { return &create_type0($_[0], $_[1], $_[2], 2); }
sub create_type0_1bit { return &create_type0($_[0], $_[1], $_[2], 1); }

sub create_type0 {
	my ($mode, $shape, $bytes, $bits) = @_;

	my $im = &pack_image($shape, $bytes, $bits, sub{
		return sprintf('#%02x%02x%02x', $_[0], $_[0], $_[0]);
	});

	my $name = "${mode}_t0_${bits}b_${shape}.png";
	my $ret = $im->Write(
		filename => "perl_tests/$name",
		type => 'Grayscale',
	);

	&debug($name);
}

#########################################################################################

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

	my $name = "${mode}_t2_8b_${shape}.png";
	my $ret = $im->Write(
		filename => "png24:perl_tests/$name",
		depth => 8,
	);

	&debug($name);
}

#########################################################################################

sub create_type3_8bit { return &create_type3($_[0], $_[1], $_[2], 8); }
sub create_type3_4bit { return &create_type3($_[0], $_[1], $_[2], 4); }
sub create_type3_2bit { return &create_type3($_[0], $_[1], $_[2], 2); }
sub create_type3_1bit { return &create_type3($_[0], $_[1], $_[2], 1); }

sub create_type3 {
	my ($mode, $shape, $bytes, $bits) = @_;

	my $im = &pack_image($shape, $bytes, $bits, sub{
		my $val = $_[0] << (8 - $bits);
		return sprintf('#%02x%02x%02x', $val, 0, 0);
	});

	my $name = "${mode}_t0_${bits}b_${shape}.png";
	my $ret = $im->Write(
		filename => "png8:perl_tests/$name",
	);

	&debug($name);
}

#########################################################################################
#
# note: this only works with ImageMagick verisons over 6.3.5-9
#

sub create_type4_8bit {
	my ($mode, $shape, $bytes) = @_;

	my ($w, $h) = &get_dims($shape, scalar(@{$bytes}), 2);

	my $im = Image::Magick->new(size=>"${w}x${h}");
	$im->ReadImage('xc:white');

	my $i=0;
	for my $y(0..$h-1){
	for my $x(0..$w-1){

		my $b1 = $bytes->[($i*2)+0] || 0;
		my $b2 = $bytes->[($i*2)+1] || 0;
		my $color = sprintf('#%02x%02x%02x%02x', $b1, $b1, $b1, $b2);

		$im->Set("pixel[$x,$y]" => $color);
		$i++;
	}
	}

	my $name = "${mode}_t4_8b_${shape}.png";
	#$im->Set(option => "png:color-type=4");	
	my $ret = $im->Write(
		filename => "perl_tests/$name",
		type => 'GrayscaleMatte',
		matte => 1,
		#depth => 8,
	);

	&debug($name);
}

#########################################################################################

sub create_type6_8bit {
	my ($mode, $shape, $bytes) = @_;

	my ($w, $h) = &get_dims($shape, scalar(@{$bytes}), 4);

	my $im = Image::Magick->new(size=>"${w}x${h}");
	$im->ReadImage('xc:white');

	my $i=0;
	for my $y(0..$h-1){
	for my $x(0..$w-1){

		my $b1 = $bytes->[($i*4)+0] || 0;
		my $b2 = $bytes->[($i*4)+1] || 0;
		my $b3 = $bytes->[($i*4)+2] || 0;
		my $b4 = $bytes->[($i*4)+3] || 0;
		my $color = sprintf('#%02x%02x%02x%02x', $b1, $b2, $b3, $b4);

		$im->Set("pixel[$x,$y]" => $color);
		$i++;
	}
	}

	my $name = "${mode}_t6_8b_${shape}.png";
	my $ret = $im->Write(
		filename => "png32:perl_tests/$name",
		depth => 8,
	);

	&debug($name);
}

#########################################################################################

sub pack_image {
	my ($shape, $bytes, $bits, $cf) = @_;

	return &pack_image_8bit($shape, $bytes, $cf) if $bits == 8;
	return &pack_image_4bit($shape, $bytes, $cf) if $bits == 4;
	return &pack_image_2bit($shape, $bytes, $cf) if $bits == 2;
	return &pack_image_1bit($shape, $bytes, $cf) if $bits == 1;
	return undef;
}

sub pack_image_8bit {
	my ($shape, $bytes, $cf) = @_;
	my ($w, $h) = &get_dims($shape, scalar(@{$bytes}), 1);

	my $im = Image::Magick->new(size=>"${w}x${h}");
	$im->ReadImage('xc:white');

	my $i=0;
	for my $y(0..$h-1){
	for my $x(0..$w-1){

		my $b1 = $bytes->[$i] || 0;

		$im->Set("pixel[$x,$y]" => &$cf($b1));
		$i++;
	}
	}

	return $im;
}

sub pack_image_4bit {
	my ($shape, $bytes, $cf) = @_;
	my ($w, $h) = &get_dims($shape, scalar(@{$bytes}), 2, 1);

	my $im = Image::Magick->new(size=>"${w}x${h}");
	$im->ReadImage('xc:white');

	my $i=0;
	my $c=0;
	for my $y(0..$h-1){
	for my $x(0..$w-1){

		my $b1 = $bytes->[$i] || 0;
		$b1 = $c ? 0xF & ($b1 >> 4) : 0xF & $b1;

		$im->Set("pixel[$x,$y]" => &$cf($b1));

		if ($c){ $i++; }
		$c = $c ? 0 : 1;
	}
	}

	return $im;
}

sub pack_image_2bit {
	my ($shape, $bytes, $cf) = @_;
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

		$im->Set("pixel[$x,$y]" => &$cf($b1));

		$c++;
		if ($c == 4){ $c = 0; $i++; }
	}
	}

	return $im;
}

sub pack_image_1bit {
	my ($shape, $bytes, $cf) = @_;
	my ($w, $h) = &get_dims($shape, scalar(@{$bytes}), 8, 1);

	my $im = Image::Magick->new(size=>"${w}x${h}");
	$im->ReadImage('xc:white');

	my $i=0;
	my $c=0;
	for my $y(0..$h-1){
	for my $x(0..$w-1){

		my $b1 = $bytes->[$i] || 0;
		$b1 = 0x1 & ($b1 >> $c);

		$im->Set("pixel[$x,$y]" => &$cf($b1));

		$c++;
		if ($c == 8){ $c = 0; $i++; }
	}
	}

	return $im;
}

#########################################################################################

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

#########################################################################################

sub debug {
	my ($name) = @_;

	print "\n";
	print "$name:\n";
	print `pngcrush -n -v perl_tests/$name | grep '      ' | grep -v \\| | grep -v '       '`;
}

#########################################################################################



#$image->Set(option => "png:color-type=4");



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
