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
import ClientServer::*;
import Pipe::*;

// CONNECTAL Libraries
import ConnectalMemory::*;

typedef Bit#(32) SGLId;
typedef 40 MemOffsetSize;
typedef `PhysAddrWidth PhysAddrWidth;
typedef 6 MemTagSize;
typedef 10 BurstLenSize;

typedef struct {
   Bit#(addrWidth) addr;
   Bit#(BurstLenSize) burstLen;
   Bit#(MemTagSize) tag;
   } PhysMemRequest#(numeric type addrWidth) deriving (Bits);
typedef struct {
   SGLId sglId;
   Bit#(MemOffsetSize) offset;
   Bit#(BurstLenSize) burstLen;
   Bit#(MemTagSize)  tag;
   } MemRequest deriving (Bits);
typedef struct {
   Bit#(dsz) data;
   Bit#(MemTagSize) tag;
   Bool                last;
   } MemData#(numeric type dsz) deriving (Bits);


///////////////////////////////////////////////////////////////////////////////////
// 

typedef struct {SGLId sglId;
		Bit#(MemOffsetSize) base;
		Bit#(BurstLenSize) burstLen;
		Bit#(32) len;
		} MemengineCmd deriving (Eq,Bits);

interface MemwriteEngineV#(numeric type dataWidth, numeric type cmdQDepth, numeric type numServers);
   interface Vector#(numServers, Server#(MemengineCmd,Bool)) writeServers;
   interface ObjectWriteClient#(dataWidth) dmaClient;
   interface Vector#(numServers, PipeIn#(Bit#(dataWidth))) dataPipes;
endinterface
typedef MemwriteEngineV#(dataWidth, cmdQDepth, 1) MemwriteEngine#(numeric type dataWidth, numeric type cmdQDepth);

interface MemreadServer#(numeric type dataWidth);
   interface Server#(MemengineCmd,Bool) cmdServer;
   interface PipeOut#(Bit#(dataWidth)) dataPipe;
endinterface
      
interface MemreadEngineV#(numeric type dataWidth, numeric type cmdQDepth, numeric type numServers);
   interface Vector#(numServers, Server#(MemengineCmd,Bool)) readServers;
   interface ObjectReadClient#(dataWidth) dmaClient;
   interface Vector#(numServers, PipeOut#(Bit#(dataWidth))) dataPipes;
   interface Vector#(numServers, MemreadServer#(dataWidth)) read_servers;
endinterface
typedef MemreadEngineV#(dataWidth, cmdQDepth, 1) MemreadEngine#(numeric type dataWidth, numeric type cmdQDepth);

// 
///////////////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////////////
// 

			     
interface ObjectReadClient#(numeric type dsz);
   interface Get#(MemRequest)    readReq;
   interface Put#(MemData#(dsz)) readData;
endinterface

interface ObjectWriteClient#(numeric type dsz);
   interface Get#(MemRequest)    writeReq;
   interface Get#(MemData#(dsz)) writeData;
   interface Put#(Bit#(MemTagSize))       writeDone;
endinterface

interface ObjectReadServer#(numeric type dsz);
   interface Put#(MemRequest) readReq;
   interface Get#(MemData#(dsz))     readData;
endinterface

interface ObjectWriteServer#(numeric type dsz);
   interface Put#(MemRequest) writeReq;
   interface Put#(MemData#(dsz))     writeData;
   interface Get#(Bit#(MemTagSize))           writeDone;
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
   interface Get#(PhysMemRequest#(asz))    readReq;
   interface Put#(MemData#(dsz)) readData;
endinterface

interface MemWriteClient#(numeric type asz, numeric type dsz);
   interface Get#(PhysMemRequest#(asz))    writeReq;
   interface Get#(MemData#(dsz)) writeData;
   interface Put#(Bit#(MemTagSize))       writeDone;
endinterface

interface MemReadServer#(numeric type asz, numeric type dsz);
   interface Put#(PhysMemRequest#(asz)) readReq;
   interface Get#(MemData#(dsz))     readData;
endinterface

interface MemWriteServer#(numeric type asz, numeric type dsz);
   interface Put#(PhysMemRequest#(asz)) writeReq;
   interface Put#(MemData#(dsz))     writeData;
   interface Get#(Bit#(MemTagSize))           writeDone;
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

instance Connectable#(MemMaster#(addrWidth, busWidth), MemSlave#(addrWidth, busWidth));
   module mkConnection#(MemMaster#(addrWidth, busWidth) m, MemSlave#(addrWidth, busWidth) s)(Empty);
      mkConnection(m.read_client.readReq, s.read_server.readReq);
      mkConnection(s.read_server.readData, m.read_client.readData);
      mkConnection(m.write_client.writeReq, s.write_server.writeReq);
      mkConnection(m.write_client.writeData, s.write_server.writeData);
      mkConnection(s.write_server.writeDone, m.write_client.writeDone);
   endmodule
endinstance

// this is used for debugging MemSlaveEngine/MemMasterEngine in BsimTop.bsv
instance Connectable#(MemMaster#(32, busWidth), MemSlave#(40, busWidth));
   module mkConnection#(MemMaster#(32, busWidth) m, MemSlave#(40, busWidth) s)(Empty);
      //mkConnection(m.read_client.readReq, s.read_server.readReq);
      rule readreq;
	 let req <- m.read_client.readReq.get();
	 s.read_server.readReq.put(PhysMemRequest { addr: extend(req.addr), burstLen: req.burstLen, tag: req.tag });
      endrule

      mkConnection(s.read_server.readData, m.read_client.readData);
      //mkConnection(m.write_client.writeReq, s.write_server.writeReq);
      rule writereq;
	 let req <- m.write_client.writeReq.get();
	 s.write_server.writeReq.put(PhysMemRequest { addr: extend(req.addr), burstLen: req.burstLen, tag: req.tag });
      endrule
      mkConnection(m.write_client.writeData, s.write_server.writeData);
      mkConnection(s.write_server.writeDone, m.write_client.writeDone);
   endmodule
endinstance

