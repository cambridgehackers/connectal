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

// In the future, NumDmaChannels will be defined somehwere in the xbsv compiler output
typedef 2 NumDmaChannels;
typedef Bit#(TLog#(NumDmaChannels)) DmaChannelId;
typedef struct {
   Bit#(32) physAddr;
   Bit#(4) burstLen; 
   } DmaChannelContext deriving (Bits);

typedef struct {
   Bit#(32) x;
   Bit#(32) y;
   Bit#(32) z;
   Bit#(32) w;
   } DmaDbgRec deriving(Bits);


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
   method Action configChan(DmaChannelId channelId, Bit#(32) pa, Bit#(4) bsz);
   interface Vector#(NumDmaChannels, ReadChan) readChanels;
   method DmaDbgRec dbg();
endinterface

interface AxiDMAWrite;
   method Action  configChan(DmaChannelId channelId, Bit#(32) pa, Bit#(4) bsz);   
   interface Vector#(NumDmaChannels, WriteChan) writeChannels;
   method DmaDbgRec dbg();
endinterface

interface AxiDMAWriteInternal;
   interface AxiDMAWrite write;
   interface Axi3WriteClient#(32,64,8,6) m_axi_write;
endinterface

interface AxiDMAReadInternal;
   interface AxiDMARead read;
   interface Axi3ReadClient#(32,64,6) m_axi_read;   
endinterface

interface AxiDMA;
   interface AxiDMAWrite write;
   interface AxiDMARead  read;
   interface Axi3Client#(32,64,8,6) m_axi;
endinterface

function Put#(void) mkPutWhenFalse(Reg#(Bool) r);
   return (interface Put;
	      method Action put(void v);
		 (_when_ (!r) (r._write(True)));
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
   BRAM1Port#(DmaChannelId, DmaChannelContext) ctxMem <- mkBRAM1Server(defaultValue);
   
   Reg#(Bit#(32))         addrReg <- mkReg(0);
   Reg#(Bit#(4))         burstReg <- mkReg(0);   
   Reg#(DmaChannelId)  activeChan <- mkReg(0);
   Reg#(InternalState)   stateReg <- mkReg(Idle);
   Reg#(DmaChannelId)   selectReg <- mkReg(0);
   
   rule incSelectReg;
      selectReg <= selectReg+1;
   endrule

   rule selectChannel if (stateReg == Idle && reqOutstanding[selectReg]);
      ctxMem.portA.request.put(BRAMRequest{write:False, responseOnWrite:False, address:selectReg, datain:?});
      activeChan <= selectReg;
      stateReg <= LoadCtxt;
   endrule
   
   rule loadChannel if (stateReg == LoadCtxt);
      let rv <- ctxMem.portA.response.get;
      if(readBuffers[activeChan].lowWater(zeroExtend(rv.burstLen)+1))
	 begin
	    reqOutstanding[activeChan] <= False;
	    burstReg <= rv.burstLen;
	    addrReg <= rv.physAddr;
	    let new_addr = rv.physAddr + ((zeroExtend(rv.burstLen)+1) << 3);
	    let new_ctx = DmaChannelContext{physAddr:new_addr,burstLen:rv.burstLen};
	    let upd_req = BRAMRequest{write:True, responseOnWrite:False, address:activeChan,datain:new_ctx};
	    ctxMem.portA.request.put(upd_req);
	    stateReg <= Address;
	 end
      else
	 begin
	    stateReg <= Idle;
	 end
   endrule
      
   interface AxiDMARead read;
      method Action configChan(DmaChannelId channelId, Bit#(32) pa, Bit#(4) bsz);
	 let ctx = DmaChannelContext{physAddr:pa, burstLen:bsz};
	 ctxMem.portA.request.put(BRAMRequest{write:True, responseOnWrite:False, address:channelId,datain:ctx});
      endmethod
      interface readChanels = zipWith(mkReadChan, map(toGet,readBuffers), map(mkPutWhenFalse, reqOutstanding));
      method DmaDbgRec dbg();
	 return DmaDbgRec{x:addrReg, y:zeroExtend(burstReg), z:zeroExtend(activeChan), w:zeroExtend(pack(stateReg))};
      endmethod
   endinterface

   interface Axi3ReadClient m_axi_read;
      method ActionValue#(Axi3ReadRequest#(32,6)) address if (stateReg == Address);
	 stateReg <= Data;
	 return Axi3ReadRequest{address:addrReg, burstLen:burstReg, id:1};
      endmethod
      method Action data(Axi3ReadResponse#(64,6) response) if (stateReg == Data);
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
   BRAM1Port#(DmaChannelId, DmaChannelContext) ctxMem <- mkBRAM1Server(defaultValue);

   Reg#(Bit#(32))         addrReg <- mkReg(0);
   Reg#(Bit#(4))         burstReg <- mkReg(0);   
   Reg#(DmaChannelId)  activeChan <- mkReg(0);
   Reg#(InternalState)   stateReg <- mkReg(Idle);
   Reg#(DmaChannelId)   selectReg <- mkReg(0);
   
   rule incSelectReg;
      selectReg <= selectReg+1;
   endrule

   rule selectChannel if (stateReg == Idle && reqOutstanding[selectReg]);
      ctxMem.portA.request.put(BRAMRequest{write:False, responseOnWrite:False, address:selectReg, datain:?});
      activeChan <= selectReg;
      stateReg <= LoadCtxt;
   endrule
   
   rule loadChannel if (stateReg == LoadCtxt);
      let rv <- ctxMem.portA.response.get;
      if(writeBuffers[activeChan].highWater(zeroExtend(rv.burstLen)+1))
	 begin
	    reqOutstanding[activeChan] <= False;
	    burstReg <= rv.burstLen;
	    addrReg <= rv.physAddr;
	    let new_addr = rv.physAddr + ((zeroExtend(rv.burstLen)+1) << 3);
	    let new_ctx = DmaChannelContext{physAddr:new_addr,burstLen:rv.burstLen};
	    let upd_req = BRAMRequest{write:True, responseOnWrite:False, address:activeChan,datain:new_ctx};
	    ctxMem.portA.request.put(upd_req);
	    stateReg <= Address;
	 end
      else
	 begin
	    stateReg <= Idle;
	 end
   endrule

   interface AxiDMAWrite write;
      method Action configChan(DmaChannelId channelId, Bit#(32) pa, Bit#(4) bsz);
	 let ctx = DmaChannelContext{physAddr:pa, burstLen:bsz};
	 ctxMem.portA.request.put(BRAMRequest{write:True, responseOnWrite:False,address:channelId, datain:ctx});
      endmethod
      interface writeChannels = zipWith3(mkWriteChan, map(toPut,writeBuffers), 
					 map(mkPutWhenFalse, reqOutstanding),
					 map(mkGetWhenTrue, writeRespRec));
      method DmaDbgRec dbg();
	 return DmaDbgRec{x:addrReg, y:zeroExtend(burstReg), z:zeroExtend(activeChan), w:zeroExtend(pack(stateReg))};
      endmethod
   endinterface

   interface Axi3WriteClient m_axi_write;
      method ActionValue#(Axi3WriteRequest#(32,6)) address if (stateReg == Address);
	 stateReg <= Data;
	 return Axi3WriteRequest{address:addrReg, burstLen:burstReg, id:1};
      endmethod
      method ActionValue#(Axi3WriteData#(64, 8, 6)) data if (stateReg == Data);
	 writeBuffers[activeChan].fifo.deq;
	 let v = writeBuffers[activeChan].fifo.first;
	 Bit#(1) last = burstReg == 0 ? 1'b1 : 1'b0;
	 if(burstReg == 0)
	    stateReg <= Done;
	 else
	    burstReg <= burstReg-1;
	 return Axi3WriteData { data: v, byteEnable: maxBound, last: last, id: 1 };
      endmethod
      method Action response(Axi3WriteResponse#(6) resp) if (stateReg == Done);
	 writeRespRec[activeChan] <= True;
	 stateReg <= Idle;
      endmethod
   endinterface
endmodule

module mkAxiDMA(AxiDMA);
   AxiDMAWriteInternal writer <- mkAxiDMAWriteInternal;
   AxiDMAReadInternal  reader <- mkAxiDMAReadInternal;
   interface AxiDMAWrite write = writer.write;
   interface AxiDMARead  read  = reader.read;
   interface Axi3Client m_axi;
      interface Axi3WriteClient write = writer.m_axi_write;
      interface Axi3ReadClient read = reader.m_axi_read;
   endinterface
endmodule
