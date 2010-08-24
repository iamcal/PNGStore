#!/usr/bin/perl

use strict;
use warnings;
use POSIX qw(ceil floor);
use Image::Magick;
use Data::Dumper;

my $dir = "perl_images";
my @shapes = ('square', 'wide', 'tall');

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


	#
	# next simplest is to store values using 7 bits, so we store 8
	# characters in every 7 bytes
	#
	# 11111112 22222233 33333444 44445555 55566666 66777777 78888888
	#

	$bytes = [];
	my $seqs = ceil($size / 8);

	for my $i(0..$seqs-1){

		my $c1 = ord(substr($data, ($i*8)+0, 1));
		my $c2 = ord(substr($data, ($i*8)+1, 1));
		my $c3 = ord(substr($data, ($i*8)+2, 1));
		my $c4 = ord(substr($data, ($i*8)+3, 1));
		my $c5 = ord(substr($data, ($i*8)+4, 1));
		my $c6 = ord(substr($data, ($i*8)+5, 1));
		my $c7 = ord(substr($data, ($i*8)+6, 1));
		my $c8 = ord(substr($data, ($i*8)+7, 1));

		my $b1 = (($c1 << 1) | ($c2 >> 6)) & 0xff;
		my $b2 = (($c2 << 2) | ($c3 >> 5)) & 0xff;
		my $b3 = (($c3 << 3) | ($c4 >> 4)) & 0xff;
		my $b4 = (($c4 << 4) | ($c5 >> 3)) & 0xff;
		my $b5 = (($c5 << 5) | ($c6 >> 2)) & 0xff;
		my $b6 = (($c6 << 6) | ($c7 >> 1)) & 0xff;
		my $b7 = ((($c7 << 7) & 0x80) | ($c8 & 0x7f)) & 0xff;

		push @{$bytes}, $b1;
		push @{$bytes}, $b2;
		push @{$bytes}, $b3;
		push @{$bytes}, $b4;
		push @{$bytes}, $b5;
		push @{$bytes}, $b6;
		push @{$bytes}, $b7;
	}

	&store_bytes($bytes, $prefix.'_seq8');
}

sub store_bytes {

	my ($bytes, $mode) = @_;
	my ($px, $w, $h);

	my $size = scalar(@{$bytes});


	#
	# type 0 : grayscale
	#

	&create_type0_8bit($mode, $_, $bytes) for @shapes;
	&create_type0_4bit($mode, $_, $bytes) for @shapes;
	&create_type0_2bit($mode, $_, $bytes) for @shapes;
	&create_type0_1bit($mode, $_, $bytes) for @shapes;


	#
	# type 2 : truecolor, no alpha
	#

	&create_type2_8bit($mode, $_, $bytes) for @shapes;


	#
	# type 3 : indexed
	#

	&create_type3_8bit($mode, $_, $bytes) for @shapes;
	&create_type3_4bit($mode, $_, $bytes) for @shapes;
	&create_type3_2bit($mode, $_, $bytes) for @shapes;
	&create_type3_1bit($mode, $_, $bytes) for @shapes;


	#
	# type 4: greyscale & alpha
	#

	&create_type4_8bit($mode, $_, $bytes) for @shapes;


	#
	# type 6: turecolor & alpha
	#

	&create_type6_8bit($mode, $_, $bytes) for @shapes;
}

#########################################################################################

sub create_type0_8bit { return &create_type0($_[0], $_[1], $_[2], 8); }
sub create_type0_4bit { return &create_type0($_[0], $_[1], $_[2], 4); }
sub create_type0_2bit { return &create_type0($_[0], $_[1], $_[2], 2); }
sub create_type0_1bit { return &create_type0($_[0], $_[1], $_[2], 1); }

sub create_type0 {
	my ($mode, $shape, $bytes, $bits) = @_;

	my $im = Image::Magick->new();

	$im->Set(option => "png:color-type=0");
	$im->Set(option => "png:bit-depth=$bits");

	&pack_image($im, $shape, $bytes, $bits, sub{
		my $val = $_[0];
		if ($bits == 4){ $val = $_[0] | ($_[0] << 4); }
		if ($bits == 2){ $val = $_[0] | ($_[0] << 2) | ($_[0] << 4) | ($_[0] << 6); }
		if ($bits == 1){ $val = $_[0] | ($_[0] << 1) | ($_[0] << 2) | ($_[0] << 3) | ($_[0] << 4) | ($_[0] << 5) | ($_[0] << 6) | ($_[0] << 7); }

		my $color = sprintf('#%02x%02x%02x', $val, $val, $val);
		#print "$color ";
		return $color;
	});


	my $name = "${mode}_t0_${bits}b_${shape}.png";
	`rm -f $dir/$name`;
	my $ret = $im->Write(
		filename => "$dir/$name",
		#type => 'Grayscale',
		#depth => 2,
	);

	&debug($ret, $name);
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
	`rm -f $dir/$name`;
	my $ret = $im->Write(
		filename => "png24:$dir/$name",
		#depth => 8,
	);

	&debug($ret, $name);
}

#########################################################################################

sub create_type3_8bit { return &create_type3($_[0], $_[1], $_[2], 8); }
sub create_type3_4bit { return &create_type3($_[0], $_[1], $_[2], 4); }
sub create_type3_2bit { return &create_type3($_[0], $_[1], $_[2], 2); }
sub create_type3_1bit { return &create_type3($_[0], $_[1], $_[2], 1); }

sub create_type3 {
	my ($mode, $shape, $bytes, $bits) = @_;

	my $im = Image::Magick->new();

	$im->Set(type => 'Palette');
	$im->Set(option => "png:color-type=3");
	$im->Set(option => "png:bit-depth=$bits");
	#$im->Set('background' => "#000000");

	for my $i(0..15){
		$im->Set("colormap[$i]", sprintf('#%02x%02x%02x', $i, 0, 0));
	}

	#$im->Set(option => "png:color-type=3");
	$im->Set(option => "png:bit-depth=$bits");

	&pack_image($im, $shape, $bytes, $bits, sub{
		my $val = $_[0];
		#print "$val, ";
		#return $val;
		return sprintf('#%02x%02x%02x', $val, 0, 0);
	});


	#my $map = {};
	#my ($w, $h) = &get_dims($shape, scalar(@{$bytes}), 1);	
	#for my $y(0..$h-1){
	#for my $x(0..$w-1){
	#	my $in = $im->Get("index[$x,$y]");
	#	print "$in ";
	#}
	#}


	#$im->Set(option => "png:color-type=3");
	$im->Set(option => "png:bit-depth=$bits");

	my $name = "${mode}_t3_${bits}b_${shape}.png";
	`rm -f $dir/$name`;
	my $ret = $im->Write(
		filename => "$dir/$name",
		#depth => $bits,
	);

	&debug($ret, $name);
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
	$im->Set(matte => 1);
 	$im->Set(alpha => 'On');

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

	#$im->Set(option => "png:color-type=4");	

	my $name = "${mode}_t4_8b_${shape}.png";
	`rm -f $dir/$name`;
	my $ret = $im->Write(
		filename => "$dir/$name",
		type => 'GrayscaleMatte',
		matte => 1,
		#depth => 8,
	);

	&debug($ret, $name);
}

#########################################################################################

sub create_type6_8bit {
	my ($mode, $shape, $bytes) = @_;

	my ($w, $h) = &get_dims($shape, scalar(@{$bytes}), 4);

	my $im = Image::Magick->new(size=>"${w}x${h}");
	$im->ReadImage('xc:white');
	$im->Set(matte => 1);
	$im->Set(alpha => 'On');

	my $i=0;
	for my $y(0..$h-1){
	for my $x(0..$w-1){

		my $b1 = $bytes->[($i*4)+0] || 0;
		my $b2 = $bytes->[($i*4)+1] || 0;
		my $b3 = $bytes->[($i*4)+2] || 0;
		my $b4 = $bytes->[($i*4)+3] || 0;
		my $color = sprintf('#%02x%02x%02x%02x', $b1, $b2, $b3, $b4);

		$im->Set("pixel[$x,$y]" => $color);
		#my $check = $im->Get("pixel[$x,$y]");
		#print "$color -> $check\n";
		#exit;
		$i++;
	}
	}

	my $name = "${mode}_t6_8b_${shape}.png";
	`rm -f $dir/$name`;
	my $ret = $im->Write(
		filename => "png32:$dir/$name",
		depth => 8,
	);

	&debug($ret, $name);
}

#########################################################################################

sub pack_image {
	my ($im, $shape, $bytes, $bits, $cf) = @_;

	return &pack_image_8bit($im, $shape, $bytes, $cf) if $bits == 8;
	return &pack_image_4bit($im, $shape, $bytes, $cf) if $bits == 4;
	return &pack_image_2bit($im, $shape, $bytes, $cf) if $bits == 2;
	return &pack_image_1bit($im, $shape, $bytes, $cf) if $bits == 1;
	return undef;
}

sub pack_image_8bit {
	my ($im, $shape, $bytes, $cf, $gs) = @_;
	my ($w, $h) = &get_dims($shape, scalar(@{$bytes}), 1);

	$im->Set(size=>"${w}x${h}");
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
	my ($im, $shape, $bytes, $cf, $gs) = @_;
	my ($w, $h) = &get_dims($shape, scalar(@{$bytes}), 2, 1);

	$im->Set(size=>"${w}x${h}");
	$im->ReadImage('xc:black');

	my $i=0;
	my $c=0;
	for my $y(0..$h-1){
	for my $x(0..$w-1){

		my $b1 = $bytes->[$i] || 0;
		$b1 = $c ? 0xF & ($b1 >> 4) : 0xF & $b1;

		my $color = &$cf($b1);
		#print "encoding byte $bytes->[$i] as $c: $b1 ($color)\n";

		$im->Set("pixel[$x,$y]" => $color);
		#$im->Set("index[$x,$y]" => $color);

		if ($c){ $i++; }
		$c = $c ? 0 : 1;
		#if ($c == 0){ exit; }
	}
	}

	return $im;
}

sub pack_image_2bit {
	my ($im, $shape, $bytes, $cf, $gs) = @_;
	my ($w, $h) = &get_dims($shape, scalar(@{$bytes}), 4, 1);

	$im->Set(size=>"${w}x${h}");
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
	my ($im, $shape, $bytes, $cf, $gs) = @_;
	my ($w, $h) = &get_dims($shape, scalar(@{$bytes}), 8, 1);

	$im->Set(size=>"${w}x${h}");
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

	my $short = 1;
	my $long = $px;
	my $long_limit = 65000;

	while ($long > $long_limit){
		$short++;
		$long = ceil($px / $short);
	}

	if ($shape eq 'wide'){ return ($long, $short); }
	if ($shape eq 'tall'){ return ($short, $long); }
	return ($w, $h);
}

#########################################################################################

sub debug {
	my ($ret, $name) = @_;

	print "\n";
	print "$name:\n";
	if ($ret){ print "\tERROR: $ret\n"; }
	print `./peek.pl $dir/$name`;
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
