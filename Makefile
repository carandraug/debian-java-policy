#!/usr/bin/make -f 

# Tools used
# Placed here in case we decide to use autoconf
DVIPS    = dvips
PS2PDF   = ps2pdf

ifeq ("$(shell dh_testversion 2.0.40 && echo potatoorabove)", "potatoorabove")
DOC = usr/share/doc
MAN = usr/share/man
DATA = usr/share/misc
else
DOC = usr/doc
MAN = usr/man
DATA = usr/lib
endif

# Some default variables
PUBLISHDIR = $(DESTDIR)/$(DOC)/java-common
# Default language to use
LANGUAGE = LANG=C LC_CTYPE=C

all: policy debian-java-faq

# Policy part
OUTPUTS=policy*.html policy.txt policy.ps policy.db

policy: policy.ps policy.txt policy.html 

policy.tex: policy.db
	jade -t tex \
		-d /usr/lib/sgml/stylesheet/dsssl/docbook/nwalsh/print/docbook.dsl \
		/usr/lib/sgml/declaration/xml.decl $<

policy.dvi: policy.tex
	jadetex $<
	jadetex $<

policy.ps: policy.dvi
	$(DVIPS) -f $< > $@

policy.html: policy.db html.dsl
	jade -t sgml \
		-d html.dsl \
		/usr/lib/sgml/declaration/xml.decl $< 

policy.txt: policy.db
	jade -t sgml -V nochunks \
		-d /usr/lib/sgml/stylesheet/dsssl/docbook/nwalsh/html/docbook.dsl \
	/usr/lib/sgml/declaration/xml.decl $< > dump.html
	lynx -force_html -dump dump.html > $@
	-rm -f dump.html

validate:
	nsgmls -s -wxml /usr/lib/sgml/declaration/xml.decl policy.db
	nsgmls -s debian-java-faq.sgml

install:: $(OUTPUTS)
	install -m 0444 $(OUTPUTS) $(PUBLISHDIR)

clean: 
	rm -rf *.html *.aux *.log *.dvi *.ps *.tex *.txt

# For the debian-java-FAQ
# by Javier Fernández-Sanguino Peña <jfs@computer.org>

debian-java-faq: debian-java-faq.html debian-java-faq.ps  debian-java-faq.txt
 
OUTPUTS +=  debian-java-faq.ps  debian-java-faq.txt

debian-java-faq.html: debian-java-faq.sgml
	$(LANGUAGE) debiandoc2html debian-java-faq.sgml
debian-java-faq.dvi: debian-java-faq.sgml
	$(LANGUAGE) debiandoc2latexdvi debian-java-faq.sgml

%.ps : %.dvi
	$(DVIPS) $< -o $@
%.pdf: %.ps
	$(PS2PDF) $< $@

debian-java-faq.txt: debian-java-faq.sgml
	$(LANGUAGE) debiandoc2text debian-java-faq.sgml

install ::
	rm -f $(PUBLISHDIR)/debian-java-faq.html
	mkdir $(PUBLISHDIR)/debian-java-faq.html
	install -p -m 644 debian-java-faq.html/*.html $(PUBLISHDIR)/debian-java-faq.html/
