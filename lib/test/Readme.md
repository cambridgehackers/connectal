SerialFIFO

A serial FIFO is like a regular FIFOF except that "in the middle"
of the FIFO, communications are serial.

tbSerialFIFO.bsv is a standalone test bench.

test with

    bsc  -p +:../bsv -sim -u -g mkTb -e mkTb tbSerialFIFO.bsv
    bsc -sim -e mkTb mkTb.ba
