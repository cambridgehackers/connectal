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

(* always_ready, always_enabled *)
interface ZynqTop#(type pins);
   (* prefix="" *)
   interface ZynqPins zynq;
   (* prefix="GPIO" *)
   interface LEDS             leds;
   (* prefix="XADC" *)
   interface XADC             xadc;
   interface pins             pins;
   interface Clock unused_clock;
   interface Reset unused_reset;
endinterface

typedef (function Module#(PortalTop#(32, 64, ipins)) mkpt()) MkPortalTop#(type ipins);

module [Module] mkZynqTopFromPortal#(MkPortalTop#(ipins) constructor)(ZynqTop#(ipins));
   B2C mainclock <- mkB2C();
   PS7 ps7 <- mkPS7(mainclock.c, mainclock.r, clocked_by mainclock.c, reset_by mainclock.r);
   let top <- constructor(clocked_by mainclock.c, reset_by mainclock.r);
   Reg#(Bit#(1)) intReg <- mkReg(0, clocked_by mainclock.c, reset_by mainclock.r);
   Reg#(Bit#(8)) addrReg <- mkReg(9, clocked_by mainclock.c, reset_by mainclock.r);
   BscanBram#(8, 64) bscanBram <- mkBscanBram(1, 256, addrReg, clocked_by mainclock.c, reset_by mainclock.r);
   ReadOnly#(Bit#(4)) debugReg <- mkNullCrossingWire(mainclock.c, bscanBram.debug());
   
   
`define TRACE_AXI
`ifndef TRACE_AXI
   mkConnection(ps7.m_axi_gp[0].client, top.ctrl);
`else
   
   Vector#(5, FIFOF#(Bit#(64))) bscan_fifos <- replicateM(mkFIFOF(clocked_by mainclock.c, reset_by mainclock.r));

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
      bscanBram.server.request.put(BRAMRequest {write:True, responseOnWrite:False, address:addrReg, datain:data});
      addrReg <= addrReg + 1;
   endrule

   // AXI trace for JTAG
   let m = ps7.m_axi_gp[0].client;
   let s = top.ctrl;
   //mkConnection(m.req_ar, s.req_ar);
   rule connect_req_ar;
       let req <- m.req_ar.get();
       s.req_ar.put(req);
       bscan_fifos[0].enq(
	   {4'h1, 7'b0, req.len, req.size, req.burst, req.id,
                    /*req.prot, req.cache, req.lock, req.qos,*/ req.address});
   endrule
   //mkConnection(s.resp_read, m.resp_read);
   rule connect_resp_read;
       let resp <- s.resp_read.get();
       m.resp_read.put(resp);
       bscan_fifos[1].enq(
           {4'h2, 13'b0, resp.id, resp.resp, resp.last, resp.data});
   endrule
   //mkConnection(m.req_aw, s.req_aw);
   rule connect_req_aw;
       let req <- m.req_aw.get();
       s.req_aw.put(req);
       bscan_fifos[2].enq(
           {4'h3, 7'b0, req.len, req.size, req.burst, req.id,
                    /*req.prot, req.cache, req.lock, req.qos,*/ req.address});
   endrule
   //mkConnection(m.resp_write, s.resp_write);
   rule connect_resp_write;
       let resp <- m.resp_write.get();
       s.resp_write.put(resp);
       bscan_fifos[3].enq(
           {4'h4, 11'b0, resp.id, resp.last, resp.byteEnable, resp.data});
   endrule
   //mkConnection(s.resp_b, m.resp_b);
   rule connect_resp_b;
       let resp <- s.resp_b.get();
       m.resp_b.put(resp);
       bscan_fifos[4].enq(
           {4'h5, 46'b0, resp.resp, resp.id});
   endrule
`endif

   mkConnection(top.m_axi, ps7.s_axi_hp[0].axi.server);
   rule send_int_rule;
       ps7.interrupt(top.interrupt ? 1'b1 : 1'b0);
   endrule
   rule bozorule;
       intReg <= top.interrupt ? 1'b1 : 1'b0;
   endrule

   rule b2c_rule;
       mainclock.inputclock(ps7.fclkclk()[0]);
       mainclock.inputreset(ps7.fclkresetn()[0]);
   endrule

   interface zynq = ps7.pins;
   interface leds = top.leds;
   interface XADC xadc;
       method Bit#(4) gpio;
           return debugReg;
`ifdef BOZOIFDEF
           return {intReg, 
                 pack((ps7.debug.arvalid == 1)
                   && (ps7.debug.araddr[18:16] == 3'd1)   // /dev/fpga1
                   && (ps7.debug.araddr[15:14] == 2'd2)   // indication
                   && (ps7.debug.araddr[13:8] == 6'd1)),  //     #1
                 ps7.debug.rvalid,
                 pack((ps7.debug.awvalid == 1)
                   && (ps7.debug.awaddr[18:16] == 3'd2)   // /dev/fpga2
                   && (ps7.debug.awaddr[15:14] == 2'd0)   // request
                   && (ps7.debug.awaddr[13:8] == 6'd1))}; //     #1
`endif
       endmethod
   endinterface
   interface pins = top.pins;
   interface unused_clock = mainclock.c;
   interface unused_reset = mainclock.r;
endmodule

module mkZynqTop(ZynqTop#(Empty));
   let top <- mkZynqTopFromPortal(mkPortalTop);
   return top;
endmodule
