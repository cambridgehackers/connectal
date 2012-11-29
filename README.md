
The script genctypes.py will generate a C++ wrapper to interact with a
BSV interface. 

To run the generator:
    genctypes.py test/dut.bsv test/dut

This produces test/dut.h and dut.cpp, which you can compile and link into
your program.

The only transport between userspace and hardware is in ushw.h,
ushw.cpp, which uses an ioctl to put a request and get a response.



