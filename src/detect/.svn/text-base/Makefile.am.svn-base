# These are installed by post/Makefile, so do not install them here.
noinst_PROGRAMS = detect
dist_noinst_SCRIPTS = modconf-generator ignore pcimap updates classids

detect_SOURCES = detect.c getids.c getmod.c util.c readconfs.c detect.h defs.h
detect_CFLAGS = -I$(top_srcdir)/src/detect -I$(top_srcdir)/src/ -I$(top_srcdir)

MAINTAINERCLEANFILES = Makefile.in
