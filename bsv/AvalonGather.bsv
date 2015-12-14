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

import FIFO::*;
import GetPut::*;
import ClientServer::*;
import AvalonBits::*;
import AvalonMasterSlave::*;

module mkAvalonMSlaveGather#(AvalonMSlaveBits#(addrWidth, dataWidth) slave) (AvalonMSlave#(addrWidth, dataWidth));
   Wire#(Bit#(addrWidth)) address <- mkDWire(0);
   Wire#(Bit#(dataWidth)) readdata <- mkDWire(0);
   Wire#(Bit#(dataWidth)) writedata <- mkDWire(0);
   Wire#(Bit#(1)) read <- mkDWire(0);
   Wire#(Bit#(1)) write <- mkDWire(0);
   Wire#(Bit#(1)) readdatavalid <- mkDWire(0);
   Wire#(Bit#(4)) burstcount <- mkDWire(0);
   Wire#(Bit#(4)) byteenable <- mkDWire(0);
   Wire#(Bit#(1)) waitrequest <- mkDWire(0);

   FIFO#(AvalonMMRequest#(addrWidth, dataWidth)) req_fifo <- mkFIFO;

   let verbose = True;

   Reg#(Bit#(32)) cycles <- mkReg(0);
   rule count if (verbose);
      cycles <= cycles + 1;
   endrule

   rule handshake0;
      let req = req_fifo.first;
      address <= req.address;
      read <= pack(!req.write);
      write <= pack(req.write);
      writedata <= req.data;
      burstcount <= req.burstcount;
      if (slave.waitrequest() == 0)
         req_fifo.deq;
   endrule

   rule handshake1;
      slave.address(address);
      slave.read(read);
      slave.write(write);
      slave.writedata(writedata);
      slave.burstcount(burstcount);
   endrule

   interface Put request = toPut(req_fifo);
   interface Get response;
      method ActionValue#(AvalonMMData#(dataWidth)) get() if (slave.readdatavalid == 1);
         AvalonMMData#(dataWidth) d;
         d.readdata = slave.readdata();
         return d;
      endmethod
   endinterface
endmodule
