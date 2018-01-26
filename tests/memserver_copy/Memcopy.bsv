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

import Vector::*;
import BuildVector::*;
import FIFO::*;
import FIFOF::*;
import BRAMFIFO::*;
import ClientServer::*;
import GetPut::*;
import ConnectalConfig::*;
import ConnectalMemTypes::*;
import Pipe::*;
import ConfigCounter::*;

typedef TDiv#(DataBusWidth,32) WordsPerBeat;

interface MemcopyRequest;
   method Action startCopy(Bit#(32) readPointer, Bit#(32) writePointer, Bit#(32) numWords, Bit#(32) numReqs, Bit#(32) burstLen);
endinterface

interface MemcopyIndication;
   method Action copyDone(Bit#(32) v);
   method Action copyProgress(Bit#(32) v);
endinterface

interface Memcopy;
   interface MemcopyRequest request;
   interface Vector#(1, MemReadClient#(DataBusWidth)) readClients;
   interface Vector#(1, MemWriteClient#(DataBusWidth)) writeClients;
endinterface

module  mkMemcopy#(MemcopyIndication indication) (Memcopy);
   Reg#(SGLId)   readPointer <- mkReg(0);
   Reg#(SGLId)   writePointer <- mkReg(0);
   Reg#(Bit#(32))        numReqs <- mkReg(0);
   Reg#(Bit#(32))        numDone <- mkReg(0);
   Reg#(Bit#(MemOffsetSize)) reqOffset <- mkReg(0);
   Reg#(Bit#(3))                   tag <- mkReg(0);
   Reg#(Bit#(32))             numWords <- mkReg(0);
   Reg#(Bit#(BurstLenSize)) burstLenBytes <- mkReg(0);
   Reg#(Bit#(32))              srcGens <- mkReg(0);

   ConfigCounter#(16) counter          <- mkConfigCounter(0);
   FIFO#(MemRequest) readReqFifo <- mkFIFO();
   FIFO#(MemRequest) writeReqFifo <- mkFIFO();
   FIFO#(MemData#(DataBusWidth))   dataFifo <- mkSizedBRAMFIFO(1024);
   FIFO#(Bit#(MemTagSize)) doneFifo <- mkFIFO();

   let verboseProgress = False;

   rule startReqRule if (numReqs != 0 && counter.read() <= unpack(extend(burstLenBytes) << 3));
      counter.increment(unpack(extend(burstLenBytes)));
      readReqFifo.enq(MemRequest { sglId: readPointer, offset: reqOffset, burstLen: burstLenBytes, tag: extend(tag) });
      writeReqFifo.enq(MemRequest { sglId: writePointer, offset: reqOffset, burstLen: burstLenBytes, tag: extend(tag) });

      numReqs <= numReqs - 1;
      reqOffset <= reqOffset + extend(burstLenBytes);
      tag <= tag + 1;
      $display("start numReqs %d offset %d", numReqs, reqOffset);
   endrule

   rule finish;
      let donetag <- toGet(doneFifo).get();
      $display("finished num todo=%d", numDone);
      if (numDone == 1) begin
         indication.copyDone(0);
      end
      numDone <= numDone - 1;
      if (verboseProgress)
	 indication.copyProgress(extend(donetag));
   endrule

   MemReadClient#(DataBusWidth) readClient = (interface MemReadClient;
      interface Get readReq = toGet(readReqFifo);
      interface Put readData;
	 method Action put(MemData#(DataBusWidth) md);
	    dataFifo.enq(md);
	    counter.decrement(fromInteger(valueOf(TDiv#(DataBusWidth,8))));
	 endmethod
      endinterface
   endinterface );
   MemWriteClient#(DataBusWidth) writeClient = (interface MemWriteClient;
      interface Get writeReq = toGet(writeReqFifo);
      interface Get writeData = toGet(dataFifo);
      interface Put writeDone = toPut(doneFifo);
   endinterface );

   interface MemcopyRequest request;
       method Action startCopy(Bit#(32) rp, Bit#(32) wp, Bit#(32) nw, Bit#(32) nreq, Bit#(32) bl);
	  //$dumpvars();
          $display("startCopy readPointer=%d writePointer=%d numWords=%d (%d) numReqs=%d burstLen=%d", rp, wp, nw, nreq*bl, nreq, bl);
          readPointer <= rp;
          writePointer <= wp;
          numWords  <= nw;
          burstLenBytes <= truncate(bl);
	  numReqs <= nreq;
	  numDone <= nreq;
       endmethod
   endinterface
   interface readClients = vec(readClient);
   interface writeClients = vec(writeClient);

endmodule
