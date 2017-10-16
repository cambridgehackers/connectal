// Copyright (c) 2015 Quanta Research Cambridge, Inc.

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
import FIFOF::*;
import Vector::*;
import GetPut::*;
import Connectable::*;
import BRAMFIFO::*;
import ConnectalMemTypes::*;
import AddressGenerator::*;

interface MemWriteEngineTest;
   interface MemWriteServer#(64) dmaServer; // connect this to memwrite engine
   interface MemWriteClient#(64) dmaClient; // connect this to memserver
   interface Get#(Bit#(32))                   req;
   interface Get#(Bit#(MemTagSize))           done;
   interface Get#(Tuple2#(Bit#(32),Bit#(64))) mismatch;
endinterface

(* synthesize *)
module mkMemWriteEngineTest(MemWriteEngineTest);

   FIFO#(MemRequest) writeReqInFifo <- mkSizedBRAMFIFO(32);
   FIFO#(MemData#(64)) writeDataInFifo <- mkSizedBRAMFIFO(128);
   FIFO#(Bit#(MemTagSize)) writeDoneInFifo <- mkSizedBRAMFIFO(32);

   FIFO#(MemRequest) writeReqOutFifo <- mkSizedBRAMFIFO(32);
   FIFO#(MemData#(64)) writeDataOutFifo <- mkSizedBRAMFIFO(128);
   FIFO#(Bit#(MemTagSize)) writeDoneOutFifo <- mkSizedBRAMFIFO(32);

   AddressGenerator#(32,64) addrGenerator <- mkAddressGenerator();
   FIFOF#(Bit#(32)) addrFifo <- mkSizedBRAMFIFOF(32);
   FIFOF#(Tuple2#(Bit#(32),Bit#(64))) mismatchFifo <- mkSizedBRAMFIFOF(32);
   FIFOF#(Bit#(MemTagSize)) doneFifo <- mkSizedBRAMFIFOF(32);

   rule reqRule;
      let req <- toGet(writeReqInFifo).get();
      $display("req: offset=%h burstLen=%d tag=%h", req.offset, req.burstLen, req.tag);
      //writeReqOutFifo.enq(req);
      addrGenerator.request.put(PhysMemRequest{addr:truncate(req.offset), burstLen: req.burstLen, tag: req.tag });
      addrFifo.enq(truncate(req.offset));
   endrule

   rule dataRule;
      let b <- addrGenerator.addrBeat.get();
      let data <- toGet(writeDataInFifo).get();
      let traceAllData = False;
      if (traceAllData)
	 mismatchFifo.enq(tuple2(b.addr, data.data));

      //writeDataOutFifo.enq(data);
      Vector#(2, Bit#(32)) v = unpack(data.data);
      if (v[0] != (b.addr>>2) || v[1] != ((b.addr>>2)+1)) begin
	 $display("mismatch: addr=%h data=%h", b.addr, data.data);
	 if (!traceAllData && mismatchFifo.notFull())
	    mismatchFifo.enq(tuple2(b.addr, data.data));
      end
      if (b.last)
	 writeDoneOutFifo.enq(b.tag);
   endrule

   rule doneRule;
      let done <- toGet(writeDoneInFifo).get();
      $display("done: tag=%h", done);
      writeDoneOutFifo.enq(done);
      doneFifo.enq(done);
   endrule

   interface MemWriteServer dmaServer;
      interface Put writeReq = toPut(writeReqInFifo);
      interface Put writeData = toPut(writeDataInFifo);
      interface Get writeDone = toGet(writeDoneOutFifo);
   endinterface
   interface MemWriteClient dmaClient;
      interface Get writeReq = toGet(writeReqOutFifo);
      interface Get writeData = toGet(writeDataOutFifo);
      interface Put writeDone = toPut(writeDoneInFifo);
   endinterface
   interface Get req = toGet(addrFifo);
   interface Get done = toGet(doneFifo);
   interface Get mismatch = toGet(mismatchFifo);
endmodule
