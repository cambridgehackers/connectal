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
import RegFile::*;
import FIFO::*;
import FIFOF::*;
import Vector::*;
import GetPut::*;
import BRAMFIFO::*;
import BRAM::*;
import MemTypes::*;
import StmtFSM::*;
import ClientServer::*;
import PortalMemory::*;

typedef 32 MaxNumSGLists;
typedef Bit#(TLog#(MaxNumSGLists)) SGListId;
typedef 12 SGListPageShift0;
typedef 16 SGListPageShift4;
typedef 20 SGListPageShift8;
typedef Bit#(TLog#(MaxNumSGLists)) RegionsIdx;

typedef 8 IndexWidth;

typedef struct {
   SGListId               id;
   Bit#(ObjectOffsetSize) off;
} ReqTup deriving (Eq,Bits,FShow);

`ifdef BSIM
`ifndef PCIE
import "BDPI" function ActionValue#(Bit#(32)) pareff(Bit#(32) handle, Bit#(32) size);
`endif
`endif

interface SGListMMU#(numeric type addrWidth);
   interface SGListSetup setup;
   interface Vector#(2,Server#(ReqTup,Bit#(addrWidth))) addr;
endinterface

typedef struct {
   Bit#(2) pageSize;
   Bit#(SGListPageShift8) value;
} Offset deriving (Eq,Bits,FShow);

typedef Bit#(TSub#(ObjectOffsetSize,SGListPageShift0)) Page;
typedef Bit#(TSub#(ObjectOffsetSize,SGListPageShift4)) Page4;
typedef Bit#(TSub#(ObjectOffsetSize,SGListPageShift8)) Page8;

typedef struct {
   Bit#(28) barrier;
   Bit#(IndexWidth) idxOffset;
   } Region deriving (Eq,Bits,FShow);

typedef struct {DmaErrorType errorType;
		Bit#(32) pref; } DmaError deriving (Bits);

// the address translation servers (addr[0], addr[1]) have a latency of 8 and are fully pipelined
module mkSGListMMU#(DmaIndication dmaIndication)(SGListMMU#(addrWidth))
   provisos(Log#(MaxNumSGLists, listIdxSize),
	    Add#(listIdxSize,8, entryIdxSize),
	    Add#(c__, addrWidth, ObjectOffsetSize));
   
   // stage 0 (latency == 1)
   Vector#(2, FIFO#(ReqTup)) incomingReqs <- replicateM(mkFIFO);

   // stage 1 (latency == 2)
   BRAM_Configure bramConfig = defaultValue;
   bramConfig.latency        = 2;
   BRAM2Port#(RegionsIdx, Region)       reg8 <- mkBRAM2Server(bramConfig);
   BRAM2Port#(RegionsIdx, Region)       reg4 <- mkBRAM2Server(bramConfig);
   BRAM2Port#(RegionsIdx, Region)       reg0 <- mkBRAM2Server(bramConfig);
   Vector#(2,FIFOF#(ReqTup))           reqs0 <- replicateM(mkSizedFIFOF(3));
   
   // stage 2 (latency == 1)
   Vector#(2,FIFOF#(Tuple3#(Bool,Bool,Bool))) conds <- replicateM(mkFIFOF);
   Vector#(2,FIFOF#(Tuple3#(Bit#(IndexWidth),Bit#(IndexWidth),Bit#(IndexWidth)))) idxOffsets0 <- replicateM(mkFIFOF);
   Vector#(2,FIFOF#(ReqTup))           reqs1 <- replicateM(mkSizedFIFOF(3));

   // stage 3 (latency == 1)
   Vector#(2,FIFOF#(Offset))           offs0 <- replicateM(mkFIFOF);
   Vector#(2,FIFOF#(Bit#(IndexWidth)))         pbases <- replicateM(mkFIFOF);
   Vector#(2,FIFOF#(Bit#(IndexWidth)))    idxOffsets1 <- replicateM(mkFIFOF);
   Vector#(2,FIFOF#(SGListId))         ptrs1 <- replicateM(mkFIFOF);

   // stage 4 (latency == 2)
   BRAM2Port#(Bit#(entryIdxSize),Page) pages <- mkBRAM2Server(bramConfig);
   Vector#(2,FIFOF#(Offset))           offs1 <- replicateM(mkSizedFIFOF(3));

   // stage 4 (latnecy == 1)
   Vector#(2,FIFOF#(Bit#(addrWidth))) pageResponseFifos <- replicateM(mkFIFOF);
      
   FIFO#(DmaError) dmaErrorFifo <- mkFIFO();
   rule dmaError;
      let error <- toGet(dmaErrorFifo).get();
      dmaIndication.dmaError(extend(pack(error.errorType)), error.pref, -1, 0);
   endrule


   let page_shift0 = fromInteger(valueOf(SGListPageShift0));
   let page_shift4 = fromInteger(valueOf(SGListPageShift4));
   let page_shift8 = fromInteger(valueOf(SGListPageShift8));
   
   function BRAMServer#(a,b) portsel(BRAM2Port#(a,b) x, Integer i);
      if(i==0) return x.portA;
      else return x.portB;
   endfunction
   
   for (Integer i = 0; i < 2; i=i+1)
      rule stage1;
	 ReqTup req <- toGet(incomingReqs[i]).get();
	 //match { .ptr, .off } = req;
	 portsel(reg8, i).request.put(BRAMRequest{write:False, responseOnWrite:False,
            address:truncate(req.id), datain:?});
	 portsel(reg4, i).request.put(BRAMRequest{write:False, responseOnWrite:False,
            address:truncate(req.id), datain:?});
	 portsel(reg0, i).request.put(BRAMRequest{write:False, responseOnWrite:False,
            address:truncate(req.id), datain:?});
	 reqs0[i].enq(req);
      endrule

   // pipeline the address lookup
   for(Integer i = 0; i < 2; i=i+1) begin
      rule stage2;
	 ReqTup req <- toGet(reqs0[i]).get;
	 //match {.ptr,.offreq} = req; 
	 Region region8 <- portsel(reg8,i).response.get;
	 Region region4 <- portsel(reg4,i).response.get;
	 Region region0 <- portsel(reg0,i).response.get;
	 
         Page off = truncate(req.off >> valueOf(SGListPageShift0));
         Page4 off4 = truncate(req.off >> valueOf(SGListPageShift4));
         Page4 off8 = truncate(req.off >> valueOf(SGListPageShift8));
	 let cond8 = off8 < truncate(region8.barrier);
	 let cond4 = off4 < truncate(region4.barrier);
	 let cond0 = off < region0.barrier;
	 
	 conds[i].enq(tuple3(cond8,cond4,cond0));
	 idxOffsets0[i].enq(tuple3(region8.idxOffset,region4.idxOffset, region0.idxOffset));
	 reqs1[i].enq(req);
      endrule
      rule stage3;
	 ReqTup req <- toGet(reqs1[i]).get;
         //match{.ptr,.off} = req;
	 Offset o = Offset{pageSize: 0, value: truncate(req.off)};
	 Bit#(IndexWidth) pbase = 0;
	 Bit#(IndexWidth) idxOffset = 0;

	 match{.cond8,.cond4,.cond0} <- toGet(conds[i]).get;
	 match{.idxOffset8,.idxOffset4,.idxOffset0} <- toGet(idxOffsets0[i]).get;

	 if (cond8) begin
	    //$display("request: req.id=%h req.off=%h", req.id, req.off);
	    o.pageSize = 3;
	    pbase = truncate(req.off>>page_shift8);
	    idxOffset = idxOffset8;
	 end
	 else if (cond4) begin
	    //$display("request: req.id=%h req.off=%h", req.id, req.off);
	    o.pageSize = 2;
	    pbase = truncate(req.off>>page_shift4);
	    idxOffset = idxOffset4;
	 end
	 else if (cond0) begin
	    //$display("request: req.id=%h req.off=%h", req.id, req.off);
	    o.pageSize = 1;
	    pbase = truncate(req.off>>page_shift0);
	    idxOffset = idxOffset0;
	 end
	 offs0[i].enq(o);
	 pbases[i].enq(pbase);
	 idxOffsets1[i].enq(idxOffset);
	 ptrs1[i].enq(req.id);
      endrule
      rule stage4;
	 let off <- toGet(offs0[i]).get();
	 let pbase <- toGet(pbases[i]).get();
	 let idxOffset <- toGet(idxOffsets1[i]).get();
	 let ptr <- toGet(ptrs1[i]).get();
	 Bit#(IndexWidth) p = pbase + idxOffset;
	 if (off.pageSize == 0) begin
	    //FIXME offset
	    //$display("mkSGListMMU.addr[%d].request.put: ERROR   ptr=%h off=%h\n", i, ptr, off);
	    dmaErrorFifo.enq(DmaError { errorType: DmaErrorBadAddrTrans, pref: extend(ptr) });
	 end
	 //$display("p ages[%d].read %h", i, rp[i].first());
	 portsel(pages, i).request.put(BRAMRequest{write:False, responseOnWrite:False,
            address:{ptr,p}, datain:?});
	 offs1[i].enq(off);
      endrule
      rule stage5;
	 Page page <- portsel(pages, i).response.get;
	 let offset <- toGet(offs1[i]).get();
	 //$display("p ages[%d].response page=%h offset=%h", i, page, offset);
	 Bit#(ObjectOffsetSize) rv = ?;
	 Page4 b4 = truncate(page);
	 Page8 b8 = truncate(page);
	 case (offset.pageSize) 
	    1: rv = {page,truncate(offset.value)};
	    2: rv = {b4,truncate(offset.value)};
	    3: rv = {b8,truncate(offset.value)};
	 endcase
	 pageResponseFifos[i].enq(truncate(rv));
      endrule
   end

   FIFO#(SGListId) configRespFifo <- mkFIFO;
   rule sendConfigResp;
      let ptr <- toGet(configRespFifo).get();
      dmaIndication.configResp(extend(ptr));
   endrule

   Vector#(2,Server#(ReqTup,Bit#(addrWidth))) addrServers;
   for(Integer i = 0; i < 2; i=i+1)
      addrServers[i] =
      (interface Server#(ReqTup,Bit#(addrWidth));
	  interface Put request;
	     method Action put(ReqTup req);
		incomingReqs[i].enq(req);
	     endmethod
	  endinterface
	  interface Get response;
	     method ActionValue#(Bit#(addrWidth)) get();
		let rv <- toGet(pageResponseFifos[i]).get();
		return rv;
	     endmethod
	  endinterface
       endinterface);

   // FIXME: split this into three methods?
   interface SGListSetup setup;
   method Action region(Bit#(32) pointer, Bit#(64) barr8, Bit#(32) index8, Bit#(64) barr4, Bit#(32) index4, Bit#(64) barr0, Bit#(32) index0);
      portsel(reg8, 0).request.put(BRAMRequest{write:True, responseOnWrite:False,
          address: truncate(pointer), datain: Region{barrier: truncate(barr8), idxOffset: truncate(index8)}});
      portsel(reg4, 0).request.put(BRAMRequest{write:True, responseOnWrite:False,
          address: truncate(pointer), datain: Region{barrier: truncate(barr4), idxOffset: truncate(index4)}});
      portsel(reg0, 0).request.put(BRAMRequest{write:True, responseOnWrite:False,
          address: truncate(pointer), datain: Region{barrier: truncate(barr0), idxOffset: truncate(index0)}});
      //$display("region pointer=%d off8=%h off4=%h off0=%h", pointer, off8, off4, off0);
      configRespFifo.enq(truncate(pointer));
   endmethod

   method Action sglist(Bit#(32) pointer, Bit#(32) pointerIndex, Bit#(64) addr,  Bit#(32) len);
`ifdef BSIM
`ifndef PCIE
	 let va <- pareff(pointer, len);
`endif
`endif
         Bit#(IndexWidth) ind = truncate(pointerIndex);
	 portsel(pages, 0).request.put(BRAMRequest{write:True, responseOnWrite:False,
             address:{truncate(pointer),ind}, datain:truncate(addr)});
   endmethod
   endinterface
   interface addr = addrServers;

endmodule

interface SglAddrServer#(numeric type addrWidth, numeric type numServers);
   interface Vector#(numServers,Server#(ReqTup,Bit#(addrWidth))) servers;
endinterface

module mkSglAddrServer#(Server#(ReqTup,Bit#(addrWidth)) server) (SglAddrServer#(addrWidth,numServers));
   
   FIFOF#(Bit#(TAdd#(1,TLog#(numServers)))) tokFifo <- mkSizedFIFOF(9);
   Vector#(numServers, Server#(ReqTup,Bit#(addrWidth))) addrServers;
   Reg#(Bit#(TLog#(numServers))) arb <- mkReg(0);

   // this is a very crude arbiter.  something more sophisticated may be required (mdk)
   rule inc_arb;
      arb <= arb+1;
   endrule
   
   for(Integer i = 0; i < valueOf(numServers); i=i+1)
      addrServers[i] = 
      (interface Server#(ReqTup,Bit#(addrWidth));
	  interface Put request;
	     method Action put(ReqTup req) if (arb == fromInteger(i));
		tokFifo.enq(fromInteger(i));
		server.request.put(req);
	     endmethod
	  endinterface
	  interface Get response;
	     method ActionValue#(Bit#(addrWidth)) get() if (tokFifo.first == fromInteger(i));
		tokFifo.deq;
		let rv <- server.response.get;
		return rv;
	     endmethod
	  endinterface
       endinterface);

   interface servers = addrServers;

endmodule
