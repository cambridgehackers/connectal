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

//
// Dma channel type
//
typedef enum {
   Read, Write
   } ChannelType deriving (Bits,Eq,FShow);

//
// @brief Channel Identifier
//
typedef Bit#(16) DmaChannelId;

typedef struct {
   Bit#(32) x;
   Bit#(32) y;
   Bit#(32) z;
   Bit#(32) w;
   } DmaDbgRec deriving(Bits);

//
// @brief Events sent from a Dma engine
//
interface DmaIndication;
   method Action configResp(Bit#(32) pointer, Bit#(40) msg);
   method Action addrResponse(Bit#(64) physAddr);
   method Action badPointer(Bit#(32) pointer);
   method Action badAddrTrans(Bit#(32) pointer, Bit#(64) offset, Bit#(40) barrier);
   method Action badPageSize(Bit#(32) pointer, Bit#(32) sz);
   method Action badNumberEntries(Bit#(32) pointer, Bit#(32) sz, Bit#(32) idx);
   method Action badAddr(Bit#(32) pointer, Bit#(40) offset, Bit#(64) physAddr);
   method Action reportStateDbg(DmaDbgRec rec);
   method Action reportMemoryTraffic(Bit#(64) words);
   method Action tagMismatch(ChannelType x, Bit#(32) a, Bit#(32) b);
endinterface

//
// @brief Configuration interface to Dma engine
//
interface DmaConfig;
   //
   // @brief Adds an address translation entry to the scatter-gather list for an object
   //
   // @param pointer Specifies the object to be translated
   // @param addr Physical address of the segment
   // @param len Length of the segment
   //
   method Action sglist(Bit#(32) pointer, Bit#(40) addr, Bit#(32) len);
   method Action region(Bit#(32) pointer, Bit#(40) barr8, Bit#(8) off8, Bit#(40) barr4, Bit#(8) off4, Bit#(40) barr0, Bit#(8) off0);
   method Action addrRequest(Bit#(32) pointer, Bit#(32) offset);
   //
   // @brief Requests debug info for the specified channel type
   //
   method Action getStateDbg(ChannelType rc);
   method Action getMemoryTraffic(ChannelType rc);
endinterface

//
// @brief Instances of type class PortalMemory implement the sglist method
//
typeclass PortalMemory#(type a);
endtypeclass

//
// @brief DmaConfig implements sglist()
//
instance PortalMemory#(DmaConfig);
endinstance

