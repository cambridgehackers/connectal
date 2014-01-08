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

package PortalMemory;

import GetPut::*;
import Vector::*;

//
// DMA channel type
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
// @brief Events sent from a DMA engine
//
interface DMAIndication;
   method Action reportStateDbg(DmaDbgRec rec);
   method Action sglistResp(Bit#(32) pref, Bit#(32) idx);
   method Action parefResp(Bit#(32) v);
   method Action sglistEntry(Bit#(64) physAddr);
   method Action badHandle(Bit#(32) handle, Bit#(32) address);
   method Action badAddr(Bit#(32) handle, Bit#(32) address);
endinterface

//
// @brief Configuration interface to DMA engine
//
interface DMARequest;

   //
   // @brief Requests debug info for the specified channel type
   //
   method Action getStateDbg(ChannelType rc);

   //
   // @brief Adds an address translation entry to the scatter-gather list for an object
   //
   // @param pref Specifies the object to be translated
   // @param addr Physical address of the segment
   // @param len Length of the segment
   //
   // @note Only implemented for hardware
   method Action sglist(Bit#(32) pref, Bit#(40) addr, Bit#(32) len);

   //
   // @brief Maps the indicated object to remote software, e.g. bluesim
   //
   // @param pref Specifies the object to be map
   // @param size Number of bytes of the object to map
   //
   // @note Only implemented for software 
   method Action paref(Bit#(32) pref, Bit#(32) size);

   method Action readSglist(ChannelType rc, Bit#(32) pref, Bit#(32) addr);
endinterface

//
// @brief Instances of type class PortalMemory implement sglist and paref methods
//
typeclass PortalMemory#(type a);
endtypeclass

//
// @brief DMARequest implements sglist()
//
instance PortalMemory#(DMARequest);
endinstance

endpackage