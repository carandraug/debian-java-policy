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
	#jw -u $< > dump.html
	#lynx -force_html -dump dump.html > $@
	#-rm -f dump.html
	jw -b txt $(DSL) $<

install: debian-java-policy-install debian-java-faq-install dummy-install script-install

dummy-install:
	mkdir -p $(PUBLISHDIR)/dummy-packages
	cp dummy/README $(PUBLISHDIR)/dummy-packages
	cp dummy/*.control $(PUBLISHDIR)/dummy-packages

script-install:
	mkdir -p $(DESTDIR)/usr/sbin
	install -m 755 scripts/update-java-alternatives $(DESTDIR)/usr/sbin/
	mkdir -p $(DESTDIR)/usr/share/man/man8
	install -m 755 scripts/update-java-alternatives.8 $(DESTDIR)/usr/share/man/man8/

debian-java-policy-install:
	install -m 0444 $(OUTPUTS) $(PUBLISHDIR)
	cp -a debian-java-policy $(PUBLISHDIR)
	ln -s debian-java-policy $(PUBLISHDIR)/html

clean: debian-java-faq
	-rm -Rf debian-java-policy
	-rm -Rf policy.html
	-rm -f $(MAKEOUT)
	-rm -f policy.dvi
	(cd $<; make clean)

debian-java-faq-gen: debian-java-faq
	(cd $<; make debian-java-faq.html/index.html)

# Change the publish dir if you want to send it to a new package.
debian-java-faq-install: debian-java-faq debian-java-faq-gen
	(cd $<; make publish PUBLISHDIR=$(PUBLISHDIR))

debian-java-faq-update: debian-java-faq
	svn export svn://svn.debian.org/svn/ddp/manuals/trunk/java-faq/ faq-update/
	cp faq-update/* $</
	rm -fr faq-update/
