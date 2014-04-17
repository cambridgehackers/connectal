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

typedef enum {CompleteBursts} CompleteBursts;
typedef enum {IncompleteBursts} IncompleteBursts;

typeclass DmaDescriptor#(type a);
endtypeclass

instance DmaDescriptor#(CompleteBursts);
endinstance

instance DmaDescriptor#(IncompleteBursts);
endinstance

///////////////////////////////////////////////////////////////////////////////////
// 

typedef ObjectReadClientConfig#(CompleteBursts, dsz)  ObjectReadClient#(numeric type dsz);
typedef ObjectWriteClientConfig#(CompleteBursts, dsz) ObjectWriteClient#(numeric type dsz);
typedef ObjectReadServerConfig#(CompleteBursts, dsz)  ObjectReadServer#(numeric type dsz);
typedef ObjectWriteServerConfig#(CompleteBursts, dsz) ObjectWriteServer#(numeric type dsz);
			     
interface ObjectReadClientConfig#(type desc, numeric type dsz);
   interface Get#(ObjectRequest)    readReq;
   interface Put#(ObjectData#(dsz)) readData;
endinterface

interface ObjectWriteClientConfig#(type desc, numeric type dsz);
   interface Get#(ObjectRequest)    writeReq;
   interface Get#(ObjectData#(dsz)) writeData;
   interface Put#(Bit#(6))       writeDone;
endinterface

interface ObjectReadServerConfig#(type desc, numeric type dsz);
   interface Put#(ObjectRequest) readReq;
   interface Get#(ObjectData#(dsz))     readData;
endinterface

interface ObjectWriteServerConfig#(type desc, numeric type dsz);
   interface Put#(ObjectRequest) writeReq;
   interface Put#(ObjectData#(dsz))     writeData;
   interface Get#(Bit#(6))           writeDone;
endinterface

//
///////////////////////////////////////////////////////////////////////////////////
// 

typedef MemReadClientConfig#(CompleteBursts, asz, dsz)  MemReadClient#(numeric type asz, numeric type dsz);
typedef MemWriteClientConfig#(CompleteBursts, asz, dsz) MemWriteClient#(numeric type asz, numeric type dsz);
typedef MemReadServerConfig#(CompleteBursts, asz, dsz)  MemReadServer#(numeric type asz, numeric type dsz);
typedef MemWriteServerConfig#(CompleteBursts, asz, dsz) MemWriteServer#(numeric type asz, numeric type dsz);
			     
interface MemSlave#(numeric type addrWidth, numeric type dataWidth);
   interface MemReadServer#(addrWidth, dataWidth) read_server;
   interface MemWriteServer#(addrWidth, dataWidth) write_server; 
endinterface

interface MemMaster#(numeric type addrWidth, numeric type dataWidth);
   interface MemReadClient#(addrWidth, dataWidth) read_client;
   interface MemWriteClient#(addrWidth, dataWidth) write_client; 
endinterface

interface MemReadClientConfig#(type desc, numeric type asz, numeric type dsz);
   interface Get#(MemRequest#(asz))    readReq;
   interface Put#(MemData#(dsz)) readData;
endinterface

interface MemWriteClientConfig#(type desc, numeric type asz, numeric type dsz);
   interface Get#(MemRequest#(asz))    writeReq;
   interface Get#(MemData#(dsz)) writeData;
   interface Put#(Bit#(6))       writeDone;
endinterface

interface MemReadServerConfig#(type desc, numeric type asz, numeric type dsz);
   interface Put#(MemRequest#(asz)) readReq;
   interface Get#(MemData#(dsz))     readData;
endinterface

interface MemWriteServerConfig#(type desc, numeric type asz, numeric type dsz);
   interface Put#(MemRequest#(asz)) writeReq;
   interface Put#(MemData#(dsz))     writeData;
   interface Get#(Bit#(6))           writeDone;
endinterface

//
///////////////////////////////////////////////////////////////////////////////////

interface DmaDbg;
   method ActionValue#(Bit#(64)) getMemoryTraffic(Bit#(32) client);
   method ActionValue#(DmaDbgRec) dbg();
endinterface


instance Connectable#(ObjectReadClientConfig#(desc,dsz), ObjectReadServerConfig#(desc,dsz));
   module mkConnection#(ObjectReadClientConfig#(desc,dsz) source, ObjectReadServerConfig#(desc,dsz) sink)(Empty);
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

instance Connectable#(ObjectWriteClientConfig#(desc,dsz), ObjectWriteServerConfig#(desc,dsz));
   module mkConnection#(ObjectWriteClientConfig#(desc,dsz) source, ObjectWriteServerConfig#(desc,dsz) sink)(Empty);
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
