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
import Vector::*;
import Connectable::*;
import BRAMFIFO::*;
import GetPut::*;

// XBSV Libraries
import PortalMemory::*;
import BRAMFIFOFLevel::*;

typedef Bit#(32) ObjectPointer;
typedef 40 ObjectOffsetSize;


typedef struct {
   Bit#(addrWidth) addr;
   Bit#(8) burstLen;
   Bit#(6) tag;
   } MemRequest#(numeric type addrWidth) deriving (Bits);
typedef struct {
   ObjectPointer pointer;
   Bit#(ObjectOffsetSize) offset;
   Bit#(8) burstLen;
   Bit#(6)  tag;
   } ObjectRequest deriving (Bits);
typedef struct {
   Bit#(dsz) data;
   Bit#(6) tag;
   } ObjectData#(numeric type dsz) deriving (Bits);
typedef ObjectData#(dsz) MemData#(numeric type dsz);

///////////////////////////////////////////////////////////////////////////////////
// 

			     
interface ObjectReadClient#(numeric type dsz);
   interface Get#(ObjectRequest)    readReq;
   interface Put#(ObjectData#(dsz)) readData;
endinterface

interface ObjectWriteClient#(numeric type dsz);
   interface Get#(ObjectRequest)    writeReq;
   interface Get#(ObjectData#(dsz)) writeData;
   interface Put#(Bit#(6))       writeDone;
endinterface

interface ObjectReadServer#(numeric type dsz);
   interface Put#(ObjectRequest) readReq;
   interface Get#(ObjectData#(dsz))     readData;
endinterface

interface ObjectWriteServer#(numeric type dsz);
   interface Put#(ObjectRequest) writeReq;
   interface Put#(ObjectData#(dsz))     writeData;
   interface Get#(Bit#(6))           writeDone;
endinterface

//
///////////////////////////////////////////////////////////////////////////////////
// 

interface MemSlave#(numeric type addrWidth, numeric type dataWidth);
   interface MemReadServer#(addrWidth, dataWidth) read_server;
   interface MemWriteServer#(addrWidth, dataWidth) write_server; 
endinterface

interface MemMaster#(numeric type addrWidth, numeric type dataWidth);
   interface MemReadClient#(addrWidth, dataWidth) read_client;
   interface MemWriteClient#(addrWidth, dataWidth) write_client; 
endinterface

interface MemReadClient#(numeric type asz, numeric type dsz);
   interface Get#(MemRequest#(asz))    readReq;
   interface Put#(MemData#(dsz)) readData;
endinterface

interface MemWriteClient#(numeric type asz, numeric type dsz);
   interface Get#(MemRequest#(asz))    writeReq;
   interface Get#(MemData#(dsz)) writeData;
   interface Put#(Bit#(6))       writeDone;
endinterface

interface MemReadServer#(numeric type asz, numeric type dsz);
   interface Put#(MemRequest#(asz)) readReq;
   interface Get#(MemData#(dsz))     readData;
endinterface

interface MemWriteServer#(numeric type asz, numeric type dsz);
   interface Put#(MemRequest#(asz)) writeReq;
   interface Put#(MemData#(dsz))     writeData;
   interface Get#(Bit#(6))           writeDone;
endinterface

//
///////////////////////////////////////////////////////////////////////////////////

interface DmaDbg;
   method ActionValue#(Bit#(64)) getMemoryTraffic();
   method ActionValue#(DmaDbgRec) dbg();
endinterface


instance Connectable#(ObjectReadClient#(dsz), ObjectReadServer#(dsz));
   module mkConnection#(ObjectReadClient#(dsz) source, ObjectReadServer#(dsz) sink)(Empty);
      rule request;
	 let req <- source.readReq.get();
	 sink.readReq.put(req);
      endrule
      rule response;
	 let resp <- sink.readData.get();
	 source.readData.put(resp);
      endrule
   endmodule
endinstance

instance Connectable#(ObjectWriteClient#(dsz), ObjectWriteServer#(dsz));
   module mkConnection#(ObjectWriteClient#(dsz) source, ObjectWriteServer#(dsz) sink)(Empty);
      rule request;
	 let req <- source.writeReq.get();
	 sink.writeReq.put(req);
      endrule
      rule response;
	 let resp <- source.writeData.get();
	 sink.writeData.put(resp);
      endrule
      rule done;
	 let resp <- sink.writeDone.get();
	 source.writeDone.put(resp);
      endrule
   endmodule
endinstance
