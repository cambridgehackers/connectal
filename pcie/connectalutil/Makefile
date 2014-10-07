CC ?= gcc

connectalutil: connectalutil.c ../../drivers/pcieportal/pcieportal.h
	$(CC) -g -O2 -o connectalutil connectalutil.c

.PHONY: install
install: connectalutil
	install -m 755 connectalutil /usr/local/bin

.PHONY: clean
clean:
	rm -f connectalutil *~
