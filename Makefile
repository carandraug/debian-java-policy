OUTPUTS=policy.html policy.txt policy.ps policy.db

all: policy

policy: policy.ps policy.txt policy.html

policy.tex: policy.db
	jade -t tex \
		-d /usr/lib/sgml/stylesheet/dsssl/docbook/nwalsh/print/docbook.dsl \
		/usr/lib/sgml/declaration/xml.decl $<

policy.dvi: policy.tex
	jadetex $<
	jadetex $<

policy.ps: policy.dvi
	dvips -f $< > $@

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

install: $(OUTPUTS)
	install -m 0444 $(OUTPUTS) *.html $(DESTDIR)/usr/doc/java-common

clean: 
	rm -f *.html *.aux *.log *.dvi *.ps *.tex *.txt

