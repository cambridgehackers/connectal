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
import GetPutF::*;
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
   Bit#(6)  tag;
   } DMAAddressRequest deriving (Bits);
typedef struct {
   Bit#(dsz) data;
   Bit#(6) tag;
   } DMAData#(numeric type dsz) deriving (Bits);

interface DMAReadClient#(numeric type dsz);
   interface GetF#(DMAAddressRequest)    readReq;
   interface PutF#(DMAData#(dsz)) readData;
endinterface

interface DMAWriteClient#(numeric type dsz);
   interface GetF#(DMAAddressRequest)    writeReq;
   interface GetF#(DMAData#(dsz)) writeData;
   interface PutF#(Bit#(6))       writeDone;
endinterface

interface DMAReadServer#(numeric type dsz);
   interface PutF#(DMAAddressRequest) readReq;
   interface GetF#(DMAData#(dsz))     readData;
endinterface

interface DMAWriteServer#(numeric type dsz);
   interface PutF#(DMAAddressRequest) writeReq;
   interface PutF#(DMAData#(dsz))     writeData;
   interface GetF#(Bit#(6))           writeDone;
endinterface

interface DMARead;
   method ActionValue#(DmaDbgRec) dbg();
endinterface

interface DMAWrite;
   method ActionValue#(DmaDbgRec) dbg();
endinterface

