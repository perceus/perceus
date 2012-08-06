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
