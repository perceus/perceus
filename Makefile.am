SUBDIRS = src scripts 3rd_party man etc post modules images

# Here are some helper targets for doing "non-standard" builds.
kernel:
	make -C 3rd_party kernel
	mv bzImage kernel

kernel-config:
	make -C 3rd_party kernel-config

initramfs:
	make -C src
	make -C 3rd_party initramfs
	make -C scripts/initramfs install
	make -C post initramfs

initramfs.img:
	make -C post initramfs.img

initrd: initramfs.img
	mv initramfs.img initrd

bzImage: kernel

# For minimal initramfs builds, run this before doing a standard "make all"
# Must define ROOT=/path/to/chroot
uclibc-initramfs:
	@ if test -z "$(ROOT)"; then echo "You must use the argument 'ROOT=/path/to/uclibc-buildroot' to this command"; exit 1; fi
	rm -rf $(ROOT)/tmp/perceus-build ||:
	mkdir -p $(ROOT)/tmp/perceus-build/
	cp -rap . $(ROOT)/tmp/perceus-build/
	rm -f $(ROOT)/tmp/perceus-build/_initramfs ||:
	/usr/sbin/chroot $(ROOT) /bin/sh -c "cd /tmp/perceus-build; ./configure --enable-uclibc"
	/usr/sbin/chroot $(ROOT) /bin/sh -c "cd /tmp/perceus-build; find . -type f | xargs touch"
	/usr/sbin/chroot $(ROOT) /bin/sh -c "cd /tmp/perceus-build; make clean"
	/usr/sbin/chroot $(ROOT) /bin/sh -c "cd /tmp/perceus-build; make initramfs"
	test -L _initramfs || \
		ln -s $(ROOT)/tmp/perceus-build/_initramfs _initramfs
	mkdir -p 3rd_party/_work/
	test -L 3rd_party/_work/busybox || \
		ln -s $(ROOT)/tmp/perceus-build/3rd_party/_work/busybox 3rd_party/_work/busybox
	test -L 3rd_party/_work/cpio || \
		ln -s $(ROOT)/tmp/perceus-build/3rd_party/_work/cpio 3rd_party/_work/cpio
	test -L 3rd_party/_work/kexec || \
		ln -s $(ROOT)/tmp/perceus-build/3rd_party/_work/kexec 3rd_party/_work/kexec
	test -L 3rd_party/_work/kexec-legacy || \
		ln -s $(ROOT)/tmp/perceus-build/3rd_party/_work/kexec-legacy 3rd_party/_work/kexec-legacy

install-vnfs:
	@ if test -z "$(ROOT)"; then echo "You must use the argument 'ROOT=/path/to/mounted/vnfs' to this command"; exit 1; fi
	make -C src
	test -d $(ROOT)/${sbindir} || mkdir -p $(ROOT)/${sbindir}
	test -d $(ROOT)/etc/init.d/ || mkdir -p $(ROOT)/etc/init.d/
	install -m 755 src/provisiond/provisiond $(ROOT)/${sbindir}/provisiond
	install -m 755 src/ethinfo/ethinfo $(ROOT)/${sbindir}/ethinfo
	install -m 755 scripts/init.d/provisiond $(ROOT)/etc/init.d/provisiond

MAINTAINERCLEANFILES = BUILD ChangeLog Makefile.in aclocal.m4 configure compile config.* ltmain.sh bzImage initrd initramfs.img
DISTCLEANFILES = bzImage initrd initramfs.img
CLEANFILES = bzImage initrd initramfs.img

EXTRA_DIST = perceus.spec BUILD MODULES docs/perceus-userguide.tex docs/Makefile
