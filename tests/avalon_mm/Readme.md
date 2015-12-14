### Tests for Avalon memory-mapped protocol 

Avalon memory-mapped interface is used by Altera device for access memories, such as DDR3 controller.

This test is related to the following files in connectal/bsv directory, modelled after Axi protocol:
* AvalonBit.bsv : Raw Avalon-MM interface bits
* AvalonGather.bsv : Converting raw bits to Get/Put interface.
* AvalonMasterSlave.bsv : Definition for AvalonMMaster and AvalonMSlave interface
* AvalonSplitter.bsv : Avalon has a shared bus for both read and write operation, this module is an arbiter to enable sharing, modelled after Pcie arbiter.
* AvalonDma.bsv : Converting PhysMemRequest to AvalonMMRequest

AvalonMM messages are verified using Altera's BFM verification IP, hence this test will only run in modelsim. You can run tests with the following commands.
```
make build.vsim
make run.vsim
```

Project structure:
* avlm_avls_1x1.qsys : Qsys project to instantiate a single Avalon-MM slave, taken from avalon verification ip simulation example.
* AvalonBfmWrapper.bsv : Bluespec wrapper for generated avlm_avls_1x1.v
* verilog/test_program.sv : Test case written in system verilog to handle AvalonMM requests in BFM model. Currently only handle slave.
* TestProgram.bsv : Bluespec wrapper for test_program.sv
* Echo.bsv, testecho.cpp : Top-level connectal project files.
