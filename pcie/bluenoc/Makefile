CC ?= gcc

bluenoc: bluenoc.c ../../drivers/pcie/bluenoc.h
	$(CC) -g -O2 -o bluenoc bluenoc.c

.PHONY: install
install: bluenoc
	install -m 755 bluenoc /usr/local/bin

.PHONY: clean
clean:
	rm -f bluenoc *~
