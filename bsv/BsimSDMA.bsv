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
import PortalSMemory::*;

import "BDPI" function Action pareff(Bit#(32) pref, Bit#(32) size);
import "BDPI" function Action init_pareff();
import "BDPI" function Action write_pareff(Bit#(32) pref, Bit#(32) addr, Bit#(64) v);
import "BDPI" function ActionValue#(Bit#(64)) read_pareff(Bit#(32) pref, Bit#(32) addr);
		       
interface BsimDMAWriteInternal;
   interface DMAWrite write;
endinterface

interface BsimDMAReadInternal;
   interface DMARead read;
endinterface

interface BsimDMA;
   interface DMARequest request;
   interface DMAWrite write;
   interface DMARead  read;
endinterface

typedef enum {Idle, LoadCtxt, Data, Done} InternalState deriving(Eq,Bits);
		 
typedef struct {
   Bit#(32)  pref;
   Bit#(32)  offset;
   Bit#(4) burstLen;
   Bool cfg;
   } DmaChannelPtr deriving (Bits);
		 
module mkBsimDMAReadInternal(BsimDMAReadInternal);
   
   Vector#(NumDmaChannels, FIFOFLevel#(Bit#(64), 16)) readBuffers  <- replicateM(mkBRAMFIFOFLevel);
   Vector#(NumDmaChannels, FIFOF#(void)) reqOutstanding <- replicateM(mkSizedFIFOF(1));
   Vector#(NumDmaChannels, Reg#(DmaChannelPtr)) ctxtPtrs <- replicateM(mkReg(unpack(0)));

   Reg#(Bit#(32))         addrReg <- mkReg(0);
   Reg#(Bit#(4))         burstReg <- mkReg(0);   
   Reg#(DmaChannelId)  activeChan <- mkReg(0);
   Reg#(InternalState)   stateReg <- mkReg(Idle);
   Reg#(DmaChannelId)   selectReg <- mkReg(0);
   
   rule incSelectReg;
      selectReg <= selectReg+1;
   endrule

   rule selectChannel if (stateReg == Idle && reqOutstanding[selectReg].notEmpty);
      activeChan <= selectReg;
      stateReg <= LoadCtxt;
   endrule
   
   rule loadChannel if (stateReg == LoadCtxt);
      let ctx = ctxtPtrs[activeChan];
      let bl = ctx.burstLen;
      if(readBuffers[activeChan].lowWater(zeroExtend(bl)+1) && ctx.cfg)
	 begin
	    reqOutstanding[activeChan].deq;
	    let  ofs = ctx.offset;
	    burstReg <= bl;
	    addrReg <= ofs;
	    stateReg <= Data;
	    ctxtPtrs[activeChan] <= DmaChannelPtr{pref:ctx.pref, offset:ofs+zeroExtend(bl)+1, burstLen:bl, cfg:True};
	 end
      else
	 begin
	    stateReg <= Idle;
	 end
   endrule
   
   rule readData if (stateReg == Data);
      addrReg <= addrReg+1;
      let v <- read_pareff(ctxtPtrs[activeChan].pref, addrReg);
      readBuffers[activeChan].fifo.enq(v);
      if(burstReg == 0)
	 stateReg <= Idle;
      else
	 burstReg <= burstReg-1;
   endrule

   interface DMARead read;
      method Action configChan(DmaChannelId channelId, Bit#(32) pref, Bit#(4) bsz);
   	 ctxtPtrs[channelId] <= DmaChannelPtr{pref:pref, offset:0, burstLen:bsz, cfg:True};
      endmethod
      interface readChannels = zipWith(mkReadChan, map(toGet,readBuffers), map(toPut, reqOutstanding));
      method ActionValue#(DmaDbgRec) dbg();
	 return ?;
      endmethod
   endinterface
   
endmodule


module mkBsimDMAWriteInternal(BsimDMAWriteInternal);

   Vector#(NumDmaChannels, FIFOFLevel#(Bit#(64), 16)) writeBuffers <- replicateM(mkBRAMFIFOFLevel);
   Vector#(NumDmaChannels, FIFOF#(void)) reqOutstanding <- replicateM(mkSizedFIFOF(1));
   Vector#(NumDmaChannels, FIFOF#(void)) writeRespRec   <- replicateM(mkSizedFIFOF(1));
   Vector#(NumDmaChannels, Reg#(DmaChannelPtr)) ctxtPtrs <- replicateM(mkReg(unpack(0)));

   Reg#(Bit#(32))         addrReg <- mkReg(0);
   Reg#(Bit#(4))         burstReg <- mkReg(0);   
   Reg#(DmaChannelId)  activeChan <- mkReg(0);
   Reg#(InternalState)   stateReg <- mkReg(Idle);
   Reg#(DmaChannelId)   selectReg <- mkReg(0);
   
   rule incSelectReg;
      selectReg <= selectReg+1;
   endrule

   rule selectChannel if (stateReg == Idle && reqOutstanding[selectReg].notEmpty);
      activeChan <= selectReg;
      stateReg <= LoadCtxt;
   endrule
   
   rule loadChannel if (stateReg == LoadCtxt);
      let ctx = ctxtPtrs[activeChan];
      let bl = ctx.burstLen;
      if(writeBuffers[activeChan].highWater(zeroExtend(bl)+1) && ctx.cfg)
	 begin
	    reqOutstanding[activeChan].deq;
	    let  ofs = ctx.offset;
	    burstReg <= bl;
	    addrReg <= ofs;
	    stateReg <= Data;
	    ctxtPtrs[activeChan] <= DmaChannelPtr{pref:ctx.pref, offset:ofs+zeroExtend(bl)+1, burstLen:bl, cfg:True};
	 end
      else
	 begin
	    stateReg <= Idle;
	 end
   endrule
   
   rule writeData if (stateReg == Data);
      addrReg <= addrReg+1;
      writeBuffers[activeChan].fifo.deq;
      let v = writeBuffers[activeChan].fifo.first;
      if(burstReg == 0)
	 stateReg <= Done;
      else
	 burstReg <= burstReg-1;
      write_pareff(ctxtPtrs[activeChan].pref, addrReg, v);
   endrule
   
   rule response if (stateReg == Done);
      writeRespRec[activeChan].enq(?);
      stateReg <= Idle;
   endrule

   interface DMAWrite write;
      method Action configChan(DmaChannelId channelId, Bit#(32) pref, Bit#(4) bsz);
   	 ctxtPtrs[channelId] <= DmaChannelPtr{pref:pref, offset:0, burstLen:bsz, cfg:True};
      endmethod
      interface writeChannels = zipWith3(mkWriteChan, map(toPut,writeBuffers), 
					 map(toPut, reqOutstanding),
					 map(toGet, writeRespRec));
      method ActionValue#(DmaDbgRec) dbg();
	 return ?;
      endmethod
   endinterface

endmodule

module mkBsimDMA#(DMAIndication indication)(BsimDMA);
   BsimDMAWriteInternal writer <- mkBsimDMAWriteInternal;
   BsimDMAReadInternal  reader <- mkBsimDMAReadInternal;
   Reg#(Bool) inited <- mkReg(False);

   rule initialize(!inited);
      inited <= True;
      init_pareff();
   endrule
   
   interface DMARequest request;
      method Action configChan(Bit#(32) rc, Bit#(32) channelId, Bit#(32) pref, Bit#(32) numWords);
	 if (rc == 0)
	    reader.read.configChan(pack(truncate(channelId)), pref, truncate((numWords>>1)-1));
	 else if (rc==1)
	    writer.write.configChan(pack(truncate(channelId)), pref, truncate((numWords>>1)-1));
	 indication.configResp(channelId);
	 //$display("configChan(%d, %d %d %d)", rc, channelId, pref, numWords);
      endmethod
      method Action getStateDbg(Bit#(32) rc);
	 let rv = ?;
	 if (rc == 0)
	    rv <- reader.read.dbg;
	 else if (rc == 1)
	    rv <- writer.write.dbg;
	 indication.reportStateDbg(rv);
      endmethod
      method Action paref(Bit#(32) pref, Bit#(32) size);
	 pareff(pref, size); 
	 indication.parefResp(pref);
      endmethod
   endinterface
   interface BsimDMAWrite write = writer.write;
   interface BsimDMARead  read  = reader.read;
endmodule
