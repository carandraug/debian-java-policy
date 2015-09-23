#!/usr/bin/make -f 

# Good info at: info make "Quick Reference"
# $^ All prerequisites
# $< First prerequisity
# $@ Target

# Some default variables
DOC = usr/share/doc
DVIPS=dvips
PUBLISHDIR=$(DESTDIR)/$(DOC)/java-policy
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

policy.html: debian-java-policy/index.html

debian-java-policy/index.html: policy.xml
	# docbook and dsl file needs to be in that dir for things to work.
	# The png file is copied there so it can be referenced in a proper way.
	#
	# This is no longer true.
	mkdir -p debian-java-policy
	jw -b html $(DSL) -o debian-java-policy $<
	# To make that file the intdex.
	(cd debian-java-policy; rm -f $^)

policy.txt: policy.xml
	jw -b txt $(DSL) $<

install: debian-java-policy-install debian-java-faq-install

debian-java-policy-install:
	mkdir -p $(PUBLISHDIR)
	install -m 0444 $(OUTPUTS) $(PUBLISHDIR)
	cp -a debian-java-policy $(PUBLISHDIR)

clean: faq
	-rm -Rf debian-java-policy
	-rm -Rf policy.html
	-rm -f $(MAKEOUT)
	-rm -f policy.dvi
	(cd $<; make clean)

debian-java-faq-gen: faq
	(cd $<; make debian-java-faq.html/index.html)

# Change the publish dir if you want to send it to a new package.
debian-java-faq-install: faq debian-java-faq-gen
	(cd $<; make publish PUBLISHDIR=$(PUBLISHDIR))

debian-java-faq-update: faq
	svn export svn://svn.debian.org/svn/ddp/manuals/trunk/java-faq/ faq-update/
	cp faq-update/* $</
	rm -fr faq-update/
