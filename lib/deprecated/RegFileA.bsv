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
import ConnectalMemTypes::*;


interface RegFileA#(type index_t, type data_t);
   method Action upd(index_t addr, data_t d);
   method ActionValue#(data_t) sub(index_t addr);
endinterface

typedef struct {
   Bit#(addrWidth) addr;
   Bit#(8) bc;
   Bit#(6) tag;
   Bool    last;
   } AddrBeat#(numeric type addrWidth) deriving (Bits);

interface AddressGenerator#(numeric type addrWidth);
   interface Put#(PhysMemRequest#(addrWidth)) request;
   interface Get#(AddrBeat#(addrWidth)) addrBeat;
endinterface

module mkAddressGenerator(AddressGenerator#(addrWidth));
   FIFOF#(PhysMemRequest#(addrWidth)) requestFifo <- mkFIFOF();
   FIFOF#(AddrBeat#(addrWidth)) addrBeatFifo <- mkFIFOF();
   Reg#(Bit#(addrWidth)) addrReg <- mkReg(0);
   Reg#(Bit#(8)) burstCountReg <- mkReg(0);
   Reg#(Bool) isLastReg <- mkReg(False);

   rule addrBeatRule;
      let req = requestFifo.first();
      let addr = addrReg;
      let burstCount = burstCountReg;
      let isLast = isLastReg;

      let nextIsLast = burstCount == 2;
      let nextBurstCount = burstCount - 1;

      addrReg <= addr + 1;
      burstCountReg <= nextBurstCount;
      isLastReg <= nextIsLast;
      if (isLast) begin
	 requestFifo.deq();
      end
      addrBeatFifo.enq(AddrBeat { addr: addr, bc: burstCount, last: isLast, tag: req.tag});
   endrule

   interface Put request;
      method Action put(PhysMemRequest#(addrWidth) req);
	 requestFifo.enq(req);
	 addrReg <= req.addr;
	 burstCountReg <= req.burstLen;
	 isLastReg <= (req.burstLen == 1);
      endmethod
   endinterface
   interface Get addrBeat;
      method ActionValue#(AddrBeat#(addrWidth)) get();
	 addrBeatFifo.deq();
	 return addrBeatFifo.first();
      endmethod
   endinterface
endmodule

module mkMemSlaveFromRegFile#(RegFileA#(Bit#(regFileAddrWidth), Bit#(busDataWidth)) rf) (MemSlave#(busAddrWidth, busDataWidth))
   provisos(Add#(a__, regFileAddrWidth, busAddrWidth));

   Reg#(Bit#(regFileAddrWidth)) writeAddrReg <- mkReg(0);
   Reg#(Bit#(8)) writeBurstCountReg <- mkReg(0);
   FIFOF#(void) writeRespFifo <- mkFIFOF();
   FIFOF#(Bit#(6)) writeTagFifo <- mkFIFOF();
   FIFO#(PhysMemRequest#(busAddrWidth)) req_aw_fifo <- mkSizedFIFO(1);
   
   AddressGenerator#(busAddrWidth) readAddrGenerator <- mkAddressGenerator();

   Bool verbose = False;
   interface MemReadServer read_server;
      interface Put readReq;
	 method Action put(PhysMemRequest#(busAddrWidth) req);
            if (verbose) $display("axiSlave.read.readAddr %h bc %d", req.addr, req.burstLen);
	    readAddrGenerator.request.put(req);
	 endmethod
      endinterface
      interface Get readData;
	 method ActionValue#(MemData#(busDataWidth)) get();
	    let addrBeat <- readAddrGenerator.addrBeat.get();
   	    let addr = addrBeat.addr;
   	    let tag = addrBeat.tag;
   	    let burstCount = addrBeat.bc;
            Bit#(regFileAddrWidth) regFileAddr = truncate(addr/fromInteger(valueOf(TDiv#(busDataWidth,8))));
            let data <- rf.sub(regFileAddr);
            if (verbose) $display("read_server.readData %h %h %d", addr, data, burstCount);
            return MemData { data: data, tag: tag, last: addrBeat.last };
	 endmethod
      endinterface
   endinterface
   interface MemWriteServer write_server;
      interface Put writeReq;
	 method Action put(PhysMemRequest#(busAddrWidth) req);
            req_aw_fifo.enq(req);
            if (verbose) $display("write_server.writeAddr %h bc %d", req.addr, req.burstLen);
	 endmethod
      endinterface
      interface Put writeData;
	 method Action put(MemData#(busDataWidth) resp);
	    let addr = writeAddrReg;
            let burstCount = writeBurstCountReg;
            if (burstCount == 0) begin
	       let req = req_aw_fifo.first;
               addr = truncate(req.addr/fromInteger(valueOf(TDiv#(busDataWidth,8))));
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

