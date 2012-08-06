etcdir = /etc/perceus/
confdir = /etc/perceus/
bash_completiondir = /etc/bash_completion.d/
httpdconfdir = /etc/httpd/conf.d/

dist_etc_DATA = defaults.conf perceus.conf
dist_bash_completion_DATA = perceus_completion
dist_conf_DATA = Perceus_Include.pm
dist_httpdconf_DATA = perceus-cgi.conf

dist_etcDATA_INSTALL = configinstall(){ source="$$1";target="$$2"; if test -f $$target; then ${INSTALL} -m 644 $$source $$target.v@perceus_version@; else ${INSTALL} -m 644 $$source $$target; fi };configinstall

MAINTAINERCLEANFILES = Makefile.in
