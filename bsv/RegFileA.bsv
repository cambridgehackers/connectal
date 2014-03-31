// Copyright (c) 2013 Quanta Research Cambridge, Inc.

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

import FIFOF::*;
import FIFO::*;
import GetPut::*;
import Connectable::*;
import RegFile::*;
import Dma::*;


interface RegFileA#(type index_t, type data_t);
   method Action upd(index_t addr, data_t d);
   method ActionValue#(data_t) sub(index_t addr);
endinterface

module mkRegFileANull#(data_t defv) (RegFileA#(index_t,data_t));
   method Action upd(index_t addr, data_t d);
      noAction;
   endmethod
   method ActionValue#(data_t) sub(index_t addr);
      return defv;
   endmethod
endmodule

module mkMemSlaveOutOfRange (MemSlave#(addrWidth, busWidth));
   RegFileA#(Bit#(addrWidth), Bit#(busWidth)) rf <- mkRegFileANull(0);
   let rv <- mkMemSlaveFromRegFile(rf);
   return rv;
endmodule

module mkMemSlaveFromRegFile#(RegFileA#(Bit#(regFileBusWidth), Bit#(busWidth)) rf) (MemSlave#(addrWidth, busWidth))
   provisos(Add#(nz, regFileBusWidth, addrWidth));

   Reg#(Bit#(regFileBusWidth)) readAddrReg <- mkReg(0);
   Reg#(Bit#(regFileBusWidth)) writeAddrReg <- mkReg(0);
   Reg#(Bit#(6)) readTagReg <- mkReg(0);
   Reg#(Bit#(8)) readBurstCountReg <- mkReg(0);
   Reg#(Bit#(8)) writeBurstCountReg <- mkReg(0);
   FIFOF#(void) writeRespFifo <- mkFIFOF();
   FIFOF#(Bit#(6)) writeTagFifo <- mkFIFOF();
   FIFOF#(MemRequest#(addrWidth)) req_ar_fifo <- mkSizedFIFOF(1);
   FIFO#(MemRequest#(addrWidth)) req_aw_fifo <- mkSizedFIFO(1);
   
   Bool verbose = False;
   interface MemReadServer read_server;
      interface Put readReq;
	 method Action put(MemRequest#(addrWidth) req);
            if (verbose) $display("axiSlave.read.readAddr %h bc %d", req.paddr, req.burstLen);
   	    req_ar_fifo.enq(req);
	 endmethod
      endinterface
      interface Get readData;
	 method ActionValue#(ObjectData#(busWidth)) get();
   	    let addr = readAddrReg;
   	    let id = readTagReg;
   	    let burstCount = readBurstCountReg;
   	    if (readBurstCountReg == 0) begin
	       let req = req_ar_fifo.first;
               addr = truncate(req.paddr/fromInteger(valueOf(TDiv#(busWidth,8))));
   	       id = req.tag;
               burstCount = req.burstLen;
   	       req_ar_fifo.deq;
   	    end
            let data <- rf.sub(addr);
            if (verbose) $display("read_server.readData %h %h %d", addr, data, burstCount);
            readBurstCountReg <= burstCount - 1;
            readAddrReg <= addr + 1;
   	    readTagReg <= id;
            return ObjectData { data: data, tag: id };
	 endmethod
      endinterface
   endinterface
   interface MemWriteServer write_server;
      interface Put writeReq;
	 method Action put(MemRequest#(addrWidth) req);
            req_aw_fifo.enq(req);
            if (verbose) $display("write_server.writeAddr %h bc %d", req.paddr, req.burstLen);
	 endmethod
      endinterface
      interface Put writeData;
	 method Action put(ObjectData#(busWidth) resp);
	    let addr = writeAddrReg;
            let burstCount = writeBurstCountReg;
            if (burstCount == 0) begin
	       let req = req_aw_fifo.first;
               addr = truncate(req.paddr/fromInteger(valueOf(TDiv#(busWidth,8))));
               burstCount = req.burstLen;
               writeTagFifo.enq(req.tag);
	       req_aw_fifo.deq;
	    end
            if (verbose) $display("writeData %h %h %d", addr, resp.data, burstCount);
            rf.upd(addr, resp.data);
            writeAddrReg <= addr + 1;
            writeBurstCountReg <= burstCount - 1;
            if (verbose) $display("write_server.writeData %h %h %d", addr, resp.data, burstCount);
            if (burstCount == 1)
               writeRespFifo.enq(?);
	 endmethod
      endinterface
      interface Get writeDone;
	 method ActionValue#(Bit#(6)) get();
            writeRespFifo.deq;
	    writeTagFifo.deq;
            return writeTagFifo.first;
	 endmethod
      endinterface
   endinterface
endmodule

