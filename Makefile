#!/usr/bin/make -f 

# Good info at: info make "Quick Reference"
# $^ All prerequisites
# $< First prerequisity
# $@ Target

# Some default variables
DOC = usr/share/doc
DVIPS=dvips
PUBLISHDIR=$(DESTDIR)/$(DOC)/java-common
#DSLF=work.dsl
#DSL=-d $(DSLF)
# Default language to use
LANGUAGE=
LANG=C
LC_CTYPE=C

all: debian-java-policy debian-java-faq-gen

# Policy part
MAKEOUT=policy.txt policy.ps
OUTPUTS=$(MAKEOUT) policy.xml
MAKEDEP=$(MAKEOUT) policy.html 

debian-java-policy: $(MAKEDEP)
update: debian-java-faq-update

policy.tex: policy.xml
	jw $(DCL) -b tex $(DSL) policy.xml

policy.dvi: policy.xml
	jw $(DCL) -b dvi $(DSL) policy.xml

policy.ps: policy.dvi
	$(DVIPS) -f $< > $@

policy.html: policy.xml
	# docbook and dsl file needs to be in that dir for things to work.
	# The png file is copied there so it can be referenced in a proper way.
	mkdir -p debian-java-policy.html
	cp $^ html
	jw -b html $(DSL) -o debian-java-policy.html $<
	# To make that file the intdex.
	(cd debian-java-policy.html; rm -f $^)

policy.txt: policy.xml
	jw -u $< > dump.html
	lynx -force_html -dump dump.html > $@
	-rm -f dump.html

install: debian-java-policy-install debian-java-faq-install

debian-java-policy-install:
	install -m 0444 $(OUTPUTS) $(PUBLISHDIR)
	cp -a debian-java-policy.html $(PUBLISHDIR)
	ln -s debian-java-policy.html $(PUBLISHDIR)/html

clean: debian-java-faq
	-rm -Rf debian-java-policy.html
	-rm -f $(MAKEOUT)
	-rm -f policy.dvi
	(cd $<; make clean)

debian-java-faq-gen: debian-java-faq
	(cd $<; make debian-java-faq.html/index.html)

# Change the publish dir if you want to send it to a new package.
debian-java-faq-install: debian-java-faq debian-java-faq-gen
	(cd $<; make publish PUBLISHDIR=$(PUBLISHDIR))

debian-java-faq:
	(cvs -d :pserver:anonymous@cvs.debian.org:/cvs/debian-doc -z3 checkout -d debian-java-faq ddp/manuals.sgml/java-faq)

debian-java-faq-update: debian-java-faq
	(cd $<; cvs -z3 update -d)
