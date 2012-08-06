initdir = $(top_srcdir)/_initramfs
sbindir = $(top_srcdir)/_initramfs/sbin
etcdir  = $(top_srcdir)/_initramfs/etc

dist_init_SCRIPTS = init
dist_sbin_SCRIPTS = dhcp-script hw_load hw_unload kexec reboot30
dist_etc_SCRIPTS = functions rc.perceus
dist_etc_DATA = initramfs.conf inittab passwd group nsswitch.conf

CLEANFILES = $(initdir)
MAINTAINERCLEANFILES = Makefile.in

install: all
	mkdir -p $(initdir)
	mkdir -p $(sbindir)
	mkdir -p $(etcdir)
	install -m 755 $(dist_sbin_SCRIPTS) $(sbindir)/
	install -m 755 $(dist_init_SCRIPTS) $(initdir)/
	install -m 755 $(dist_etc_SCRIPTS)  $(etcdir)/
	install -m 644 $(dist_etc_DATA)     $(etcdir)/
