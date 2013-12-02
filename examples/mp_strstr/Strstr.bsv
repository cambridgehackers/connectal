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
import GetPut::*;
import Vector::*;
import BRAM::*;
import Gearbox::*;

import AxiClientServer::*;
import AxiSDMA::*;
import BsimSDMA::*;
import PortalMemory::*;
import PortalSMemory::*;
import PortalSMemoryUtils::*;

interface CoreRequest;
   method Action search(Bit#(32) needle_len, Bit#(32) haystack_len);
endinterface

interface CoreIndication;
   method Action searchResult(Int#(32) v);
endinterface

interface StrstrRequest;
   interface Axi3Client#(40,64,8,12) m_axi;
   interface CoreRequest coreRequest;
   interface DMARequest dmaRequest;
endinterface

interface StrstrIndication;
   interface CoreIndication coreIndication;
   interface DMAIndication dmaIndication;
endinterface

typedef Bit#(8) Char;
typedef Bit#(64) DWord;
typedef Bit#(32) Word;

typedef 1024 MaxNeedleLen;
typedef Bit#(TLog#(MaxNeedleLen)) NeedleIdx;

typedef enum {Idle, Init, Run} Stage deriving (Eq, Bits);

module mkStrstrRequest#(StrstrIndication indication)(StrstrRequest);
   
`ifdef BSIM
   BsimDMA  dma <- mkBsimDMA(indication.dmaIndication);
`else
   AxiDMA   dma <- mkAxiDMA(indication.dmaIndication);
`endif

   ReadChan   haystack_read_chan = dma.read.readChannels[0];
   ReadChan     needle_read_chan = dma.read.readChannels[1];
   ReadChan    mp_next_read_chan = dma.read.readChannels[2];
   
   Clock clk <- exposeCurrentClock;
   Reset rst <- exposeCurrentReset;
   BRAM1Port#(NeedleIdx, Char) needle  <- mkBRAM1Server(defaultValue);
   BRAM1Port#(NeedleIdx, Bit#(32)) mpNext <- mkBRAM1Server(defaultValue);
   Gearbox#(8,1,Char) haystack <- mkNto1Gearbox(clk,rst,clk,rst);
   
   Reg#(Stage) stage <- mkReg(Idle);
   Reg#(Bit#(32)) needleLenReg <- mkReg(0);
   Reg#(Bit#(32)) haystackLenReg <- mkReg(0);
   Reg#(Bit#(32)) i <- mkReg(0);
   Reg#(Bit#(32)) j <- mkReg(0);
   
   ReadChan2BRAM#(NeedleIdx) n2b <- mkReadChan2BRAM(needle_read_chan, needle);
   ReadChan2BRAM#(NeedleIdx) mp2b <- mkReadChan2BRAM(mp_next_read_chan, mpNext);

   Reg#(Bit#(2)) epoch <- mkReg(0);
   FIFOF#(Bit#(2)) efifo <- mkSizedFIFOF(2);
   
   rule start;
      let x <- n2b.finished;
      let y <- mp2b.finished;
      stage <= Run;
      i <= 0;
      j <= 0;
   endrule
   
   rule haystackReq(stage == Run);
      haystack_read_chan.readReq.put(?);
   endrule
   
   rule haystackResp;
      let rv <- haystack_read_chan.readData.get;
      Vector#(8,Char) pv = unpack(rv);
      haystack.enq(pv);
   endrule

   rule haystackDrain(stage != Run);
      haystack.deq;
   endrule
 
   rule matchNeedleReq(stage == Run);
      needle.portA.request.put(BRAMRequest{write:False, address:truncate(i)});
      mpNext.portA.request.put(BRAMRequest{write:False, address:truncate(i+1)});
      efifo.enq(epoch);
      i <= i+1;
   endrule
   
   rule matchNeedleResp(stage == Run);
      let m = haystackLenReg;
      let nv <- needle.portA.response.get;
      let mp <- mpNext.portA.response.get;
      let hv = haystack.first;
      efifo.deq;
      if (efifo.first == epoch) begin
	 if (i==m+1) begin
	    indication.coreIndication.searchResult(unpack(j)-1);
	 end
	 else if ((i==m+1) || ((i>0) && (nv != hv[0]))) begin
	    epoch <= epoch+1;
	    i <= mp;
	 end
	 else begin
	    j <= j+1;
	    haystack.deq;
	 end
      end
   endrule
   
   interface CoreRequest coreRequest;
      method Action search(Bit#(32) needle_len, Bit#(32) haystack_len) if (stage == Idle);
	 needleLenReg <= needle_len;
	 haystackLenReg <= haystack_len;
	 n2b.start(pack(truncate(needle_len)));
	 mp2b.start(pack(truncate(needle_len)));
	 stage <= Init;
      endmethod
   endinterface
`ifndef BSIM
   interface Axi3Client m_axi = dma.m_axi;
`endif
   interface DMARequest dmaRequest = dma.request;
endmodule
