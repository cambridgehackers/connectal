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

// XBSV Libraries
import MemTypes::*;
import PortalMemory::*;
import SGList::*;
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

function  MemWriteClient#(addrWidth, busWidth) null_mem_write_client();
   return (interface MemWriteClient;
              interface Get writeReq = null_get;
              interface Get writeData = null_get;
              interface Put writeDone = null_put;
           endinterface);
endfunction

function  MemReadClient#(addrWidth, busWidth) null_mem_read_client();
   return (interface MemReadClient;
              interface Get readReq = null_get;
              interface Put readData = null_put;
           endinterface);
endfunction

typedef 4 NUM_OO_TAGS;		
 
interface MemServer#(numeric type addrWidth, numeric type dataWidth, numeric type nMasters);
   interface DmaConfig request;
   interface Vector#(nMasters,MemMaster#(addrWidth, dataWidth)) masters;
endinterface
		 	 
module mkMemServer#(DmaIndication dmaIndication,
		    Vector#(numReadClients, ObjectReadClient#(dataWidth)) readClients,
		    Vector#(numWriteClients, ObjectWriteClient#(dataWidth)) writeClients)
   (MemServer#(PhysAddrWidth, dataWidth, nMasters))
   provisos(Add#(1,a__,dataWidth),
	    Mul#(TDiv#(dataWidth, 8), 8, dataWidth),
	    Div#(numReadClients, nMasters, nrc),
	    Mul#(nrc, nMasters, numReadClients),
	    Add#(b__, TLog#(nrc), 6),
	    Div#(numWriteClients, nMasters, nwc),
	    Mul#(nwc, nMasters, numWriteClients),
	    Add#(c__, TLog#(nwc), 6)
	    );
   
   Vector#(nMasters,TagGen#(nwc,nwc)) writeTagGens <- replicateM(mkTagGenIO);
   Vector#(nMasters,TagGen#(nrc,nrc)) readTagGens  <- replicateM(mkTagGenIO);
   let rv <- mkConfigMemServerRW(dmaIndication, readTagGens, writeTagGens, readClients, writeClients);
   return rv;
   
endmodule
		 
module mkMemServerR#(DmaIndication dmaIndication,
		     Vector#(numReadClients, ObjectReadClient#(dataWidth)) readClients)
   (MemServer#(PhysAddrWidth, dataWidth, nMasters))
   provisos(Add#(1,a__,dataWidth),
	    Mul#(TDiv#(dataWidth, 8), 8, dataWidth),
	    Div#(numReadClients, nMasters, nrc),
	    Mul#(nrc, nMasters, numReadClients),
	    Add#(b__, TLog#(nrc), 6)
	    );
   
   SGListMMU#(PhysAddrWidth) sgl <- mkSGListMMU(dmaIndication);
   Vector#(nMasters,TagGen#(nrc,nrc)) readTagGens <- replicateM(mkTagGenIO);
   let rv <- mkConfigMemServerR(dmaIndication,readTagGens,readClients,sgl);
   return rv;
   
endmodule
		 
module mkMemServerW#(DmaIndication dmaIndication,
		    Vector#(numWriteClients, ObjectWriteClient#(dataWidth)) writeClients)
   (MemServer#(PhysAddrWidth, dataWidth, nMasters))
   provisos(Add#(1,a__,dataWidth),
	    Mul#(TDiv#(dataWidth, 8), 8, dataWidth),
	    Div#(numWriteClients, nMasters, nwc),
	    Mul#(nwc, nMasters, numWriteClients),
	    Add#(i__, TLog#(nwc), 6)
	    );
   
   SGListMMU#(PhysAddrWidth) sgl <- mkSGListMMU(dmaIndication);
   Vector#(nMasters,TagGen#(nwc,nwc)) writeTagGens <- replicateM(mkTagGenIO);
   let rv <- mkConfigMemServerW(dmaIndication, writeTagGens, writeClients,sgl);
   return rv;
   
endmodule

   
module mkMemServerOO#(DmaIndication dmaIndication,
		      Vector#(numReadClients, ObjectReadClient#(dataWidth)) readClients,
		      Vector#(numWriteClients, ObjectWriteClient#(dataWidth)) writeClients)
   (MemServer#(PhysAddrWidth, dataWidth, nMasters))
   provisos(Add#(1,a__,dataWidth),
	    Mul#(TDiv#(dataWidth, 8), 8, dataWidth),
	    Div#(numReadClients, nMasters, nrc),
	    Mul#(nrc, nMasters, numReadClients),
	    Add#(i__, TLog#(nrc), 6),
	    Div#(numWriteClients, nMasters, nwc),
	    Mul#(nwc, nMasters, numWriteClients),
	    Add#(j__, TLog#(nwc), 6)
	    );


   Vector#(nMasters,TagGen#(nwc,NUM_OO_TAGS)) writeTagGens <- replicateM(mkTagGenOO);
   Vector#(nMasters,TagGen#(nrc,NUM_OO_TAGS)) readTagGens <- replicateM(mkTagGenOO);
   let rv <- mkConfigMemServerRW(dmaIndication, readTagGens, writeTagGens, readClients, writeClients);
   return rv;

endmodule

module mkMemServerOOR#(DmaIndication dmaIndication,
		       Vector#(numReadClients, ObjectReadClient#(dataWidth)) readClients)
   (MemServer#(PhysAddrWidth, dataWidth, nMasters))
   provisos(Add#(1,a__,dataWidth),
	    Mul#(TDiv#(dataWidth, 8), 8, dataWidth),
	    Div#(numReadClients, nMasters, nrc),
	    Mul#(nrc, nMasters, numReadClients)
      );
   
   SGListMMU#(PhysAddrWidth) sgl <- mkSGListMMU(dmaIndication);
   Vector#(nMasters,TagGen#(nrc,NUM_OO_TAGS)) readTagGens <- replicateM(mkTagGenOO);
   let rv <- mkConfigMemServerR(dmaIndication,readTagGens,readClients,sgl);
   return rv;
   
endmodule
		 
module mkMemServerOOW#(DmaIndication dmaIndication,
		    Vector#(numWriteClients, ObjectWriteClient#(dataWidth)) writeClients)
   (MemServer#(PhysAddrWidth, dataWidth, nMasters))
   provisos(Add#(1,a__,dataWidth),
	    Mul#(TDiv#(dataWidth, 8), 8, dataWidth),
	    Div#(numWriteClients, nMasters, nwc),
	    Mul#(nwc, nMasters, numWriteClients)
	    );
   
   SGListMMU#(PhysAddrWidth) sgl <- mkSGListMMU(dmaIndication);
   Vector#(nMasters,TagGen#(nwc,NUM_OO_TAGS)) writeTagGens <- replicateM(mkTagGenOO);
   let rv <- mkConfigMemServerW(dmaIndication, writeTagGens,writeClients,sgl);
   return rv;
   
endmodule

   
typedef struct {
   DmaErrorType errorType;
   Bit#(32) pref;
   } DmaError deriving (Bits);

module mkConfigMemServerRW#(DmaIndication dmaIndication,
			    Vector#(nMasters,TagGen#(nrc, numReadTags)) readTagGens,
			    Vector#(nMasters,TagGen#(nwc, numWriteTags)) writeTagGens,
			    Vector#(numReadClients, ObjectReadClient#(dataWidth)) readClients,
			    Vector#(numWriteClients, ObjectWriteClient#(dataWidth)) writeClients)
   (MemServer#(PhysAddrWidth, dataWidth, nMasters))
   
   provisos (Add#(1,a__,dataWidth),
	     Mul#(TDiv#(dataWidth, 8), 8, dataWidth),
	     Add#(b__, TLog#(numReadTags), 6),
	     Add#(c__, TLog#(numWriteTags), 6),
	     Mul#(nwc, nMasters, numWriteClients),
	     Mul#(nrc, nMasters, numReadClients)
	     );


   SGListMMU#(PhysAddrWidth) sgl <- mkSGListMMU(dmaIndication);
   MemServer#(PhysAddrWidth,dataWidth,nMasters) reader <- mkConfigMemServerR(dmaIndication, readTagGens,  readClients,  sgl);
   MemServer#(PhysAddrWidth,dataWidth,nMasters) writer <- mkConfigMemServerW(dmaIndication, writeTagGens, writeClients, sgl);
   
   FIFO#(DmaError) dmaErrorFifo <- mkFIFO();
   rule dmaError;
      let error <- toGet(dmaErrorFifo).get();
      dmaIndication.dmaError(extend(pack(error.errorType)), error.pref, 0, 0);
   endrule

   function MemMaster#(PhysAddrWidth,dataWidth) mkm(Integer i) = (interface MemMaster#(PhysAddrWidth,dataWidth);
								 interface MemReadClient read_client = reader.masters[i].read_client;
								 interface MemWriteClient write_client = writer.masters[i].write_client;
							      endinterface);

   interface DmaConfig request;
      method Action getStateDbg(ChannelType rc);
	 if (rc == Read)
	    reader.request.getStateDbg(rc);
	 else
	    writer.request.getStateDbg(rc);
      endmethod
      method Action getMemoryTraffic(ChannelType rc);
	 if (rc == Read) 
	    reader.request.getMemoryTraffic(rc);
	 else 
	    writer.request.getMemoryTraffic(rc);
      endmethod
      method sglist = sgl.setup.sglist;
      method region = sgl.setup.region;
      method Action addrRequest(Bit#(32) pointer, Bit#(32) offset);
	 writer.request.addrRequest(pointer,offset);
      endmethod
   endinterface
   interface masters = map(mkm,genVector);
endmodule
	
module mkConfigMemServerR#(DmaIndication dmaIndication,
			   Vector#(nMasters,TagGen#(nrc, numReadTags)) readTagGens,
			   Vector#(numReadClients, ObjectReadClient#(dataWidth)) readClients,
			   SGListMMU#(PhysAddrWidth) sgl)
   (MemServer#(PhysAddrWidth, dataWidth, nMasters))
   
   provisos (Add#(1,a__,dataWidth),
	     Mul#(TDiv#(dataWidth, 8), 8, dataWidth),
	     Add#(h__, TLog#(numReadTags), 6),
	     Mul#(nrc, nMasters, numReadClients));


   FIFO#(void)   addrReqFifo <- mkFIFO;
   Reg#(Bit#(8)) dbgPtr <- mkReg(0);
   Reg#(Bit#(8)) trafficPtr <- mkReg(0);
   Reg#(Bit#(64)) trafficAccum <- mkReg(0);

   
   Vector#(nMasters,List#(ObjectReadClient#(dataWidth))) client_bins = replicate(Nil);
   for(Integer i = 0; i < valueOf(numReadClients); i=i+1)
      client_bins[i%valueOf(nMasters)] = List::cons(readClients[i], client_bins[i%valueOf(nMasters)]);

   SglAddrServer#(PhysAddrWidth,nMasters) sgl_server <- mkSglAddrServer(sgl.addr[0]);
   Vector#(nMasters,MemReadInternal#(PhysAddrWidth,dataWidth)) readers;
   for(Integer i = 0; i < valueOf(nMasters); i = i+1)
      readers[i] <- mkMemReadInternal(i, toVector(client_bins[i]), dmaIndication, sgl_server.servers[i], readTagGens[i]);
   
   rule sglistEntry;
      addrReqFifo.deq;
      let physAddr <- sgl.addr[0].response.get;
      dmaIndication.addrResponse(zeroExtend(physAddr));
   endrule
   
   function MemMaster#(PhysAddrWidth,dataWidth) mkm(Integer i) = (interface MemMaster#(PhysAddrWidth,dataWidth);
								 interface MemReadClient read_client = readers[i].read_client;
								 interface MemWriteClient write_client = null_mem_write_client;
							      endinterface);

   Stmt dbgStmt = seq
		     for(dbgPtr <= 0; dbgPtr < fromInteger(valueOf(nMasters)); dbgPtr <= dbgPtr+1)
			(action
			    let rv <- readers[dbgPtr].dbg.dbg;
			    dmaIndication.reportStateDbg(rv);
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
			 dmaIndication.reportMemoryTraffic(trafficAccum);
		      endseq;
   FSM trafficFSM <- mkFSM(trafficStmt);
      
   FIFO#(DmaError) dmaErrorFifo <- mkFIFO();
   rule dmaError;
      let error <- toGet(dmaErrorFifo).get();
      dmaIndication.dmaError(extend(pack(error.errorType)), error.pref, 0, 0);
   endrule

   interface DmaConfig request;
      method Action getStateDbg(ChannelType rc);
	 if (rc == Read)
	    dbgFSM.start;
      endmethod
      method Action getMemoryTraffic(ChannelType rc);
	 if (rc == Read)
	    trafficFSM.start;
      endmethod
      method sglist = sgl.setup.sglist;
      method region = sgl.setup.region;
      method Action addrRequest(Bit#(32) pointer, Bit#(32) offset);
	 addrReqFifo.enq(?);
	 sgl.addr[0].request.put(ReqTup{id:truncate(pointer), off:extend(offset)});
      endmethod
   endinterface
   interface masters = map(mkm,genVector);
endmodule
	
module mkConfigMemServerW#(DmaIndication dmaIndication,
			   Vector#(nMasters,TagGen#(nwc,numWriteTags)) writeTagGens,
			   Vector#(numWriteClients, ObjectWriteClient#(dataWidth)) writeClients,
			   SGListMMU#(PhysAddrWidth) sgl)
   (MemServer#(PhysAddrWidth, dataWidth, nMasters))
   
   provisos (Add#(1,a__,dataWidth),
	     Mul#(TDiv#(dataWidth, 8), 8, dataWidth),
	     Add#(j__, TLog#(numWriteTags), 6),
	     Mul#(nwc, nMasters, numWriteClients));

   FIFO#(void)   addrReqFifo <- mkFIFO;
   Reg#(Bit#(8)) dbgPtr <- mkReg(0);
   Reg#(Bit#(8)) trafficPtr <- mkReg(0);
   Reg#(Bit#(64)) trafficAccum <- mkReg(0);
   
   Vector#(nMasters,List#(ObjectWriteClient#(dataWidth))) client_bins = replicate(Nil);
   for(Integer i = 0; i < valueOf(numWriteClients); i=i+1)
      client_bins[i%valueOf(nMasters)] = List::cons(writeClients[i], client_bins[i%valueOf(nMasters)]);

   SglAddrServer#(PhysAddrWidth,nMasters) sgl_server <- mkSglAddrServer(sgl.addr[1]);
   Vector#(nMasters,MemWriteInternal#(PhysAddrWidth,dataWidth)) writers;
   for(Integer i = 0; i < valueOf(nMasters); i = i+1)
      writers[i] <- mkMemWriteInternal(i, toVector(client_bins[i]), dmaIndication, sgl_server.servers[i], writeTagGens[i]);
   
   rule sglistEntry;
      addrReqFifo.deq;
      let physAddr <- sgl.addr[1].response.get;
      dmaIndication.addrResponse(zeroExtend(physAddr));
   endrule

   function MemMaster#(PhysAddrWidth,dataWidth) mkm(Integer i) = (interface MemMaster#(PhysAddrWidth,dataWidth);
								 interface MemReadClient read_client = null_mem_read_client;
								 interface MemWriteClient write_client = writers[i].write_client;
							      endinterface);
   
   Stmt dbgStmt = seq
		     for(dbgPtr <= 0; dbgPtr < fromInteger(valueOf(nMasters)); dbgPtr <= dbgPtr+1)
			(action
			    let rv <- writers[dbgPtr].dbg.dbg;
			    dmaIndication.reportStateDbg(rv);
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
			 dmaIndication.reportMemoryTraffic(trafficAccum);
		      endseq;
   FSM trafficFSM <- mkFSM(trafficStmt);

   FIFO#(DmaError) dmaErrorFifo <- mkFIFO();
   rule dmaError;
      let error <- toGet(dmaErrorFifo).get();
      dmaIndication.dmaError(extend(pack(error.errorType)), error.pref, 0, 0);
   endrule

   interface DmaConfig request;
      method Action getStateDbg(ChannelType rc);
	 if (rc == Write)
	    dbgFSM.start;
      endmethod
      method Action getMemoryTraffic(ChannelType rc);
	 if (rc == Write) 
	    trafficFSM.start;
      endmethod
      method sglist = sgl.setup.sglist;
      method region = sgl.setup.region;
      method Action addrRequest(Bit#(32) pointer, Bit#(32) offset);
	 addrReqFifo.enq(?);
	 sgl.addr[1].request.put(ReqTup{id:truncate(pointer), off:extend(offset)});
      endmethod
   endinterface
   interface masters = map(mkm,genVector);
endmodule

