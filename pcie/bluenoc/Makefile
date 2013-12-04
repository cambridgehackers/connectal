CC ?= gcc

xbsvutil: bluenoc.c ../../drivers/pcie/bluenoc.h
	$(CC) -g -O2 -o xbsvutil bluenoc.c

.PHONY: install
install: bluenoc
	install -m 755 xbsvutil /usr/local/bin

.PHONY: clean
clean:
	rm -f xbsvutil *~
