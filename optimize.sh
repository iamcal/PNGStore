#!/bin/sh

rm -f perl_optipng_images/*.png
optipng -zc1-9 -zm1-9 -zs0-3 -f0-5 -dir perl_optipng_images perl_images/*.png

