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

import FIFO::*;
import FIFOF::*;
import BRAMFIFO::*;
import ClientServer::*;
import GetPut::*;
import MemTypes::*;
import MemwriteEngine::*;
import Pipe::*;
import AddressGenerator::*;

interface MemwriteRequest;
   method Action startWrite(Bit#(32) pointer, Bit#(32) numWords, Bit#(32) numReqs, Bit#(32) burstLen);
endinterface

interface MemwriteIndication;
   method Action writeDone(Bit#(32) v);
endinterface

interface Memwrite;
   interface MemwriteRequest request;
   interface MemWriteClient#(64) dmaClient;
endinterface

module  mkMemwrite#(MemwriteIndication indication) (Memwrite);
   Reg#(SGLId)   pointer <- mkReg(0);
   Reg#(Bit#(32))        numReqs <- mkReg(0);
   Reg#(Bit#(32))        numDone <- mkReg(0);
   Reg#(Bit#(MemOffsetSize)) reqOffset <- mkReg(0);
   Reg#(Bit#(MemTagSize))          tag <- mkReg(0);
   Reg#(Bit#(32))             numWords <- mkReg(0);
   Reg#(Bit#(BurstLenSize)) burstLenBytes <- mkReg(0);
   Reg#(Bit#(32))              srcGens <- mkReg(0);

   AddressGenerator#(32, 64) addrGenerator <- mkAddressGenerator();
   FIFO#(MemRequest) reqFifo <- mkFIFO();
   FIFO#(MemData#(64))   dataFifo <- mkSizedBRAMFIFO(64);
   FIFO#(Bit#(MemTagSize)) doneFifo <- mkFIFO();

   rule start if (numReqs != 0);
      reqFifo.enq(MemRequest { sglId: pointer, offset: reqOffset, burstLen: burstLenBytes, tag: tag });
      addrGenerator.request.put(PhysMemRequest { addr: 0, burstLen: burstLenBytes, tag: tag });
      numReqs <= numReqs - 1;
      reqOffset <= reqOffset + extend(burstLenBytes);
      tag <= tag + 1;
      $display("start numReqs", numReqs);
   endrule

   rule finish;
      let rv <- toGet(doneFifo).get();
      $display("finished num todo=%d", numDone);
      if (numDone == 1) begin
         indication.writeDone(0);
      end
      numDone <= numDone - 1;
   endrule

   rule src if (numWords != 0);
      let b <- addrGenerator.addrBeat.get();
      let v = {srcGens+1,srcGens};
      dataFifo.enq(MemData { data: v, tag: b.tag});
      srcGens <= srcGens+2;
      numWords <= numWords - 2;
   endrule

   interface MemwriteRequest request;
       method Action startWrite(Bit#(32) wp, Bit#(32) nw, Bit#(32) nreq, Bit#(32) bl);
          $display("startWrite pointer=%d numWords=%d (%d) numReqs=%d burstLen=%d", pointer, nw, nreq*bl, nreq, bl);
          pointer <= wp;
          numWords  <= nw;
          burstLenBytes <= truncate(bl);
	  numReqs <= nreq;
	  numDone <= nreq;
       endmethod
   endinterface

   interface MemWriteClient dmaClient;
      interface Get writeReq = toGet(reqFifo);
      interface Get writeData = toGet(dataFifo);
      interface Put writeDone = toPut(doneFifo);
   endinterface 
endmodule

