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
import PortalRMemory::*;
import Adapter::*;
import SGList::*;

interface AxiDMAWriteInternal#(type t);
   interface DMAWrite#(t) write;
   interface Axi3WriteClient#(40,64,8,12) m_axi_write;
   method Action page(Bit#(32) tabsel, Bit#(32) off, Bit#(40) addr);
endinterface

interface AxiDMAReadInternal#(type t);
   interface DMARead#(t) read;
   interface Axi3ReadClient#(40,64,12) m_axi_read;
   method Action page(Bit#(32) tabel, Bit#(32) off, Bit#(40) addr);
endinterface

interface AxiDMA#(type t);
   interface DMARequest request;
   interface DMAWrite#(t) write;
   interface DMARead#(t)   read;
   interface Axi3Client#(40,64,8,12) m_axi;
endinterface

typedef enum {Idle, LoadCtxt, Address, Data, Done} InternalState deriving(Eq,Bits);
		 
typedef struct {
   SGListId  sglid;
   } DmaChannelPtr deriving (Bits);
		 
module mkAxiDMAReadInternal(AxiDMAReadInternal#(t))
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
   SGListMMU sgl <- mkSGListMMU();
   
   Reg#(Bit#(40))         addrReg <- mkReg(0);
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
      sgl.addrReq(ctxtPtrs[selectReg].sglid,reqOutstanding[selectReg].first);
      stateReg <= LoadCtxt;
   endrule
   
   rule loadChannel if (stateReg == LoadCtxt);
      let ctx = ctxtPtrs[activeChan];
      Bit#(4) bl = fromInteger(valueOf(n))-1;
      let phys_addr <- sgl.addrResp;
      if(readBuffers[activeChan].lowWater(zeroExtend(bl)+1))
	 begin
	    reqOutstanding[activeChan].deq;
	    addrReg <= phys_addr;
	    stateReg <= Address;
	    burstReg <= bl;
	 end
      else
	 begin
	    stateReg <= Idle;
	 end
   endrule
   
   method Action page(Bit#(32) tabsel, Bit#(32) off, Bit#(40) addr);
      sgl.page(truncate(tabsel), off, addr);
   endmethod
   
   interface DMARead read;
      method Action configChan(DmaChannelId channelId, Bit#(32) pref);
   	 ctxtPtrs[channelId] <= DmaChannelPtr{sglid:truncate(pref)};
      endmethod
      interface readChannels = zipWith(mkReadChan, map(toGet,readAdapters), map(toPut, reqOutstanding));
      method ActionValue#(DmaDbgRec) dbg();
	 return DmaDbgRec{x:truncate(addrReg), y:zeroExtend(burstReg), z:zeroExtend(activeChan), w:zeroExtend(pack(stateReg))};
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


module mkAxiDMAWriteInternal(AxiDMAWriteInternal#(t))
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
   SGListMMU sgl <- mkSGListMMU();
   
   Reg#(Bit#(40))         addrReg <- mkReg(0);
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
      sgl.addrReq(ctxtPtrs[selectReg].sglid,reqOutstanding[selectReg].first);
      stateReg <= LoadCtxt;
   endrule
   
   rule loadChannel if (stateReg == LoadCtxt);
      let ctx = ctxtPtrs[activeChan];
      Bit#(4) bl = fromInteger(valueOf(n))-1;
      let phys_addr <- sgl.addrResp;
      if(writeBuffers[activeChan].highWater(zeroExtend(bl)+1))
	 begin
	    reqOutstanding[activeChan].deq;
	    addrReg <= phys_addr;
	    stateReg <= Address;
	    burstReg <= bl;
	 end
      else
	 begin
	    stateReg <= Idle;
	 end
   endrule
   
   method Action page(Bit#(32) tabsel, Bit#(32) off, Bit#(40) addr);
      sgl.page(truncate(tabsel), off, addr);
   endmethod

   interface DMAWrite write;
      method Action configChan(DmaChannelId channelId, Bit#(32) pref);
   	 ctxtPtrs[channelId] <= DmaChannelPtr{sglid:truncate(pref)};
      endmethod
      interface writeChannels = zipWith3(mkWriteChan, map(toPut,writeAdapters), 
					 map(toPut, reqOutstanding),
					 map(toGet, writeRespRec));
      method ActionValue#(DmaDbgRec) dbg();
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
	 writeRespRec[activeChan].enq(?);
	 stateReg <= Idle;
      endmethod
   endinterface
endmodule

module mkAxiDMA#(DMAIndication indication)(AxiDMA#(t))
   provisos(Bits#(t,__a),
	    Add#(1, a__, __a),
	    Add#(64, b__, TMul#(64, TDiv#(__a, 64))),
	    Add#(__a, c__, TMul#(64, TDiv#(__a, 64))),
	    Mul#(d__, 64, __a),
	    Max#(d__, 16, 16));
	    
   AxiDMAWriteInternal#(t) writer <- mkAxiDMAWriteInternal;
   AxiDMAReadInternal#(t)  reader <- mkAxiDMAReadInternal;

   Reg#(Bit#(40)) addrReg         <- mkReg(0);
   Reg#(Bit#(32)) prefReg         <- mkReg(0);
   Reg#(Bit#(32))  lenReg         <- mkReg(0);
   Reg#(Bit#(32))  idxReg         <- mkReg(0);
   
   let page_shift = fromInteger(valueOf(SGListPageShift));

   rule write_pages(idxReg < lenReg);
      idxReg <= idxReg + 1;
      addrReg <= addrReg + 1;
      writer.page(prefReg,idxReg,addrReg);
      reader.page(prefReg,idxReg,addrReg);
      if(idxReg+1 == lenReg)
	 indication.sglistResp(prefReg);
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
      method Action sglist(Bit#(32) pref, Bit#(40) addr, Bit#(32) len) if (idxReg == lenReg);
	 addrReg <= addr >> page_shift;
	 lenReg  <= len >> page_shift;
	 prefReg <= pref;
	 idxReg  <= 0;
	 if (addr == 0 && len == 0) // sw marks end-of-list with zeros
	    indication.sglistResp(pref);
      endmethod
   endinterface
   interface AxiDMAWrite write = writer.write;
   interface AxiDMARead  read  = reader.read;
   interface Axi3Client m_axi;
      interface Axi3WriteClient write = writer.m_axi_write;
      interface Axi3ReadClient read = reader.m_axi_read;
   endinterface
endmodule
