#!/bin/sh

aclocal
libtoolize --force -c
automake -ca
autoconf

if [ -n "$1" ]; then
   ./configure $@
fi

