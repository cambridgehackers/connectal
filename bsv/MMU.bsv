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
import Connectable::*;
import BRAMFIFO::*;
import BRAM::*;

import ConnectalBram::*;
import MemTypes::*;
import StmtFSM::*;
import ClientServer::*;
import ConnectalMemory::*;
import ConnectalCompletionBuffer::*;
import SimDma::*;

`include "ConnectalProjectConfig.bsv"

typedef 32 MaxNumSGLists;
typedef Bit#(TLog#(MaxNumSGLists)) SGListId;
typedef 12 SGListPageShift0;
typedef 16 SGListPageShift4;
typedef 20 SGListPageShift8;
typedef 24 SGListPageShift12;
typedef Bit#(TLog#(MaxNumSGLists)) RegionsIdx;

typedef 8 IndexWidth;

typedef struct {
   SGListId             id;
   Bit#(MemOffsetSize) off;
} AddrTransRequest deriving (Eq,Bits,FShow);

interface MMU#(numeric type addrWidth);
   interface MMURequest request;
   interface Vector#(2,Server#(AddrTransRequest,Bit#(addrWidth))) addr;
endinterface

typedef struct {
   Bit#(3) pageSize;
   Bit#(SGListPageShift12) value;
} Offset deriving (Eq,Bits,FShow);

typedef Bit#(TSub#(MemOffsetSize,SGListPageShift0)) Page0;
typedef Bit#(TSub#(MemOffsetSize,SGListPageShift4)) Page4;
typedef Bit#(TSub#(MemOffsetSize,SGListPageShift8)) Page8;
typedef Bit#(TSub#(MemOffsetSize,SGListPageShift12)) Page12;

typedef struct {
   Bit#(TSub#(MemOffsetSize,SGListPageShift0)) barrier;
   Bit#(IndexWidth) idxOffset;
   } SingleRegion deriving (Eq,Bits,FShow);

typedef struct {
   SingleRegion reg12;
   SingleRegion reg8;
   SingleRegion reg4;
   SingleRegion reg0;
   } Region deriving (Eq,Bits,FShow);

typedef struct {DmaErrorType errorType;
		Bit#(32) pref;
		Bit#(MemOffsetSize) off;
   } DmaError deriving (Bits);

typedef struct {
   Bool cond12;
   Bool cond8;
   Bool cond4;
   Bool cond0;
   Bit#(IndexWidth) idxOffset12;
   Bit#(IndexWidth) idxOffset8;
   Bit#(IndexWidth) idxOffset4;
   Bit#(IndexWidth) idxOffset0;
   AddrTransRequest req;
   } Stage3Params deriving (Bits);

typedef struct {
   Offset off;
   Bit#(IndexWidth) pbase;
   Bit#(IndexWidth) idxOffset;
   SGListId ptr;
   } Stage4Params deriving (Bits);

// the address translation servers (addr[0], addr[1]) have a latency of 8 and are fully pipelined
module mkMMU#(Integer iid, Bool hostMapped, MMUIndication mmuIndication)(MMU#(addrWidth))
   provisos(Log#(MaxNumSGLists, listIdxSize),
	    Add#(listIdxSize,8, entryIdxSize),
	    Add#(a__,addrWidth,MemOffsetSize));
   
	    
   let verbose = False;
   TagGen#(MaxNumSGLists) sglId_gen <- mkTagGen();
   rule complete_sglId_gen;
      let __x <- sglId_gen.complete;
   endrule
   
   // for simulators
   SimDma#(32) simDma <- mkSimDma();

   // stage 0 (latency == 1)
   Vector#(2, FIFO#(AddrTransRequest)) incomingReqs <- replicateM(mkFIFO);

   // stage 1 (latency == 2)
   BRAM_Configure bramConfig = defaultValue;
   bramConfig.latency        = 2;
   BRAM2Port#(RegionsIdx, Maybe#(Region)) regall <- ConnectalBram::mkBRAM2Server(bramConfig);
   Vector#(2,FIFOF#(AddrTransRequest))          reqs0 <- replicateM(mkSizedFIFOF(3));
   
   // stage 2 (latency == 1)
   Vector#(2, FIFOF#(Stage3Params)) stage3Params <- replicateM(mkFIFOF);

   // stage 3 (latency == 1)
   Vector#(2, FIFOF#(Stage4Params)) stage4Params <- replicateM(mkFIFOF);

   // stage 4 (latency == 2)
   BRAM2Port#(Bit#(entryIdxSize),Page0) pages <- ConnectalBram::mkBRAM2Server(bramConfig);
   Vector#(2,FIFOF#(Offset))           offs1 <- replicateM(mkSizedFIFOF(3));

   // stage 4 (latnecy == 1)
   Vector#(2,FIFOF#(Bit#(addrWidth))) pageResponseFifos <- replicateM(mkFIFOF);
      
   FIFO#(DmaError) dmaErrorFifo <- mkFIFO();
   Vector#(2,FIFO#(DmaError)) dmaErrorFifos <- replicateM(mkFIFO());
   for (Integer i = 0; i < 2; i = i + 1)
      mkConnection(toGet(dmaErrorFifos[i]), toPut(dmaErrorFifo));
   rule dmaError;
      let error <- toGet(dmaErrorFifo).get();
      mmuIndication.error(extend(pack(error.errorType)), error.pref, extend(error.off), fromInteger(iid));
   endrule

   let page_shift0 = fromInteger(valueOf(SGListPageShift0));
   let page_shift4 = fromInteger(valueOf(SGListPageShift4));
   let page_shift8 = fromInteger(valueOf(SGListPageShift8));
   let page_shift12 = fromInteger(valueOf(SGListPageShift12));
   
   function BRAMServer#(a,b) portsel(BRAM2Port#(a,b) x, Integer i);
      if(i==0) return x.portA;
      else return x.portB;
   endfunction
   
   for (Integer i = 0; i < 2; i=i+1) begin
      rule stage1;  // first read in the address cutoff values between regions
	 AddrTransRequest req <- toGet(incomingReqs[i]).get();
	 portsel(regall, i).request.put(BRAMRequest{write:False, responseOnWrite:False,
            address:truncate(req.id), datain:?});
	 reqs0[i].enq(req);
      endrule

      // pipeline the address lookup
      rule stage2; // Now compare address cutoffs with requested offset
	 AddrTransRequest req <- toGet(reqs0[i]).get;
	 Maybe#(Region) m_regionall <- portsel(regall,i).response.get;
	 
	 case (m_regionall) matches 
	    tagged Valid .regionall: begin
               Page0 off0 = truncate(req.off >> valueOf(SGListPageShift0));
               Page4 off4 = truncate(req.off >> valueOf(SGListPageShift4));
               Page8 off8 = truncate(req.off >> valueOf(SGListPageShift8));
               Page12 off12 = truncate(req.off >> valueOf(SGListPageShift12));
	       let cond12 = off12 < truncate(regionall.reg12.barrier);
	       let cond8 = off8 < truncate(regionall.reg8.barrier);
	       let cond4 = off4 < truncate(regionall.reg4.barrier);
	       let cond0 = off0 < regionall.reg0.barrier;
	       
	       if (verbose) $display("mkMMU::stage2: id=%d off=%h (%h %h %h) (%h %h %h)", req.id, req.off, 
				     regionall.reg8.barrier, regionall.reg4.barrier, regionall.reg0.barrier,
				     off8, off4, off0);
	       
	       stage3Params[i].enq(Stage3Params {cond12: cond12, cond8: cond8, cond4: cond4, cond0: cond0,
						 idxOffset12: regionall.reg12.idxOffset,idxOffset8: regionall.reg8.idxOffset,
						 idxOffset4: regionall.reg4.idxOffset, idxOffset0: regionall.reg0.idxOffset,
						 req: req });
	    end
	    tagged Invalid:
	       dmaErrorFifos[0].enq(DmaError { errorType: DmaErrorSGLIdInvalid, pref: extend(req.id), off:req.off });
	 endcase
      endrule
      rule stage3; // Based on results of comparision, select a region, putting it into 'o.pageSize'.  idxOffset holds offset in sglist table of relevant entry
	 let params <- toGet(stage3Params[i]).get();
	 AddrTransRequest req = params.req;
	 Offset o = Offset{pageSize: 0, value: truncate(req.off)};
	 Bit#(IndexWidth) pbase = 0;
	 Bit#(IndexWidth) idxOffset = 0;

	 if (params.cond12) begin
	    if (verbose) $display("mkMMU::request: req.id=%h req.off=%h", req.id, req.off);
	    o.pageSize = 4;
	    pbase = truncate(req.off>>page_shift12);
	    idxOffset = params.idxOffset12;
	 end
	 else if (params.cond8) begin
	    if (verbose) $display("mkMMU::request: req.id=%h req.off=%h", req.id, req.off);
	    o.pageSize = 3;
	    pbase = truncate(req.off>>page_shift8);
	    idxOffset = params.idxOffset8;
	 end
	 else if (params.cond4) begin
	    if (verbose) $display("mkMMU::request: req.id=%h req.off=%h", req.id, req.off);
	    o.pageSize = 2;
	    pbase = truncate(req.off>>page_shift4);
	    idxOffset = params.idxOffset4;
	 end
	 else if (params.cond0) begin
	    if (verbose) $display("mkMMU::request: req.id=%h req.off=%h", req.id, req.off);
	    o.pageSize = 1;
	    pbase = truncate(req.off>>page_shift0);
	    idxOffset = params.idxOffset0;
	 end
	 stage4Params[i].enq(Stage4Params { off: o, pbase: pbase, idxOffset: idxOffset, ptr: req.id });
      endrule
      (* descending_urgency = "stage2, stage4" *)
      rule stage4; // Read relevant sglist entry
	 let params <- toGet(stage4Params[i]).get();
	 let off = params.off;
	 let pbase = params.pbase;
	 let idxOffset = params.idxOffset;
	 let ptr = params.ptr;
	 Bit#(IndexWidth) p = pbase + idxOffset;
	 if (off.pageSize == 0) begin
	    if (verbose) $display("mkMMU::addr[%d].request.put: ERROR   ptr=%h off=%h\n", i, ptr, off);
	    dmaErrorFifos[1].enq(DmaError { errorType: DmaErrorOffsetOutOfRange, pref: extend(ptr), off:extend(off.value) });
	 end
	 else begin
	    if (verbose) $display("mkMMU::pages[%d].read %h", i, {ptr,p});
	    portsel(pages, i).request.put(BRAMRequest{write:False, responseOnWrite:False,
						      address:{ptr,p}, datain:?});
	    offs1[i].enq(off);
	 end
      endrule
      rule stage5; // Concatenate page base address from sglist entry with LSB offset bits from request and return
	 Page0 page <- portsel(pages, i).response.get;
	 let offset <- toGet(offs1[i]).get();
	 if (verbose) $display("mkMMU::p ages[%d].response page=%h offset=%h", i, page, offset);
	 Bit#(MemOffsetSize) rv = ?;
	 Page4 b4 = truncate(page);
	 Page8 b8 = truncate(page);
	 Page12 b12 = truncate(page);
	 case (offset.pageSize) 
	    1: rv = {page,truncate(offset.value)};
	    2: rv = {b4,truncate(offset.value)};
	    3: rv = {b8,truncate(offset.value)};
	    4: rv = {b12,truncate(offset.value)};
	 endcase
	 pageResponseFifos[i].enq(truncate(rv));
      endrule
   end

   FIFO#(SGListId) configRespFifo <- mkFIFO;
   rule sendConfigResp;
      let ptr <- toGet(configRespFifo).get();
      mmuIndication.configResp(extend(ptr));
   endrule
   
   // given that the BRAM is faster than the connection from software, I see no need for a SizedBRAMFIFOF here. -Jamey
   FIFOF#(Bit#(32)) idReturnFifo <- mkFIFOF();
   rule idReturnRule;
      let sglId <- toGet(idReturnFifo).get;
      sglId_gen.returnTag(truncate(sglId));
      portsel(regall, 1).request.put(BRAMRequest{write:True, responseOnWrite:False, address: truncate(sglId), datain: tagged Invalid });
      $display("idReturn %d", sglId);
   endrule
   
   function Server#(AddrTransRequest,Bit#(addrWidth)) addrServer(Integer i);
   return
      (interface Server#(AddrTransRequest,Bit#(addrWidth));
	  interface Put request;
	     method Action put(AddrTransRequest req);
		incomingReqs[i].enq(req);
	     endmethod
	  endinterface
	  interface Get response;
	     method ActionValue#(Bit#(addrWidth)) get();
		let rv <- toGet(pageResponseFifos[i]).get();
`ifdef BSIM
		rv = rv | (fromInteger(iid)<<valueOf(addrWidth)-3);
`endif
`ifdef XSIM
		rv = rv | (fromInteger(iid)<<valueOf(addrWidth)-3);
`endif
		return rv;
	     endmethod
	  endinterface
       endinterface);
   endfunction
      
   interface MMURequest request;
   method Action idRequest(SpecialTypeForSendingFd fd);
      let nextId <- sglId_gen.getTag;
      let resp = (fromInteger(iid) << 16) | extend(nextId);
      if (verbose) $display("mkMMU::idRequest %d", fd);
      let va <- simDma.initfd(resp, fd);
      mmuIndication.idResponse(resp);
   endmethod
   method Action idReturn(Bit#(32) sglId);
      idReturnFifo.enq(sglId);
      if (hostMapped)
	 simDma.idreturn(sglId);
   endmethod
   method Action region(Bit#(32) pointer, Bit#(64) barr12, Bit#(32) index12, Bit#(64) barr8, Bit#(32) index8, Bit#(64) barr4, Bit#(32) index4, Bit#(64) barr0, Bit#(32) index0);
      portsel(regall, 1).request.put(BRAMRequest{write:True, responseOnWrite:False,
          address: truncate(pointer), datain: tagged Valid Region{
             reg12: SingleRegion{barrier: truncate(barr12), idxOffset: truncate(index12)},
             reg8: SingleRegion{barrier: truncate(barr8), idxOffset: truncate(index8)},
             reg4: SingleRegion{barrier: truncate(barr4), idxOffset: truncate(index4)},
             reg0: SingleRegion{barrier: truncate(barr0), idxOffset: truncate(index0)}} });
      if (verbose) $display("mkMMU::region pointer=%d barr12=%h barr8=%h barr4=%h barr0=%h", pointer, barr12, barr8, barr4, barr0);
      configRespFifo.enq(truncate(pointer));
   endmethod

   method Action sglist(Bit#(32) pointer, Bit#(32) pointerIndex, Bit#(64) addr,  Bit#(32) len);
         if (fromInteger(iid) != pointer[31:16]) begin
	    $display("mkMMU::sglist ERROR");
	    $finish();
	 end
	 if(hostMapped)
	    let va <- simDma.init({0,pointer[31:16]}, {0,pointer[15:0]}, len);
         Bit#(IndexWidth) ind = truncate(pointerIndex);
	 portsel(pages, 0).request.put(BRAMRequest{write:True, responseOnWrite:False,
             address:{truncate(pointer),ind}, datain:truncate(addr)});
         if (verbose) $display("mkMMU::sglist pointer=%d pointerIndex=%d addr=%d len=%d", pointer, pointerIndex, addr, len);
   endmethod
   method Action setInterface(Bit#(32) interfaceId, Bit#(32) sglId);
       /* this method is only implemented in s/w responders */
   endmethod
   endinterface
   interface addr = genWith(addrServer);

endmodule

interface ArbitratedMMU#(numeric type addrWidth, numeric type numServers);
   interface Vector#(numServers,Server#(AddrTransRequest,Bit#(addrWidth))) servers;
endinterface

module mkArbitratedMMU#(Server#(AddrTransRequest,Bit#(addrWidth)) server) (ArbitratedMMU#(addrWidth,numServers));
   
   FIFOF#(Bit#(TAdd#(1,TLog#(numServers)))) tokFifo <- mkSizedFIFOF(9);
   Reg#(Bit#(TLog#(numServers))) arb <- mkReg(0);

   // this is a very crude arbiter.  something more sophisticated may be required (mdk)
   rule inc_arb;
      arb <= arb+1;
   endrule
   
   function Server#(AddrTransRequest,Bit#(addrWidth)) arbitratedServer(Integer i);
   return
      (interface Server#(AddrTransRequest,Bit#(addrWidth));
	  interface Put request;
	     method Action put(AddrTransRequest req) if (arb == fromInteger(i));
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
   endfunction

   interface servers = genWith(arbitratedServer);

endmodule
