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
//typedef Bit#(16) DmaChannelId;

typedef struct {
   Bit#(32) x;
   Bit#(32) y;
   Bit#(32) z;
   Bit#(32) w;
   } DmaDbgRec deriving(Bits);

typedef enum {
   DmaErrorNone,
   //DmaErrorAddrResponse,
   DmaErrorBadPointer1,
   DmaErrorBadPointer2,
   DmaErrorBadPointer3,
   DmaErrorBadPointer4,
   DmaErrorBadPointer5,
   DmaErrorBadAddrTrans,
   DmaErrorBadPageSize,
   DmaErrorBadNumberEntries,
   DmaErrorBadAddr,
   DmaErrorTagMismatch
   } DmaErrorType deriving (Bits);

//
// @brief Events sent from a Dma engine
//
interface DmaDebugIndication;
   method Action addrResponse(Bit#(64) physAddr);
   method Action reportStateDbg(DmaDbgRec rec);
   method Action reportMemoryTraffic(Bit#(64) words);
   method Action error(Bit#(32) code, Bit#(32) pointer, Bit#(64) offset, Bit#(64) extra);
endinterface

//
// @brief Events sent from a MMU
//
interface MMUConfigIndication;
   method Action idResponse(Bit#(32) sglId);
   method Action configResp(Bit#(32) pointer);
   method Action error(Bit#(32) code, Bit#(32) pointer, Bit#(64) offset, Bit#(64) extra);
endinterface

//
// @brief Configuration interface to an MMU
//
interface MMUConfigRequest;
   //
   // @brief Adds an address translation entry to the scatter-gather list for an object
   //
   // @param pointer Specifies the object to be translated
   // @param addr Physical address of the segment
   // @param len Length of the segment
   //
   method Action sglist(Bit#(32) pointer, Bit#(32) pointerIndex, Bit#(64) addr,  Bit#(32) len);
   method Action region(Bit#(32) pointer, Bit#(64) barr8, Bit#(32) index8, Bit#(64) barr4, Bit#(32) index4, Bit#(64) barr0, Bit#(32) index0);
   method Action idRequest();
endinterface

//
// @brief Debug interface to Dma engine
//
interface DmaDebugRequest;
   //
   // @brief Requests an address translation
   //
   method Action addrRequest(Bit#(32) pointer, Bit#(32) offset);
   //
   // @brief Requests debug info for the specified channel type
   //
   method Action getStateDbg(ChannelType rc);
   method Action getMemoryTraffic(ChannelType rc);
endinterface
