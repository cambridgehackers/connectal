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
import AxiClientServer::*;
import BRAMFIFOFLevel::*;
import PortalMemory::*;
import SGList::*;

typedef struct {
   Bit#(32) x;
   Bit#(32) y;
   Bit#(32) z;
   Bit#(32) w;
   } DmaDbgRec deriving(Bits);

interface DMAIndication;
   method Action reportStateDbg(DmaDbgRec rec);
   method Action configResp(Bit#(32) channelId);
   method Action sglistResp(Bit#(32) v);
endinterface

interface DMARequest;
   method Action configReadChan(Bit#(32) channelId, Bit#(40) pa, Bit#(32) bsz);
   method Action configWriteChan(Bit#(32) channelId, Bit#(40) pa, Bit#(32) bsz);
   method Action getReadStateDbg();
   method Action getWriteStateDbg();
   method Action sglist(Bit#(32) off, Bit#(40) addr, Bit#(32) len);
endinterface

instance PortalMemory#(DMARequest);
endinstance
		       
// In the future, NumDmaChannels will be defined somehwere in the xbsv compiler output
typedef 2 NumDmaChannels;
typedef Bit#(TLog#(NumDmaChannels)) DmaChannelId;
typedef struct {
   SGListId   sglid;
   Bit#(4) burstLen; 
   } DmaChannelPtr deriving (Bits);

interface ReadChan;
   interface Get#(Bit#(64)) readData;
   interface Put#(void)     readReq;
endinterface

interface WriteChan;
   interface Put#(Bit#(64)) writeData;
   interface Put#(void)     writeReq;
   interface Get#(void)     writeDone;
endinterface

interface AxiDMARead;
   method Action configChan(DmaChannelId channelId, Bit#(40) pa, Bit#(4) bsz);
   interface Vector#(NumDmaChannels, ReadChan) readChannels;
   method DmaDbgRec dbg();
endinterface

interface AxiDMAWrite;
   method Action  configChan(DmaChannelId channelId, Bit#(40) pa, Bit#(4) bsz);   
   interface Vector#(NumDmaChannels, WriteChan) writeChannels;
   method DmaDbgRec dbg();
endinterface

interface AxiDMAWriteInternal;
   interface AxiDMAWrite write;
   interface Axi3WriteClient#(40,64,8,12) m_axi_write;
   method Action sglist(Bit#(32) off, Bit#(40) addr, Bit#(32) len);
endinterface

interface AxiDMAReadInternal;
   interface AxiDMARead read;
   interface Axi3ReadClient#(40,64,12) m_axi_read;   
   method Action sglist(Bit#(32) off, Bit#(40) addr, Bit#(32) len);
endinterface

interface AxiDMA;
   interface DMARequest request;
   interface AxiDMAWrite write;
   interface AxiDMARead  read;
   interface Axi3Client#(40,64,8,12) m_axi;
endinterface

function Put#(void) mkPutWhenFalse(Reg#(Bool) r);
   return (interface Put;
	      method Action put(void v);
		 _when_ (!r) (r._write(True));
	      endmethod
	   endinterface);
endfunction

function Get#(void) mkGetWhenTrue(Reg#(Bool) r);
   return (interface Get;
	      method ActionValue#(void) get;
		 _when_ (r) (r._write(False));
		 return ?;
	      endmethod
	   endinterface);
endfunction

function ReadChan mkReadChan(Get#(Bit#(64)) rd, Put#(void) rr);
   return (interface ReadChan;
	      interface Get readData = rd;
	      interface Put readReq  = rr;
	   endinterface);
endfunction

function WriteChan mkWriteChan(Put#(Bit#(64)) wd, Put#(void) wr, Get#(void) d);
   return (interface WriteChan;
	      interface Put writeData = wd;
	      interface Put writeReq  = wr;
	      interface Get writeDone = d;
	   endinterface);
endfunction

typedef enum {Idle, LoadCtxt, Address, Data, Done} InternalState deriving(Eq,Bits);

module mkAxiDMAReadInternal(AxiDMAReadInternal);
   Vector#(NumDmaChannels, FIFOFLevel#(Bit#(64), 16)) readBuffers  <- replicateM(mkBRAMFIFOFLevel);
   Vector#(NumDmaChannels, Reg#(Bool)) reqOutstanding <- replicateM(mkReg(False));
   Vector#(NumDmaChannels, Reg#(DmaChannelPtr)) ctxtPtrs <- replicateM(mkReg(unpack(0)));
   SGListManager sgl <- mkSGListManager();
   
   Reg#(Bit#(40))         addrReg <- mkReg(0);
   Reg#(Bit#(4))         burstReg <- mkReg(0);   
   Reg#(DmaChannelId)  activeChan <- mkReg(0);
   Reg#(InternalState)   stateReg <- mkReg(Idle);
   Reg#(DmaChannelId)   selectReg <- mkReg(0);
   
   rule incSelectReg;
      selectReg <= selectReg+1;
   endrule

   rule selectChannel if (stateReg == Idle && reqOutstanding[selectReg]);
      activeChan <= selectReg;
      sgl.loadCtx(ctxtPtrs[selectReg].sglid);
      stateReg <= LoadCtxt;
   endrule
   
   rule loadChannel if (stateReg == LoadCtxt);
      let bl = ctxtPtrs[activeChan].burstLen;
      if(readBuffers[activeChan].lowWater(zeroExtend(bl)+1))
	 begin
	    reqOutstanding[activeChan] <= False;
	    let phys_addr <- sgl.nextAddr(bl);
	    burstReg <= bl;
	    addrReg <= phys_addr;
	    stateReg <= Address;
	 end
      else
	 begin
	    stateReg <= Idle;
	    sgl.dropCtx;
	 end
   endrule
   
   method Action sglist(Bit#(32) off, Bit#(40) addr, Bit#(32) len);
      sgl.sglist(off, addr, len);
   endmethod
   
   interface AxiDMARead read;
      method Action configChan(DmaChannelId channelId, Bit#(40) pa, Bit#(4) bsz);
	 ctxtPtrs[channelId] <= DmaChannelPtr{sglid:truncate(pa), burstLen:bsz};
      endmethod
      interface readChannels = zipWith(mkReadChan, map(toGet,readBuffers), map(mkPutWhenFalse, reqOutstanding));
      method DmaDbgRec dbg();
	 return DmaDbgRec{x:truncate(addrReg), y:zeroExtend(burstReg), z:zeroExtend(pack(readVReg(reqOutstanding))), w:zeroExtend(pack(stateReg))};
      endmethod
   endinterface

   interface Axi3ReadClient m_axi_read;
      method ActionValue#(Axi3ReadRequest#(40,12)) address if (stateReg == Address);
	 stateReg <= Data;
	 return Axi3ReadRequest{address:addrReg, burstLen:burstReg, id:1};
      endmethod
      method Action data(Axi3ReadResponse#(64,12) response) if (stateReg == Data);
	 readBuffers[activeChan].fifo.enq(response.data);
	 if(burstReg == 0)
	    stateReg <= Idle;
	 else
	    burstReg <= burstReg-1;
      endmethod
   endinterface
endmodule


module mkAxiDMAWriteInternal(AxiDMAWriteInternal);
   Vector#(NumDmaChannels, FIFOFLevel#(Bit#(64), 16)) writeBuffers <- replicateM(mkBRAMFIFOFLevel);
   Vector#(NumDmaChannels, Reg#(Bool)) reqOutstanding <- replicateM(mkReg(False));
   Vector#(NumDmaChannels, Reg#(Bool)) writeRespRec   <- replicateM(mkReg(False));
   Vector#(NumDmaChannels, Reg#(DmaChannelPtr)) ctxtPtrs <- replicateM(mkReg(unpack(0)));
   SGListManager sgl <- mkSGListManager();

   Reg#(Bit#(40))         addrReg <- mkReg(0);
   Reg#(Bit#(4))         burstReg <- mkReg(0);   
   Reg#(DmaChannelId)  activeChan <- mkReg(0);
   Reg#(InternalState)   stateReg <- mkReg(Idle);
   Reg#(DmaChannelId)   selectReg <- mkReg(0);
   
   rule incSelectReg;
      selectReg <= selectReg+1;
   endrule

   rule selectChannel if (stateReg == Idle && reqOutstanding[selectReg]);
      activeChan <= selectReg;
      sgl.loadCtx(ctxtPtrs[selectReg].sglid);
      stateReg <= LoadCtxt;
   endrule
   
   rule loadChannel if (stateReg == LoadCtxt);
      let bl = ctxtPtrs[activeChan].burstLen;
      if(writeBuffers[activeChan].highWater(zeroExtend(bl)+1))
	 begin
	    reqOutstanding[activeChan] <= False;
	    let phys_addr <- sgl.nextAddr(bl);
	    burstReg <= bl;
	    addrReg <= phys_addr;
	    stateReg <= Address;
	 end
      else
	 begin
	    stateReg <= Idle;
	    sgl.dropCtx;
	 end
   endrule
   
   
   method Action sglist(Bit#(32) off, Bit#(40) addr, Bit#(32) len);
      sgl.sglist(off, addr, len);
   endmethod

   interface AxiDMAWrite write;
      method Action configChan(DmaChannelId channelId, Bit#(40) pa, Bit#(4) bsz);
	 ctxtPtrs[channelId] <= DmaChannelPtr{sglid:truncate(pa), burstLen:bsz};
      endmethod
      interface writeChannels = zipWith3(mkWriteChan, map(toPut,writeBuffers), 
					 map(mkPutWhenFalse, reqOutstanding),
					 map(mkGetWhenTrue, writeRespRec));
      method DmaDbgRec dbg();
	 return DmaDbgRec{x:truncate(addrReg), y:zeroExtend(burstReg), z:zeroExtend(activeChan), w:zeroExtend(pack(stateReg))};
      endmethod
   endinterface

   interface Axi3WriteClient m_axi_write;
      method ActionValue#(Axi3WriteRequest#(40,12)) address if (stateReg == Address);
	 stateReg <= Data;
	 return Axi3WriteRequest{address:addrReg, burstLen:burstReg, id:1};
      endmethod
      method ActionValue#(Axi3WriteData#(64, 8, 12)) data if (stateReg == Data);
	 writeBuffers[activeChan].fifo.deq;
	 let v = writeBuffers[activeChan].fifo.first;
	 Bit#(1) last = burstReg == 0 ? 1'b1 : 1'b0;
	 if(burstReg == 0)
	    stateReg <= Done;
	 else
	    burstReg <= burstReg-1;
	 return Axi3WriteData { data: v, byteEnable: maxBound, last: last, id: 1 };
      endmethod
      method Action response(Axi3WriteResponse#(12) resp) if (stateReg == Done);
	 writeRespRec[activeChan] <= True;
	 stateReg <= Idle;
      endmethod
   endinterface
endmodule

module mkAxiDMA#(DMAIndication indication)(AxiDMA);
   AxiDMAWriteInternal writer <- mkAxiDMAWriteInternal;
   AxiDMAReadInternal  reader <- mkAxiDMAReadInternal;
   interface DMARequest request;
      method Action configReadChan(Bit#(32) channelId, Bit#(40) pa, Bit#(32) numWords);
	 reader.read.configChan(pack(truncate(channelId)), pa, truncate((numWords>>1)-1));
	 indication.configResp(channelId);
      endmethod
      method Action configWriteChan(Bit#(32) channelId, Bit#(40) pa, Bit#(32) numWords);
	 writer.write.configChan(pack(truncate(channelId)), pa, truncate((numWords>>1)-1));
	 indication.configResp(channelId);
      endmethod
      method Action getReadStateDbg();
	 indication.reportStateDbg(reader.read.dbg());
      endmethod
      method Action getWriteStateDbg();
	 indication.reportStateDbg(writer.write.dbg());
      endmethod
      method Action sglist(Bit#(32) off, Bit#(40) addr, Bit#(32) len);
	 writer.sglist(off, addr, len);
	 reader.sglist(off, addr, len);
	 indication.sglistResp(off);
      endmethod
   endinterface
   interface AxiDMAWrite write = writer.write;
   interface AxiDMARead  read  = reader.read;
   interface Axi3Client m_axi;
      interface Axi3WriteClient write = writer.m_axi_write;
      interface Axi3ReadClient read = reader.m_axi_read;
   endinterface
endmodule
