#!/bin/sh

rm -f perl_images_optipng/*.png
rm -f perl_images_pngcrush/*.png
rm -f perl_images_pngout/*.png

optipng -zc1-9 -zm1-9 -zs0-3 -f0-5 -dir perl_images_optipng perl_images/*.png

pngcrush -brute -d perl_images_pngcrush/ perl_images/*

perl pngout.pl

