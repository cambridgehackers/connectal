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

`include "ConnectalProjectConfig.bsv"
import BuildVector::*;
import Clocks::*;
import Connectable::*;
import FIFOF::*;
import GetPut::*;
import Vector::*;

import AxiBits::*;
import ConnectalClocks::*;
import ConnectalConfig::*;
import DefaultValue::*;
import HostInterface::*;
import ConnectalMemTypes::*;
import Pipe::*;
import TraceMemClient::*;
import XilinxCells::*;

import AxiPcieRootPort::*;
import RootPortIfc::*;
import RootPortPins::*;

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


interface RootPort;
   interface RootPortRequest request;
   interface RootPortTrace trace;
   interface RootPortPins pins;
   interface Vector#(1, MemReadClient#(DataBusWidth)) dmaReadClient;
   interface Vector#(1, MemWriteClient#(DataBusWidth)) dmaWriteClient;
`ifdef TOP_SOURCES_PORTAL_CLOCK
   interface Clock portalClockSource;
`endif
endinterface

module mkRootPort#(HostInterface host, RootPortIndication ind, RootPortTrace trace)(RootPort);
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

   FIFOF#(PhysMemRequest#(32,DataBusWidth)) araddrFifo <- mkDualClockBramFIFOF(clock, reset, axiClock, axiReset);
   FIFOF#(PhysMemRequest#(32,DataBusWidth)) awaddrFifo <- mkDualClockBramFIFOF(clock, reset, axiClock, axiReset);
   FIFOF#(MemData#(DataBusWidth))           rdataFifo <- mkDualClockBramFIFOF(axiClock, axiReset, clock, reset);
   FIFOF#(MemData#(DataBusWidth))           wdataFifo <- mkDualClockBramFIFOF(clock, reset, axiClock, axiReset);
   FIFOF#(Bit#(6))                doneFifo <- mkDualClockBramFIFOF(axiClock, axiReset, clock, reset);

   let araddrCnx <- mkConnection(toGet(araddrFifo), axiRootPortMemSlave.read_server.readReq);
   let awaddrCnx <- mkConnection(toGet(awaddrFifo), axiRootPortMemSlave.write_server.writeReq);
   let rdataCnx  <- mkConnection(axiRootPortMemSlave.read_server.readData, toPut(rdataFifo));
   let wdataCnx  <- mkConnection(toGet(wdataFifo), axiRootPortMemSlave.write_server.writeData);
   let doneCnx   <- mkConnection(axiRootPortMemSlave.write_server.writeDone, toPut(doneFifo));

   rule rl_rdata;
      let rdata <- toGet(rdataFifo).get();
      ind.readDone(rdata.data);
   endrule

   rule rl_writeDone;
      let tag <- toGet(doneFifo).get();
      ind.writeDone();
   endrule

   FIFOF#(PhysMemRequest#(32,32)) araddrFifoCtl <- mkDualClockBramFIFOF(clock, reset, axiCtlClock, axiCtlReset);
   FIFOF#(PhysMemRequest#(32,32)) awaddrFifoCtl <- mkDualClockBramFIFOF(clock, reset, axiCtlClock, axiCtlReset);
   FIFOF#(MemData#(32))           rdataFifoCtl <- mkDualClockBramFIFOF(axiCtlClock, axiCtlReset, clock, reset);
   FIFOF#(MemData#(32))           wdataFifoCtl <- mkDualClockBramFIFOF(clock, reset, axiCtlClock, axiCtlReset);
   FIFOF#(Bit#(6))                doneFifoCtl <- mkDualClockBramFIFOF(axiCtlClock, axiCtlReset, clock, reset);

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
   let memReadClients  <- mapM(mkMemReadClient(getObjId), vec(m_axi_mm));
   let memWriteClients <- mapM(mkMemWriteClient(getObjId), vec(m_axi_mm));

   FIFOF#(Tuple4#(DmaChannel,Bool,MemRequest,Bit#(32))) traceFifo <- mkDualClockBramFIFOF(clock, reset, clock, reset);
   FIFOF#(Tuple4#(DmaChannel,Bool,MemRequest,Bit#(32))) traceFifo0 <- mkFIFOF();
   FIFOF#(Tuple4#(DmaChannel,Bool,MemRequest,Bit#(32))) traceFifo1 <- mkFIFOF();
   PipeIn#(Tuple4#(DmaChannel,Bool,MemRequest,Bit#(32))) tracePipe = toPipeIn(traceFifo0);
   FIFOF#(Tuple4#(DmaChannel,Bool,MemData#(DataBusWidth),Bit#(32))) traceDataFifo <- mkDualClockBramFIFOF(clock, reset, clock, reset);
   FIFOF#(Tuple4#(DmaChannel,Bool,MemData#(DataBusWidth),Bit#(32))) traceDataFifo0 <- mkFIFOF();
   FIFOF#(Tuple4#(DmaChannel,Bool,MemData#(DataBusWidth),Bit#(32))) traceDataFifo1 <- mkFIFOF();
   PipeIn#(Tuple4#(DmaChannel,Bool,MemData#(DataBusWidth),Bit#(32))) traceDataPipe = toPipeIn(traceDataFifo0);
   let trace0Cnx <- mkConnection(toGet(traceFifo0), toPut(traceFifo));
   let trace1Cnx <- mkConnection(toGet(traceFifo), toPut(traceFifo1));
   rule rl_trace1;
      match { .chan, .write, .req, .timestamp } <- toGet(traceFifo1).get();
      trace.traceDmaRequest(chan, write, truncate(req.sglId), extend(req.offset), extend(req.burstLen), extend(req.tag), timestamp);
   endrule
   let traceData0Cnx <- mkConnection(toGet(traceDataFifo0), toPut(traceDataFifo));
   let traceData1Cnx <- mkConnection(toGet(traceDataFifo), toPut(traceDataFifo1));
   rule rl_trace_data;
      match { .chan, .write, .md, .timestamp } <- toGet(traceDataFifo1).get();
      trace.traceDmaData(chan, write, md.data, md.last, extend(md.tag), timestamp);
   endrule

   let traceReadClients <- mapM(uncurry(mkTraceReadClient(tracePipe,traceDataPipe)),
				zip(vec(DMA_TX),
				    memReadClients));
   let traceWriteClients <- mapM(uncurry(mkTraceWriteClient(tracePipe,traceDataPipe)),
				 zip(vec(DMA_RX),
				     memWriteClients));

   interface RootPortRequest request;

      method Action status();
        ind.status(axiRootPort.mmcm.lock());
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
   endinterface
   interface Clock portalClockSource = axiRootPort.axi.aclk_out;
   interface RootPortPins pins;
      interface deleteme_unused_clock = clock;
      interface pcie_sys_reset_n = reset;
      interface pcie = axiRootPort.pci;
      method Action pcie_refclk(Bit#(1) p, Bit#(1) n);
         refclk_p.inputclock(p);
         refclk_n.inputclock(n);
      endmethod
   endinterface
   interface Vector dmaReadClient = traceReadClients;
   interface Vector dmaWriteClient = traceWriteClients;
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
