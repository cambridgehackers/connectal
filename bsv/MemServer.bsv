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
import List::*;
import GetPut::*;
import ClientServer::*;
import Assert::*;
import StmtFSM::*;
import SpecialFIFOs::*;
import Connectable::*;

// CONNECTAL Libraries
import HostInterface::*;
import MemTypes::*;
import ConnectalMemory::*;
import MMU::*;
import MemServerInternal::*;

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

function  PhysMemWriteClient#(addrWidth, busWidth) null_phys_mem_write_client();
   return (interface PhysMemWriteClient;
              interface Get writeReq = null_get;
              interface Get writeData = null_get;
              interface Put writeDone = null_put;
           endinterface);
endfunction

function  PhysMemReadClient#(addrWidth, busWidth) null_phys_mem_read_client();
   return (interface PhysMemReadClient;
              interface Get readReq = null_get;
              interface Put readData = null_put;
           endinterface);
endfunction

function  MemWriteClient#(busWidth) null_mem_write_client();
   return (interface MemWriteClient;
              interface Get writeReq = null_get;
              interface Get writeData = null_get;
              interface Put writeDone = null_put;
           endinterface);
endfunction

function  MemReadClient#(busWidth) null_mem_read_client();
   return (interface MemReadClient;
              interface Get readReq = null_get;
              interface Put readData = null_put;
           endinterface);
endfunction

interface MemServer#(numeric type addrWidth, numeric type dataWidth, numeric type nMasters, numeric type numReadServers, numeric type numWriteServers);
   interface MemServerRequest request;
   interface Vector#(nMasters,PhysMemMaster#(addrWidth, dataWidth)) masters;
   interface Vector#(numReadServers, MemReadServer#(dataWidth)) read_servers;
   interface Vector#(numWriteServers,MemWriteServer#(dataWidth)) write_servers;
endinterface		 	 
   
typedef struct {
   DmaErrorType errorType;
   Bit#(32) pref;
   } DmaError deriving (Bits);


module mkMemServer#(MemServerIndication indication,
		    Vector#(numMMUs,MMU#(addrWidth)) mmus)
   (MemServer#(addrWidth, dataWidth, nMasters, numReadServers, numWriteServers))
   provisos(Mul#(a__, nMasters, numWriteServers)
	    ,Mul#(b__, nMasters, numReadServers)
	    ,Add#(TLog#(TDiv#(dataWidth, 8)), d__, 8)
	    ,Add#(c__, addrWidth, 64)
	    );
   
   
   MemServer#(addrWidth,dataWidth,nMasters,numReadServers,0)  reader <- mkMemServerR(indication, mmus);
   MemServer#(addrWidth,dataWidth,nMasters,0,numWriteServers) writer <- mkMemServerW(indication, mmus);
   
   function PhysMemMaster#(addrWidth,dataWidth) mkm(Integer i) = (interface PhysMemMaster#(addrWidth,dataWidth);
								 interface PhysMemReadClient read_client = reader.masters[i].read_client;
								 interface PhysMemWriteClient write_client = writer.masters[i].write_client;
							      endinterface);

   interface read_servers = reader.read_servers;
   interface write_servers = writer.write_servers;
   interface MemServerRequest request;
      method Action stateDbg(ChannelType rc);
	 if (rc == Read)
	    reader.request.stateDbg(rc);
	 else
	    writer.request.stateDbg(rc);
      endmethod
      method Action memoryTraffic(ChannelType rc);
	 if (rc == Read) 
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

module mkMemServerR#(MemServerIndication indication,
		     Vector#(numMMUs,MMU#(addrWidth)) mmus)
   (MemServer#(addrWidth, dataWidth, nMasters, numReadServers, 0))
   provisos(Mul#(nrc, nMasters, numReadServers)
	    ,Add#(a__, addrWidth, 64)
	    ,Add#(TLog#(TDiv#(dataWidth, 8)), b__, 8)
	    );


   FIFO#(Bit#(32))   addrReqFifo <- mkFIFO;
   Reg#(Bit#(8)) dbgPtr <- mkReg(0);
   Reg#(Bit#(8)) trafficPtr <- mkReg(0);
   Reg#(Bit#(64)) trafficAccum <- mkReg(0);

   
   function a selectClient(Vector#(n, a) in, Integer r, Integer i, Integer j); return in[j * r + i]; endfunction
   function Vector#(nrc, a) selectServers(Vector#(numReadServers, a) vec, Integer m);
      return genWith(selectClient(vec, valueOf(nMasters), m));
   endfunction

   module foo#(Integer i) (MMUAddrServer#(addrWidth,nMasters));
      let rv <- mkMMUAddrServer(mmus[i].addr[0]);
      return rv;
   endmodule
   Vector#(numMMUs,MMUAddrServer#(addrWidth,nMasters)) mmu_servers <- mapM(foo,genVector);

   Vector#(nMasters,MemReadInternal#(addrWidth,dataWidth,MemServerTags,nrc)) readers;
   Vector#(numReadServers, MemReadServer#(dataWidth)) rs;
   for(Integer i = 0; i < valueOf(nMasters); i = i+1) begin
      Vector#(numMMUs,Server#(ReqTup,Bit#(addrWidth))) ss;
      for(Integer j = 0; j < valueOf(numMMUs); j=j+1)
	 ss[j] = mmu_servers[j].servers[i];
      readers[i] <- mkMemReadInternal(indication,ss);
      for(Integer j = 0; j < valueOf(nrc); j=j+1)
	 rs[i*valueOf(nrc)+j] = readers[i].servers[j];
   end
   
   rule mmuEntry;
      addrReqFifo.deq;
      let physAddr <- mmus[addrReqFifo.first[31:16]].addr[0].response.get;
      indication.addrResponse(zeroExtend(physAddr));
   endrule
   
   function PhysMemMaster#(addrWidth,dataWidth) mkm(Integer i) = (interface PhysMemMaster#(addrWidth,dataWidth);
								 interface PhysMemReadClient read_client = readers[i].read_client;
								 interface PhysMemWriteClient write_client = null_phys_mem_write_client;
							      endinterface);

   Stmt dbgStmt = seq
		     for(dbgPtr <= 0; dbgPtr < fromInteger(valueOf(nMasters)); dbgPtr <= dbgPtr+1)
			(action
			    let rv <- readers[dbgPtr].dbg.dbg;
			    indication.reportStateDbg(rv);
			 endaction);
		  endseq;
   FSM dbgFSM <- mkFSM(dbgStmt);

   Stmt trafficStmt = seq
			 trafficAccum <= 0;
			 for(trafficPtr <= 0; trafficPtr < fromInteger(valueOf(nMasters)); trafficPtr <= trafficPtr+1)
			    (action
				let rv <- readers[trafficPtr].dbg.getMemoryTraffic();
				trafficAccum <= trafficAccum + rv;
			     endaction);
			 indication.reportMemoryTraffic(trafficAccum);
		      endseq;
   FSM trafficFSM <- mkFSM(trafficStmt);
      
   interface read_servers = rs;
   interface write_servers = nil;
   interface MemServerRequest request;
      method Action stateDbg(ChannelType rc);
	 if (rc == Read)
	    dbgFSM.start;
      endmethod
      method Action memoryTraffic(ChannelType rc);
	 if (rc == Read)
	    trafficFSM.start;
      endmethod
      method Action addrTrans(Bit#(32) pointer, Bit#(32) offset);
	 addrReqFifo.enq(pointer);
	 mmus[pointer[31:16]].addr[0].request.put(ReqTup{id:truncate(pointer), off:extend(offset)});
      endmethod
   endinterface
   interface masters = map(mkm,genVector);
endmodule
	
module mkMemServerW#(MemServerIndication indication,
		     Vector#(numMMUs,MMU#(addrWidth)) mmus)
   (MemServer#(addrWidth, dataWidth, nMasters, 0, numWriteServers))
   provisos(Mul#(nwc, nMasters, numWriteServers)
	    ,Add#(a__, addrWidth, 64)
	    ,Add#(TLog#(TDiv#(dataWidth, 8)), b__, 8)
	    );
   
   FIFO#(Bit#(32))   addrReqFifo <- mkFIFO;
   Reg#(Bit#(8)) dbgPtr <- mkReg(0);
   Reg#(Bit#(8)) trafficPtr <- mkReg(0);
   Reg#(Bit#(64)) trafficAccum <- mkReg(0);
   
   function a selectClient(Vector#(n, a) in, Integer r, Integer i, Integer j); return in[j * r + i]; endfunction
   function Vector#(nwc, a) selectClients(Vector#(numWriteClients, a) vec, Integer m);
      return genWith(selectClient(vec, valueOf(nMasters), m));
   endfunction

   module foo#(Integer i) (MMUAddrServer#(addrWidth,nMasters));
      let rv <- mkMMUAddrServer(mmus[i].addr[1]);
      return rv;
   endmodule
   Vector#(numMMUs,MMUAddrServer#(addrWidth,nMasters)) mmu_servers <- mapM(foo,genVector);

   Vector#(nMasters,MemWriteInternal#(addrWidth,dataWidth,MemServerTags,nwc)) writers;
   Vector#(numWriteServers, MemWriteServer#(dataWidth)) ws;
   for(Integer i = 0; i < valueOf(nMasters); i = i+1) begin
      Vector#(numMMUs,Server#(ReqTup,Bit#(addrWidth))) ss;
      for(Integer j = 0; j < valueOf(numMMUs); j=j+1)
	 ss[j] = mmu_servers[j].servers[i];
      writers[i] <- mkMemWriteInternal(indication, ss);
      for(Integer j = 0; j < valueOf(nwc); j=j+1)
	 ws[i*valueOf(nwc)+j] = writers[i].servers[j];
   end
   
   rule mmuEntry;
      addrReqFifo.deq;
      let physAddr <- mmus[addrReqFifo.first[31:16]].addr[1].response.get;
      indication.addrResponse(zeroExtend(physAddr));
   endrule

   function PhysMemMaster#(addrWidth,dataWidth) mkm(Integer i) = (interface PhysMemMaster#(addrWidth,dataWidth);
								 interface PhysMemReadClient read_client = null_phys_mem_read_client;
								 interface PhysMemWriteClient write_client = writers[i].write_client;
							      endinterface);
   
   Stmt dbgStmt = seq
		     for(dbgPtr <= 0; dbgPtr < fromInteger(valueOf(nMasters)); dbgPtr <= dbgPtr+1)
			(action
			    let rv <- writers[dbgPtr].dbg.dbg;
			    indication.reportStateDbg(rv);
			 endaction);
		  endseq;
   FSM dbgFSM <- mkFSM(dbgStmt);

   Stmt trafficStmt = seq
			 trafficAccum <= 0;
			 for(trafficPtr <= 0; trafficPtr < fromInteger(valueOf(nMasters)); trafficPtr <= trafficPtr+1)
			    (action
				let rv <- writers[trafficPtr].dbg.getMemoryTraffic();
				trafficAccum <= trafficAccum + rv;
			     endaction);
			 indication.reportMemoryTraffic(trafficAccum);
		      endseq;
   FSM trafficFSM <- mkFSM(trafficStmt);
   
   interface read_servers = nil;
   interface write_servers = ws;
   interface MemServerRequest request;
      method Action stateDbg(ChannelType rc);
	 if (rc == Write)
	    dbgFSM.start;
      endmethod
      method Action memoryTraffic(ChannelType rc);
	 if (rc == Write) 
	    trafficFSM.start;
      endmethod
      method Action addrTrans(Bit#(32) pointer, Bit#(32) offset);
	 addrReqFifo.enq(pointer);
	 mmus[pointer[31:16]].addr[1].request.put(ReqTup{id:truncate(pointer), off:extend(offset)});
      endmethod
   endinterface
   interface masters = map(mkm,genVector);
endmodule

interface SimpleMemServer#(numeric type addrWidth, numeric type dataWidth, numeric type nMasters, numeric type numReadServers, numeric type numWriteServers);
   interface MemServerRequest memServerRequest;
   interface MMURequest mmuRequest;
   interface Vector#(nMasters,PhysMemMaster#(addrWidth, dataWidth)) masters;
   interface Vector#(2,Server#(ReqTup,Bit#(addrWidth))) addr;
   interface Vector#(numReadServers, MemWriteServer#(dataWidth)) read_servers;
   interface Vector#(numWriteServers, MemReadServer#(dataWidth)) write_servers;
endinterface

module mkSimpleMemServer#(Vector#(numReadClients, MemReadClient#(dataWidth)) readClients,
			  Vector#(numWriteClients, MemWriteClient#(dataWidth)) writeClients,
			  MemServerIndication indication,
			  MMUIndication mmuIndication)(SimpleMemServer#(addrWidth, dataWidth,nMasters, numReadServers, numWriteServers))
   provisos(Mul#(a__, nMasters, numWriteServers)
	    ,Mul#(b__, nMasters, numReadServers)
	    ,Add#(TLog#(TDiv#(dataWidth, 8)), e__, 8)
	    ,Add#(c__, addrWidth, 64)
	    ,Add#(d__, addrWidth, 44)
	    );
   
   MMU#(addrWidth) hostMMU <- mkMMU(0, True, mmuIndication);
   MemServer#(addrWidth,dataWidth,nMasters,numReadServers,numWriteServers) dma <- mkMemServer(indication, cons(hostMMU,nil));

   interface MemServerRequest memServerRequest = dma.request;
   interface MMURequest mmuRequest = hostMMU.request;
   interface Vector masters = dma.masters;
   interface Vector addr = hostMMU.addr;
endmodule


