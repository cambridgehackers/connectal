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
   ChannelType_Read, ChannelType_Write
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
   DmaErrorSGLIdOutOfRange_r,
   DmaErrorSGLIdOutOfRange_w,
   DmaErrorMMUOutOfRange_r,
   DmaErrorMMUOutOfRange_w,
   DmaErrorOffsetOutOfRange,
   DmaErrorSGLIdInvalid,
   DmaErrorTileTagOutOfRange
   } DmaErrorType deriving (Bits);

//
// @brief Events sent from a Dma engine
//
interface MemServerIndication;
   method Action addrResponse(Bit#(64) physAddr);
   method Action reportStateDbg(DmaDbgRec rec);
   method Action reportMemoryTraffic(Bit#(64) words);
   method Action error(Bit#(32) code, Bit#(32) sglId, Bit#(64) offset, Bit#(64) extra);
endinterface

//
// @brief Events sent from a MMU
//
interface MMUIndication;
   method Action idResponse(Bit#(32) sglId);
   method Action configResp(Bit#(32) sglId);
   method Action error(Bit#(32) code, Bit#(32) sglId, Bit#(64) offset, Bit#(64) extra);
endinterface

typedef Bit#(32) SpecialTypeForSendingFd;
//
// @brief Configuration interface to an MMU
//
interface MMURequest;
   //
   // @brief Adds an address translation entry to the scatter-gather list for an object
   //
   // @param sglId Specifies the object to be translated
   // @param addr Physical address of the segment
   // @param len Length of the segment
   //
   method Action sglist(Bit#(32) sglId, Bit#(32) sglIndex, Bit#(64) addr,  Bit#(32) len);
   method Action region(Bit#(32) sglId, Bit#(64) barr12, Bit#(32) index12, Bit#(64) barr8, Bit#(32) index8, Bit#(64) barr4, Bit#(32) index4, Bit#(64) barr0, Bit#(32) index0);
   method Action idRequest(SpecialTypeForSendingFd fd);
   method Action idReturn(Bit#(32) sglId);
   method Action setInterface(Bit#(32) interfaceId, Bit#(32) sglId);
endinterface

typedef enum {
   Idle, Stopped, Running
   } TileState deriving (Bits,Eq);

typedef struct {
   Bit#(2) tile;
   TileState state;
   } TileControl deriving (Bits);

//
// @brief Control interface to Dma engine
//
interface MemServerRequest;
   // @brief Requests an address translation
   //
   method Action addrTrans(Bit#(32) sglId, Bit#(32) offset);

   // @brief Changes tile status
   //
   method Action setTileState(TileControl tc);
   //
   // @brief Requests debug info for the specified channel type
   //
   method Action stateDbg(ChannelType rc);
   method Action memoryTraffic(ChannelType rc);
endinterface
