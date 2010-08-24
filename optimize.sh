#!/bin/sh

rm -f perl_images_optipng/*.png
optipng -zc1-9 -zm1-9 -zs0-3 -f0-5 -dir perl_images_optipng perl_images/*.png

rm -f perl_images_pngcrush/*.png
pngcrush -brute -d perl_images_pngcrush/ perl_images/*

perl pngout.pl

