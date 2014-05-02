

all: generated/html/portal.html generated/bootstrap/portal.html

generated/html/portal.html: portal.asciidoc Makefile
	mkdir -p generated/html
	asciidoc -o generated/html/portal.html -b html -a toc portal.asciidoc

generated/bootstrap/portal.html: portal.asciidoc Makefile
	mkdir -p generated/bootstrap
	asciidoc  -b bootstrap -a docinfo -a toc -a totop -a jumbotron -a bsver=3 -o generated/bootstrap/portal.html portal.asciidoc
