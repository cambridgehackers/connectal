

setMode -bscan
setCable -p auto
addDevice -p 1 -file .build/kc705/fpga/mkLoadStoreTop.bit
program -p 1
quit

