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


import GetPut::*;
import Vector::*;
import PortalMemory::*;

function ReadChan#(t) mkReadChan(Get#(t) rd, Put#(Bit#(40)) rr);
   return (interface ReadChan;
	      interface Get readData = rd;
	      interface Put readReq  = rr;
	   endinterface);
endfunction

function WriteChan#(t) mkWriteChan(Put#(t) wd, Put#(Bit#(40)) wr, Get#(void) d);
   return (interface WriteChan;
	      interface Put writeData = wd;
	      interface Put writeReq  = wr;
	      interface Get writeDone = d;
	   endinterface);
endfunction

interface ReadChan#(type t);
   interface Get#(t)        readData;
   interface Put#(Bit#(40)) readReq;
endinterface

interface WriteChan#(type t);
   interface Put#(t)        writeData;
   interface Put#(Bit#(40)) writeReq;
   interface Get#(void)     writeDone;
endinterface

interface DMARead#(type t);
   method Action configChan(DmaChannelId channelId, Bit#(32) pref);
   interface Vector#(NumDmaChannels, ReadChan#(t)) readChannels;
   method ActionValue#(DmaDbgRec) dbg();
endinterface

interface DMAWrite#(type t);
   method Action  configChan(DmaChannelId channelId, Bit#(32) pref);   
   interface Vector#(NumDmaChannels, WriteChan#(t)) writeChannels;
   method ActionValue#(DmaDbgRec) dbg();
endinterface

