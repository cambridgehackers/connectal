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

// In the future, NumDmaChannels will be defined somehwere in the xbsv compiler output
typedef 2 NumDmaChannels;
typedef Bit#(TLog#(NumDmaChannels)) DmaChannelId;
typedef struct {
   Bit#(32) physAddr;
   Bit#(4) burstLen; 
   } DmaChannelContext deriving (Bits);

interface AxiDMARead;
   method Action configChan(DmaChannelId channelId, Bit#(32) pa, Bit#(4) bsz);   
   interface Vector#(NumDmaChannels, Get#(Bit#(64))) readData;
   interface Vector#(NumDmaChannels, Put#(void))     readReq;
endinterface

interface AxiDMAWrite;
   method Action  configChan(DmaChannelId channelId, Bit#(32) pa, Bit#(4) bsz);   
   interface Vector#(NumDmaChannels, Put#(Bit#(64))) writeData;
   interface Vector#(NumDmaChannels, Put#(void))     writeReq;
   interface Vector#(NumDmaChannels, Get#(void))     writeDone;
endinterface

interface AxiDMAWriteInternal;
   interface AxiDMAWrite write;
   interface Axi3WriteClient#(64,8,6) m_axi_write;
endinterface

interface AxiDMAReadInternal;
   interface AxiDMARead read;
   interface Axi3ReadClient#(64,6) m_axi_read;   
endinterface

interface AxiDMA;
   interface AxiDMAWrite write;
   interface AxiDMARead  read;
   interface Axi3Client#(64,8,6) m_axi;
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

interface Counter#(type count_sz);
   method Action reset();
   method Action increment();
   method Action decrement();
   method Bit#(count_sz) read();
endinterface

module mkCounter#(Bit#(count_sz) init_val)(Counter#(count_sz));

   PulseWire inc_wire <- mkPulseWire;
   PulseWire dec_wire <- mkPulseWire;
   PulseWire rst_wire <- mkPulseWire;
   Reg#(Bit#(count_sz)) cnt <- mkReg(init_val);

   (* fire_when_enabled *)
   rule react;
      if (rst_wire)
	 cnt <= 0;
      else if (inc_wire && dec_wire)
	 noAction;
      else if (inc_wire)
	 cnt <= cnt+1;
      else if (dec_wire)
	 cnt <= cnt-1;
      else
	 noAction;
   endrule

   method Action increment = inc_wire.send;
   method Action decrement = dec_wire.send;
   method Action reset = rst_wire.send;
   method Bit#(count_sz) read = cnt._read;

endmodule

interface FIFOFCount#(numeric type data_sz, numeric type count_sz);
   interface FIFOF#(Bit#(data_sz)) fifo;
   method Bool highWater(Bit#(count_sz) mark);
   method Bool lowWater(Bit#(count_sz) mark);
endinterface

instance ToGet#(FIFOFCount#(a,b), Bit#(a));
   function Get#(Bit#(a)) toGet(FIFOFCount#(a,b) f) = toGet(f.fifo);
endinstance

instance ToPut#(FIFOFCount#(a,b), Bit#(a));
   function Put#(Bit#(a)) toPut(FIFOFCount#(a,b) f) = toPut(f.fifo);
endinstance

module mkSizedBRAMFIFOFCount#(Integer depth)(FIFOFCount#(data_sz, count_sz))
   provisos (Add#(1, a__, data_sz));

   Counter#(count_sz) cnt <- mkCounter(0);
   FIFOF#(Bit#(data_sz))  fif <- mkSizedBRAMFIFOF(depth);
   
   method Bool highWater(Bit#(count_sz) mark);
      return (cnt.read >= mark);
   endmethod
   
   method Bool lowWater(Bit#(count_sz) mark);
      return (fromInteger(depth)-cnt.read >= mark);
   endmethod
  
   interface FIFOF fifo;
      method Action enq (Bit#(data_sz) x);
	 cnt.increment;
	 fif.enq(x);
      endmethod
      method Action deq;
	 cnt.decrement;
	 fif.deq;
      endmethod
      method Action clear;
	 cnt.reset;
	 fif.clear;
      endmethod
      method Bit#(data_sz) first = fif.first;
      method Bool notFull = fif.notFull;
      method Bool notEmpty = fif.notEmpty;
   endinterface
   
endmodule

typedef enum {Idle, Loading, Busy, Done} InternalState deriving(Eq,Bits);

function Maybe#(DmaChannelId) selectChannel(Vector#(NumDmaChannels, Reg#(Bool)) v);
   Maybe#(DmaChannelId) chan = Nothing;
   // this will need to be replaced with a more efficient decocer
   // I've seen something in HackersDelight about computing the
   // number of leading zeros, but I'm too lazy to look for it (mdk)
   for(DmaChannelId i = 0; i < fromInteger(valueOf(NumDmaChannels)-1); i=i+1)
      if(v[i])
	 chan = tagged Valid i;
   return chan;
endfunction
   
module mkAxiDMAReadInternal(AxiDMAReadInternal);
   Vector#(NumDmaChannels, FIFOFCount#(64, 16)) readBuffers  <- replicateM(mkSizedBRAMFIFOFCount(16));
   Vector#(NumDmaChannels, Reg#(Bool)) reqOutstanding <- replicateM(mkReg(False));
   BRAM1Port#(DmaChannelId, DmaChannelContext) ctxMem <- mkBRAM1Server(defaultValue);
   
   Reg#(Bit#(4))         burstReg <- mkReg(0);   
   Reg#(DmaChannelId)  activeChan <- mkReg(0);
   Reg#(InternalState)   stateReg <- mkReg(Idle);
   
   rule selectChannel if (stateReg == Idle &&& selectChannel(reqOutstanding) matches tagged Valid .c);
      ctxMem.portA.request.put(BRAMRequest{write:False, responseOnWrite:False, address:c, datain:?});
      activeChan <= c;
      stateReg <= Loading;
   endrule
      
   interface AxiDMARead read;
      method Action configChan(DmaChannelId channelId, Bit#(32) pa, Bit#(4) bsz);
	 let ctx = DmaChannelContext{physAddr:pa, burstLen:bsz};
	 ctxMem.portA.request.put(BRAMRequest{write:True, responseOnWrite:False, address:channelId,datain:ctx});
      endmethod
      interface readData = map(toGet,readBuffers);
      interface readReq = map(mkPutWhenFalse, reqOutstanding);
   endinterface

   interface Axi3ReadClient m_axi_read;
      method ActionValue#(Axi3ReadRequest#(6)) address if (stateReg == Loading);
	 let rv <- ctxMem.portA.response.get;
	 burstReg <= rv.burstLen;
	 let new_addr = rv.physAddr + ((zeroExtend(rv.burstLen)+1) << 3);
	 let upd_req = BRAMRequest{write:True, responseOnWrite:False, address:activeChan, 
				   datain:(DmaChannelContext{physAddr:new_addr,burstLen:rv.burstLen})};
	 ctxMem.portA.request.put(upd_req);
	 _when_ (readBuffers[activeChan].lowWater(zeroExtend(rv.burstLen)+1)) (reqOutstanding[activeChan]._write(False)); 
	 stateReg <= Busy;
	 return Axi3ReadRequest{address:rv.physAddr, burstLen:rv.burstLen, id:1};
      endmethod
      method Action data(Axi3ReadResponse#(64,6) response) if (stateReg == Busy);
	 readBuffers[activeChan].fifo.enq(response.data);
	 if(burstReg == 0)
	    stateReg <= Idle;
	 else
	    burstReg <= burstReg-1;
      endmethod
   endinterface
endmodule

module mkAxiDMAWriteInternal(AxiDMAWriteInternal);
   Vector#(NumDmaChannels, FIFOFCount#(64, 16)) writeBuffers <- replicateM(mkSizedBRAMFIFOFCount(16));
   Vector#(NumDmaChannels, Reg#(Bool)) reqOutstanding <- replicateM(mkReg(False));
   Vector#(NumDmaChannels, Reg#(Bool)) writeRespRec   <- replicateM(mkReg(False));
   BRAM1Port#(DmaChannelId, DmaChannelContext) ctxMem <- mkBRAM1Server(defaultValue);

   Reg#(Bit#(4))         burstReg <- mkReg(0);   
   Reg#(DmaChannelId)  activeChan <- mkReg(0);
   Reg#(InternalState)   stateReg <- mkReg(Idle);

   rule selectChannel if (stateReg == Idle &&& selectChannel(reqOutstanding) matches tagged Valid .c);
      ctxMem.portA.request.put(BRAMRequest{write:False, responseOnWrite:False, address:c, datain:?});
      activeChan <= c;
      stateReg <= Loading;
   endrule
   
   interface AxiDMAWrite write;
      method Action configChan(DmaChannelId channelId, Bit#(32) pa, Bit#(4) bsz);
	 let ctx = DmaChannelContext{physAddr:pa, burstLen:bsz};
	 ctxMem.portA.request.put(BRAMRequest{write:True, responseOnWrite:False,address:channelId, datain:ctx});
      endmethod
      interface writeData = map(toPut,writeBuffers);
      interface writeReq  = map(mkPutWhenFalse, reqOutstanding);
      interface writeDone = map(mkGetWhenTrue, writeRespRec);
   endinterface

   interface Axi3WriteClient m_axi_write;
      method ActionValue#(Axi3WriteRequest#(6)) address if (stateReg == Loading);
	 let rv <- ctxMem.portA.response.get;
	 burstReg <= rv.burstLen;
	 let new_addr = rv.physAddr + ((zeroExtend(rv.burstLen)+1) << 3);
	 let upd_req = BRAMRequest{write:True, responseOnWrite:False, address:activeChan, 
				   datain:(DmaChannelContext{physAddr:new_addr,burstLen:rv.burstLen})};
	 ctxMem.portA.request.put(upd_req);
	 _when_ (writeBuffers[activeChan].highWater(zeroExtend(rv.burstLen)+1)) (reqOutstanding[activeChan]._write(False)); 
	 stateReg <= Busy;
	 return Axi3WriteRequest{address:rv.physAddr, burstLen:rv.burstLen, id:1};
      endmethod
      method ActionValue#(Axi3WriteData#(64, 8, 6)) data if (stateReg == Busy);
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
