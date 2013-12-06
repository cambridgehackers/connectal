CC ?= gcc

xbsvutil: bluenoc.c ../../drivers/pcieportal/bluenoc.h
	$(CC) -g -O2 -o xbsvutil bluenoc.c

.PHONY: install
install: xbsvutil
	install -m 755 xbsvutil /usr/local/bin

.PHONY: clean
clean:
	rm -f xbsvutil *~
