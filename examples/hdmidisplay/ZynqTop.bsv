// Copyright (c) 2014 Quanta Research Cambridge, Inc.

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

import Clocks :: *;
import Vector            :: *;
import Connectable       :: *;
import Portal            :: *;
import Leds              :: *;
import Top               :: *;
import AxiMasterSlave    :: *;
import XbsvXilinxCells   :: *;
import PS7LIB::*;
import PPS7LIB::*;
import XADC::*;
import BRAM::*;
import Bscan::*;
import FIFOF::*;
import HDMI::*;

//`define TRACE_AXI
//`define AXI_READ_TIMING

(* always_ready, always_enabled *)
interface ZynqTop#(type pins);
   (* prefix="" *)
   interface ZynqPins zynq;
   (* prefix="GPIO" *)
   interface LEDS             leds;
   (* prefix="XADC" *)
   interface XADC             xadc;
   (* prefix="hdmi" *)
   interface pins             pins;
   interface Vector#(4, Clock) unused_clock;
   interface Vector#(4, Reset) unused_reset;
endinterface

typedef (function Module#(PortalTop#(32, 64, ipins)) mkpt(Clock clk1)) MkPortalTop#(type ipins);

module [Module] mkZynqTopFromPortal#(MkPortalTop#(ipins) constructor)(ZynqTop#(ipins));
   // B2C converts a bit to a clock, enabling us to break the apparent cycle
   PS7 ps7 <- mkPS7();
   Clock mainclock = ps7.fclkclk[0];
   Reset mainreset = ps7.fclkreset[0];

   let top <- constructor(ps7.fclkclk[1], clocked_by mainclock, reset_by mainreset);
   Reg#(Bit#(8)) addrReg <- mkReg(9, clocked_by mainclock, reset_by mainreset);
   BscanBram#(Bit#(8), Bit#(64)) bscanBram <- mkBscanBram(1, addrReg, clocked_by mainclock, reset_by mainreset);
   BRAM_Configure bramCfg = defaultValue;
   bramCfg.memorySize = 256;
   bramCfg.latency = 1;
   BRAM2Port#(Bit#(8), Bit#(64)) traceBram <- mkSyncBRAM2Server(bramCfg, mainclock, mainreset,
								bscanBram.jtagClock, bscanBram.jtagReset);
   mkConnection(bscanBram.bramClient, traceBram.portB);

   ReadOnly#(Bit#(4)) debugReg <- mkNullCrossingWire(mainclock, bscanBram.debug());
   
   let interrupt_bit = top.interrupt ? 1'b1 : 1'b0;
   
`ifndef TRACE_AXI
   mkConnection(ps7.m_axi_gp[0].client, top.ctrl);
`else
   
   Vector#(5, FIFOF#(Bit#(64))) bscan_fifos <- replicateM(mkFIFOF(clocked_by mainclock, reset_by mainreset));

   rule write_bscanBram;
      Bit#(64) data = ?;
      if (bscan_fifos[0].notEmpty) begin
	 data = bscan_fifos[0].first;
	 bscan_fifos[0].deq;
      end
      else if (bscan_fifos[1].notEmpty) begin
	 data = bscan_fifos[1].first;
	 bscan_fifos[1].deq;
      end
      else if (bscan_fifos[2].notEmpty) begin
	 data = bscan_fifos[2].first;
	 bscan_fifos[2].deq;
      end
      else if (bscan_fifos[3].notEmpty) begin
	 data = bscan_fifos[3].first;
	 bscan_fifos[3].deq;
      end
      else begin
	 data = bscan_fifos[4].first;
	 bscan_fifos[4].deq;
      end
      traceBram.portA.request.put(BRAMRequest {write:True, responseOnWrite:False, address:addrReg, datain:data});
      addrReg <= addrReg + 1;
   endrule
   Reg#(Bit#(16)) seqCounter <- mkReg(0, clocked_by mainclock, reset_by mainreset);
   rule seqinc;
       seqCounter <= seqCounter + 1;
   endrule

   // AXI trace for JTAG
   let m = ps7.m_axi_gp[0].client;
   let s = top.ctrl;
   //mkConnection(m.req_ar, s.req_ar);
   rule connect_req_ar;
       let req <- m.req_ar.get();
       s.req_ar.put(req);
       bscan_fifos[0].enq(
	   {3'h1, interrupt_bit, req.id,
`ifdef AXI_READ_TIMING
                    seqCounter,
`else
                    req.len, req.cache, req.prot, req.size,
                    pack(req.burst == 2'b01), pack(req.lock == 0 && req.qos == 0),
`endif
                    req.address});
   endrule
   //mkConnection(s.resp_read, m.resp_read);
   rule connect_resp_read;
       let resp <- s.resp_read.get();
       m.resp_read.put(resp);
       bscan_fifos[1].enq(
           {3'h2, interrupt_bit, resp.id, resp.resp, resp.last, 13'b0, resp.data});
   endrule
   //mkConnection(m.req_aw, s.req_aw);
   rule connect_req_aw;
       let req <- m.req_aw.get();
       s.req_aw.put(req);
       bscan_fifos[2].enq(
           {3'h3, interrupt_bit, req.id, req.len, req.cache, req.prot, req.size,
                    pack(req.burst == 2'b01), pack(req.lock == 0 && req.qos == 0), req.address});
   endrule
   //mkConnection(m.resp_write, s.resp_write);
   rule connect_resp_write;
       let resp <- m.resp_write.get();
       s.resp_write.put(resp);
       bscan_fifos[3].enq(
           {3'h4, interrupt_bit, resp.id, resp.last, resp.byteEnable, 11'b0, resp.data});
   endrule
   //mkConnection(s.resp_b, m.resp_b);
   rule connect_resp_b;
       let resp <- s.resp_b.get();
       m.resp_b.put(resp);
       bscan_fifos[4].enq(
           {3'h5, interrupt_bit, resp.id, resp.resp, 46'b0});
   endrule
`endif

   mkConnection(top.m_axi, ps7.s_axi_hp[0].axi.server);
   rule send_int_rule;
       ps7.interrupt(interrupt_bit);
   endrule

   interface zynq = ps7.pins;
   interface leds = top.leds;
   interface XADC xadc;
       method Bit#(4) gpio;
           return debugReg;
       endmethod
   endinterface
   interface pins = top.pins;

   // these are exported to make bsc happy, and then the ports are disconnected after synthesis
   interface unused_clock = ps7.fclkclk;
   interface unused_reset = ps7.fclkreset;
endmodule

module mkHdmiZynqTop(ZynqTop#(HDMI));
   let top <- mkZynqTopFromPortal(mkPortalTop);
   return top;
endmodule
