// Copyright (c) 2015 Connectal Project.

// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use, copy,
// modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
// BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
// ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
import Vector::*;
import Connectable::*;

interface AvalonMMasterBits#(numeric type addrWidth, numeric type dataWidth);
    method Bit#(addrWidth) address();
    method Bit#(4)     burstcount();
    method Bit#(4)     byteenable();
    method Bit#(1)     read();
    method Action      readdata(Bit#(dataWidth) v);
    method Action      readdatavalid(Bit#(1) v);
    method Action      waitrequest(Bit#(1) v);
    method Bit#(1)     write();
    method Bit#(dataWidth) writedata();
endinterface

interface AvalonMSlaveBits#(numeric type addrWidth, numeric type dataWidth);
    method Action      address(Bit#(addrWidth) v);
    method Action      burstcount(Bit#(4) v);
    method Action      byteenable(Bit#(4) v);
    method Action      read(Bit#(1) v);
    method Bit#(dataWidth) readdata();
    method Bit#(1)     readdatavalid();
    method Bit#(1)     waitrequest();
    method Action      write(Bit#(1) v);
    method Action      writedata(Bit#(dataWidth) v);
endinterface

instance Connectable#(AvalonMMasterBits#(addrWidth, dataWidth), AvalonMSlaveBits#(addrWidth, dataWidth));
   module mkConnection#(AvalonMMasterBits#(addrWidth, dataWidth) m, AvalonMSlaveBits#(addrWidth, dataWidth) s)(Empty);
      mkConnection(s.address, m.address);
      mkConnection(s.burstcount, m.burstcount);
      mkConnection(s.byteenable, m.byteenable);
      mkConnection(s.read, m.read);
      mkConnection(s.write, m.write);
      mkConnection(s.writedata, m.writedata);
      mkConnection(m.readdata, s.readdata);
      mkConnection(m.readdatavalid, s.readdatavalid);
      mkConnection(m.waitrequest, s.waitrequest);
   endmodule
endinstance
