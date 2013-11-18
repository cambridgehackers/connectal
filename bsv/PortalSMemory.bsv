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

interface ReadChan;
   interface Get#(Bit#(64)) readData;
   interface Put#(void)     readReq;
endinterface

interface WriteChan;
   interface Put#(Bit#(64)) writeData;
   interface Put#(void)     writeReq;
   interface Get#(void)     writeDone;
endinterface

interface DMARead;
   method Action configChan(DmaChannelId channelId, Bit#(32) pref, Bit#(4) bsz);
   interface Vector#(NumDmaChannels, ReadChan) readChannels;
   method ActionValue#(DmaDbgRec) dbg();
endinterface

interface DMAWrite;
   method Action  configChan(DmaChannelId channelId, Bit#(32) pref, Bit#(4) bsz);   
   interface Vector#(NumDmaChannels, WriteChan) writeChannels;
   method ActionValue#(DmaDbgRec) dbg();
endinterface

