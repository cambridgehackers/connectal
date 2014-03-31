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

typedef Bit#(32) DmaPointer;
typedef 40 DmaOffsetSize;


typedef struct {
   Bit#(addrWidth) paddr;
   Bit#(8) burstLen;
   Bit#(6) tag;
   } PhysicalRequest#(numeric type addrWidth) deriving (Bits);
typedef struct {
   DmaPointer pointer;
   Bit#(DmaOffsetSize) offset;
   Bit#(8) burstLen;
   Bit#(6)  tag;
   } DmaRequest deriving (Bits);
typedef struct {
   Bit#(dsz) data;
   Bit#(6) tag;
   } DmaData#(numeric type dsz) deriving (Bits);

typedef enum {CompleteBursts} CompleteBursts;
typedef enum {IncompleteBursts} IncompleteBursts;

typeclass DmaDescriptor#(type a);
endtypeclass

instance DmaDescriptor#(CompleteBursts);
endinstance

instance DmaDescriptor#(IncompleteBursts);
endinstance

///////////////////////////////////////////////////////////////////////////////////
// virtual addresses

typedef DmaReadClientConfig#(CompleteBursts, dsz)  DmaReadClient#(numeric type dsz);
typedef DmaWriteClientConfig#(CompleteBursts, dsz) DmaWriteClient#(numeric type dsz);
typedef DmaReadServerConfig#(CompleteBursts, dsz)  DmaReadServer#(numeric type dsz);
typedef DmaWriteServerConfig#(CompleteBursts, dsz) DmaWriteServer#(numeric type dsz);
			     
interface DmaReadClientConfig#(type desc, numeric type dsz);
   interface Get#(DmaRequest)    readReq;
   interface Put#(DmaData#(dsz)) readData;
endinterface

interface DmaWriteClientConfig#(type desc, numeric type dsz);
   interface Get#(DmaRequest)    writeReq;
   interface Get#(DmaData#(dsz)) writeData;
   interface Put#(Bit#(6))       writeDone;
endinterface

interface DmaReadServerConfig#(type desc, numeric type dsz);
   interface Put#(DmaRequest) readReq;
   interface Get#(DmaData#(dsz))     readData;
endinterface

interface DmaWriteServerConfig#(type desc, numeric type dsz);
   interface Put#(DmaRequest) writeReq;
   interface Put#(DmaData#(dsz))     writeData;
   interface Get#(Bit#(6))           writeDone;
endinterface

//
///////////////////////////////////////////////////////////////////////////////////
// physical addresses

typedef PhysicalReadClientConfig#(CompleteBursts, asz, dsz)  PhysicalReadClient#(numeric type asz, numeric type dsz);
typedef PhysicalWriteClientConfig#(CompleteBursts, asz, dsz) PhysicalWriteClient#(numeric type asz, numeric type dsz);
typedef PhysicalReadServerConfig#(CompleteBursts, asz, dsz)  PhysicalReadServer#(numeric type asz, numeric type dsz);
typedef PhysicalWriteServerConfig#(CompleteBursts, asz, dsz) PhysicalWriteServer#(numeric type asz, numeric type dsz);
			     
interface PhysicalDmaSlave#(numeric type addrWidth, numeric type dataWidth);
   interface PhysicalReadServer#(addrWidth, dataWidth) read_server;
   interface PhysicalWriteServer#(addrWidth, dataWidth) write_server; 
endinterface

interface PhysicalDmaMaster#(numeric type addrWidth, numeric type dataWidth);
   interface PhysicalReadClient#(addrWidth, dataWidth) read_client;
   interface PhysicalWriteClient#(addrWidth, dataWidth) write_client; 
endinterface

interface PhysicalReadClientConfig#(type desc, numeric type asz, numeric type dsz);
   interface Get#(PhysicalRequest#(asz))    readReq;
   interface Put#(DmaData#(dsz)) readData;
endinterface

interface PhysicalWriteClientConfig#(type desc, numeric type asz, numeric type dsz);
   interface Get#(PhysicalRequest#(asz))    writeReq;
   interface Get#(DmaData#(dsz)) writeData;
   interface Put#(Bit#(6))       writeDone;
endinterface

interface PhysicalReadServerConfig#(type desc, numeric type asz, numeric type dsz);
   interface Put#(PhysicalRequest#(asz)) readReq;
   interface Get#(DmaData#(dsz))     readData;
endinterface

interface PhysicalWriteServerConfig#(type desc, numeric type asz, numeric type dsz);
   interface Put#(PhysicalRequest#(asz)) writeReq;
   interface Put#(DmaData#(dsz))     writeData;
   interface Get#(Bit#(6))           writeDone;
endinterface


//
///////////////////////////////////////////////////////////////////////////////////

interface DmaDbg;
   method ActionValue#(Bit#(64)) getMemoryTraffic(Bit#(32) client);
   method ActionValue#(DmaDbgRec) dbg();
endinterface


instance Connectable#(DmaReadClientConfig#(desc,dsz), DmaReadServerConfig#(desc,dsz));
   module mkConnection#(DmaReadClientConfig#(desc,dsz) source, DmaReadServerConfig#(desc,dsz) sink)(Empty);
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

instance Connectable#(DmaWriteClientConfig#(desc,dsz), DmaWriteServerConfig#(desc,dsz));
   module mkConnection#(DmaWriteClientConfig#(desc,dsz) source, DmaWriteServerConfig#(desc,dsz) sink)(Empty);
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

function Put#(t) null_put();
   return (interface Put;
	      method Action put(t x) if (False);
		 noAction;
	      endmethod
	   endinterface);
endfunction

function Get#(t) null_get();
   return (interface Get;
	      method ActionValue#(t) get() if (False);
		 return ?;
	      endmethod
	   endinterface);
endfunction
      
function  PhysicalWriteClient#(addrWidth, busWidth) null_physical_write_client();
   return (interface PhysicalWriteClient;
	      interface Get writeReq = null_get;
	      interface Get writeData = null_get;
	      interface Put writeDone = null_put;
	   endinterface);
endfunction

function  PhysicalReadClient#(addrWidth, busWidth) null_physical_read_client();
   return (interface PhysicalReadClient;
	      interface Get readReq = null_get;
	      interface Put readData = null_put;
	   endinterface);
endfunction

function PhysicalDmaMaster#(addrWidth, busWidth) null_physical_dma_master();
   return (interface PhysicalDmaMaster;
	      interface PhysicalReadClient read_client = null_physical_read_client;
	      interface PhysicalWriteClient write_client = null_physical_write_client;
	   endinterface);
endfunction