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
import FIFO::*;
import Vector::*;
import List::*;
import GetPut::*;
import ClientServer::*;
import Assert::*;
import StmtFSM::*;
import SpecialFIFOs::*;
import Connectable::*;
import HostInterface::*;
import ConnectalMemTypes::*;
import ConnectalConfig::*;
import ConnectalMemory::*;
import ConnectalMMU::*;
import MemServerInternal::*;

interface MemServer#(numeric type addrWidth, numeric type busWidth, numeric type nMasters);
   interface MemServerRequest request;
   interface Vector#(nMasters,PhysMemMaster#(addrWidth, busWidth)) masters;
endinterface		

interface MemServerWithMMU#(numeric type addrWidth, numeric type busWidth, numeric type nMasters);
   interface MemServerRequest memServerRequest;
   interface Vector#(nMasters,PhysMemMaster#(addrWidth, busWidth)) masters;
   interface MMURequest mmuRequest;
endinterface

interface MemServerRead#(numeric type addrWidth, numeric type busWidth, numeric type numClients, numeric type numServers);
   interface MemServerRequest request;
   interface Vector#(numClients, PhysMemReadClient#(addrWidth,busWidth)) clients;
   interface Vector#(numServers, MemReadServer#(busWidth)) servers;
endinterface

interface MemServerWrite#(numeric type addrWidth, numeric type busWidth, numeric type numClients, numeric type numServers);
   interface MemServerRequest request;
   interface Vector#(numClients, PhysMemWriteClient#(addrWidth,busWidth)) clients;
   interface Vector#(numServers, MemWriteServer#(busWidth)) servers;
endinterface
   
typedef struct {
   DmaErrorType errorType;
   Bit#(32) pref;
   } DmaError deriving (Bits);

module mkMemServer#(Vector#(numReadClients, MemReadClient#(busWidth)) readClients,
		    Vector#(numWriteClients, MemWriteClient#(busWidth)) writeClients,
		    Vector#(numMMUs,MMU#(addrWidth)) mmus,
		    MemServerIndication indication)  
   (MemServer#(addrWidth, busWidth, nMasters))
   provisos(Mul#(TDiv#(numWriteClients, nMasters),nMasters,nws)
	    ,Mul#(TDiv#(numReadClients, nMasters),nMasters,nrs)
	    ,Add#(TLog#(TDiv#(busWidth, 8)), a__, 8)
	    ,Add#(TLog#(TDiv#(busWidth, 8)), b__, BurstLenSize)
	    ,Add#(c__, addrWidth, 64)
	    ,Add#(numWriteClients, d__, nws)
	    ,Add#(numReadClients, e__, nrs)
	    ,Add#(f__, TDiv#(busWidth, 8), ByteEnableSize)
	    );
   
   MemServerRead#(addrWidth,busWidth,nMasters,nrs)  reader <- mkMemServerRead(indication, mmus);
   MemServerWrite#(addrWidth,busWidth,nMasters,nws) writer <- mkMemServerWrite(indication, mmus);
   
   zipWithM_(mkConnection,readClients,take(reader.servers));
   zipWithM_(mkConnection,writeClients,take(writer.servers));
   
   function PhysMemMaster#(addrWidth,busWidth) mkm(Integer i) = (interface PhysMemMaster#(addrWidth,busWidth);
		     interface PhysMemReadClient read_client = reader.clients[i];
		     interface PhysMemWriteClient write_client = writer.clients[i];
		  endinterface);

   interface MemServerRequest request;
      method Action setTileState(TileControl tc);
	 reader.request.setTileState(tc);
	 writer.request.setTileState(tc);
      endmethod
      method Action stateDbg(ChannelType rc);
	 if (rc == ChannelType_Read)
	    reader.request.stateDbg(rc);
	 else
	    writer.request.stateDbg(rc);
      endmethod
      method Action memoryTraffic(ChannelType rc);
	 if (rc == ChannelType_Read) 
	    reader.request.memoryTraffic(rc);
	 else 
	    writer.request.memoryTraffic(rc);
      endmethod
      method Action addrTrans(Bit#(32) pointer, Bit#(32) offset);
	 writer.request.addrTrans(pointer,offset);
      endmethod
   endinterface
   interface masters = map(mkm,genVector);
endmodule

module mkMemServerRead#(MemServerIndication indication,
			Vector#(numMMUs,MMU#(addrWidth)) mmus)
   (MemServerRead#(addrWidth, busWidth, numClients, numServers))
   provisos(Mul#(nrc, numClients, numServers)
	    ,Add#(a__, addrWidth, 64)
	    ,Add#(TLog#(TDiv#(busWidth, 8)), b__, 8)
	    ,Add#(TLog#(TDiv#(busWidth, 8)), c__, BurstLenSize)
	    ,Add#(d__, TDiv#(busWidth, 8), ByteEnableSize)
	    );

   FIFO#(Bit#(32))   addrReqFifo <- mkFIFO;
   Reg#(Bit#(8)) dbgPtr <- mkReg(0);
   Reg#(Bit#(8)) trafficPtr <- mkReg(0);
   Reg#(Bit#(64)) trafficAccum <- mkReg(0);
   
   function Server#(AddrTransRequest,AddrTransResponse#(addrWidth)) selectMMUPort(Integer i);
      return mmus[i].addr[0];
   endfunction
   Vector#(numMMUs,ArbitratedMMU#(addrWidth,numClients)) mmu_servers <- mapM(mkArbitratedMMU,map(selectMMUPort,genVector));
   Vector#(numClients,MemReadInternal#(addrWidth,busWidth,MemServerTags,nrc)) readers;
   Vector#(numClients, PhysMemReadClient#(addrWidth,busWidth)) read_clients;
   Vector#(numServers, MemReadServer#(busWidth)) read_servers;

   for(Integer i = 0; i < valueOf(numClients); i = i+1) begin
      Vector#(numMMUs,Server#(AddrTransRequest,AddrTransResponse#(addrWidth))) ss;
      for(Integer j = 0; j < valueOf(numMMUs); j=j+1)
	 ss[j] = mmu_servers[j].servers[i];
      readers[i] <- mkMemReadInternal(indication,ss);
      read_clients[i] = readers[i].client;
      for(Integer j = 0; j < valueOf(nrc); j=j+1)
	 read_servers[i*valueOf(nrc)+j] = readers[i].servers[j];
   end
   
   rule mmuEntry;
      addrReqFifo.deq;
      let addrTransResponse <- mmus[addrReqFifo.first[31:16]].addr[0].response.get;
      indication.addrResponse(zeroExtend(addrTransResponse.physAddr));
   endrule
   
   Stmt dbgStmt = 
   seq
      for(dbgPtr <= 0; dbgPtr < fromInteger(valueOf(numClients)); dbgPtr <= dbgPtr+1)
	 (action
	     let rv <- readers[dbgPtr].dbg.dbg;
	     indication.reportStateDbg(rv);
	  endaction);
   endseq;
   FSM dbgFSM <- mkFSM(dbgStmt);

   Stmt trafficStmt = 
   seq
      trafficAccum <= 0;
      for(trafficPtr <= 0; trafficPtr < fromInteger(valueOf(numClients)); trafficPtr <= trafficPtr+1)
	 (action
	     let rv <- readers[trafficPtr].dbg.getMemoryTraffic();
	     trafficAccum <= trafficAccum + rv;
	  endaction);
      indication.reportMemoryTraffic(trafficAccum);
   endseq;
   FSM trafficFSM <- mkFSM(trafficStmt);
      
   interface servers = read_servers;
   interface clients = read_clients;
   interface MemServerRequest request;
      method Action setTileState(TileControl tc);
	 for(Integer i = 0; i < valueOf(numClients); i=i+1)
	    readers[i].tileControl.put(tc);
      endmethod
      method Action stateDbg(ChannelType rc);
	 if (rc == ChannelType_Read)
	    dbgFSM.start;
      endmethod
      method Action memoryTraffic(ChannelType rc);
	 if (rc == ChannelType_Read)
	    trafficFSM.start;
      endmethod
      method Action addrTrans(Bit#(32) pointer, Bit#(32) offset);
	 addrReqFifo.enq(pointer);
	 mmus[pointer[31:16]].addr[0].request.put(AddrTransRequest{id:truncate(pointer), off:extend(offset)});
      endmethod
   endinterface
endmodule
	
module mkMemServerWrite#(MemServerIndication indication,
		     Vector#(numMMUs,MMU#(addrWidth)) mmus)
   (MemServerWrite#(addrWidth, busWidth, numClients, numServers))
   provisos(Mul#(nwc, numClients, numServers)
	    ,Add#(a__, addrWidth, 64)
	    ,Add#(TLog#(TDiv#(busWidth, 8)), b__, 8)
	    ,Add#(TLog#(TDiv#(busWidth, 8)), c__, BurstLenSize)
	    ,Add#(d__, TDiv#(busWidth, 8), ByteEnableSize)
	    );
   
   FIFO#(Bit#(32))   addrReqFifo <- mkFIFO;
   Reg#(Bit#(8)) dbgPtr <- mkReg(0);
   Reg#(Bit#(8)) trafficPtr <- mkReg(0);
   Reg#(Bit#(64)) trafficAccum <- mkReg(0);
   
   function Server#(AddrTransRequest,AddrTransResponse#(addrWidth)) selectMMUPort(Integer i);
      return mmus[i].addr[1];
   endfunction
   Vector#(numMMUs,ArbitratedMMU#(addrWidth,numClients)) mmu_servers <- mapM(mkArbitratedMMU,map(selectMMUPort,genVector));
   Vector#(numClients,MemWriteInternal#(addrWidth,busWidth,MemServerTags,nwc)) writers;
   Vector#(numClients, PhysMemWriteClient#(addrWidth,busWidth)) write_clients;
   Vector#(numServers, MemWriteServer#(busWidth)) write_servers;

   for(Integer i = 0; i < valueOf(numClients); i = i+1) begin
      Vector#(numMMUs,Server#(AddrTransRequest,AddrTransResponse#(addrWidth))) ss;
      for(Integer j = 0; j < valueOf(numMMUs); j=j+1)
	 ss[j] = mmu_servers[j].servers[i];
      writers[i] <- mkMemWriteInternal(indication, ss);
      write_clients[i] = writers[i].client;
      for(Integer j = 0; j < valueOf(nwc); j=j+1)
	 write_servers[i*valueOf(nwc)+j] = writers[i].servers[j];
   end
   
   rule mmuEntry;
      addrReqFifo.deq;
      let addrTransResponse <- mmus[addrReqFifo.first[31:16]].addr[1].response.get;
      let physAddr = addrTransResponse.physAddr;
      indication.addrResponse(zeroExtend(physAddr));
   endrule

   Stmt dbgStmt = 
   seq
      for(dbgPtr <= 0; dbgPtr < fromInteger(valueOf(numClients)); dbgPtr <= dbgPtr+1)
	 (action
	     let rv <- writers[dbgPtr].dbg.dbg;
	     indication.reportStateDbg(rv);
	  endaction);
   endseq;
   FSM dbgFSM <- mkFSM(dbgStmt);

   Stmt trafficStmt = 
   seq
      trafficAccum <= 0;
      for(trafficPtr <= 0; trafficPtr < fromInteger(valueOf(numClients)); trafficPtr <= trafficPtr+1)
	 (action
	     let rv <- writers[trafficPtr].dbg.getMemoryTraffic();
	     trafficAccum <= trafficAccum + rv;
	  endaction);
      indication.reportMemoryTraffic(trafficAccum);
   endseq;
   FSM trafficFSM <- mkFSM(trafficStmt);
   
   interface servers = write_servers;
   interface clients = write_clients;
   interface MemServerRequest request;
      method Action setTileState(TileControl tc);
	 for(Integer i = 0; i < valueOf(numClients); i=i+1)
	    writers[i].tileControl.put(tc);
      endmethod
      method Action stateDbg(ChannelType rc);
	 if (rc == ChannelType_Write)
	    dbgFSM.start;
      endmethod
      method Action memoryTraffic(ChannelType rc);
	 if (rc == ChannelType_Write) 
	    trafficFSM.start;
      endmethod
      method Action addrTrans(Bit#(32) pointer, Bit#(32) offset);
	 addrReqFifo.enq(pointer);
	 mmus[pointer[31:16]].addr[1].request.put(AddrTransRequest{id:truncate(pointer), off:extend(offset)});
      endmethod
   endinterface
endmodule

module mkMemServerWithMMU#(Vector#(numReadClients, MemReadClient#(busWidth)) readClients,
			  Vector#(numWriteClients, MemWriteClient#(busWidth)) writeClients,
			  MemServerIndication indication,
			  MMUIndication mmuIndication)(MemServerWithMMU#(PhysAddrWidth, busWidth,nMasters))

   provisos(Add#(TLog#(TDiv#(busWidth, 8)), e__, 8)
	    ,Add#(TLog#(TDiv#(busWidth, 8)), f__, BurstLenSize)
	    ,Add#(c__, PhysAddrWidth, 64)
	    ,Add#(d__, PhysAddrWidth, MemOffsetSize)
	    ,Add#(numWriteClients, a__, TMul#(TDiv#(numWriteClients, nMasters),nMasters))
	    ,Add#(numReadClients, b__, TMul#(TDiv#(numReadClients, nMasters),nMasters))
	    ,Add#(g__, TDiv#(busWidth, 8), ByteEnableSize)
	    );

   
   MMU#(PhysAddrWidth) hostMMU <- mkMMU(0, True, mmuIndication);
   MemServer#(PhysAddrWidth,busWidth,nMasters) dma <- mkMemServer(readClients, writeClients, cons(hostMMU,nil), indication);

   interface MemServerRequest memServerRequest = dma.request;
   interface MMURequest mmuRequest = hostMMU.request;
   interface Vector masters = dma.masters;
endmodule
