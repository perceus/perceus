initdir = /etc/init.d/
confdir = /etc/sysconfig

dist_conf_DATA = perceus

DISTRO_INIT_FILES = \
	debian-perceus.in \
	debian-provisiond.in \
	gentoo-perceus.in \
	gentoo-provisiond.in \
	nsa-perceus.in \
	nsa-provisiond.in \
	redhat-perceus.in \
	redhat-provisiond.in \
	slackware-perceus.in \
	slackware-provisiond.in \
	suse-perceus.in \
	suse-provisiond.in


DISTFILES = Makefile.am Makefile.in $(DISTRO_INIT_FILES) $(dist_conf_DATA)

MAINTAINERCLEANFILES = Makefile.in

install-exec-hook: $(DISTRO_INIT_FILES)
	test -z "$(initdir)" || $(mkdir_p) "$(DESTDIR)$(initdir)"
	list='perceus provisiond'; for p in $$list; do \
	  if test -f $(srcdir)/$(perceus_init_format)-$$p; then \
	    f=`echo "$$p" | sed 's|^.*/||;$(transform)'`; \
	    echo " $(INSTALL_SCRIPT) '$(srcdir)/$(perceus_init_format)-$$p' '$(DESTDIR)$(initdir)/$$f'"; \
	    $(INSTALL_SCRIPT) "$(srcdir)/$(perceus_init_format)-$$p" "$(DESTDIR)$(initdir)/$$f"; \
	  else :; fi; \
	done

dist_confDATA_INSTALL = configinstall(){ source="$$1";target="$$2"; if test -f $$target; then ${INSTALL} -m 644 $$source $$target.v@perceus_version@; else ${INSTALL} -m 644 $$source $$target; fi };configinstall
