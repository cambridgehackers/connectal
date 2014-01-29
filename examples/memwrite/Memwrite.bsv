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
import GetPutF::*;

import AxiMasterSlave::*;
import Dma::*;

interface MemwriteRequest;
   method Action startWrite(Bit#(32) handle, Bit#(32) numWords, Bit#(32) burstLen);
   method Action getStateDbg();   
endinterface

interface Memwrite;
   interface MemwriteRequest request;
   interface DmaWriteClient#(64) dmaClient;
endinterface

interface MemwriteIndication;
   method Action started(Bit#(32) numWords);
   method Action reportStateDbg(Bit#(32) streamRdCnt, Bit#(32) srcGen);
   method Action writeReq(Bit#(32) v);
   method Action writeDone(Bit#(32) v);
endinterface

module mkMemwriteRequest#(MemwriteIndication indication,
			  DmaWriteServer#(64) dma_stream_write_server) (MemwriteRequest);

   Reg#(Bit#(32)) streamWrCnt <- mkReg(0);
   Reg#(Bit#(DmaAddrSize)) streamWrOff <- mkReg(0);
   Reg#(Bit#(32))      srcGen <- mkReg(0);
   Reg#(Bit#(32))    wrHandle <- mkReg(0); 

   Reg#(Bit#(8))     burstLen <- mkReg(1);
   Reg#(Bit#(DmaAddrSize)) deltaOffset <- mkReg(1*8);

   rule resp;
      let rv <- dma_stream_write_server.writeDone.get;
   endrule
   
   rule produce;
      dma_stream_write_server.writeData.put(DmaData{data:{srcGen+1,srcGen}, tag: 0});
      srcGen <= srcGen+2;
   endrule
   
   rule writeReq(streamWrCnt > 0);
      streamWrCnt <= streamWrCnt-1;
      dma_stream_write_server.writeReq.put(DmaRequest {handle: wrHandle, address: streamWrOff, burstLen: burstLen, tag: 0});
      streamWrOff <= streamWrOff + deltaOffset;
      indication.writeReq(streamWrCnt);
      if (streamWrCnt == 1)
	 indication.writeDone(srcGen);
   endrule

   method Action startWrite(Bit#(32) handle, Bit#(32) numWords, Bit#(32) blen) if (streamWrCnt == 0);
      streamWrCnt <= numWords;
      burstLen <= truncate(blen);
      deltaOffset <= truncate(blen) * 8;
      indication.started(numWords);
      wrHandle <= handle;
   endmethod
   
   method Action getStateDbg();
      indication.reportStateDbg(streamWrCnt, srcGen);
   endmethod
endmodule

module  mkMemwrite#(MemwriteIndication indication) (Memwrite);

   Reg#(Bit#(32)) streamWrCnt <- mkReg(0);
   Reg#(Bit#(DmaAddrSize)) streamWrOff <- mkReg(0);
   Reg#(Bit#(32))      srcGen <- mkReg(0);
   Reg#(Bit#(32))    wrHandle <- mkReg(0); 

   Reg#(Bit#(8))     burstLen <- mkReg(1);
   Reg#(Bit#(DmaAddrSize)) deltaOffset <- mkReg(1*8);
   
   FIFOF#(Bit#(6))   dataTags <- mkFIFOF();
   FIFOF#(Bit#(6))   doneTags <- mkFIFOF();
   Reg#(Bit#(8))   burstCount <- mkReg(0);

   interface DmaWriteClient dmaClient;
      interface GetF writeReq;
	 method ActionValue#(DmaRequest) get() if (streamWrCnt > 0);
	    streamWrCnt <= streamWrCnt-1;
	    streamWrOff <= streamWrOff + deltaOffset;
	    indication.writeReq(streamWrCnt);
	    if (streamWrCnt == 1)
	       indication.writeDone(srcGen);
	    $display("burstlen=%d", burstLen);
	    Bit#(6) tag = truncate(streamWrOff >> 5);
	    dataTags.enq(tag);
	    doneTags.enq(tag);
	    return DmaRequest {handle: wrHandle, address: streamWrOff, burstLen: burstLen, tag: tag};
	 endmethod
	 method Bool notEmpty;
	    return streamWrCnt > 0;
	 endmethod
      endinterface : writeReq
      interface GetF writeData;
	 method ActionValue#(DmaData#(64)) get();
	    let bc = burstCount;
	    if (bc == 0)
	       bc = burstLen;

	    let tag = dataTags.first();
	    if (bc == 1)
	       dataTags.deq();
	    burstCount <= bc - 1;

	    srcGen <= srcGen+2;
	    let dmadata = {srcGen+1,srcGen};
	    $display("Memwrite dmadata=%h", dmadata);
	    return DmaData{data:dmadata, tag: tag};
	 endmethod
	 method Bool notEmpty;
	    return dataTags.notEmpty();
	 endmethod
      endinterface : writeData
      interface PutF writeDone;
	 method Action put(Bit#(6) tag);
	    if (tag != doneTags.first)
	       $display("doneTag mismatch tag=%h doneTag=%h", tag, doneTags.first);
	    doneTags.deq();
	 endmethod
	 method Bool notFull = doneTags.notFull;
      endinterface : writeDone
   endinterface : dmaClient

   interface MemwriteRequest request;
       method Action startWrite(Bit#(32) handle, Bit#(32) numWords, Bit#(32) blen) if (streamWrCnt == 0);
	  streamWrCnt <= numWords;
	  burstLen <= truncate(blen);
	  deltaOffset <= truncate(blen) * 8;
	  indication.started(numWords);
	  wrHandle <= handle;
       endmethod

       method Action getStateDbg();
	  indication.reportStateDbg(streamWrCnt, srcGen);
       endmethod
   endinterface
endmodule