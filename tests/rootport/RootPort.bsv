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

import Clocks::*;
import Connectable::*;
import FIFOF::*;
import GetPut::*;
import Vector::*;

import ConnectalClocks::*;
import ConnectalBramFifo::*;
import DefaultValue::*;
import HostInterface::*;
import XilinxCells::*;
import MemTypes::*;
import AxiBits::*;

import AxiPcieRootPort::*;
import RootPortIfc::*;
import RootPortPins::*;

interface RootPort;
   interface RootPortRequest request;
   interface RootPortPins pins;
endinterface

module mkRootPort#(HostInterface host, RootPortIndication ind)(RootPort);
   let clock <- exposeCurrentClock;
   let reset <- exposeCurrentReset;
   let refclk_p <- mkB2C1();
   let refclk_n <- mkB2C1();
   let pcie_clk_100mhz_buf <- mkClockIBUFDS_GTE2(
`ifdef ClockDefaultParam
       defaultValue,
`endif
      True, refclk_p.c, refclk_n.c);
   let axiClockB2C    <- mkB2C1();
   let axiCtlClockB2C <- mkB2C1();
   let axiClock = axiClockB2C.c;
   let axiCtlClock = axiCtlClockB2C.c;
   let axiReset <- mkSyncReset(10, reset, axiClock);
   let axiCtlReset <- mkSyncReset(10, reset, axiCtlClock);

   let axiRootPort <- mkAPRP(pcie_clk_100mhz_buf, reset, axiClock, axiReset, axiCtlClock, axiCtlReset);
   let axiClockC2B <- mkC2B(axiRootPort.axi.aclk_out);
   let axiCtlClockC2B <- mkC2B(axiRootPort.axi.ctl_aclk_out);
   rule rl_connect_clocks;
      axiClockB2C.inputclock(axiClockC2B.o);
      axiCtlClockB2C.inputclock(axiClockC2B.o);
   endrule


   FIFOF#(Bit#(32)) dfifoCtl <- mkFIFOF();
   Axi4SlaveBits#(32,64,4,Empty) axiRootPortSlave    = toAxi4SlaveBits(axiRootPort.s_axi);
   Axi4SlaveLiteBits#(32,32)     axiRootPortSlaveCtl = toAxi4SlaveBits(axiRootPort.s_axi_ctl);
   PhysMemSlave#(32,64)          axiRootPortMemSlave    <- mkPhysMemSlave(axiRootPortSlave, clocked_by axiClock, reset_by axiReset);
   PhysMemSlave#(32,32)          axiRootPortMemSlaveCtl <- mkPhysMemSlave(axiRootPortSlaveCtl, clocked_by axiCtlClock, reset_by axiCtlReset);

   FIFOF#(PhysMemRequest#(32,64)) araddrFifo <- mkDualClockBramFIFOF(clock, reset, axiClock, axiReset);
   FIFOF#(PhysMemRequest#(32,64)) awaddrFifo <- mkDualClockBramFIFOF(clock, reset, axiClock, axiReset);
   FIFOF#(MemData#(64))           rdataFifo <- mkDualClockBramFIFOF(axiClock, axiReset, clock, reset);
   FIFOF#(MemData#(64))           wdataFifo <- mkDualClockBramFIFOF(clock, reset, axiClock, axiReset);
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

   interface RootPortRequest request;
      method Action status();
        ind.status(axiRootPort.mmcm.lock());
      endmethod

      method Action read(Bit#(32) addr);
	 araddrFifo.enq(PhysMemRequest { addr: addr, burstLen: 4, tag: 0 });
      endmethod
      method Action write(Bit#(32) addr, Bit#(64) value);
	 awaddrFifo.enq(PhysMemRequest { addr: addr, burstLen: 4, tag: 0 });
	 wdataFifo.enq(MemData {data: value, tag: 0, last: True});
      endmethod

      method Action readCtl(Bit#(32) addr);
	 araddrFifoCtl.enq(PhysMemRequest { addr: addr, burstLen: 4, tag: 0 });
      endmethod
      method Action writeCtl(Bit#(32) addr, Bit#(64) value);
	 awaddrFifoCtl.enq(PhysMemRequest { addr: addr, burstLen: 4, tag: 0 });
	 wdataFifoCtl.enq(MemData {data: truncate(value), tag: 0, last: True});
      endmethod
   endinterface
   interface RootPortPins pins;
      interface deleteme_unused_clock = clock;
      interface pcie_sys_reset_n = reset;
      interface pcie = axiRootPort.pci;
      method Action pcie_refclk(Bit#(1) p, Bit#(1) n);
         refclk_p.inputclock(p);
         refclk_n.inputclock(n);
      endmethod
   endinterface

endmodule

instance ToAxi4SlaveBits#(Axi4SlaveBits#(32,64,4,Empty), AprpS_axi);
   function Axi4SlaveBits#(32,64,4,Empty) toAxi4SlaveBits(AprpS_axi s);
      return (interface Axi4SlaveBits#(32,64,4,Empty);
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
	 method Action      wvalid(Bit#(1) v);
	    s.wvalid(v);
	    s.wstrb(pack(replicate(v)));
	 endmethod
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
