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
import FIFOF::*;
import GetPut::*;

import MemTypes::*;
import Pipe::*;

interface MemWriterPipe#(numeric type dsz);
   interface PipeOut#(Bool) lastPipe;
   interface MemWriteClient#(dsz) writeClient;
endinterface

module mkMemWriterPipe#(Reg#(SGLId) ptrReg,
			IteratorIfc#(Bit#(addrsz)) addrIterator,
			PipeOut#(dtype) dataPipe,
			Bit#(BurstLenSize) burstLen)(MemWriterPipe#(dsz))
   provisos (Bits#(dtype, dsz),
	     Add#(a__, addrsz, MemOffsetSize));

   FIFO#(MemRequest)              writeReqFifo <- mkFIFO();
   FIFOF#(MemData#(dsz)) writeDataFifo <- mkSizedFIFOF(8);
   FIFO#(Bit#(MemTagSize))       writeDoneFifo <- mkFIFO();
   FIFOF#(Bool)                       lastFifo <- mkFIFOF();
   FIFOF#(Bool)                       doneFifo <- mkFIFOF();

   Reg#(Bit#(32)) wrrCount <- mkReg(0);
   Reg#(Bit#(32)) wdoneCount <- mkReg(0);
   rule writeReqRule;
      let offset <- toGet(addrIterator.pipe).get();
      let tag = 22;
      wrrCount <= wrrCount + 1;
      $display("writeReqRule: offset=%h addrIterator.isLast %d wrr %d", offset, addrIterator.isLast(), wrrCount);
      writeReqFifo.enq(MemRequest { sglId: ptrReg, offset: extend(offset), burstLen: burstLen, tag: tag });
      lastFifo.enq(addrIterator.isLast());
   endrule
   rule writeDataRule;
      let tag = 22;
      let v <- toGet(dataPipe).get();
      $display("writeDataRule: data=%h", v);
      writeDataFifo.enq(MemData { data: pack(v), tag: tag });
   endrule
   rule writeDone;
      let last <- toGet(lastFifo).get();
      $display("writeDone: wdoneCount=%d last=%d", wdoneCount, last);
      wdoneCount <= wdoneCount + 1;
      let tag <- toGet(writeDoneFifo).get();
      doneFifo.enq(last);
   endrule
   interface PipeOut lastPipe = toPipeOut(doneFifo);
   interface MemWriteClient writeClient;
      interface Get writeReq = toGet(writeReqFifo);
      interface Get writeData = toGet(writeDataFifo);
      interface Put writeDone = toPut(writeDoneFifo);
   endinterface
endmodule
