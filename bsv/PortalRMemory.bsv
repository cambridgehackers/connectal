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

//
// @brief A channel for reading an object of type t from DRAM
//
//
// @param t The type of object to write.
//
// @note The size of t must be a multiple of 64 bits.
//
// Put the index of the next object desired to the readReq interface
//
// @param index The number of the next object to read
//
// The virtual address of the object will be 
//     base + index*objectsize
// where objectsize is in bytes and base is
// configured via the configChan method
//
// Get the object from the readData interface
//
interface ReadChan#(type t);
   //
   // Returns the next object
   //
   interface Put#(Bit#(40)) readReq;
   interface Get#(t)        readData;
endinterface

//
// @brief A channel for writing an object of type t to DRAM
//
// @param t The type of object to write.
//
// @note The size of t must be a multiple of 64 bits.
//
// Put the index of the next object desired to the writeReq interface
//
// @param index The number of the next object to write
//
// The virtual address of the object will be 
//     base + index*objectsize
// where objectsize is in bytes and base is
// configured via the configChan method
//
// Put the object to the writeData interface.
//
// Get a void value from the writeDone interface when the write has completed.
//
interface WriteChan#(type t);
   interface Put#(t)        writeData;
   interface Put#(Bit#(40)) writeReq;
   interface Get#(void)     writeDone;
endinterface

//
// @brief A DMA engine for reading objects of type t
//
// @param t The type of object to write.
//
// @note The size of t must be a multiple of 64 bits.
interface DMARead#(type t);

   //
   // @brief Configure a DMA read channel
   //
   // @param channelId The number of the channel to configure
   // @param pref The something
   method Action configChan(DmaChannelId channelId, Bit#(32) pref);
   interface Vector#(NumDmaChannels, ReadChan#(t)) readChannels;
   method ActionValue#(DmaDbgRec) dbg();
endinterface

//
// @brief A DMA engine for writing objects of type t
//
// @param t The type of object to write.
//
// @note The size of t must be a multiple of 64 bits.
interface DMAWrite#(type t);

   //
   // @brief Configure a DMA read channel
   //
   // @param channelId The number of the channel to configure
   // @param pref The something
   //
   method Action  configChan(DmaChannelId channelId, Bit#(32) pref);   

   interface Vector#(NumDmaChannels, WriteChan#(t)) writeChannels;
   method ActionValue#(DmaDbgRec) dbg();
endinterface

