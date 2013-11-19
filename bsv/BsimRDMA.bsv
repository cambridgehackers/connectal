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
import PortalRMemory::*;
import Adapter::*;

import "BDPI" function Action pareff(Bit#(32) pref, Bit#(32) size);
import "BDPI" function Action init_pareff();
import "BDPI" function Action write_pareff(Bit#(32) pref, Bit#(32) addr, Bit#(64) v);
import "BDPI" function ActionValue#(Bit#(64)) read_pareff(Bit#(32) pref, Bit#(32) addr);
		       
interface BsimDMAWriteInternal#(type t);
   interface DMAWrite#(t) write;
endinterface

interface BsimDMAReadInternal#(type t);
   interface DMARead#(t) read;
endinterface

interface BsimDMA#(type t);
   interface DMARequest request;
   interface DMAWrite#(t) write;
   interface DMARead#(t)   read;
endinterface

typedef enum {Idle, LoadCtxt, Data, Done} InternalState deriving(Eq,Bits);
		 
typedef struct {
   Bit#(32)  pref;
   Bool cfg;
   } DmaChannelPtr deriving (Bits);
		 
module mkBsimDMAReadInternal(BsimDMAReadInternal#(t))
   provisos(Bits#(t,tsz),
	    Add#(1,a__,tsz),
	    Mul#(n,64,tsz),
	    Max#(n,16,16),
	    Add#(64, b__, TMul#(64, TDiv#(tsz, 64))),
	    Add#(tsz, c__, TMul#(64, TDiv#(tsz, 64))));
   
   Vector#(NumDmaChannels, FromBit#(64, t))          readAdapters <- replicateM(mkFromBit);
   Vector#(NumDmaChannels, FIFOFLevel#(Bit#(64), 16)) readBuffers <- replicateM(mkBRAMFIFOFLevel);
   Vector#(NumDmaChannels, FIFOF#(Bit#(40)))       reqOutstanding <- replicateM(mkSizedFIFOF(1));
   Vector#(NumDmaChannels, Reg#(DmaChannelPtr))          ctxtPtrs <- replicateM(mkReg(unpack(0)));

   Reg#(Bit#(32))         addrReg <- mkReg(0);
   Reg#(Bit#(4))         burstReg <- mkReg(0);   
   Reg#(DmaChannelId)  activeChan <- mkReg(0);
   Reg#(InternalState)   stateReg <- mkReg(Idle);
   Reg#(DmaChannelId)   selectReg <- mkReg(0);
   
   for(int i = 0; i < fromInteger(valueOf(NumDmaChannels)); i=i+1)
      rule adapt;
	 readAdapters[i].enq(readBuffers[i].fifo.first);
	 readBuffers[i].fifo.deq;
      endrule

   rule incSelectReg;
      selectReg <= selectReg+1;
   endrule

   rule selectChannel if (stateReg == Idle && reqOutstanding[selectReg].notEmpty);
      activeChan <= selectReg;
      stateReg <= LoadCtxt;
   endrule
   
   rule loadChannel if (stateReg == LoadCtxt);
      let ctx = ctxtPtrs[activeChan];
      Bit#(4) bl = fromInteger(valueOf(n))-1;
      if(readBuffers[activeChan].lowWater(zeroExtend(bl)+1) && ctx.cfg)
	 begin
	    reqOutstanding[activeChan].deq;
	    addrReg <= truncate(reqOutstanding[activeChan].first);
	    stateReg <= Data;
	    burstReg <= bl;
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
      method Action configChan(DmaChannelId channelId, Bit#(32) pref);
   	 ctxtPtrs[channelId] <= DmaChannelPtr{pref:pref, cfg:True};
      endmethod
      interface readChannels = zipWith(mkReadChan, map(toGet,readAdapters), map(toPut, reqOutstanding));
      method ActionValue#(DmaDbgRec) dbg();
	 return ?;
      endmethod
   endinterface
   
endmodule


module mkBsimDMAWriteInternal(BsimDMAWriteInternal#(t))
   provisos(Bits#(t,tsz),
	    Add#(1,a__,tsz),
	    Mul#(n,64,tsz),
	    Max#(n,16,16),
	    Add#(64, b__, TMul#(64, TDiv#(tsz, 64))),
	    Add#(tsz, c__, TMul#(64, TDiv#(tsz, 64))));

   Vector#(NumDmaChannels, ToBit#(64, t))            writeAdapters <- replicateM(mkToBit);
   Vector#(NumDmaChannels, FIFOFLevel#(Bit#(64), 16)) writeBuffers <- replicateM(mkBRAMFIFOFLevel);
   Vector#(NumDmaChannels, FIFOF#(Bit#(40)))        reqOutstanding <- replicateM(mkSizedFIFOF(1));
   Vector#(NumDmaChannels, FIFOF#(void))              writeRespRec <- replicateM(mkSizedFIFOF(1));
   Vector#(NumDmaChannels, Reg#(DmaChannelPtr))           ctxtPtrs <- replicateM(mkReg(unpack(0)));

   Reg#(Bit#(32))         addrReg <- mkReg(0);
   Reg#(Bit#(4))         burstReg <- mkReg(0);   
   Reg#(DmaChannelId)  activeChan <- mkReg(0);
   Reg#(InternalState)   stateReg <- mkReg(Idle);
   Reg#(DmaChannelId)   selectReg <- mkReg(0);
   
   for(int i = 0; i < fromInteger(valueOf(NumDmaChannels)); i=i+1)
      rule adapt;
	 writeBuffers[i].fifo.enq(writeAdapters[i].first);
	 writeAdapters[i].deq;
      endrule

   rule incSelectReg;
      selectReg <= selectReg+1;
   endrule

   rule selectChannel if (stateReg == Idle && reqOutstanding[selectReg].notEmpty);
      activeChan <= selectReg;
      stateReg <= LoadCtxt;
   endrule
   
   rule loadChannel if (stateReg == LoadCtxt);
      let ctx = ctxtPtrs[activeChan];
      Bit#(4) bl = fromInteger(valueOf(n))-1;
      if(writeBuffers[activeChan].highWater(zeroExtend(bl)+1) && ctx.cfg)
	 begin
	    reqOutstanding[activeChan].deq;
	    addrReg <= truncate(reqOutstanding[activeChan].first);
	    stateReg <= Data;
	    burstReg <= bl;
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
      method Action configChan(DmaChannelId channelId, Bit#(32) pref);
   	 ctxtPtrs[channelId] <= DmaChannelPtr{pref:pref, cfg:True};
      endmethod
      interface writeChannels = zipWith3(mkWriteChan, map(toPut,writeAdapters), 
					 map(toPut, reqOutstanding),
					 map(toGet, writeRespRec));
      method ActionValue#(DmaDbgRec) dbg();
	 return ?;
      endmethod
   endinterface

endmodule
		 
		 	 
module mkBsimDMA#(DMAIndication indication)(BsimDMA#(t))
   provisos(Bits#(t,__a),
	    Add#(1, a__, __a),
	    Add#(64, b__, TMul#(64, TDiv#(__a, 64))),
	    Add#(__a, c__, TMul#(64, TDiv#(__a, 64))),
	    Mul#(d__, 64, __a),
	    Max#(d__, 16, 16));
	    
   BsimDMAWriteInternal#(t) writer <- mkBsimDMAWriteInternal;
   BsimDMAReadInternal#(t)  reader <- mkBsimDMAReadInternal;
   Reg#(Bool) inited <- mkReg(False);

   rule initialize(!inited);
      inited <= True;
      init_pareff();
   endrule
   
   interface DMARequest request;
      method Action configReadChan(Bit#(32) channelId, Bit#(32) pref, Bit#(32) __ignored);
	 reader.read.configChan(pack(truncate(channelId)), pref);
	 indication.configResp(channelId);
      endmethod
      method Action configWriteChan(Bit#(32) channelId, Bit#(32) pref, Bit#(32) __ignored);
	 writer.write.configChan(pack(truncate(channelId)), pref);
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
      method Action paref(Bit#(32) pref, Bit#(32) size);
	 pareff(pref, size); 
	 indication.parefResp(pref);
      endmethod
   endinterface
   interface BsimDMAWrite write = writer.write;
   interface BsimDMARead  read  = reader.read;
endmodule
