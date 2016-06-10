// Copyright (c) 2016 Connectal Project

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

import Arbitrate::*;
import BRAM::*;
import BuildVector::*;
import Clocks::*;
import Connectable::*;
import FIFOF::*;
import GetPut::*;
import Probe::*;
import StmtFSM::*;
import Vector::*;

import AddressGenerator::*;
import AxiBits::*;
import ConnectalClocks::*;
import ConnectalConfig::*;
import DefaultValue::*;
import HostInterface::*;
import MemReadEngine::*;
import MemTypes::*;
import PhysMemSlaveFromBram::*;
import Pipe::*;
import TraceMemClient::*;
import XilinxCells::*;
import MPEngine::*;

import AxiPcieRootPort::*;
import NvmeIfc::*;
import NvmePins::*;

typedef struct {
   Bit#(8)  opcode;
   Bit#(8)  flags;
   Bit#(16) requestId;
   Bit#(64) startBlock;
   Bit#(32) numBlocks;
   } NvmeIoCommand deriving (Bits);

`ifndef TOP_SOURCES_PORTAL_CLOCK
import ConnectalBramFifo::*;
`else
import BRAMFIFO::*;
module mkDualClockBramFIFOF#(Clock clock1, Reset reset1, Clock clock2, Reset reset2)(FIFOF#(a))
   provisos (Bits#(a, asz), Add#(1, a__, asz));
   FIFOF#(a) fifo <- mkSizedBRAMFIFOF(512, clocked_by clock1, reset_by reset1);
   return fifo;
endmodule
`endif


function PipeIn#(t) sinkPipe();
   return (interface PipeIn#(a);
	      method Action enq(t v); endmethod
	      method Bool notFull(); return False; endmethod
	   endinterface);
endfunction

instance ArbRequestTC#(BRAMRequest#(a,b));
   function Bool isReadRequest(BRAMRequest#(a,b) x); return !x.write; endfunction
   function Bool isWriteRequest(BRAMRequest#(a,b) x); return x.write; endfunction
endinstance

interface Nvme;
   interface NvmeRequest request;
   interface MemServerPortalRequest bramRequest;
   interface NvmeTrace trace;
   interface NvmePins pins;
   interface Vector#(2, MemReadClient#(DataBusWidth)) dmaReadClient;
   interface Vector#(1, MemWriteClient#(DataBusWidth)) dmaWriteClient;
`ifdef TOP_SOURCES_PORTAL_CLOCK
   interface Clock portalClockSource;
`endif
endinterface

module mkNvme#(NvmeIndication ind, NvmeTrace trace, MemServerPortalIndication bramIndication)(Nvme);
   let clock <- exposeCurrentClock;
   let reset <- exposeCurrentReset;
   let refclk_p <- mkB2C1();
   let refclk_n <- mkB2C1();
   let pcie_clk_100mhz_buf <- mkClockIBUFDS_GTE2(
`ifdef ClockDefaultParam
       defaultValue,
`endif
      True, refclk_p.c, refclk_n.c);
`ifndef TOP_SOURCES_PORTAL_CLOCK
   let axiClockB2C    <- mkB2C1();
   let axiCtlClockB2C <- mkB2C1();
   let axiClock = axiClockB2C.c;
   let axiCtlClock = axiCtlClockB2C.c;
   let axiReset <- mkSyncReset(10, reset, axiClock);
   let axiCtlReset <- mkSyncReset(10, reset, axiCtlClock);
`else
   let axiClock = clock;
   let axiCtlClock = clock;
   let axiReset = reset;
   let axiCtlReset = reset;
`endif

   let axiRootPort <- mkAPRP(pcie_clk_100mhz_buf, reset, axiClock, axiReset, axiCtlClock, axiCtlReset);
`ifndef TOP_SOURCES_PORTAL_CLOCK
   let axiClockC2B <- mkC2B(axiRootPort.axi.aclk_out);
   let axiCtlClockC2B <- mkC2B(axiRootPort.axi.ctl_aclk_out);
   rule rl_connect_clocks;
      axiClockB2C.inputclock(axiClockC2B.o);
      axiCtlClockB2C.inputclock(axiClockC2B.o);
   endrule
`endif

   FIFOF#(Bit#(32)) dfifoCtl <- mkFIFOF();
   Axi4SlaveBits#(32,DataBusWidth,4,Empty) axiRootPortSlave    = toAxi4SlaveBits(axiRootPort.s_axi);
   Axi4SlaveLiteBits#(32,32)     axiRootPortSlaveCtl = toAxi4SlaveBits(axiRootPort.s_axi_ctl);
   PhysMemSlave#(32,DataBusWidth)          axiRootPortMemSlave    <- mkPhysMemSlave(axiRootPortSlave, clocked_by axiClock, reset_by axiReset);
   PhysMemSlave#(32,32)          axiRootPortMemSlaveCtl <- mkPhysMemSlave(axiRootPortSlaveCtl, clocked_by axiCtlClock, reset_by axiCtlReset);

   FIFOF#(PhysMemRequest#(32,DataBusWidth)) araddrFifo <- mkFIFOF();
   FIFOF#(PhysMemRequest#(32,DataBusWidth)) awaddrFifo <- mkFIFOF();
   FIFOF#(MemData#(DataBusWidth))           rdataFifo <- mkFIFOF();
   FIFOF#(MemData#(DataBusWidth))           wdataFifo <- mkFIFOF();
   FIFOF#(Bit#(6))                           doneFifo <- mkFIFOF();

   let araddrCnx <- mkConnection(toGet(araddrFifo), axiRootPortMemSlave.read_server.readReq);
   let awaddrCnx <- mkConnection(toGet(awaddrFifo), axiRootPortMemSlave.write_server.writeReq);
   let rdataCnx  <- mkConnection(axiRootPortMemSlave.read_server.readData, toPut(rdataFifo));
   let wdataCnx  <- mkConnection(toGet(wdataFifo), axiRootPortMemSlave.write_server.writeData);
   let doneCnx   <- mkConnection(axiRootPortMemSlave.write_server.writeDone, toPut(doneFifo));

   rule rl_rdata;
      let rdata <- toGet(rdataFifo).get();
      if (rdata.tag == 0)
	 ind.readDone(rdata.data);
   endrule

   rule rl_writeDone;
      let tag <- toGet(doneFifo).get();
      if (tag == 0)
	 ind.writeDone();
   endrule

   FIFOF#(PhysMemRequest#(32,32)) araddrFifoCtl <- mkFIFOF();
   FIFOF#(PhysMemRequest#(32,32)) awaddrFifoCtl <- mkFIFOF();
   FIFOF#(MemData#(32))           rdataFifoCtl <- mkFIFOF();
   FIFOF#(MemData#(32))           wdataFifoCtl <- mkFIFOF();
   FIFOF#(Bit#(6))                doneFifoCtl <- mkFIFOF();

   let araddrCtlCnx <- mkConnection(toGet(araddrFifoCtl), axiRootPortMemSlaveCtl.read_server.readReq);
   let awaddrCtlCnx <- mkConnection(toGet(awaddrFifoCtl), axiRootPortMemSlaveCtl.write_server.writeReq);
   let rdataCtlCnx  <- mkConnection(axiRootPortMemSlaveCtl.read_server.readData, toPut(rdataFifoCtl));
   let wdataCtlCnx  <- mkConnection(toGet(wdataFifoCtl), axiRootPortMemSlaveCtl.write_server.writeData);
   let doneCtlCnx   <- mkConnection(axiRootPortMemSlaveCtl.write_server.writeDone, toPut(doneFifoCtl));

   rule rl_rdata_ctl;
      let rdata <- toGet(rdataFifoCtl).get();
      ind.readDone(extend(rdata.data));
   endrule

   rule rl_writeDone_ctl;
      let tag <- toGet(doneFifoCtl).get();
      ind.writeDone();
   endrule

   Axi4MasterBits#(32,DataBusWidth,MemTagSize,Empty) m_axi_mm = toAxi4MasterBits(axiRootPort.m_axi);
   let getObjId = (interface GetObjId;
		   method SGLId objId(Bit#(32) addr); return extend(addr[31:24]); endmethod
		   method Bit#(MemOffsetSize) addr(Bit#(32) axiAddr); return extend(axiAddr[23:0]); endmethod
		   endinterface);
   let memReadClient  <- mkMemReadClient(getObjId, m_axi_mm);
   let memWriteClient <- mkMemWriteClient(getObjId, m_axi_mm);

   Reg#(Bool) traceEnabled <- mkReg(False);

   FIFOF#(Tuple4#(DmaChannel,Bool,MemRequest,Bit#(32))) traceFifo <- mkSizedBRAMFIFOF(128);
   PipeIn#(Tuple4#(DmaChannel,Bool,MemRequest,Bit#(32))) tracePipe = traceEnabled ? toPipeIn(traceFifo) : sinkPipe();
   FIFOF#(Tuple4#(DmaChannel,Bool,MemData#(DataBusWidth),Bit#(32))) traceDataFifo <- mkSizedBRAMFIFOF(2048);
   PipeIn#(Tuple4#(DmaChannel,Bool,MemData#(DataBusWidth),Bit#(32))) traceDataPipe = traceEnabled ? toPipeIn(traceDataFifo) : sinkPipe();
   FIFOF#(Tuple2#(DmaChannel,Bit#(32)))                              traceDoneFifo <- mkSizedBRAMFIFOF(128);
   PipeIn#(Tuple2#(DmaChannel,Bit#(32)))                             traceDonePipe = traceEnabled ? toPipeIn(traceDoneFifo) : sinkPipe();

   rule rl_trace1;
      match { .chan, .write, .req, .timestamp } <- toGet(traceFifo).get();
      trace.traceDmaRequest(chan, write, truncate(req.sglId), extend(req.offset), extend(req.burstLen), extend(req.tag), timestamp);
   endrule
   rule rl_trace_data;
      match { .chan, .write, .md, .timestamp } <- toGet(traceDataFifo).get();
      trace.traceDmaData(chan, write, md.data, md.last, extend(md.tag), timestamp);
   endrule
   rule rl_trace_done;
      match { .chan, .timestamp } <- toGet(traceDoneFifo).get();
      trace.traceDmaDone(chan, 0, timestamp);
   endrule

   let traceReadClient <- mkTraceReadClient(tracePipe,traceDataPipe,DMA_TX,memReadClient);
   let traceWriteClient <- mkTraceWriteClient(tracePipe,traceDataPipe,traceDonePipe,DMA_RX,memWriteClient);
   let traceClient = (interface MemClient#(DataBusWidth);
			 interface readClient = traceReadClient;
			 interface writeClient = traceWriteClient;
		      endinterface);

   let splitter <- mkSplitMemServer();
   BRAM_Configure bramConfig = defaultValue;
   bramConfig.latency = 2;
   bramConfig.memorySize = 2048; // 4 pages
   BRAM2Port#(Bit#(32),Bit#(DataBusWidth)) bram <- mkBRAM2Server(bramConfig);

   let arbIfc <- mkFixedPriority();
   Arbiter#(2, BRAMRequest#(Bit#(32),Bit#(DataBusWidth)),Bit#(DataBusWidth)) arbiter <- mkArbiter(arbIfc,2);
   let arbCnx <- mkConnection(arbiter.master, bram.portB);

   MemServer#(DataBusWidth)            bramMemA <- mkMemServerFromBram(bram.portA);
   PhysMemSlave#(32,DataBusWidth)      bramMemB <- mkPhysMemSlaveFromBram(arbiter.users[0]);
   MemServerPortal          bramMemServerPortal <- mkPhysMemSlavePortal(bramMemB,bramIndication);

   let portB1 = arbiter.users[1];
   Reg#(Bit#(16)) requestId <- mkReg(0);
   Reg#(Bit#(16)) requestQueueEntryCount <- mkReg(8);
   Reg#(Bool) requestInProgress <- mkReg(True);
   Reg#(Vector#(16,Bit#(32))) ioCommand <- mkReg(unpack(0));

   FIFOF#(NvmeIoCommand) ioCommandFifo <- mkFIFOF();

   let bramQueryAddress <- mkProbe();
   let bramQueryResponse <- mkProbe();
   let requestCompleted <- mkProbe();

   let fsm <- mkAutoFSM(seq
      while (True) seq
	 action
	    let req <- toGet(ioCommandFifo).get();
	    Vector#(16,Bit#(32)) command = unpack(0);
	    command[0] = { req.requestId, req.flags, req.opcode };
	    command[1] = 1; // nsid
	    // prp1: send data to fifo
	    command[6] = 32'h30000000;
	    // p2p2: read PRP list from BRAM at offset 0x2000
	    command[8] = 32'h20002000;
	    command[10] = req.startBlock[31:0];
	    command[11] = req.startBlock[63:32];
	    command[12] = req.numBlocks-1;
	    requestId <= req.requestId;
	    ioCommand <= command; 
	 endaction
	 // write a IO read request to BRAM
	 portB1.request.put(BRAMRequest {address: 'h1000/8 + (extend(requestId[2:0]) << 3) + 0, write: True, responseOnWrite: False, datain: {ioCommand[1],ioCommand[0]}});
	 portB1.request.put(BRAMRequest {address: 'h1000/8 + (extend(requestId[2:0]) << 3) + 1, write: True, responseOnWrite: False, datain: {ioCommand[3],ioCommand[2]}});
	 portB1.request.put(BRAMRequest {address: 'h1000/8 + (extend(requestId[2:0]) << 3) + 2, write: True, responseOnWrite: False, datain: {ioCommand[5],ioCommand[4]}});
	 portB1.request.put(BRAMRequest {address: 'h1000/8 + (extend(requestId[2:0]) << 3) + 3, write: True, responseOnWrite: False, datain: {ioCommand[7],ioCommand[6]}});
	 portB1.request.put(BRAMRequest {address: 'h1000/8 + (extend(requestId[2:0]) << 3) + 4, write: True, responseOnWrite: False, datain: {ioCommand[9],ioCommand[8]}});
	 portB1.request.put(BRAMRequest {address: 'h1000/8 + (extend(requestId[2:0]) << 3) + 5, write: True, responseOnWrite: False, datain: {ioCommand[11],ioCommand[10]}});
	 portB1.request.put(BRAMRequest {address: 'h1000/8 + (extend(requestId[2:0]) << 3) + 6, write: True, responseOnWrite: False, datain: {ioCommand[13],ioCommand[12]}});
	 portB1.request.put(BRAMRequest {address: 'h1000/8 + (extend(requestId[2:0]) << 3) + 7, write: True, responseOnWrite: False, datain: {ioCommand[15],ioCommand[14]}});
	 // tell the NVME the new submission queue tail pointer
	 action
	    awaddrFifo.enq(PhysMemRequest { addr: 'h1000 + (2*2+0)*(4<<0), burstLen: 4, tag: 1 });
	    wdataFifo.enq(MemData{data: zeroExtend((requestId+1)[2:0]), tag: 1, last: True});
	    requestInProgress <= True;
	 endaction
	 // wait for response queue to be updated
	 while (requestInProgress) seq
	    portB1.request.put(BRAMRequest {address: (extend(requestId[2:0]) << 1) + 1, write: False, responseOnWrite: False, datain: 0});
	    bramQueryAddress <= (requestId << 1) + 1;
	    action
	       let response <- portB1.response.get();
	       bramQueryResponse <= response;
	       if (response[16+32] == 1) begin
		  requestCompleted <= response;
		  // if status field written by NVME
		  let nextRequestId = (requestId + 1);
		  if (nextRequestId == requestQueueEntryCount)
		     nextRequestId = 0;
		  requestId <= nextRequestId;
		  ind.transferCompleted(requestId, response);
		  requestInProgress <= False;
	       end
	    endaction
	 endseq // while requestInProgress

	 // tell the NVME the new response queue head pointer
	 action
	    awaddrFifo.enq(PhysMemRequest { addr: 'h1000 + (2*2+1)*(4<<0), burstLen: 4, tag: 1 });
	    wdataFifo.enq(MemData{data: zeroExtend((requestId+1)[2:0]), tag: 1, last: True});
	 endaction
      endseq // while True
      endseq);

   Reg#(Bit#(32))                       dataCounter <- mkReg(0);
   FIFOF#(Bit#(32))                  dataLengthFifo <- mkFIFOF();
   let                                     fifoToMp <- mkFIFOF();
   MemReadEngine#(DataBusWidth,DataBusWidth,2,1) re <- mkMemReadEngine();
   MPEngine#(DataBusWidth,DataBusWidth)    mpEngine <- mkMPStreamEngine(toPipeOut(fifoToMp), re.readServers[0]);

   rule rl_count_data_to_mp;
      let data <- toGet(splitter.data).get();
      data.last = (dataCounter+fromInteger(valueOf(DataBusWidth)/8)) >= dataLengthFifo.first;
      fifoToMp.enq(data);
      dataCounter <= dataCounter + 1;
   endrule

   let traceMemCnx <- mkConnection(traceClient, splitter.server);
   let bramMemCnx  <- mkConnection(splitter.bramClient, bramMemA);
   // rule rl_data;
   //    let md <- toGet(splitter.data).get();
   //    trace.traceData(md.data, md.last, extend(md.tag));
   // endrule
   rule rl_locdone;
      let loc <- toGet(mpEngine.locdone).get();
      ind.strstrLoc(pack(loc));
   endrule

   interface MemServerPortalRequest bramRequest = bramMemServerPortal.request;
   interface NvmeRequest request;

      method Action status();
        ind.status(axiRootPort.mmcm.lock(), dataCounter);
      endmethod
      method Action trace(Bool enabled);
	 traceEnabled <= enabled;
      endmethod
      method Action read32(Bit#(32) addr);
	 araddrFifo.enq(PhysMemRequest { addr: addr, burstLen: 4, tag: 0 });
      endmethod
      method Action write32(Bit#(32) addr, Bit#(32) value);
	 awaddrFifo.enq(PhysMemRequest { addr: addr, burstLen: 4, tag: 0 });
	 wdataFifo.enq(MemData {data: extend(value), tag: 0, last: True});
      endmethod
      method Action read(Bit#(32) addr);
	 araddrFifo.enq(PhysMemRequest { addr: addr, burstLen: fromInteger(valueOf(TDiv#(DataBusWidth,8))), tag: 0 });
      endmethod
      method Action write(Bit#(32) addr, Bit#(DataBusWidth) value);
	 awaddrFifo.enq(PhysMemRequest { addr: addr, burstLen: fromInteger(valueOf(TDiv#(DataBusWidth,8))), tag: 0 });
	 wdataFifo.enq(MemData {data: value, tag: 0, last: True});
      endmethod

      method Action readCtl(Bit#(32) addr);
	 araddrFifoCtl.enq(PhysMemRequest { addr: addr, burstLen: 4, tag: 0 });
      endmethod
      method Action writeCtl(Bit#(32) addr, Bit#(DataBusWidth) value);
	 awaddrFifoCtl.enq(PhysMemRequest { addr: addr, burstLen: 4, tag: 0 });
	 wdataFifoCtl.enq(MemData {data: truncate(value), tag: 0, last: True});
      endmethod
      method Action setSearchString(Bit#(32) needleSglId, Bit#(32) mpNextSglId, Bit#(32) needleLen);
	 mpEngine.setsearch.enq(tuple3(needleSglId, mpNextSglId, needleLen));
      endmethod
      method Action startSearch(Bit#(32) haystackLen);
	 dataLengthFifo.enq(haystackLen);
	 mpEngine.setsearch.enq(tuple3(/* unused */maxBound, haystackLen, /* unused */0));
      endmethod
      method Action startTransfer(Bit#(8) opcode, Bit#(8) flags, Bit#(16) requestId, Bit#(64) startBlock, Bit#(32) numBlocks);
	 ioCommandFifo.enq(NvmeIoCommand{opcode: opcode, flags: flags, requestId: requestId, startBlock: startBlock, numBlocks: numBlocks });
      endmethod
   endinterface
   interface Clock portalClockSource = axiRootPort.axi.aclk_out;
   interface NvmePins pins;
      interface deleteme_unused_clock = clock;
      interface pcie_sys_reset_n = reset;
      interface pcie = axiRootPort.pci;
      method Action pcie_refclk(Bit#(1) p, Bit#(1) n);
         refclk_p.inputclock(p);
         refclk_n.inputclock(n);
      endmethod
   endinterface
   interface Vector dmaReadClient = vec(splitter.busClient.readClient, re.dmaClient);
   interface Vector dmaWriteClient = vec(splitter.busClient.writeClient);
endmodule

instance ToAxi4SlaveBits#(Axi4SlaveBits#(32,DataBusWidth,4,Empty), AprpS_axi);
   function Axi4SlaveBits#(32,DataBusWidth,4,Empty) toAxi4SlaveBits(AprpS_axi s);
      return (interface Axi4SlaveBits#(32,DataBusWidth,4,Empty);
	 method araddr = compose(s.araddr, extend);
	 method arburst = s.arburst;
	 //method arcache = s.arcache;
	 method arid = s.arid;
	 method arlen = s.arlen;
	 //method arlock = s.arlock;
	 //method arprot = s.arprot;
	 //method arqos = s.arqos;
	 method arready = s.arready;
	 method arsize = s.arsize;
	 method arvalid = s.arvalid;
	 
	 method awaddr = compose(s.awaddr, extend);
	 method awburst = s.awburst;
	 //method awcache = s.awcache;
	 method awid = s.awid;
	 method awlen = s.awlen;
	 //method awlock = s.awlock;
	 //method awprot = s.awprot;
	 //method awqos = s.awqos;
	 method awready = s.awready;
	 method awsize = s.awsize;
	 method awvalid = s.awvalid;

	 method bid = s.bid;
	 method bready = s.bready;
	 method bresp = s.bresp;
	 method bvalid = s.bvalid;
	 method rdata = s.rdata;
	 method rid = s.rid;
	 method rlast = s.rlast;
	 method rready = s.rready;
	 method rresp = s.rresp;
	 method rvalid = s.rvalid;
	 method wdata = s.wdata;
	 method wlast = s.wlast;
	 method wready = s.wready;
	 method wvalid = s.wvalid;
	 method wstrb = s.wstrb;
	 endinterface);
   endfunction
endinstance

instance ToAxi4SlaveBits#(Axi4SlaveLiteBits#(32,32), AprpS_axi_ctl);
   function Axi4SlaveLiteBits#(32,32) toAxi4SlaveBits(AprpS_axi_ctl s);
      return (interface Axi4SlaveLiteBits#(32,32);
	 method araddr = compose(s.araddr, extend);
	 method arready = s.arready;
	 method arvalid = s.arvalid;

	 method awaddr = compose(s.awaddr, extend);
	 method awready = s.awready;
	 method awvalid = s.awvalid;

	 method bready = s.bready;
	 method bresp = s.bresp;
	 method bvalid = s.bvalid;
	 method rdata = s.rdata;
	 method rready = s.rready;
	 method rresp = s.rresp;
	 method rvalid = s.rvalid;
	 method wdata = s.wdata;
	 method wready = s.wready;
	 method Action      wvalid(Bit#(1) v);
	    s.wvalid(v);
	    s.wstrb(pack(replicate(v)));
	 endmethod
	 endinterface);
   endfunction
endinstance

instance ToAxi4MasterBits#(Axi4MasterBits#(32,DataBusWidth,tagWidth,Empty), AprpM_axi);
function Axi4MasterBits#(32,DataBusWidth,tagWidth,Empty) toAxi4MasterBits(AprpM_axi m);
   return (interface Axi4MasterBits#(32,DataBusWidth,tagWidth,Empty);
	   method araddr = m.araddr;
	   method arburst = m.arburst;
	   method arcache = m.arcache;
	   method arlen = m.arlen;
	   method arlock = extend(m.arlock);
	   method arready = m.arready;
	   method arsize = m.arsize;
	   method arvalid = m.arvalid;
	   method Bit#(1) aresetn(); return 1; endmethod
	   method Bit#(tagWidth)     arid(); return 0; endmethod
	   method arprot = m.arprot;
	   method arqos = 0;
	   method awaddr = m.awaddr;
	   method awburst = m.awburst;
	   method awcache = m.awcache;
	   method Bit#(tagWidth)     awid(); return 0; endmethod
	   method awlen = m.awlen;
	   method awlock = extend(m.awlock);
	   method awprot = m.awprot;
	   method awready = m.awready;
	   method Bit#(4)     awqos(); return 0; endmethod
	   method awsize = m.awsize;
	   method awvalid = m.awvalid;
	   method Action      bid(Bit#(tagWidth) v); endmethod
	   method bready = m.bready;
	   method bresp = m.bresp;
	   method bvalid = m.bvalid;
	   method rdata = m.rdata;
	   method Action      rid(Bit#(tagWidth) v); endmethod
	   method rlast = m.rlast;
	   method rready = m.rready;
	   method rresp = m.rresp;
	   method rvalid = m.rvalid;
	   method wdata = m.wdata;
	   method Bit#(tagWidth)     wid(); return 0; endmethod
	   method wlast = m.wlast;
	   method wready = m.wready;
	   method wstrb = m.wstrb;
	   method wvalid = m.wvalid;
	 interface extra = ?;   
	 endinterface);
   endfunction
endinstance

interface SplitMemServer;
   interface MemServer#(DataBusWidth) server;
   interface MemClient#(DataBusWidth) busClient;
   interface MemClient#(DataBusWidth) bramClient;
   interface PipeOut#(MemData#(DataBusWidth)) data;
endinterface

module mkSplitMemServer(SplitMemServer);
   let readReqFifo   <- mkFIFOF();
   let readDataFifo  <- mkFIFOF();
   let writeReqFifo  <- mkFIFOF();
   let writeDataFifo <- mkFIFOF();
   let writeDoneFifo <- mkFIFOF();

   let busReadReqFifo   <- mkFIFOF();
   let busReadDataFifo  <- mkSizedBRAMFIFOF(16);
   let busWriteReqFifo  <- mkFIFOF();
   let busWriteDataFifo <- mkSizedBRAMFIFOF(16);
   let busWriteDoneFifo <- mkFIFOF();

   let bramReadReqFifo   <- mkFIFOF();
   let bramReadDataFifo  <- mkSizedBRAMFIFOF(16);
   let bramWriteReqFifo  <- mkFIFOF();
   let bramWriteDataFifo <- mkSizedBRAMFIFOF(16);
   let bramWriteDoneFifo <- mkFIFOF();

   let doneFifo <- mkFIFOF();

   let dataFifo <- mkSizedBRAMFIFOF(4096);

   AddressGenerator#(24,DataBusWidth) readAddrGenerator <- mkAddressGenerator();
   AddressGenerator#(24,DataBusWidth) writeAddrGenerator <- mkAddressGenerator();

   let readReqObj <- mkProbe();
   let readReqDest <- mkProbe();
   let readReqOffset <- mkProbe();
   let readDataDest <- mkProbe();
   let readDataData <- mkProbe();
   let readDataLast <- mkProbe();
   let readBeatAddr <- mkProbe();
   let readBeatByteCount <- mkProbe();
   let readBeatLast <- mkProbe();
   let busReadDataData <- mkProbe();
   let busReadDataLast <- mkProbe();
   let writeReqObj <- mkProbe();
   let writeReqDest <- mkProbe();
   let writeReqOffset <- mkProbe();
   let writeDataDest <- mkProbe();
   let writeDataData <- mkProbe();
   let writeDataLast <- mkProbe();
   let writeBeatAddr <- mkProbe();
   let writeBeatByteCount <- mkProbe();
   let writeBeatLast <- mkProbe();
   let writeDoneTag <- mkProbe();
   let writeDoneDest <- mkProbe();

   rule rl_rd_req;
      MemRequest req <- toGet(readReqFifo).get();
      let dest = req.sglId[5:4];
      if (dest == 2)
	 bramReadReqFifo.enq(req);
      else
	 busReadReqFifo.enq(req);
      readAddrGenerator.request.put(PhysMemRequest { addr: truncate(req.offset), burstLen: req.burstLen, tag: extend(dest) });

      readReqObj <= req.sglId;
      readReqDest <= dest;
      readReqOffset <= req.offset[31:0];
   endrule

   rule rl_rd_data;
      let addrBeat <- readAddrGenerator.addrBeat.get();
      let dest = addrBeat.tag[1:0];
      MemData#(DataBusWidth) md;
      if (dest == 2)
	 md <- toGet(bramReadDataFifo).get();
      else
	 md <- toGet(busReadDataFifo).get();
      readDataFifo.enq(md);

      readDataDest <= dest;
      readDataData <= md.data;
      readDataLast <= md.last;
      readBeatAddr <= addrBeat.addr[15:0];
      readBeatByteCount <= addrBeat.bc;
      readBeatLast <= addrBeat.last;
   endrule

   rule rl_wr_req;
      MemRequest req <- toGet(writeReqFifo).get();
      Bit#(2) dest = req.sglId[5:4];
      if (dest == 2)
	 bramWriteReqFifo.enq(req);
      else if (dest == 3) begin
	 // no need to send the request
      end else
	 busWriteReqFifo.enq(req);
      writeAddrGenerator.request.put(PhysMemRequest { addr: truncate(req.offset), burstLen: req.burstLen, tag: extend(dest) });

      writeReqObj <= req.sglId;
      writeReqDest <= dest;
      writeReqOffset <= req.offset[31:0];
   endrule
   
   rule rl_wr_data;
      let addrBeat <- writeAddrGenerator.addrBeat.get();
      let dest = addrBeat.tag[1:0];
      MemData#(DataBusWidth) md <- toGet(writeDataFifo).get();
      if (dest == 2)
	 bramWriteDataFifo.enq(md);
      else if (dest == 3)
	 dataFifo.enq(md);
      else
	 busWriteDataFifo.enq(md);
      if (addrBeat.last)
	 doneFifo.enq(tuple2(dest, md.tag));
      else if (md.last)
	 doneFifo.enq(tuple2(dest, maxBound));

      writeDataDest <= dest;
      writeDataData <= md.data;
      writeDataLast <= md.last;
      writeBeatAddr <= addrBeat.addr[15:0];
      writeBeatByteCount <= addrBeat.bc;
      writeBeatLast <= addrBeat.last;

   endrule

   rule rl_wr_done;
      match { .dest, .tag } <- toGet(doneFifo).get();
      Bit#(MemTagSize) doneTag;
      if (dest == 2)
	 doneTag <- toGet(bramWriteDoneFifo).get();
      else if (dest == 3)
	 doneTag = 0;
      else
	 doneTag <- toGet(busWriteDoneFifo).get();
      writeDoneFifo.enq(doneTag);

      writeDoneTag <= doneTag;
      writeDoneDest <= dest;
   endrule

   interface MemServer server;
      interface MemReadServer readServer;
	 interface readReq  = toPut(readReqFifo);
	 interface readData = toGet(readDataFifo);
      endinterface
      interface MemWriteServer writeServer;
	 interface writeReq  = toPut(writeReqFifo);
	 interface writeData = toPut(writeDataFifo);
	 interface writeDone = toGet(writeDoneFifo);
      endinterface
   endinterface
   interface MemClient busClient;
      interface MemReadClient readClient;
	 interface readReq  = toGet(busReadReqFifo);
	 interface Put readData;
	    method Action put(MemData#(DataBusWidth) md);
	       busReadDataFifo.enq(md);
	       busReadDataData <= md.data;
	       busReadDataLast <= md.last;
	    endmethod
	 endinterface
      endinterface
      interface MemWriteClient writeClient;
	 interface writeReq  = toGet(busWriteReqFifo);
	 interface writeData = toGet(busWriteDataFifo);
	 interface writeDone = toPut(busWriteDoneFifo);
      endinterface
   endinterface
   interface MemClient bramClient;
      interface MemReadClient readClient;
	 interface readReq  = toGet(bramReadReqFifo);
	 interface readData = toPut(bramReadDataFifo);
      endinterface
      interface MemWriteClient writeClient;
	 interface writeReq  = toGet(bramWriteReqFifo);
	 interface writeData = toGet(bramWriteDataFifo);
	 interface writeDone = toPut(bramWriteDoneFifo);
      endinterface
   endinterface
   interface PipeOut data = toPipeOut(dataFifo);
endmodule

interface MemServerPortal;
   interface MemServerPortalRequest request;
endinterface

module mkPhysMemSlavePortal#(PhysMemSlave#(32,DataBusWidth) ms, MemServerPortalIndication ind)(MemServerPortal);

   FIFOF#(PhysMemRequest#(32,DataBusWidth)) araddrFifo <- mkFIFOF();
   FIFOF#(PhysMemRequest#(32,DataBusWidth)) awaddrFifo <- mkFIFOF();
   FIFOF#(MemData#(DataBusWidth))           rdataFifo <- mkFIFOF();
   FIFOF#(MemData#(DataBusWidth))           wdataFifo <- mkFIFOF();
   FIFOF#(Bit#(6))                doneFifo <- mkFIFOF();

   let araddrCnx <- mkConnection(toGet(araddrFifo), ms.read_server.readReq);
   let awaddrCnx <- mkConnection(toGet(awaddrFifo), ms.write_server.writeReq);
   let rdataCnx  <- mkConnection(ms.read_server.readData, toPut(rdataFifo));
   let wdataCnx  <- mkConnection(toGet(wdataFifo), ms.write_server.writeData);
   let doneCnx   <- mkConnection(ms.write_server.writeDone, toPut(doneFifo));

   rule rl_rdata;
      let rdata <- toGet(rdataFifo).get();
      ind.readDone(rdata.data);
   endrule

   rule rl_writeDone;
      let tag <- toGet(doneFifo).get();
      ind.writeDone();
   endrule

   interface MemServerPortalRequest request;
      method Action read(Bit#(32) addr);
	 araddrFifo.enq(PhysMemRequest { addr: addr, burstLen: fromInteger(valueOf(TDiv#(DataBusWidth,8))), tag: 0 });
      endmethod
      method Action write(Bit#(32) addr, Bit#(DataBusWidth) value);
	 awaddrFifo.enq(PhysMemRequest { addr: addr, burstLen: fromInteger(valueOf(TDiv#(DataBusWidth,8))), tag: 0 });
	 wdataFifo.enq(MemData {data: value, tag: 0, last: True});
      endmethod
   endinterface
endmodule
