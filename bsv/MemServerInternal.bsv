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
import FIFO::*;
import Vector::*;
import GetPut::*;
import ClientServer::*;
import Assert::*;

// XBSV Libraries
import Dma::*;
import PortalMemory::*;
import SGList::*;

typedef enum {InOrderCompletion} InOrderCompletion;
typedef enum {OutOfOrderCompletion} OutOfOrderCompletion;		 

interface MemWriteInternal#(type desc, numeric type addrWidth, numeric type dataWidth);
   interface DmaDbg dbg;
   interface MemWriteClient#(addrWidth,dataWidth) write_client;
endinterface

interface MemReadInternal#(type desc, numeric type addrWidth, numeric type dataWidth);
   interface DmaDbg dbg;
   interface MemReadClient#(addrWidth,dataWidth) read_client;
endinterface

typeclass MemServerInternals#(type desc, numeric type addrWidth, numeric type dataWidth);
   module mkMemReadInternal#(Vector#(numReadClients, ObjectReadClient#(dataWidth)) readClients, DmaIndication dmaIndication,Server#(Tuple2#(SGListId,Bit#(ObjectOffsetSize)),Bit#(addrWidth)) sgl) (MemReadInternal#(desc, addrWidth, dataWidth));
   module mkMemWriteInternal#(Vector#(numWriteClients, ObjectWriteClient#(dataWidth)) writeClients,DmaIndication dmaIndication,Server#(Tuple2#(SGListId,Bit#(ObjectOffsetSize)),Bit#(addrWidth)) sgl) (MemWriteInternal#(desc, addrWidth, dataWidth));
endtypeclass

function Bool bad_pointer(ObjectPointer p);
   return (p > fromInteger(valueOf(MaxNumSGLists)) || p == 0);
endfunction
		 
typedef struct {ObjectRequest req;
		Bit#(addrWidth) pa;
		Bit#(6) chan; } IRec#(numeric type addrWidth) deriving(Bits);
