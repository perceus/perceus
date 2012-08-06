#!/bin/sh

if test -d ".svn"; then
   if which svnversion >/dev/null 2>&1; then
      echo "Getting repository version"
      BUILD=`svnversion .`
   else
      BUILD="0000"
   fi
   if test -z "$NO_CHANGELOG" && which svn >/dev/null 2>&1; then
      echo "Building ChangeLog"
      svn -v log > ChangeLog
   else
      echo "No changelog here" > ChangeLog
   fi
else
   BUILD="0000"
fi

if echo "$BUILD" | grep -q "M"; then
   echo "WARNING: Building on a modified source tree!"
   ZERO=1
fi
if echo "$BUILD" | grep -q ":"; then
   echo "WARNING: Not using the latest SVN update!"
   BUILD=`echo $BUILD | awk -F : '{print $2}'`
   ZERO=1
fi
 
if test -n "$ZERO" ; then
   BUILD="0.$BUILD"
   sleep 2
fi

echo
echo "Setting BUILD to '$BUILD'"
echo

echo $BUILD > BUILD

set -x

libtoolize -f -c
aclocal
autoheader
autoconf
automake -ca -Wno-portability

if [ -z "$NO_CONFIGURE" ]; then
   ./configure $@
fi
