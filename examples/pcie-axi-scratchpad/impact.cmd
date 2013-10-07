

setMode -bscan
setCable -p auto
addDevice -p 1 -file .build/kc705/fpga/mkBridge.bit
program -p 1
quit

