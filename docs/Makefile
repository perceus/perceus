
DOCNAMES=perceus-userguide perceus-nsa-quickstart

all:
	for i in $(DOCNAMES); do \
		(cd .. && /bin/sh ./config.status docs/$$i.tex); \
		texi2pdf $$i.tex ; \
	done

clean:
	rm -f *.aux *.log *.pdf *.toc ||:
