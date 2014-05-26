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
import Dma            :: *;

interface MemSlaveClient;
    method Bit#(32) rd(UInt#(30) addr);
    method Action wr(UInt#(30) addr, Bit#(32) dword);
endinterface

module mkMemSlave#(MemSlaveClient client)(MemSlave#(32,32));
   FIFOF#(MemRequest#(32)) req_ar_fifo <- mkFIFOF();
   FIFOF#(MemData#(32)) resp_read_fifo <- mkSizedFIFOF(8);
   FIFOF#(MemRequest#(32)) req_aw_fifo <- mkFIFOF();
   FIFOF#(MemData#(32)) resp_write_fifo <- mkSizedFIFOF(8);
   FIFOF#(Bit#(ObjectTagSize)) resp_b_fifo <- mkFIFOF();

   Reg#(Bit#(8)) readBurstCount <- mkReg(0);
   Reg#(Bit#(30)) readAddr <- mkReg(0);
   rule do_read if (req_ar_fifo.notEmpty());
      Bit#(8) bc = readBurstCount;
      Bit#(30) addr = readAddr;
      let req = req_ar_fifo.first();
      if (bc == 0) begin
	 bc = extend(req.burstLen);
	 addr = truncate(req.addr);
      end

      let v = client.rd(unpack(addr >> 2));
      $display("MemSlave do_read addr=%h len=%d v=%h", addr, bc, v);
      resp_read_fifo.enq(MemData { data: v, tag: req.tag });

      addr = addr + 4;
      bc = bc - 1;

      readBurstCount <= bc;
      readAddr <= addr;
      if (bc == 0)
	 req_ar_fifo.deq();
   endrule

   Reg#(Bit#(8)) writeBurstCount <- mkReg(0);
   Reg#(Bit#(30)) writeAddr <- mkReg(0);
   rule do_write if (req_aw_fifo.notEmpty());
      Bit#(8) bc = writeBurstCount;
      Bit#(30) addr = writeAddr;
      let req = req_aw_fifo.first();
      if (bc == 0) begin
	 bc = extend(req.burstLen);
	 addr = truncate(req.addr);
      end

      let resp_write = resp_write_fifo.first();
      resp_write_fifo.deq();

      client.wr(unpack(addr >> 2), resp_write.data);

      addr = addr + 4;
      bc = bc - 1;

      writeBurstCount <= bc;
      writeAddr <= addr;
      if (bc == 0) begin
	 req_aw_fifo.deq();
	 resp_b_fifo.enq(req.tag);
      end
   endrule

   interface MemReadServer read_server;
      interface Put readReq;
         method Action put(MemRequest#(32) req);
            req_ar_fifo.enq(req);
         endmethod
      endinterface
      interface Get     readData;
         method ActionValue#(MemData#(32)) get();
            let resp = resp_read_fifo.first();
            resp_read_fifo.deq();
            return resp;
         endmethod
      endinterface
   endinterface
   interface MemWriteServer write_server; 
      interface Put writeReq;
         method Action put(MemRequest#(32) req);
            req_aw_fifo.enq(req);
         endmethod
      endinterface
      interface Put writeData;
         method Action put(MemData#(32) resp);
            resp_write_fifo.enq(resp);
         endmethod
      endinterface
      interface Get writeDone;
         method ActionValue#(Bit#(ObjectTagSize)) get();
            let b = resp_b_fifo.first();
            resp_b_fifo.deq();
            return b;
         endmethod
      endinterface
   endinterface
endmodule
