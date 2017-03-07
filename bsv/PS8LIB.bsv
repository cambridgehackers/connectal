
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
`include "ConnectalProjectConfig.bsv"
import ConnectalConfig::*;
import BuildVector::*;
import Clocks::*;
import DefaultValue::*;
import FIFOF::*;
import GetPut::*;
import Connectable::*;
import ConnectableWithTrace::*;
import Bscan::*;
import Vector::*;
import XilinxCells::*;
import ConnectalXilinxCells::*;
import ConnectalClocks::*;
import AxiMasterSlave::*;
import Axi4MasterSlave::*;
import AxiDma::*;
import AxiBits::*;
import MemTypes::*;
import Platform::*;
import ZYNQ_ULTRA::*;

(* always_ready, always_enabled *)
interface Bidir#(numeric type data_width);
    method Action             i(Bit#(data_width) v);
    method Bit#(data_width)   o();
    method Bit#(data_width)   t();
endinterface

interface ZynqPins;
endinterface

interface PS8LIB;
    (* prefix="" *)
    interface Vector#(1, Ps8Maxigp)     m_axi_gp;
    interface Vector#(1, Ps8Saxigp)     s_axi_gp;
    method Action                             interrupt(Bit#(1) v);
    interface Vector#(4, Clock) plclk;
    interface Clock portalClock;
    interface Reset portalReset;
    interface Clock derivedClock;
    interface Reset derivedReset;
endinterface

module mkPS8LIB#(Clock axiClock)(PS8LIB);
   // B2C converts a bit to a clock, enabling us to break the apparent cycle
   Vector#(4, B2C) b2c <- replicateM(mkB2C());

   // need the bufg here to reduce clock skew
   module mkBufferedClock#(Integer i)(Clock); let c <- mkClockBUFG(clocked_by b2c[i].c); return c; endmodule
   module mkBufferedReset#(Integer i)(Reset); let r <- mkResetBUFG(clocked_by b2c[i].c, reset_by b2c[i].r); return r; endmodule
   Vector#(4, Clock) fclk <- genWithM(mkBufferedClock);
   Vector#(4, Reset) freset <- genWithM(mkBufferedReset);

`ifndef TOP_SOURCES_PORTAL_CLOCK
   Clock single_clock = fclk[0];
`ifdef ZYNQ_NO_RESET
   freset[0]          = noReset;
`endif
   let single_reset   = freset[0];
`else
   //Clock axiClockBuf <- mkClockBUFG(clocked_by axiClock);
   Clock axiClockBuf = axiClock;
   Clock single_clock = axiClockBuf;
   Reset axiResetUnbuffered <- mkSyncReset(10, freset[0], single_clock);
   Reset axiReset <- mkResetBUFG(clocked_by axiClockBuf, reset_by axiResetUnbuffered);
   let single_reset   = axiReset;
`endif

   ClockGenerator7Params clockParams = defaultValue;
   // input clock 200MHz for speed grade -2, 100MHz for speed grade -1
   // fpll needs to be in the range 600MHz - 1200MHz for either input clock
   //
   // fclkin = 1e9 / mainClockPeriod
   // fpll = 1e9 = mult_f * 1e9 / mainClockPeriod
   // mult_f = mainClockPeriod
   //
   // fclkout0 = 1e9 / divide_f = 1e9 / derivedClockPeriod
   // divide_f = derivedClockPeriod
   //
   clockParams.clkfbout_mult_f       = mainClockPeriod;
   clockParams.clkfbout_phase     = 0.0;
   clockParams.clkfbout_phase     = 0.0;
   clockParams.clkin1_period      = mainClockPeriod;
   clockParams.clkout0_divide_f   = derivedClockPeriod;
   clockParams.clkout0_duty_cycle = 0.5;
   clockParams.clkout0_phase      = 0.0000;
   clockParams.clkout0_buffer     = True;
   clockParams.clkin_buffer = False;
   ClockGenerator7   clockGen <- mkClockGenerator7(clockParams, clocked_by single_clock, reset_by single_reset);
   let derived_clock = clockGen.clkout0;
   let derived_reset_unbuffered <- mkSyncReset(10, single_reset, derived_clock);
   let derived_reset <- mkResetBUFG(clocked_by derived_clock, reset_by derived_reset_unbuffered);

   ZYNQ_ULTRA::PS8 psu <- ZYNQ_ULTRA::mkPS8(single_clock, single_clock, single_clock);

   // this rule connects the pl_clk wires to the clock net via B2C
   for (Integer i = 0; i < 1; i = i + 1) begin
      ReadOnly#(Bit#(1)) fclkb;
      ReadOnly#(Bit#(1)) fclkresetnb;
      fclkb       <- mkNullCrossingWire(b2c[i].c, psu.pl.clk0);
      fclkresetnb <- mkNullCrossingWire(b2c[i].c, psu.pl.resetn0);
`ifndef BSV_POSITIVE_RESET
      let resetValue = 0;
`else
      let resetValue = 1;
`endif
      rule b2c_rule1;
	 b2c[i].inputclock(fclkb[i]);
	 b2c[i].inputreset(fclkresetnb[i] == 0 ? resetValue : ~resetValue);
      endrule
   end

    interface m_axi_gp = vec(psu.maxigp0);
    interface s_axi_gp = vec(psu.saxigp0);
    interface plclk = fclk;
`ifndef TOP_SOURCES_PORTAL_CLOCK
    interface portalClock = fclk[0];
    interface portalReset = freset[0];
`else
    interface portalClock = axiClockBuf;
    interface portalReset = axiReset;
`endif
    interface derivedClock = derived_clock;
    interface derivedReset = derived_reset;
    method Action interrupt(Bit#(1) v);
       psu.pl.ps_irq0(v);
    endmethod
endmodule

interface Ps8Aruser;
    method Action      aruser(Bit#(5) v);
    method Action      awuser(Bit#(5) v);
endinterface

instance ToAxi4MasterBits#(Axi4MasterBits#(40,128,16,Ps8Aruser), Ps8Maxigp);
function Axi4MasterBits#(40,128,16,Ps8Aruser) toAxi4MasterBits(Ps8Maxigp m);
   return (interface Axi4MasterBits#(40,128,16,Ps8Aruser);
      method araddr = m.araddr;
	   method arburst = m.arburst;
	   method arcache = m.arcache;
           method aresetn = 0;
	   method arid = m.arid;
	   method arlen = m.arlen;
	   method arlock = extend(m.arlock);
	   method arprot = m.arprot;
	   method arqos = m.arqos;
	   method arready = m.arready;
	   method arsize = m.arsize;
	   method arvalid = m.arvalid;
	   method awaddr = m.awaddr;
	   method awburst = m.awburst;
	   method awcache = m.awcache;
	   method awid = m.awid;
	   method awlen = m.awlen;
	   method awlock = extend(m.awlock);
	   method awprot = m.awprot;
	   method awqos = m.awqos;
	   method awready = m.awready;
	   method awsize = m.awsize;
	   method awvalid = m.awvalid;
	   method bid = m.bid;
	   method bready = m.bready;
	   method bresp = m.bresp;
	   method bvalid = m.bvalid;
	   method rdata = m.rdata;
	   method rid = m.rid;
	   method rlast = m.rlast;
	   method rready = m.rready;
	   method rresp = m.rresp;
	   method rvalid = m.rvalid;
	   method wdata = m.wdata;
	   //method wid = m.wid;
	   method wlast = m.wlast;
	   method wready = m.wready;
	   method wstrb = m.wstrb;
	   method wvalid = m.wvalid;
	 interface extra = ?;   
	 endinterface);
   endfunction: toAxi4MasterBits
endinstance

instance ToAxi4SlaveBits#(Axi4SlaveBits#(49,128,6,Empty), Ps8Saxigp);
   function Axi4SlaveBits#(49,128,6,Empty) toAxi4SlaveBits(Ps8Saxigp s);
      return (interface Axi4SlaveBits#(49,128,6,Empty);
	 method araddr = s.araddr;
	 method arburst = s.arburst;
	 method arcache = s.arcache;
	 method arid = s.arid;
	 method arlen = s.arlen;
	 method arlock = compose(s.arlock, truncate);
	 method arprot = s.arprot;
	 method arqos = s.arqos;
	 method arready = s.arready;
	 method arsize = s.arsize;
	 method arvalid = s.arvalid;
	 
	 method awaddr = s.awaddr;
	 method awburst = s.awburst;
	 method awcache = s.awcache;
	 method awid = s.awid;
	 method awlen = s.awlen;
	 method awlock = compose(s.awlock, truncate);
	 method awprot = s.awprot;
	 method awqos = s.awqos;
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

//FIXME extra aruser awuser
instance MkPhysMemSlave#(Axi4SlaveBits#(49,128,6,Empty),addrWidth,DataBusWidth)
      provisos (Add#(addrWidth,a__,49));
   module mkPhysMemSlave#(Axi4SlaveBits#(49,128,6,Empty) axiSlave)(PhysMemSlave#(addrWidth,DataBusWidth));
      FIFOF#(PhysMemRequest#(addrWidth,DataBusWidth)) arfifo <- mkAxiFifoF();
      FIFOF#(MemData#(DataBusWidth)) rfifo <- mkAxiFifoF();
      FIFOF#(PhysMemRequest#(addrWidth,DataBusWidth)) awfifo <- mkAxiFifoF();
      FIFOF#(MemData#(DataBusWidth)) wfifo <- mkAxiFifoF();
      FIFOF#(Bit#(MemTagSize)) bfifo <- mkAxiFifoF();
      FIFOF#(Bit#(MemTagSize)) rtagfifo <- mkAxiFifoF();
      FIFOF#(Bit#(MemTagSize)) wtagfifo <- mkAxiFifoF();

      rule rl_arvalid_araddr;
	 axiSlave.arvalid(pack(arfifo.notEmpty && rtagfifo.notFull));
      endrule
      rule rl_arfifo if (axiSlave.arready() == 1);
	 let req <- toGet(arfifo).get();
	 Axi4ReadRequest#(addrWidth,6) axireq = toAxi4ReadRequest(req);
	 axiSlave.araddr(extend(axireq.address));
	 axiSlave.arid(axireq.id);
	 axiSlave.arsize(axireq.size);
	 axiSlave.arlen(axireq.len);
	 axiSlave.arburst(2'b01);   //FIXME
	 axiSlave.arcache(4'b0011); //FIXME
	 //FIXME axiSlave.extra.aruser();
	 rtagfifo.enq(req.tag);
      endrule
      rule rl_rready;
	 axiSlave.rready(pack(rfifo.notFull && rtagfifo.notEmpty));
      endrule
      rule rl_rdata if (axiSlave.rvalid() == 1);
	 let rtag <- toGet(rtagfifo).get();
	 rfifo.enq(MemData { data: truncate(axiSlave.rdata()), tag: rtag } );
      endrule

      rule rl_awvalid_awaddr;
	 axiSlave.awvalid(pack(awfifo.notEmpty && wtagfifo.notFull));
      endrule
      rule rl_awfifo if (axiSlave.awready() == 1);
	 let req <- toGet(awfifo).get();
	 Axi4WriteRequest#(addrWidth,6) axireq = toAxi4WriteRequest(req);
	 axiSlave.awaddr(extend(axireq.address));
	 axiSlave.awid(axireq.id);
	 axiSlave.awsize(axireq.size);
	 axiSlave.awlen(axireq.len);
	 axiSlave.awburst(2'b01);   //FIXME
	 axiSlave.awcache(4'b0011); //FIXME
	 //FIXME axiSlave.extra.awuser();
	 wtagfifo.enq(req.tag);
      endrule
      rule rl_wvalid;
	 axiSlave.wvalid(pack(wfifo.notEmpty));
      endrule
      rule rl_wdata if (axiSlave.wready() == 1);
	 let wdata = wfifo.first.data;
	 wfifo.deq();
	 axiSlave.wdata(extend(wdata));
      endrule
      rule rl_bready;
	 axiSlave.bready(pack(wtagfifo.notEmpty && bfifo.notFull));
      endrule
      rule rl_done if (axiSlave.bvalid() == 1);
	 let tag <- toGet(wtagfifo).get();
	 bfifo.enq(tag);
      endrule

      interface PhysMemReadServer read_server;
	 interface Put readReq = toPut(arfifo);
	 interface Get readData = toGet(rfifo);
      endinterface
      interface PhysMemWriteServer write_server;
	 interface Put writeReq = toPut(awfifo);
	 interface Put writeData = toPut(wfifo);
	 interface Get writeDone = toGet(bfifo);
      endinterface
   endmodule
endinstance

instance ConnectableWithTrace#(PS8LIB, Platform, traceType);
   module mkConnectionWithTrace#(PS8LIB psu, Platform top, traceType readout)(Empty);
      Axi4MasterBits#(40,128,16,Ps8Aruser) master = toAxi4MasterBits(psu.m_axi_gp[0]);
      PhysMemMaster#(32,32) physMemMaster <- mkPhysMemMaster(master);
      mkConnection(physMemMaster, top.slave);

      Axi4SlaveBits#(49,128,6,Empty) slave = toAxi4SlaveBits(psu.s_axi_gp[0]);
      PhysMemSlave#(32,DataBusWidth) physMemSlave <- mkPhysMemSlave(slave);
      mkConnection(top.masters[0], physMemSlave);
   endmodule
endinstance
