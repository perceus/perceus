all: dnsmasq busybox kexec kexec-legacy pxelinux memtest kernel build-initramfs
initramfs: busybox kexec kexec-legacy build-initramfs

top_srcdir = ..
prefix = /usr
localstatedir = ${prefix}/var
exec_prefix = ${prefix}
sbindir = ${exec_prefix}/sbin
mandir = ${datarootdir}/man
datarootdir = ${prefix}/share
ARCHITECTURE = x86_64
KCONFIG = configs/kernel-x86_64.config
libdirname= lib64
enable_gpxe = 
busybox_config = busybox-default.config
LIBZ = /usr/lib/gcc/x86_64-linux-gnu/4.4.5/../../../../lib/libz.a
BUSYBOX_LIBS =  /lib/../lib/libc.so.6 /lib/../lib/ld-linux-x86-64.so.2 /lib/../lib/libnss_dns.so.2 /lib/../lib/libresolv.so.2 /lib/../lib/libpthread.so.0 /lib/../lib/libuuid.so.1 /lib/../lib/librt.so.1


KERNEL_VERSION = 2.6.32
KERNEL_SOURCE = linux-$(KERNEL_VERSION).tar.bz2
KERNEL_DIR = linux-$(KERNEL_VERSION)
KERNEL_PATCHES = 

BUSYBOX_VERSION = 1.16.2
BUSYBOX_SOURCE = busybox-$(BUSYBOX_VERSION).tar.bz2
BUSYBOX_DIR = busybox-$(BUSYBOX_VERSION)
BUSYBOX_PATCHES = 

KEXEC_VERSION = 2.0.0
KEXEC_SOURCE = kexec-tools-$(KEXEC_VERSION).tar.gz
KEXEC_DIR = kexec-tools-$(KEXEC_VERSION)
KEXEC_PATCHES = kexec-tools-multiboot_x86_user_h.patch kexec-tools-testing-20080324-static_libs.patch

KEXEC_LEGACY_VERSION = 1.101
KEXEC_LEGACY_SOURCE = kexec-tools-$(KEXEC_LEGACY_VERSION).tar.gz
KEXEC_LEGACY_DIR = kexec-tools-$(KEXEC_LEGACY_VERSION)
KEXEC_LEGACY_PATCHES = kexec-tools-1.101-perceusfixes.patch kexec-tools-multiboot-getpagesize.patch

DNSMASQ_VERSION = 2.45
DNSMASQ_SOURCE = dnsmasq-$(DNSMASQ_VERSION).tar.gz
DNSMASQ_DIR = dnsmasq-$(DNSMASQ_VERSION)
DNSMASQ_PATCHES = dnsmasq-2.45-perceus.patch dnsmasq-2.45-ipoib_clid.patch dnsmasq-2.45-allow_cluster_name_suffixes.patch

SYSLINUX_VERSION = 3.72
SYSLINUX_SOURCE = syslinux-$(SYSLINUX_VERSION).tar.bz2
SYSLINUX_DIR = syslinux-$(SYSLINUX_VERSION)
SYSLINUX_PATCHES = 

MEMTEST_VERSION = 2.11
MEMTEST_SOURCE = memtest86+-$(MEMTEST_VERSION).bin.gz

E2FSPROGS_VERSION = 1.41.6
E2FSPROGS_SOURCE = e2fsprogs-$(E2FSPROGS_VERSION).tar.gz
E2FSPROGS_DIR = e2fsprogs-$(E2FSPROGS_VERSION)
E2FSPROGS_PATCHES =

MDADM_VERSION = 3.0
MDADM_SOURCE = mdadm-$(MDADM_VERSION).tar.gz
MDADM_DIR = mdadm-$(MDADM_VERSION)
MDADM_PATCHES = mdadm-3.0-super-intel_c.patch

XFSPROGS_VERSION = 3.0.1
XFSPROGS_SOURCE = xfsprogs-$(XFSPROGS_VERSION).tar.gz
XFSPROGS_DIR = xfsprogs-$(XFSPROGS_VERSION)
XFSPROGS_PATCHES = xfsprogs-3.1.0-glibc-fixes.patch

STRIP = strip

install-data install-exec install-info: install

installdirs:
	install -m 755 -d $(DESTDIR)/${prefix}/var/lib/perceus/tftp/
	install -m 755 -d $(DESTDIR)/${exec_prefix}/libexec/perceus
	install -m 755 -d $(DESTDIR)/${prefix}/var/lib/perceus/bin

install: installdirs
	@ if test "x$(enable_gpxe)" = "xyes"; then \
		install -m 644 _work/syslinux/$(SYSLINUX_DIR)/gpxe/gpxelinux.0 $(DESTDIR)/${prefix}/var/lib/perceus/tftp/gpxelinux.0; \
	fi
	install -m 644 _work/syslinux/$(SYSLINUX_DIR)/core/pxelinux.0 $(DESTDIR)/${prefix}/var/lib/perceus/tftp/pxelinux.0
	install -m 644 _work/syslinux/$(SYSLINUX_DIR)/com32/modules/chain.c32 $(DESTDIR)/${prefix}/var/lib/perceus/tftp/chain.c32
	install -m 644 _work/syslinux/$(SYSLINUX_DIR)/com32/menu/menu.c32 $(DESTDIR)/${prefix}/var/lib/perceus/tftp/menu.c32
	install -m 644 _work/syslinux/$(SYSLINUX_DIR)/com32/menu/vesamenu.c32 $(DESTDIR)/${prefix}/var/lib/perceus/tftp/vesamenu.c32
	install -m 644 _work/memtest/memtest86+-$(MEMTEST_VERSION).bin $(DESTDIR)/${prefix}/var/lib/perceus/tftp/memtest
	install -m 755 _work/dnsmasq/$(DNSMASQ_DIR)/src/dnsmasq $(DESTDIR)/${exec_prefix}/libexec/perceus/perceus-dnsmasq
	install -m 755 _work/kexec/$(KEXEC_DIR)/build/sbin/kexec $(DESTDIR)/${prefix}/var/lib/perceus/bin/kexec
	install -m 755 _work/kexec-legacy/$(KEXEC_LEGACY_DIR)/objdir*/build/sbin/kexec $(DESTDIR)/${prefix}/var/lib/perceus/bin/kexec-legacy

build-initramfs: busybox mke2fs mdadm mkfs.xfs
	install -m 755 -d $(top_srcdir)/_initramfs
	install -m 755 -d $(top_srcdir)/_initramfs/bin
	install -m 755 -d $(top_srcdir)/_initramfs/sbin
	install -m 755 -d $(top_srcdir)/_initramfs/proc
	install -m 755 -d $(top_srcdir)/_initramfs/sys
	install -m 755 -d $(top_srcdir)/_initramfs/lib/modules
	install -m 755 -d $(top_srcdir)/_initramfs/etc
	install -m 755 -d $(top_srcdir)/_initramfs/libexec
	install -m 755 -d $(top_srcdir)/_initramfs/$(libdirname)
	install -m 755 _work/kexec/$(KEXEC_DIR)/build/sbin/kexec $(top_srcdir)/_initramfs/libexec/kexec
	install -m 755 _work/kexec-legacy/$(KEXEC_LEGACY_DIR)/objdir*/build/sbin/kexec $(top_srcdir)/_initramfs/libexec/kexec-legacy
	install -m 755 _work/e2fsprogs/$(E2FSPROGS_DIR)/misc/mke2fs $(top_srcdir)/_initramfs/sbin
	install -m 755 _work/xfsprogs/$(XFSPROGS_DIR)/mkfs/mkfs.xfs $(top_srcdir)/_initramfs/sbin
	install -m 755 _work/mdadm/$(MDADM_DIR)/mdadm $(top_srcdir)/_initramfs/sbin
	cp -rap _work/busybox/$(BUSYBOX_DIR)/_install/* $(top_srcdir)/_initramfs/
	for i in $(BUSYBOX_LIBS); do \
		install -m 755 $${i} $(top_srcdir)/_initramfs/$(libdirname)/ ;\
	done
	if [ $(libdirname) = "lib64" ]; then \
		cd $(top_srcdir)/_initramfs/lib ;\
		ln -s ../lib64/* . ;\
	fi
	find $(top_srcdir)/_initramfs/bin -type f | xargs -n 1 strip 2>/dev/null ||:
	find $(top_srcdir)/_initramfs/sbin -type f | xargs -n 1 strip 2>/dev/null ||:
	find $(top_srcdir)/_initramfs/lib*/l*.so* -type f | xargs -n 1 strip 2>/dev/null ||:
	find $(top_srcdir)/_initramfs/libexec -type f | xargs -n 1 strip 2>/dev/null ||:

uninstall:
	echo "We need to do something better here one day"

kernel-prep:
	@ if [ ! -d "_work/kernel/$(KERNEL_DIR)" ]; then \
		echo "Preparing to build Perceus Kernel" ;\
		mkdir -p _work/kernel ;\
		tar xjf $(KERNEL_SOURCE) -C _work/kernel/ ;\
		for i in $(KERNEL_PATCHES); do\
			(cd _work/kernel/$(KERNEL_DIR); patch -p1 < ../../../patches/$${i} || exit 1) \
		done ;\
		sed -i 's@^EXTRAVERSION.*@EXTRAVERSION = -perceus@' _work/kernel/$(KERNEL_DIR)/Makefile ;\
		cp $(KCONFIG) _work/kernel/$(KERNEL_DIR)/.config ;\
	fi

kernel-config: kernel-prep
	make -C _work/kernel/$(KERNEL_DIR) ARCH=$(ARCHITECTURE) menuconfig
	cp _work/kernel/$(KERNEL_DIR)/.config configs/kernel-custom.config

kernel: kernel-prep
	@ if [ ! -f "$(top_srcdir)/bzImage" ]; then \
		echo "Building Perceus Kernel" ;\
		make -j 2 -C _work/kernel/$(KERNEL_DIR)/ ARCH=$(ARCHITECTURE) oldconfig ;\
		make -j 2 -C _work/kernel/$(KERNEL_DIR)/ ARCH=$(ARCHITECTURE) ;\
		make -j 2 -C _work/kernel/$(KERNEL_DIR)/ ARCH=$(ARCHITECTURE) modules ;\
		mkdir -p $(top_srcdir)/_initramfs ;\
		make -C _work/kernel/$(KERNEL_DIR)/ ARCH=$(ARCHITECTURE) INSTALL_MOD_PATH=`pwd`/../_initramfs modules_install ;\
		rm $(top_srcdir)/_initramfs/lib/modules/*/build 2>/dev/null ;\
		rm $(top_srcdir)/_initramfs/lib/modules/*/source 2>/dev/null ;\
		find $(top_srcdir)/_initramfs/ -type f | xargs -n 1 strip -g 2>/dev/null ||: ;\
	else \
		echo "Remove the bzImage in the top source directory to rebuild" ;\
	fi
	cp _work/kernel/$(KERNEL_DIR)/arch/$(ARCHITECTURE)/boot/bzImage ../

busybox:
	@ if [ ! -d "_work/busybox/$(BUSYBOX_DIR)" ]; then \
		echo "Preparing to build Perceus initramfs core" ;\
		mkdir -p _work/busybox ;\
		tar xjf $(BUSYBOX_SOURCE) -C _work/busybox/ ;\
		for i in $(BUSYBOX_PATCHES); do \
			(cd _work/busybox/$(BUSYBOX_DIR); patch -p1 < ../../../patches/$${i} || exit 1) \
		done ;\
		cp configs/$(busybox_config) _work/busybox/$(BUSYBOX_DIR)/.config ;\
	fi
	@ if [ ! -f "_work/busybox/$(BUSYBOX_DIR)/busybox" ]; then \
		echo "Building Perceus initramfs core" ;\
		make -C _work/busybox/$(BUSYBOX_DIR) busybox ;\
	fi
	@ if [ ! -d "_work/busybox/$(BUSYBOX_DIR)/_install" ]; then \
		echo "Installing Perceus initramfs core" ;\
		make -C _work/busybox/$(BUSYBOX_DIR) install ;\
	fi

memtest:
	@ if [ ! -f _work/memtest/memtest86+-$(MEMTEST_VERSION).bin ]; then \
		mkdir -p _work/memtest ;\
		cp $(MEMTEST_SOURCE) _work/memtest/ ;\
		gzip -d _work/memtest/$(MEMTEST_SOURCE) ;\
	else \
		echo "Using cached memtest" ;\
	fi


pxelinux:
	@ if [ ! -d "_work/syslinux/$(SYSLINUX_DIR)" ]; then \
		echo "Preparing to build Pxelinux" ;\
		mkdir -p _work/syslinux ;\
		tar xjf $(SYSLINUX_SOURCE) -C _work/syslinux ;\
		for i in $(SYSLINUX_PATCHES); do \
			(cd _work/syslinux/$(SYSLINUX_DIR); patch -p1 < ../../../patches/$${i} || exit 1) \
		done ;\
	fi		
	@ if [ ! -f "_work/syslinux/$(SYSLINUX_DIR)/core/pxelinux.0" ]; then \
		echo "Building Pxelinux" ;\
		make -C _work/syslinux/$(SYSLINUX_DIR)/core/ pxelinux.0 ;\
	fi
	@ if [ ! -f "_work/syslinux/$(SYSLINUX_DIR)/com32/modules/chain.c32" ]; then \
		echo "Building chain.c32" ;\
		make -C _work/syslinux/$(SYSLINUX_DIR)/com32/modules/ chain ;\
	fi
	@ if [ ! -f "_work/syslinux/$(SYSLINUX_DIR)/com32/menu/menu.c32" ]; then \
		echo "Building menu.c32" ;\
		make -C _work/syslinux/$(SYSLINUX_DIR)/com32/menu/ menu ;\
	fi
	@ if test "x$(enable_gpxe)" = "xyes"; then \
		if [ ! -f "_work/syslinux/$(SYSLINUX_DIR)/gpxe/gpxelinux.0" ]; then \
			echo "Building GPxelinux" ;\
			make NO_WERROR=1 -C _work/syslinux/$(SYSLINUX_DIR)/gpxe/;\
		fi \
	fi

dnsmasq:
	@ if [ ! -d "_work/dnsmasq/$(DNSMASQ_DIR)" ]; then \
		echo "Preparing to build Dnsmasq" ;\
		mkdir -p _work/dnsmasq ;\
		tar xzf $(DNSMASQ_SOURCE) -C _work/dnsmasq ;\
		for i in $(DNSMASQ_PATCHES); do \
			(cd _work/dnsmasq/$(DNSMASQ_DIR); echo $${i} ; patch -p1 < ../../../patches/$${i} || exit 1) \
		done ;\
		cp configs/dnsmasq_config.h _work/dnsmasq/$(DNSMASQ_DIR)/src/config.h ;\
	fi
	@ if [ ! -d "_work/dnsmasq/$(DNSMASQ_DIR)/src/dnsmasq" ]; then \
		echo "Building Dnsmasq" ;\
		make -C _work/dnsmasq/$(DNSMASQ_DIR) AWK=awk COPTS=-DNO_IPV6 ;\
	fi

kexec-legacy:
	@ if [ ! -d "_work/kexec-legacy/$(KEXEC_LEGACY_DIR)" ]; then \
		echo "Preparing to build Kexec legacy" ;\
		mkdir -p _work/kexec-legacy ;\
		tar xzf $(KEXEC_LEGACY_SOURCE) -C _work/kexec-legacy ;\
		for i in $(KEXEC_LEGACY_PATCHES); do\
			(cd _work/kexec-legacy/$(KEXEC_LEGACY_DIR); patch -p1 < ../../../patches/$${i} || exit 1) \
		done ;\
	fi
	@ if [ ! -f "_work/kexec-legacy/$(KEXEC_LEGACY_DIR)/objdir-*/build/sbin/kexec" ]; then \
		echo "Building Kexec legacy" ;\
		(cd _work/kexec-legacy/$(KEXEC_LEGACY_DIR); sh ./configure ) ;\
		make CC=gcc LIBS="$(LIBZ)" -C _work/kexec-legacy/$(KEXEC_LEGACY_DIR) ;\
	fi

kexec:
	@ if [ ! -d "_work/kexec/$(KEXEC_DIR)" ]; then \
		echo "Preparing to build Kexec" ;\
		mkdir -p _work/kexec ;\
		tar xzf $(KEXEC_SOURCE) -C _work/kexec ;\
		for i in $(KEXEC_PATCHES); do\
			(cd _work/kexec/$(KEXEC_DIR); patch -p1 < ../../../patches/$${i} || exit 1) \
		done ;\
	fi
	@ if [ ! -f "_work/kexec/$(KEXEC_DIR)/objdir-*/build/sbin/kexec" ]; then \
		echo "Building Kexec" ;\
		(cd _work/kexec/$(KEXEC_DIR); sh ./configure --without-xen ) ;\
		make CC=gcc LIBS="$(LIBZ)" -C _work/kexec/$(KEXEC_DIR) ;\
	fi

mke2fs:
	@ if [ ! -d "_work/e2fsprogs/$(E2FSPROGS_DIR)" ]; then \
		echo "Preparing to build mke2fs" ;\
		mkdir -p _work/e2fsprogs ;\
		tar xzf $(E2FSPROGS_SOURCE) -C _work/e2fsprogs ;\
		for i in $(E2FSPROGS_PATCHES); do\
			(cd _work/e2fsprogs/$(E2FSPROGS_DIR); patch -p1 < ../../../patches/$${i} || exit 1) \
		done ;\
	fi
	@ if [ ! -f "_work/e2fsprogs/$(E2FSPROGS_DIR)/misc/mke2fs" ]; then \
		echo "Building mke2fs" ;\
		(cd _work/e2fsprogs/$(E2FSPROGS_DIR); sh ./configure ) ;\
		make -C _work/e2fsprogs/$(E2FSPROGS_DIR) ;\
	fi
	
mdadm:
	@ if [ ! -d "_work/mdadm/$(MDADM_DIR)" ]; then \
		echo "Preparing to build mdadm" ;\
		mkdir -p _work/mdadm;\
		tar xzf $(MDADM_SOURCE) -C _work/mdadm;\
		for i in $(MDADM_PATCHES); do\
			(cd _work/mdadm/$(MDADM_DIR); patch -p1 < ../../../patches/$${i} || exit 1) \
		done ;\
	fi
	@ if [ ! -f "_work/mdadm/$(MDADM_DIR)/mdadm" ]; then \
		echo "Building mdadm" ;\
		make -C _work/mdadm/$(MDADM_DIR) mdadm;\
	fi
	
mkfs.xfs:
	@ if [ ! -d "_work/xfsprogs/$(XFSPROGS_DIR)" ]; then \
		echo "Preparing to build mkfs.xfs" ;\
		mkdir -p _work/xfsprogs ;\
		tar xzf $(XFSPROGS_SOURCE) -C _work/xfsprogs ;\
		for i in $(XFSPROGS_PATCHES); do\
			(cd _work/xfsprogs/$(XFSPROGS_DIR); patch -p1 < ../../../patches/$${i} || exit 1) \
		done ;\
	fi
	@ if [ ! -f "_work/xfsprogs/$(XFSPROGS_DIR)/mkfs/mkfs.xfs" ]; then \
		echo "Building mkfs.xfs" ;\
		(cd _work/xfsprogs/$(XFSPROGS_DIR); sh ./configure ) ;\
		make -C _work/xfsprogs/$(XFSPROGS_DIR) include libxfs libxlog libxcmd libhandle libdisk DEBUG=-DNDEBUG ;\
		make -C _work/xfsprogs/$(XFSPROGS_DIR) mkfs DEBUG=-DNDEBUG ;\
	fi
	

clean distclean maintainer-clean mostlyclean:
	rm -rf _work

distdir:
	cp $(KERNEL_SOURCE) $(MEMTEST_SOURCE) $(BUSYBOX_SOURCE) $(KEXEC_SOURCE) $(KEXEC_LEGACY_SOURCE) $(CPIO_SOURCE) $(DNSMASQ_SOURCE) $(SYSLINUX_SOURCE) $(SXCPU_SOURCE) $(E2FSPROGS_SOURCE) $(MDADM_SOURCE) $(XFSPROGS_SOURCE) $(distdir)/
	cp README Makefile.in $(distdir)/
	mkdir $(distdir)/configs $(distdir)/patches
	cp configs/*config* $(distdir)/configs/
	cp patches/*.patch $(distdir)/patches/

check installcheck:

dvi pdf ps info html tags ctags:
