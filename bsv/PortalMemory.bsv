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

typedef enum {
   Read, Write
   } ChannelType deriving (Bits,Eq);

typedef 4 NumDmaChannels;
typedef Bit#(TLog#(NumDmaChannels)) DmaChannelId;

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
   method Action configChan(ChannelType rc, Bit#(32) channelId, Bit#(32) pref, Bit#(32) bsz);
   method Action getStateDbg(ChannelType rc);
   method Action sglist(Bit#(32) pref, Bit#(40) addr, Bit#(32) len);
   method Action paref(Bit#(32) pref, Bit#(32) size);
endinterface

typeclass PortalMemory#(type a);
endtypeclass

instance PortalMemory#(DMARequest);
endinstance