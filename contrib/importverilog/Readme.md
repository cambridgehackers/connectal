This example shows how to integrate a verilog module
with Bluespec code.

In the Makefile there is a target to build RefFile.bsv automatically
from regfile.v.  This creates a Bluespec wrapper for the verilog,
allowing Bluespec code to send signals into the verilog and to get
results back into Bluespec.
