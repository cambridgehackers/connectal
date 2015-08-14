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
typedef 44 MemOffsetSize;
typedef 6 MemTagSize;
typedef `BurstLenSize BurstLenSize;
`ifndef USE_ACP
typedef 32 MemServerTags;
`else
typedef 8 MemServerTags;
`endif

// memory request with physical addresses.
// these can be transmitted directly to the bus master
typedef struct {
   Bit#(addrWidth) addr;
   Bit#(BurstLenSize) burstLen;
   Bit#(MemTagSize) tag;
   } PhysMemRequest#(numeric type addrWidth) deriving (Bits);

// memory request with "virtual" addresses.
// these need to be translated before they can be send to the bus
typedef struct {
   SGLId sglId;
   Bit#(MemOffsetSize) offset;
   Bit#(BurstLenSize) burstLen;
   Bit#(MemTagSize)  tag;
   } MemRequest deriving (Bits);

// memory paylaod
typedef struct {
   Bit#(dsz) data;
   Bit#(MemTagSize) tag;
   Bool last;
   } MemData#(numeric type dsz) deriving (Bits);


///////////////////////////////////////////////////////////////////////////////////
// 

typedef struct {SGLId sglId;
		Bit#(MemOffsetSize) base;
		Bit#(BurstLenSize) burstLen;
		Bit#(32) len;
		Bit#(MemTagSize) tag;
		} MemengineCmd deriving (Eq,Bits);

interface MemwriteServer#(numeric type dataWidth);
   interface Server#(MemengineCmd,Bool) cmdServer;
   interface PipeIn#(Bit#(dataWidth)) dataPipe;
endinterface

interface MemwriteEngine#(numeric type dataWidth, numeric type cmdQDepth, numeric type numServers);
   interface MemWriteClient#(dataWidth) dmaClient;
   interface Vector#(numServers, MemwriteServer#(dataWidth)) write_servers;
endinterface

typedef struct {
   Bit#(dsz) data;
   Bit#(MemTagSize) tag;
   Bool first;
   Bool last;
   } MemDataF#(numeric type dsz) deriving (Bits);

interface MemreadServer#(numeric type dataWidth);
   interface Put#(MemengineCmd)             request;
   interface PipeOut#(MemDataF#(dataWidth)) memDataPipe;
endinterface
      
interface MemreadEngine#(numeric type dataWidth, numeric type cmdQDepth, numeric type numServers);
   interface MemReadClient#(dataWidth) dmaClient;
   interface Vector#(numServers, MemreadServer#(dataWidth)) read_servers;
endinterface

// 
///////////////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////////////
// 

			     
interface MemReadClient#(numeric type dsz);
   interface Get#(MemRequest)    readReq;
   interface Put#(MemData#(dsz)) readData;
endinterface

interface MemWriteClient#(numeric type dsz);
   interface Get#(MemRequest)    writeReq;
   interface Get#(MemData#(dsz)) writeData;
   interface Put#(Bit#(MemTagSize))       writeDone;
endinterface

interface MemReadServer#(numeric type dsz);
   interface Put#(MemRequest) readReq;
   interface Get#(MemData#(dsz))     readData;
endinterface

interface MemWriteServer#(numeric type dsz);
   interface Put#(MemRequest) writeReq;
   interface Put#(MemData#(dsz))     writeData;
   interface Get#(Bit#(MemTagSize))           writeDone;
endinterface
      
//
///////////////////////////////////////////////////////////////////////////////////
// 

interface PhysMemSlave#(numeric type addrWidth, numeric type dataWidth);
   interface PhysMemReadServer#(addrWidth, dataWidth) read_server;
   interface PhysMemWriteServer#(addrWidth, dataWidth) write_server; 
endinterface

interface PhysMemMaster#(numeric type addrWidth, numeric type dataWidth);
   interface PhysMemReadClient#(addrWidth, dataWidth) read_client;
   interface PhysMemWriteClient#(addrWidth, dataWidth) write_client; 
endinterface

interface PhysMemReadClient#(numeric type asz, numeric type dsz);
   interface Get#(PhysMemRequest#(asz))    readReq;
   interface Put#(MemData#(dsz)) readData;
endinterface

interface PhysMemWriteClient#(numeric type asz, numeric type dsz);
   interface Get#(PhysMemRequest#(asz))    writeReq;
   interface Get#(MemData#(dsz)) writeData;
   interface Put#(Bit#(MemTagSize))       writeDone;
endinterface

interface PhysMemReadServer#(numeric type asz, numeric type dsz);
   interface Put#(PhysMemRequest#(asz)) readReq;
   interface Get#(MemData#(dsz))     readData;
endinterface

interface PhysMemWriteServer#(numeric type asz, numeric type dsz);
   interface Put#(PhysMemRequest#(asz)) writeReq;
   interface Put#(MemData#(dsz))     writeData;
   interface Get#(Bit#(MemTagSize))           writeDone;
endinterface

//
///////////////////////////////////////////////////////////////////////////////////

instance Connectable#(MemReadClient#(dsz), MemReadServer#(dsz));
   module mkConnection#(MemReadClient#(dsz) source, MemReadServer#(dsz) sink)(Empty);
      rule mr_request;
	 let req <- source.readReq.get();
	 sink.readReq.put(req);
      endrule
      rule mr_response;
	 let resp <- sink.readData.get();
	 source.readData.put(resp);
      endrule
   endmodule
endinstance

instance Connectable#(MemWriteClient#(dsz), MemWriteServer#(dsz));
   module mkConnection#(MemWriteClient#(dsz) source, MemWriteServer#(dsz) sink)(Empty);
      rule mw_request;
	 let req <- source.writeReq.get();
	 sink.writeReq.put(req);
      endrule
      rule mw_response;
	 let resp <- source.writeData.get();
	 sink.writeData.put(resp);
      endrule
      rule mw_done;
	 let resp <- sink.writeDone.get();
	 source.writeDone.put(resp);
      endrule
   endmodule
endinstance

instance Connectable#(PhysMemMaster#(addrWidth, busWidth), PhysMemSlave#(addrWidth, busWidth));
   module mkConnection#(PhysMemMaster#(addrWidth, busWidth) m, PhysMemSlave#(addrWidth, busWidth) s)(Empty);
      mkConnection(m.read_client.readReq, s.read_server.readReq);
      mkConnection(s.read_server.readData, m.read_client.readData);
      mkConnection(m.write_client.writeReq, s.write_server.writeReq);
      mkConnection(m.write_client.writeData, s.write_server.writeData);
      mkConnection(s.write_server.writeDone, m.write_client.writeDone);
   endmodule
endinstance

// this is used for debugging MemToPcie/PcieToMem in BsimTop.bsv
instance Connectable#(PhysMemMaster#(32, busWidth), PhysMemSlave#(40, busWidth));
   module mkConnection#(PhysMemMaster#(32, busWidth) m, PhysMemSlave#(40, busWidth) s)(Empty);
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

function Bool isQuadWordAligned(Bit#(7) lower_addr);
   return (lower_addr[2:0]==3'b0);
endfunction


