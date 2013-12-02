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
import SpecialFIFOs::*;
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
   Reg#(Bit#(32)) iReg <- mkReg(0);
   Reg#(Bit#(32)) jReg <- mkReg(0);
   
   ReadChan2BRAM#(NeedleIdx) n2b <- mkReadChan2BRAM(needle_read_chan, needle);
   ReadChan2BRAM#(NeedleIdx) mp2b <- mkReadChan2BRAM(mp_next_read_chan, mpNext);

   Reg#(Bit#(2)) epochReg <- mkReg(0);
   FIFO#(Tuple2#(Bit#(2),Bit#(32))) efifo <- mkSizedFIFO(2);
   Reg#(Bit#(32)) cycle <- mkReg(0);
   
   rule start (stage == Init);
      let x <- n2b.finished;
      let y <- mp2b.finished;
      stage <= Run;
      iReg <= 1;
      jReg <= 1;
   endrule

   (* descending_urgency = "mp2b_load, n2b_load, matchNeedleResp, matchNeedleReq" *)
   
   rule haystackReq (stage == Run);
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
      needle.portA.request.put(BRAMRequest{write:False, address:truncate(iReg-1)});
      mpNext.portA.request.put(BRAMRequest{write:False, address:truncate(iReg)});
      efifo.enq(tuple2(epochReg,iReg));
      iReg <= iReg+1;
   endrule
   
   rule hb (stage==Run);
      $display("cycle %h", cycle);
      cycle <= cycle+1;
   endrule
   
   rule matchNeedleResp(stage == Run);
      let n = haystackLenReg;
      let m = needleLenReg;
      let nv <- needle.portA.response.get;
      let mp <- mpNext.portA.response.get;
      let hv = haystack.first;
      let epoch = tpl_1(efifo.first);
      let i = tpl_2(efifo.first);
      let j = jReg;
      efifo.deq;
      if (epoch == epochReg) begin
	 if (j > n) begin
	    indication.coreIndication.searchResult(-1);
	    $display("no match found");
	 end
	 else if (i==m+1) begin
	    $display("string match %d", j);
	    indication.coreIndication.searchResult(unpack(j-i));
	    stage <= Idle;
	 end
	 else if ((i==m+1) || ((i>0) && (nv != hv[0]))) begin
	    epochReg <= epochReg + 1;
	    iReg <= mp;
	    $display("char mismatch %d %d MP_Next[i]=%d", i, j, mp);
	 end
	 else begin
	    $display("   char match %d %d", i, j);
	    jReg <= j+1;
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
