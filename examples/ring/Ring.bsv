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
import BRAMFIFO::*;
import GetPut::*;

import AxiClientServer::*;
import AxiRDMA::*;
import BsimRDMA::*;
import PortalMemory::*;
import PortalRMemory::*;

import RingBuffer::*;


typedef struct{
   Bit#(32) a;
   Bit#(32) b;
   } S0 deriving (Bits);

interface CoreRequest;
   method Action readWord(Bit#(40) addr);
   method Action writeWord(Bit#(40) addr, S0 data);
   method Action set(Bit#(1) cmd, Bit#(2) regist, Bit#(40) addr);
   method Action get(Bit#(1) cmd, Bit#(2) regist);
   method Action hwenable(Bit#(1) en);
endinterface

interface CoreIndication;
   method Action readWordResult(S0 v);
   method Action writeWordResult(S0 v);
   method Action setResult(Bit#(1) cmd, Bit#(2) regist, Bit#(40) addr);
   method Action getResult(Bit#(1) cmd, Bit#(2) regist, Bit#(40) addr);
endinterface

interface RingRequest;
   interface Axi3Client#(40,64,8,12) m_axi;
   interface CoreRequest coreRequest;
   interface DMARequest dmaRequest;
endinterface

interface RingIndication;
   interface CoreIndication coreIndication;
   interface DMAIndication dmaIndication;
endinterface

module mkRingRequest#(RingIndication indication)(RingRequest);
   
`ifdef BSIM
   BsimDMA#(S0)  dma <- mkBsimDMA(indication.dmaIndication);
`else
   AxiDMA#(S0)   dma <- mkAxiDMA(indication.dmaIndication);
`endif

   ReadChan#(S0)   dma_read_chan = dma.read.readChannels[0];
   WriteChan#(S0) dma_write_chan = dma.write.writeChannels[0];
   RingBuffer cmdRing <- mkRingBuffer;
   RingBuffer statusRing <- mkRingBuffer;
   Reg#(Bool) hwenabled <- mkReg(False);

   rule writeRule;
      let v <- dma_write_chan.writeDone.get;
      indication.coreIndication.writeWordResult(unpack(0));
   endrule

   rule readRule;
      let v <- dma_read_chan.readData.get;
      indication.coreIndication.readWordResult(v);
   endrule
   
   interface CoreRequest coreRequest;

   method Action set(Bit#(1) cmd, Bit#(2) regist, Bit#(40) addr);
     if (cmd == 1)
       cmdRing.set(regist, addr);
     else
       statusRing.set(regist, addr);
     indication.coreIndication.setResult(cmd, regist, addr);
   endmethod

   method Action get(Bit#(1) cmd, Bit#(2) regist);
     if (cmd == 1)
       indication.coreIndication.getResult(1, regist, cmdRing.get(regist));
     else
       indication.coreIndication.getResult(0, regist, statusRing.get(regist));
   endmethod

   method Action hwenable(Bit#(1) en);
     hwenabled <= en == 1;
     endmethod

      method Action readWord(Bit#(40) addr);
	 dma_read_chan.readReq.put(addr);
      endmethod

      method Action writeWord(Bit#(40) addr, S0 data);
	 dma_write_chan.writeReq.put(addr);
	 dma_write_chan.writeData.put(data);
      endmethod  
       
   endinterface

`ifndef BSIM
   interface Axi3Client m_axi = dma.m_axi;
`endif
   interface DMARequest dmaRequest = dma.request;
endmodule