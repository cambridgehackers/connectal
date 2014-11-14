CC ?= gcc

ifeq ("$(DESTDIR)","")
PREFIX=/usr/local
else
PREFIX=/usr
endif

all: connectalutil

connectalutil: connectalutil.c ../../drivers/pcieportal/pcieportal.h
	$(CC) -g -O2 -o connectalutil connectalutil.c

.PHONY: install
install: connectalutil
	install -d -m755 $(DESTDIR)$(PREFIX)/bin
	install -m 755 connectalutil $(DESTDIR)$(PREFIX)/bin

.PHONY: clean
clean:
	rm -f connectalutil *~
