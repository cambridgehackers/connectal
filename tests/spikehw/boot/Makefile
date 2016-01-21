
all: bootrom.bin bootrom.hex bootromx4.hex

clean:
	rm -f *.o *.elf *.bin *.hex

entry.o: entry.S
	riscv64-unknown-elf-gcc -O -c entry.S
	riscv64-unknown-elf-objdump -d -S entry.o > entry.dump

copybbl.o: copybbl.c
	riscv64-unknown-elf-gcc -O -c copybbl.c

copybbl.elf: entry.o copybbl.o bbl.o vmlinux.o Makefile
	riscv64-unknown-elf-ld -o copybbl.elf -Ttext 0x0000000 -Tdata 400 --entry=0000000 entry.o copybbl.o bbl.o
	riscv64-unknown-elf-objdump -D copybbl.elf | head -1000 > copybbl.dump

bootrom.hex: copybbl.elf
	rm -f copybbl.hex
	#elf2hex 8 1048576 copybbl.elf > bootrom.hex
	elf2hex 8 524288 copybbl.elf > bootrom.hex
	#elf2hex 8 16384 copybbl.elf > bootrom.hex

bootromx4.hex: copybbl.elf
	rm -f copybbl.hex
	#elf2hex 8 1048576 copybbl.elf > bootrom.hex
	elf2hex 4 16384 copybbl.elf > bootromx4.hex
	#elf2hex 8 16384 copybbl.elf > bootrom.hex

bootrom.bin: copybbl.elf
	riscv64-unknown-elf-objcopy -O binary copybbl.elf bootrom.bin
	hexdump -C bootrom.bin > bootrom.txt

bbl.o: bbl.elf Makefile
	riscv64-unknown-elf-objcopy -O binary bbl.elf bbl.bin
	riscv64-unknown-elf-objcopy -I binary -O elf64-littleriscv -B riscv bbl.bin bbl.o
	riscv64-unknown-elf-objdump -D bbl.elf > bbl.dump
	riscv64-unknown-elf-objdump -b binary -m riscv -D bbl.bin > bbl2.dump
	hexdump -C bbl.elf > bbl.txt
	hexdump -C bbl.bin > bbl2.txt

LINUX_DIR = ../../../../linux

vmlinux.o: $(LINUX_DIR)/vmlinux Makefile
	cp -f $(LINUX_DIR)/vmlinux vmlinux.elf
	riscv64-unknown-elf-objcopy -I binary -O elf64-littleriscv -B riscv vmlinux.elf vmlinux.o


BBL_FILE = ../../../../riscv-pk/build/bbl

bbl.elf: $(BBL_FILE)
	cp -fv $(BBL_FILE) bbl.elf

bbl.hex: $(BBL_FILE)
	elf2hex 8 8192 $(BBL_FILE) > bbl.hex

dump: copybbl.elf
	riscv64-unknown-elf-objdump -D copybbl.elf
