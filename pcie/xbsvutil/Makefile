CC ?= gcc

xbsvutil: xbsvutil.c ../../drivers/pcieportal/bluenoc.h
	$(CC) -g -O2 -o xbsvutil xbsvutil.c

.PHONY: install
install: xbsvutil
	install -m 755 xbsvutil /usr/local/bin

.PHONY: clean
clean:
	rm -f xbsvutil *~
