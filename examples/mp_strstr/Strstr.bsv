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
import Vector::*;

import AxiClientServer::*;
import AxiRDMA::*;
import BsimRDMA::*;
import PortalMemory::*;
import PortalRMemory::*;


interface CoreRequest;
   method Action search();
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
typedef Vector#(8,Char) DWord;

module mkStrstrRequest#(StrstrIndication indication)(StrstrRequest);
   
`ifdef BSIM
   BsimDMA#(DWord)  dma <- mkBsimDMA(indication.dmaIndication);
`else
   AxiDMA#(DWord)   dma <- mkAxiDMA(indication.dmaIndication);
`endif

   ReadChan#(DWord)   haystack_read_chan = dma.read.readChannels[0];
   ReadChan#(DWord)     needle_read_chan = dma.read.readChannels[1];
   
   interface CoreRequest coreRequest;
      method Action search();
	 indication.coreIndication.searchResult(-1);
      endmethod
   endinterface
`ifndef BSIM
   interface Axi3Client m_axi = dma.m_axi;
`endif
   interface DMARequest dmaRequest = dma.request;
endmodule
