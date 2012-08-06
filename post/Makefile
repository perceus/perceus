all:	initramfs

top_srcdir = ..
prefix = /usr
localstatedir = ${prefix}/var
exec_prefix = ${prefix}
sbindir = ${exec_prefix}/sbin
bindir = ${exec_prefix}/bin
mandir = ${datarootdir}/man
datarootdir = ${prefix}/share
ARCHITECTURE = @architecture@
PWD = $(shell pwd)


initramfs: 
	mkdir -p $(top_srcdir)/_initramfs/etc/detect
	mkdir -p $(top_srcdir)/_initramfs/sbin
	mkdir -p $(top_srcdir)/_initramfs/bin
	mkdir -p $(top_srcdir)/_initramfs/dev
	test -f $(top_srcdir)/_initramfs/sbin/provisiond || \
		install -m 755 ../src/provisiond/provisiond $(top_srcdir)/_initramfs/sbin/
	test -f $(top_srcdir)/_initramfs/bin/ethinfo || \
		install -m 755 ../src/ethinfo/ethinfo $(top_srcdir)/_initramfs/bin/
	test -f $(top_srcdir)/_initramfs/sbin/detect || \
		install -m 755 ../src/detect/detect $(top_srcdir)/_initramfs/sbin/
	install -m 755 ../src/detect/modconf-generator $(top_srcdir)/_initramfs/sbin
	install -m 644 ../src/detect/ignore $(top_srcdir)/_initramfs/etc/detect
	install -m 644 ../src/detect/pcimap $(top_srcdir)/_initramfs/etc/detect
	install -m 644 ../src/detect/updates $(top_srcdir)/_initramfs/etc/detect
	install -m 644 ../src/detect/classids $(top_srcdir)/_initramfs/etc/detect
	install -m 644 mdev.conf $(top_srcdir)/_initramfs/etc/mdev.conf

initramfs.img:
	cp devs.cpio initramfs.cpio
	(cd $(top_srcdir)/_initramfs/; find . | cpio -o -H newc -A -F $(PWD)/initramfs.cpio )
	gzip -9 < initramfs.cpio > ../initramfs.img

install-data install-exec install-info: install

installdirs: initramfs.img
	mkdir -p $(DESTDIR)$(localstatedir)/lib/perceus/nodescripts/init/all
	mkdir -p $(DESTDIR)$(localstatedir)/lib/perceus/nodescripts/init/group
	mkdir -p $(DESTDIR)$(localstatedir)/lib/perceus/nodescripts/init/node
	mkdir -p $(DESTDIR)$(localstatedir)/lib/perceus/nodescripts/init/vnfs
	mkdir -p $(DESTDIR)$(localstatedir)/lib/perceus/vnfs
	mkdir -p $(DESTDIR)$(localstatedir)/lib/perceus/tftp
	mkdir -p $(DESTDIR)$(localstatedir)/lib/perceus/nodescripts

install: installdirs
	test -L $(DESTDIR)/etc/perceus/nodescripts && rm -f $(DESTDIR)/etc/perceus/nodescripts ||:
	test -L $(DESTDIR)/etc/perceus/vnfs && rm -f $(DESTDIR)/etc/perceus/vnfs ||:
	ln -sf $(localstatedir)/lib/perceus/nodescripts $(DESTDIR)/etc/perceus/nodescripts
	ln -sf $(localstatedir)/lib/perceus/vnfs $(DESTDIR)/etc/perceus/vnfs
	install -m 644 ../initramfs.img $(DESTDIR)/${prefix}/var/lib/perceus/tftp/initramfs.img
	install -m 644 ../bzImage $(DESTDIR)/${prefix}/var/lib/perceus/tftp/kernel
	grep -q "^perceus:" /etc/group || groupadd -r perceus || groupadd perceus ||:
	chgrp perceus $(bindir)/perceus ||:

uninstall:
	echo "We need to do something better here one day"

clean distclean maintainer-clean mostlyclean:
	rm -f initramfs.cpio

distdir:
	cp mdev.conf devs.cpio Makefile.in $(distdir)/

check installcheck:

dvi pdf ps info html tags ctags:
