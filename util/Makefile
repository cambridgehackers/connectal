
all:
	gcc -o dumpbit dumpbit.c
	gcc -o pciescanportal pciescanportal.c

install: all
	sudo cp pciescanportal ../scripts/pciescan.sh /usr/local/bin/
	sudo chown root:root /usr/local/bin/pciescanportal
	sudo chmod 7555 /usr/local/bin/pciescanportal
