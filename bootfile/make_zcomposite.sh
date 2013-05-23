#
objcopy -I binary -O elf32-little imagefiles/zImage z.tmp
objcopy -I binary -O elf32-little imagefiles/ramdisk8M.image.gz r.tmp
objcopy -I binary -O elf32-little imagefiles/devicetree.dtb d.tmp
arm-none-linux-gnueabi-gcc -c ../bootfile/clearreg.S
arm-none-linux-gnueabi-ld -Ttext-segment 0 -e 0 -o c.tmp clearreg.o
ld -b elf32-little --accept-unknown-input-arch  -z max-page-size=0x8000 -o zcomposite.elf -T ../bootfile/zynq_linux_boot.lds 
rm -f z.tmp r.tmp d.tmp c.tmp clearreg.o
