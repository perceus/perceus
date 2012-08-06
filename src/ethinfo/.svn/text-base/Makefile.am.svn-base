# Installed by post/Makefile in initramfs but ALSO needed for provisiond subpackage.
sbin_PROGRAMS = ethinfo

ethinfo_SOURCES = ethinfo.c

ethinfo_LDADD = $(top_builddir)/src/libethinfo.la

MAINTAINERCLEANFILES = Makefile.in
