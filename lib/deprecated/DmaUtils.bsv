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


import BRAM::*;
import FIFO::*;
import Vector::*;
import Gearbox::*;
import FIFOF::*;
import SpecialFIFOs::*;

import ConfigCounter::*;
import BRAMFIFOFLevel::*;
import GetPut::*;
import ConnectalMemTypes::*;

function MemReadClient#(dataWidth) orc(DmaReadBuffer#(dataWidth,bufferDepth) rb) = rb.dmaClient;
function MemWriteClient#(dataWidth) owc(DmaWriteBuffer#(dataWidth,bufferDepth) wb) = wb.dmaClient;
function MemReadServer#(dataWidth) ors(DmaReadBuffer#(dataWidth,bufferDepth) rb) = rb.dmaServer;
function MemWriteServer#(dataWidth) ows(DmaWriteBuffer#(dataWidth,bufferDepth) wb) = wb.dmaServer;

//
// @brief A buffer for reading from a bus of width dataWidth.
//
// @param dataWidth The number of bits in the bus.
// @param bufferDepth The depth of the internal buffer
//
interface DmaReadBuffer#(numeric type dataWidth, numeric type bufferDepth);
   interface MemReadServer #(dataWidth) dmaServer;
   interface MemReadClient#(dataWidth) dmaClient;
endinterface

//
// @brief A buffer for writing to a bus of width dataWidth.
//
// @param dataWidth The number of bits in the bus.
// @param bufferDepth The depth of the internal buffer
//
interface DmaWriteBuffer#(numeric type dataWidth, numeric type bufferDepth);
   interface MemWriteServer#(dataWidth) dmaServer;
   interface MemWriteClient#(dataWidth) dmaClient;
endinterface



//
// @brief Makes a Dma buffer for reading wordSize words from memory.
//
// @param dataWidth The width of the bus in bits.
// @param bufferDepth The depth of the internal buffer
//
module mkDmaReadBuffer(DmaReadBuffer#(dataWidth, bufferDepth))
   provisos(Add#(b__, TAdd#(1,TLog#(bufferDepth)), BurstLenSize),
	    Div#(dataWidth,8,dataWidthBytes),
	    Mul#(dataWidthBytes,8,dataWidth),
	    Log#(dataWidthBytes,beatShift));

   FIFOFLevel#(MemData#(dataWidth),bufferDepth)  readBuffer <- mkBRAMFIFOFLevel;
   FIFOF#(MemRequest)        reqOutstanding <- mkFIFOF();
   ConfigCounter#(TAdd#(1,TLog#(bufferDepth))) unfulfilled <- mkConfigCounter(0);
   let beat_shift = fromInteger(valueOf(beatShift));
   
   // only issue the readRequest when sufficient buffering is available.  This includes the bufering we have already comitted.
   Bit#(TAdd#(1,TLog#(bufferDepth))) sreq = pack(satPlus(Sat_Bound, unpack(truncate(reqOutstanding.first.burstLen>>beat_shift)), unfulfilled.read()));

   interface MemReadServer dmaServer;
      interface Put readReq = toPut(reqOutstanding);
      interface Get readData = toGet(readBuffer);
   endinterface
   interface MemReadClient dmaClient;
      interface Get readReq;
	 method ActionValue#(MemRequest) get if (readBuffer.lowWater(sreq));
	    reqOutstanding.deq;
	    unfulfilled.increment(unpack(truncate(reqOutstanding.first.burstLen>>beat_shift)));
	    return reqOutstanding.first;
	 endmethod
      endinterface
      interface Put readData;
	 method Action put(MemData#(dataWidth) x);
	    readBuffer.fifo.enq(x);
	    unfulfilled.decrement(1);
	 endmethod
      endinterface
   endinterface
endmodule

//
// @brief Makes a Dma channel for writing wordSize words from memory.
//
// @param dataWidth The width of the bus in bits.
// @param bufferDepth The depth of the internal buffer
//
module mkDmaWriteBuffer(DmaWriteBuffer#(dataWidth, bufferDepth))
   provisos(Add#(b__, TAdd#(1, TLog#(bufferDepth)), BurstLenSize),
	    Div#(dataWidth,8,dataWidthBytes),
	    Mul#(dataWidthBytes,8,dataWidth),
	    Log#(dataWidthBytes,beatShift));

   FIFOFLevel#(MemData#(dataWidth),bufferDepth) writeBuffer <- mkBRAMFIFOFLevel;
   FIFOF#(MemRequest)        reqOutstanding <- mkFIFOF();
   FIFOF#(Bit#(6))                        doneTags <- mkFIFOF();
   ConfigCounter#(TAdd#(1,TLog#(bufferDepth)))  unfulfilled <- mkConfigCounter(0);
   let beat_shift = fromInteger(valueOf(beatShift));
   
   // only issue the writeRequest when sufficient data is available.  This includes the data we have already comitted.
   Bit#(TAdd#(1,TLog#(bufferDepth))) sreq = pack(satPlus(Sat_Bound, unpack(truncate(reqOutstanding.first.burstLen>>beat_shift)), unfulfilled.read()));

   interface MemWriteServer dmaServer;
      interface Put writeReq = toPut(reqOutstanding);
      interface Put writeData = toPut(writeBuffer);
      interface Get writeDone = toGet(doneTags);
   endinterface
   interface MemWriteClient dmaClient;
      interface Get writeReq;
	 method ActionValue#(MemRequest) get if (writeBuffer.highWater(sreq));
	    reqOutstanding.deq;
	    unfulfilled.increment(unpack(truncate(reqOutstanding.first.burstLen>>beat_shift)));
	    return reqOutstanding.first;
	 endmethod
      endinterface
      interface Get writeData;
	 method ActionValue#(MemData#(dataWidth)) get();
	    unfulfilled.decrement(1);
	    writeBuffer.fifo.deq;
	    return writeBuffer.fifo.first;
	 endmethod
      endinterface
      interface Put writeDone = toPut(doneTags);
   endinterface
endmodule
   
   
module mkDmaReadMux#(Vector#(numClients,MemReadClient#(dataWidth)) readClients)(MemReadClient#(dataWidth))
   provisos(Log#(numClients,tagsz),
	    Add#(tagsz,a__,MemTagSize));

   FIFO#(MemRequest)          readReqFifo  <- mkFIFO();
   FIFO#(MemData#(dataWidth)) readRespFifo <- mkFIFO();

   for (Integer i = 0; i < valueOf(numClients); i = i + 1) begin
      // assume fixed tag per client
      Reg#(Bit#(MemTagSize)) tagReg <- mkReg(0);
      rule getreq;
	   let req <- readClients[i].readReq.get();
	   tagReg <= req.tag;
	   req.tag = fromInteger(i);
	   readReqFifo.enq(req);
      endrule
      rule sendresp if (readRespFifo.first.tag == fromInteger(i));
	   let resp <- toGet(readRespFifo).get();
	   resp.tag = tagReg;
	   readClients[i].readData.put(resp);
      endrule
   end

   interface Get readReq = toGet(readReqFifo);
   interface Put readData = toPut(readRespFifo);
endmodule

module mkDmaWriteMux#(Vector#(numClients,MemWriteClient#(dataWidth)) writeClients)(MemWriteClient#(dataWidth))
   provisos(Log#(numClients,tagsz),
       Add#(tagsz,a__,MemTagSize));

   FIFO#(MemRequest)          writeReqFifo  <- mkFIFO();
   FIFO#(MemData#(dataWidth)) writeDataFifo <- mkFIFO();
   FIFO#(Bit#(MemTagSize))    writeDoneFifo <- mkFIFO();
   FIFO#(Bit#(MemTagSize))    arbFifo       <- mkFIFO();

   for (Integer i = 0; i < valueOf(numClients); i = i + 1) begin
      // assume fixed tag per client
      Reg#(Bit#(MemTagSize)) tagReg <- mkReg(0);
      rule getreq;
	   let req <- writeClients[i].writeReq.get();
	   tagReg <= req.tag;
	   req.tag = fromInteger(i);
	   writeReqFifo.enq(req);
	   arbFifo.enq(req.tag);
      endrule
      rule senddata if (fromInteger(i) == arbFifo.first);
	   let data <- writeClients[i].writeData.get();
	   data.tag = tagReg;
	   writeDataFifo.enq(data);
      endrule
      rule senddone if (writeDoneFifo.first == fromInteger(i));
	   arbFifo.deq();
	   let done <- toGet(writeDoneFifo).get();
	   writeClients[i].writeDone.put(tagReg);
      endrule
   end

   interface Get writeReq = toGet(writeReqFifo);
   interface Get writeData = toGet(writeDataFifo);
   interface Put writeDone = toPut(writeDoneFifo);
endmodule
