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

// BSV Libraries
import FIFOF::*;
import Vector::*;
import GetPut::*;
import ClientServer::*;
import BRAMFIFO::*;
import BRAM::*;

// XBSV Libraries
import BRAMFIFOFLevel::*;
import PortalMemory::*;
		       
interface BsimDMAWriteInternal;
   interface DMAWrite write;
   method Action paref(Bit#(32) off, Bit#(32) pref);
endinterface

interface BsimDMAReadInternal;
   interface DMARead read;
   method Action paref(Bit#(32) off, Bit#(32) pref);
endinterface

interface BsimDMA;
   interface DMARequest request;
   interface DMAWrite write;
   interface DMARead  read;
endinterface

module mkBsimDMAReadInternal(BsimDMAReadInternal);
   
   Vector#(NumDmaChannels, FIFOFLevel#(Bit#(64), 16)) readBuffers  <- replicateM(mkBRAMFIFOFLevel);
   Vector#(NumDmaChannels, Reg#(Bool)) reqOutstanding <- replicateM(mkReg(False));

   method Action paref(Bit#(32) off, Bit#(32) pref);
      noAction;
   endmethod
   
   interface DMARead read;
      method Action configChan(DmaChannelId channelId, Bit#(32) pref, Bit#(4) bsz);
	 noAction;
      endmethod
      interface readChannels = zipWith(mkReadChan, map(toGet,readBuffers), map(mkPutWhenFalse, reqOutstanding));
      method ActionValue#(DmaDbgRec) dbg();
	 return ?;
      endmethod
   endinterface
   
endmodule


module mkBsimDMAWriteInternal(BsimDMAWriteInternal);

   Vector#(NumDmaChannels, FIFOFLevel#(Bit#(64), 16)) writeBuffers <- replicateM(mkBRAMFIFOFLevel);
   Vector#(NumDmaChannels, Reg#(Bool)) reqOutstanding <- replicateM(mkReg(False));
   Vector#(NumDmaChannels, Reg#(Bool)) writeRespRec   <- replicateM(mkReg(False));

   method Action paref(Bit#(32) off, Bit#(32) pref);
      noAction;
   endmethod

   interface DMAWrite write;
      method Action configChan(DmaChannelId channelId, Bit#(32) pref, Bit#(4) bsz);
	 noAction;
      endmethod
      interface writeChannels = zipWith3(mkWriteChan, map(toPut,writeBuffers), 
					 map(mkPutWhenFalse, reqOutstanding),
					 map(mkGetWhenTrue, writeRespRec));
      method ActionValue#(DmaDbgRec) dbg();
	 return ?;
      endmethod
   endinterface

endmodule

module mkBsimDMA#(DMAIndication indication)(BsimDMA);
   BsimDMAWriteInternal writer <- mkBsimDMAWriteInternal;
   BsimDMAReadInternal  reader <- mkBsimDMAReadInternal;
   interface DMARequest request;
      method Action configReadChan(Bit#(32) channelId, Bit#(32) pref, Bit#(32) numWords);
	 reader.read.configChan(pack(truncate(channelId)), pref, truncate((numWords>>1)-1));
	 indication.configResp(channelId);
      endmethod
      method Action configWriteChan(Bit#(32) channelId, Bit#(32) pref, Bit#(32) numWords);
	 writer.write.configChan(pack(truncate(channelId)), pref, truncate((numWords>>1)-1));
	 indication.configResp(channelId);
      endmethod
      method Action getReadStateDbg();
	 let rv <- reader.read.dbg;
	 indication.reportStateDbg(rv);
      endmethod
      method Action getWriteStateDbg();
	 let rv <- writer.write.dbg;
	 indication.reportStateDbg(rv);
      endmethod
      method Action paref(Bit#(32) off, Bit#(32) pref);
	 writer.paref(off, pref);
	 reader.paref(off, pref);
	 indication.parefResp(off);
      endmethod
   endinterface
   interface BsimDMAWrite write = writer.write;
   interface BsimDMARead  read  = reader.read;
endmodule
