#!/usr/bin/perl

use warnings;
use strict;

opendir D, "perl_images" or die $!;
while (my $file = readdir D){

	if ($file =~ /\.png$/){

		print `pngout-static -y perl_images/$file perl_images_pngout/$file`;
	}
}
