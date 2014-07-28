// Copyright (c) 2014 Quanta Research Cambridge, Inc.

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

import Vector         :: *;
import FIFOF          :: *;
import GetPut         :: *;
import Clocks         :: *;
import MemTypes       :: *;
import AddressGenerator:: *;

interface MemSlaveClient;
    method Bit#(32) rd(UInt#(16) addr);
    method Action wr(UInt#(16) addr, Bit#(32) dword);
endinterface

module mkMemSlave#(MemSlaveClient client)(MemSlave#(32,32));
   FIFOF#(MemData#(32)) slaveReadDataFifos <- mkSizedFIFOF(8);
   FIFOF#(MemData#(32)) slaveWriteDataFifos <- mkSizedFIFOF(8);
   FIFOF#(Bit#(ObjectTagSize)) slaveBrespFifo <- mkFIFOF();

   AddressGenerator#(16) readAddrGenerator <- mkAddressGenerator();
   AddressGenerator#(16) writeAddrGenerator <- mkAddressGenerator();

   rule do_read;
      let b <- readAddrGenerator.addrBeat.get();
      let addr = b.addr;

      let v = client.rd(unpack(truncate(addr >> 2)));
      //$display("MemSlave do_read addr=%h len=%d v=%h", addr, bc, v);
      slaveReadDataFifos.enq(MemData { data: v, tag: b.tag, last: b.last });

   endrule

   rule do_write;
      let b <- writeAddrGenerator.addrBeat.get();
      let resp_write <- toGet(slaveWriteDataFifos).get();
      let addr = b.addr;

      client.wr(unpack(truncate(addr >> 2)), resp_write.data);

      if (b.last) begin
	 slaveBrespFifo.enq(b.tag);
      end
   endrule

   interface MemWriteServer write_server; 
      interface Put writeReq;
	 method Action put(MemRequest#(32) req);
	    writeAddrGenerator.request.put(MemRequest {addr: truncate(req.addr), burstLen:req.burstLen, tag:req.tag});
	 endmethod
      endinterface
      interface Put writeData = toPut(slaveWriteDataFifos);
      interface Get writeDone = toGet(slaveBrespFifo);
   endinterface
   interface MemReadServer read_server;
      interface Put readReq;
	 method Action put(MemRequest#(32) req);
	    readAddrGenerator.request.put(MemRequest {addr: truncate(req.addr), burstLen:req.burstLen, tag:req.tag});
	 endmethod
      endinterface
      interface Get     readData = toGet(slaveReadDataFifos);
   endinterface
endmodule
