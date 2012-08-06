MODULE                  = $(shell basename $(subdir))

dist_module_DATA             = $(shell test -f defaultroles && echo defaultroles)
dist_nodescripts_SCRIPTS     = $(shell ls [0-9]*.sh)
dist_module_SCRIPTS          = $(shell test -f install && echo install)
dist_module_SCRIPTS         += $(shell test -f configure && echo configure)
dist_module_SCRIPTS         += $(shell test -f readme && echo readme)
dist_module_SCRIPTS         += $(shell test -f activate && echo activate)

moduledir = $(localstatedir)/lib/perceus/modules/$(MODULE)
nodescriptsdir = $(localstatedir)/lib/perceus/modules/$(MODULE)/nodescripts

MAINTAINERCLEANFILES = Makefile.in

module:
	mkdir -p build/nodescripts
	install -m 755 *.sh build/nodescripts
	test -f install     && install -m 755 install build/     ||:
	test -f configure   && install -m 755 configure build/   ||:
	test -f readme      && install -m 755 readme build/      ||:
	test -f activate    && install -m 755 activate build/    ||:
	test -f defaultroles && install -m 755 defaultroles build/ ||:
	(cd build; tar cvjf ../$(MODULE)-$(VERSION).pmod .)

