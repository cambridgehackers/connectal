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
import AxiMasterSlave :: *;
import Clocks         :: *;

interface CsrIf;
    method Bit#(32) rd(UInt#(30) addr);
    method Action wr(UInt#(30) addr, Bit#(4) be, Bit#(32) dword);
endinterface

module mkAxiSlave#(CsrIf csr)(Axi3Slave#(32,32,12));
   FIFOF#(Axi3ReadRequest#(32,12)) req_ar_fifo <- mkFIFOF();
   FIFOF#(Axi3ReadResponse#(32,12)) resp_read_fifo <- mkSizedFIFOF(8);
   FIFOF#(Axi3WriteRequest#(32,12)) req_aw_fifo <- mkFIFOF();
   FIFOF#(Axi3WriteData#(32,12)) resp_write_fifo <- mkSizedFIFOF(8);
   FIFOF#(Axi3WriteResponse#(12)) resp_b_fifo <- mkFIFOF();

   Reg#(Bit#(5)) readBurstCount <- mkReg(0);
   Reg#(Bit#(30)) readAddr <- mkReg(0);
   rule do_read if (req_ar_fifo.notEmpty());
      Bit#(5) bc = readBurstCount;
      Bit#(30) addr = readAddr;
      let req = req_ar_fifo.first();
      if (bc == 0) begin
	 bc = extend(req.len)+1;
	 addr = truncate(req.address);
      end

      let v = csr.rd(unpack(addr >> 2));
      $display("AxiCsr do_read addr=%h len=%d v=%h", addr, bc, v);
      resp_read_fifo.enq(Axi3ReadResponse { data: v, resp: 0, last: pack(bc == 1), id: req.id });

      addr = addr + 4;
      bc = bc - 1;

      readBurstCount <= bc;
      readAddr <= addr;
      if (bc == 0)
	 req_ar_fifo.deq();
   endrule

   Reg#(Bit#(5)) writeBurstCount <- mkReg(0);
   Reg#(Bit#(30)) writeAddr <- mkReg(0);
   rule do_write if (req_aw_fifo.notEmpty());
      Bit#(5) bc = writeBurstCount;
      Bit#(30) addr = writeAddr;
      let req = req_aw_fifo.first();
      if (bc == 0) begin
	 bc = extend(req.len)+1;
	 addr = truncate(req.address);
      end

      let resp_write = resp_write_fifo.first();
      resp_write_fifo.deq();

      csr.wr(unpack(addr >> 2), 'hf, resp_write.data);

      addr = addr + 4;
      bc = bc - 1;

      writeBurstCount <= bc;
      writeAddr <= addr;
      if (bc == 0) begin
	 req_aw_fifo.deq();
	 resp_b_fifo.enq(Axi3WriteResponse { resp: 0, id: req.id});
      end
   endrule

   interface Put req_ar;
      method Action put(Axi3ReadRequest#(32,12) req);
         req_ar_fifo.enq(req);
      endmethod
   endinterface: req_ar
   interface Get resp_read;
      method ActionValue#(Axi3ReadResponse#(32,12)) get();
         let resp = resp_read_fifo.first();
         resp_read_fifo.deq();
         return resp;
      endmethod
   endinterface: resp_read
   interface Put req_aw;
      method Action put(Axi3WriteRequest#(32,12) req);
         req_aw_fifo.enq(req);
      endmethod
   endinterface: req_aw
   interface Put resp_write;
      method Action put(Axi3WriteData#(32,12) resp);
         resp_write_fifo.enq(resp);
      endmethod
   endinterface: resp_write
   interface Get resp_b;
      method ActionValue#(Axi3WriteResponse#(12)) get();
         let b = resp_b_fifo.first();
         resp_b_fifo.deq();
         return b;
      endmethod
   endinterface: resp_b
endmodule
