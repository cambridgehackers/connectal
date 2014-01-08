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


// BSV Libraries
import FIFOF::*;
import Adapter::*;
import GetPut::*;
import Vector::*;
import ClientServer::*;
import BRAMFIFO::*;

// XBSV Libraries
import PortalMemory::*;
import BRAMFIFOFLevel::*;

typedef Bit#(32) DmaMemHandle;

typedef 24 DmaAddrSize;
// SGListMaxPages is derived from this

typedef struct {
   DmaMemHandle handle;
   Bit#(DmaAddrSize)  address;
   Bit#(8) burstLen;
   Bit#(8)  tag;
   } DMAAddressRequest deriving (Bits);
typedef struct {
   Bit#(dsz) data;
   Bit#(8) tag;
   } DMAData#(numeric type dsz) deriving (Bits);

interface DMAReadClient#(numeric type dsz);
   interface Get#(DMAAddressRequest)    readReq;
   interface Put#(DMAData#(dsz)) readData;
endinterface

interface DMAWriteClient#(numeric type dsz);
   interface Get#(DMAAddressRequest)    writeReq;
   interface Get#(DMAData#(dsz)) writeData;
   interface Put#(Bit#(8))       writeDone;
endinterface

interface DMAReadServer#(numeric type dsz);
   interface Put#(DMAAddressRequest) readReq;
   interface Get#(DMAData#(dsz))     readData;
endinterface

interface DMAWriteServer#(numeric type dsz);
   interface Put#(DMAAddressRequest) writeReq;
   interface Put#(DMAData#(dsz))     writeData;
   interface Get#(Bit#(8))           writeDone;
endinterface

//
// @brief A buffer for reading from a bus of width bsz.
//
// @param bsz The number of bits in the bus.
// @param maxBurst The number of words to buffer
//
interface DMAReadBuffer#(numeric type bsz, numeric type maxBurst);
   interface DMAReadServer #(bsz) dmaServer;
   interface DMAReadClient#(bsz) dmaClient;
endinterface

//
// @brief A buffer for writing to a bus of width bsz.
//
// @param bsz The number of bits in the bus.
// @param maxBurst The number of words to buffer
//
interface DMAWriteBuffer#(numeric type bsz, numeric type maxBurst);
   interface DMAWriteServer#(bsz) dmaServer;
   interface DMAWriteClient#(bsz) dmaClient;
endinterface

//
// @brief Makes a DMA buffer for reading wordSize words from memory.
//
// @param dsz The width of the bus in bits.
// @param maxBurst The max number of words to transfer per request.
//
module mkDMAReadBuffer(DMAReadBuffer#(dsz, maxBurst))
   provisos(Add#(1,a__,dsz),
	    Add#(b__, TAdd#(1, TLog#(maxBurst)), 8));

   FIFOFLevel#(DMAData#(dsz),maxBurst) readBuffer <- mkBRAMFIFOFLevel;
   FIFOF#(DMAAddressRequest)       reqOutstanding <- mkFIFOF();

   interface DMAReadServer dmaServer;
      interface Put readReq = toPut(reqOutstanding);
      interface Get readData = toGet(readBuffer);
   endinterface
   interface DMAReadClient dmaClient;
      // only issue the readRequest when sufficient buffering is available
      interface Get readReq;
	 method ActionValue#(DMAAddressRequest) get if (readBuffer.lowWater(truncate(reqOutstanding.first.burstLen)));
	    reqOutstanding.deq;
	    return reqOutstanding.first;
	 endmethod
      endinterface
      interface Put readData = toPut(readBuffer);
   endinterface
endmodule

//
// @brief Makes a DMA channel for writing wordSize words from memory.
//
// @param bsz The width of the bus in bits.
// @param maxBurst The max number of words to transfer per request.
//
module mkDMAWriteBuffer(DMAWriteBuffer#(bsz, maxBurst))
   provisos(Add#(1,a__,bsz),
	    Add#(b__, TAdd#(1, TLog#(maxBurst)), 8));

   FIFOFLevel#(DMAData#(bsz),maxBurst) writeBuffer <- mkBRAMFIFOFLevel;
   FIFOF#(DMAAddressRequest)        reqOutstanding <- mkFIFOF();
   FIFOF#(Bit#(8))                        doneTags <- mkFIFOF();

   interface DMAWriteServer dmaServer;
      interface Put writeReq = toPut(reqOutstanding);
      interface Put writeData = toPut(writeBuffer);
      interface Get writeDone = toGet(doneTags);
   endinterface
   interface DMAWriteClient dmaClient;
      // only issue the writeRequest when sufficient data has been buffered
      interface Get writeReq;
	 method ActionValue#(DMAAddressRequest) get if (writeBuffer.highWater(truncate(reqOutstanding.first.burstLen)));
	    reqOutstanding.deq;
	    return reqOutstanding.first;
	 endmethod
      endinterface
      interface Get writeData = toGet(writeBuffer);
      interface Put writeDone = toPut(doneTags);
   endinterface
endmodule

interface DMARead;
   method ActionValue#(DmaDbgRec) dbg();
endinterface

interface DMAWrite;
   method ActionValue#(DmaDbgRec) dbg();
endinterface

