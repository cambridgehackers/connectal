SerialFIFO

A serial FIFO is like a regular FIFOF except that "in the middle"
of the FIFO, communications are serial.

tbSerialFIFO.bsv is a standalone test bench.

test with

    bsc  -p +:../bsv -sim -u -g mkTb tbSerialFIFO.bsv
    bsc -sim -e mkTb mkTb.ba

tbDDS is a standalone test bench for DDS.bsv

    bsc  -p +:../../examples/channelselect +:../bsv -sim -u -g mkTb tbDDS.bsv
    bsc -sim -e mkTb mkTb.ba


when run, it should print all the values in the sine table.  Make sure ../../examples/channelselect/sine.bin is in the CWD when you run it.

