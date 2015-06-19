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
import ClientServer::*;
import BRAM::*;
import Vector::*;

import MemTypes::*;
import Pipe::*;

interface MemReaderPipe#(numeric type dsz);
   interface PipeOut#(MemData#(dsz)) dataPipe;
   interface MemReadClient#(dsz) readClient;
endinterface

module mkMemReaderPipe#(Reg#(SGLId) ptrReg,
			IteratorIfc#(Bit#(addrsz)) addrIterator,
			Bit#(BurstLenSize) burstLen)(MemReaderPipe#(dsz))
   provisos (Add#(a__, addrsz, MemOffsetSize));

   let verbose = False;

   FIFO#(MemRequest) readReqFifo <- mkFIFO();
   FIFOF#(MemData#(dsz)) readDataFifo <- mkSizedFIFOF(8);
   Reg#(Bit#(MemTagSize)) tagReg <- mkReg(0);

   rule startReadReqRule;
      let offset <- toGet(addrIterator.pipe).get();
      let tag = tagReg;
      if (addrIterator.isFirst())
	 tag = 0;
      if (verbose) $display("startReadReqRule: offset=%d", offset);
      readReqFifo.enq(MemRequest { sglId: ptrReg, offset: extend(offset), burstLen: burstLen, tag: extend(tag) });

      tagReg <= tag + 1;
   endrule

   interface dataPipe = toPipeOut(readDataFifo);
   interface MemReadClient readClient;
      interface Get readReq = toGet(readReqFifo);
      interface Put readData = toPut(readDataFifo);
   endinterface
endmodule

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

   FIFO#(MemRequest)              writeReqFifo <- mkSizedFIFO(4);
   FIFOF#(MemData#(dsz)) writeDataFifo <- mkSizedFIFOF(4);
   FIFO#(Bit#(MemTagSize))       writeDoneFifo <- mkSizedFIFO(32);
   FIFOF#(Bool)                       lastFifo <- mkSizedFIFOF(4);
   FIFOF#(Bool)                       doneFifo <- mkSizedFIFOF(4);

   Reg#(Bit#(32)) wrrCount <- mkReg(0);
   Reg#(Bit#(32)) wdoneCount <- mkReg(0);
   rule writeReqRule;
      let offset <- toGet(addrIterator.pipe).get();
      let tag = 22;
      wrrCount <= wrrCount + 1;
      $display("writeReqRule: offset=%h burstLen=%d addrIterator.isLast %d wrr %d", offset, burstLen, addrIterator.isLast(), wrrCount);
      writeReqFifo.enq(MemRequest { sglId: ptrReg, offset: extend(offset), burstLen: burstLen, tag: tag });
      lastFifo.enq(addrIterator.isLast());
   endrule
   rule writeDataRule;
      let tag = 22;
      let v <- toGet(dataPipe).get();
      //$display("MemWriterPipe.writeDataRule: data=%h", v);
      writeDataFifo.enq(MemData { data: pack(v), tag: tag, last: False });
   endrule
   rule writeDone;
      let last <- toGet(lastFifo).get();
      //$display("writeDone: wdoneCount=%d last=%d", wdoneCount, last);
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


module mkBramReaderPipe#(BRAMServer#(Bit#(addrsz), dataType) bramServer,
			 PipeOut#(IteratorValue#(Bit#(addrsz),void)) addrIterator)(PipeOut#(IteratorValue#(dataType,void)))
   provisos (Add#(a__, addrsz, MemOffsetSize),
	     Bits#(dataType,dsz));

   FIFOF#(Tuple2#(Bool,Bool)) firstlastFifo <- mkFIFOF();
   FIFOF#(IteratorValue#(dataType,void)) readDataFifo <- mkFIFOF();

   let verbose = False;

   rule issueBramReadRequest;
      let item <- toGet(addrIterator).get();
      bramServer.request.put(BRAMRequest{write: False, responseOnWrite: False, address: item.value, datain: unpack(0)});
      firstlastFifo.enq(tuple2(item.first, item.last));
      if (verbose) $display("issueBramReadRequest addr=%h first=%d last=%d", item.value, item.first, item.last);
   endrule

   rule readData;
      let v <- bramServer.response.get();
      match { .first, .last } <- toGet(firstlastFifo).get();
      readDataFifo.enq(IteratorValue { value: v, first: first, last: last });
   endrule
   return toPipeOut(readDataFifo);
endmodule

interface BramWriterPipe#(numeric type dsz);
   interface PipeOut#(Bool) lastPipe;
endinterface

module mkBramWriterPipe#(BRAMServer#(Bit#(addrsz), dtype) bramServer,
			IteratorIfc#(Bit#(addrsz)) addrIterator,
			PipeOut#(dtype) dataPipe)(BramWriterPipe#(dsz))
   provisos (Bits#(dtype, dsz),
	     Add#(a__, addrsz, MemOffsetSize));

   FIFOF#(Bool)                       lastFifo <- mkFIFOF();
   FIFOF#(Bool)                       doneFifo <- mkFIFOF();

   Reg#(Bit#(32)) wrrCount <- mkReg(0);
   Reg#(Bit#(32)) wdoneCount <- mkReg(0);
   rule writeReqRule;
      let offset <- toGet(addrIterator.pipe).get();
      let v <- toGet(dataPipe).get();
      wrrCount <= wrrCount + 1;
      //$display("BramWriter.writeReqRule: offset=%h addrIterator.isLast %d wrr %d", offset, addrIterator.isLast(), wrrCount);
      bramServer.request.put(BRAMRequest { write: True, responseOnWrite: False, address: offset, datain: v });
      lastFifo.enq(addrIterator.isLast());
   endrule
   rule writeDone;
      let last <- toGet(lastFifo).get();
      //$display("writeDone: wdoneCount=%d last=%d", wdoneCount, last);
      wdoneCount <= wdoneCount + 1;
      doneFifo.enq(last);
   endrule
   interface PipeOut lastPipe = toPipeOut(doneFifo);
endmodule
