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

typeclass PortalMemory#(type a);
endtypeclass

///////////////////////////////////////////////////////////////////
// internal interfaces

function Put#(void) mkPutWhenFalse(Reg#(Bool) r);
   return (interface Put;
	      method Action put(void v);
		 _when_ (!r) (r._write(True));
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

// In the future, NumDmaChannels will be defined somehwere in the xbsv compiler output
typedef 2 NumDmaChannels;
typedef Bit#(TLog#(NumDmaChannels)) DmaChannelId;

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

///////////////////////////////////////////////////////////////////
// external interfaces

typedef struct {
   Bit#(32) x;
   Bit#(32) y;
   Bit#(32) z;
   Bit#(32) w;
   } DmaDbgRec deriving(Bits);

interface DMAIndication;
   method Action reportStateDbg(DmaDbgRec rec);
   method Action configResp(Bit#(32) channelId);
   method Action sglistResp(Bit#(32) v);
   method Action parefResp(Bit#(32) v);
endinterface

interface DMARequest;
   method Action configReadChan(Bit#(32) channelId, Bit#(32) pref, Bit#(32) bsz);
   method Action configWriteChan(Bit#(32) channelId, Bit#(32) pref, Bit#(32) bsz);
   method Action getReadStateDbg();
   method Action getWriteStateDbg();
   method Action sglist(Bit#(32) off, Bit#(40) addr, Bit#(32) len);
   method Action paref(Bit#(32) off, Bit#(32) pref);
endinterface

instance PortalMemory#(DMARequest);
endinstance