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


import AxiClientServer::*;
import Vector::*;
import Leds::*;

interface Portal#(numeric type portalAddrBits, 
		  numeric type slaveBusAddrWidth, 
		  numeric type slaveBusDataWidth, 
		  numeric type slaveBusDataWidthBytes, 
		  numeric type slaveBusIdWidth);
   
   method Bit#(32) ifcId();
   method Bit#(32) ifcType();
   interface Axi3Server#(slaveBusAddrWidth,slaveBusDataWidth,slaveBusDataWidthBytes,slaveBusIdWidth) ctrl;
   interface ReadOnly#(Bool) interrupt;

endinterface


function ReadOnly#(Bool) getInterrupt(Portal#(_n,_a,_b,_c,_d) p);
   return p.interrupt;
endfunction

function Axi3Server#(_a,_b,_c,_d) getCtrl(Portal#(_n,_a,_b,_c,_d) p);
   return p.ctrl;
endfunction

typedef Axi3Server#(40,64,8,12) StdAxi3Server;
typedef Axi3Client#(40,64,8,12) StdAxi3Client;
typedef Portal#(16,32,32,4,12) StdPortal;

interface PortalTop#(numeric type nmasters, numeric type dataWidth, type pins);
   interface Axi3Server#(32,32,4,12) ctrl;
   interface Vector#(nmasters, Axi3Client#(40,dataWidth,TDiv#(dataWidth,8),12)) m_axi;
   interface ReadOnly#(Bool)  interrupt;
   interface LEDS             leds;
   interface pins             pins;
endinterface

interface PortalDmaTop#(type pins);
   interface Axi3Server#(32,32,4,12) ctrl;
   interface StdAxi3Client    m_axi;
   interface ReadOnly#(Bool)  interrupt;
   interface LEDS             leds;
   interface pins             pins;
endinterface

typedef PortalTop#(0,64,Empty)     StdPortalTop;
typedef PortalTop#(1,64,Empty)     StdPortalDmaTop;
