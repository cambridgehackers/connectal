
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

import Clocks       :: *;
import DefaultValue :: *;
import XilinxCells  :: *;
import Vector       :: *;

(* always_ready, always_enabled *)
interface AxiBus;
   //method Bit#(5) cntvalueout();
   method Action aclk(Bit#(1) v);
   method Action arlock(Bit#(1) v);
   method Action awlock(Bit#(1) v);
   method Action araddr(Bit#(1) v);
   method Action arburst(Bit#(1) v);
   method Action arcache(Bit#(1) v);
   method Action arid(Bit#(1) v);
   method Action arlen(Bit#(1) v);
   method Action arprot(Bit#(1) v);
   method Action arready(Bit#(1) v);
   method Action arsize(Bit#(1) v);
   method Action arvalid(Bit#(1) v);
   method Action awaddr(Bit#(1) v);
   method Action awburst(Bit#(1) v);
   method Action awcache(Bit#(1) v);
   method Action awid(Bit#(1) v);
   method Action awlen(Bit#(1) v);
   method Action awprot(Bit#(1) v);
   method Action awready(Bit#(1) v);
   method Action awsize(Bit#(1) v);
   method Action awvalid(Bit#(1) v);
   method Action bid(Bit#(1) v);
   method Action bready(Bit#(1) v);
   method Action bresp(Bit#(1) v);
   method Action bvalid(Bit#(1) v);
   method Action rdata(Bit#(1) v);
   method Action rid(Bit#(1) v);
   method Action rlast(Bit#(1) v);
   method Action rready(Bit#(1) v);
   method Action rresp(Bit#(1) v);
   method Action rvalid(Bit#(1) v);
   method Action wdata(Bit#(1) v);
   method Action wid(Bit#(1) v);
   method Action wlast(Bit#(1) v);
   method Action wready(Bit#(1) v);
   method Action wstrb(Bit#(1) v);
   method Action wvalid(Bit#(1) v);
endinterface
interface Ddr;
   method Action addr(Bit#(1) v);
   method Action bankaddr(Bit#(1) v);
   method Action cas_n(Bit#(1) v);
   method Action cke(Bit#(1) v);
   method Action cs_n(Bit#(1) v);
   method Action clk(Bit#(1) v);
   method Action clk_n(Bit#(1) v);
   method Action dm(Bit#(1) v);
   method Action dq(Bit#(1) v);
   method Action dqs(Bit#(1) v);
   method Action dqs_n(Bit#(1) v);
   method Action drstb(Bit#(1) v);
   method Action odt(Bit#(1) v);
   method Action ras_n(Bit#(1) v);
   method Action vrn(Bit#(1) v);
   method Action vrp(Bit#(1) v);
   method Action web(Bit#(1) v);
endinterface
interface Ps7;
   interface AxiBus m_axi_gp0;
   interface Ddr ddr;
   method Action fclk_clk0(Bit#(1) v);
   method Action fclk_clk1(Bit#(1) v);
   method Action fclk_clk2(Bit#(1) v);
   method Action fclk_clk3(Bit#(1) v);
   method Action fclk_reset0_n(Bit#(1) v);
   method Action irq_f2p(Bit#(1) v);
   method Action mio(Bit#(1) v);
   method Action ps_porb(Bit#(1) v);
   method Action ps_srstb(Bit#(1) v);
   method Action i2c1_sda_i(Bit#(1) v);
   method Action i2c1_sda_o(Bit#(1) v);
   method Action i2c1_sda_t(Bit#(1) v);
   method Action i2c1_scl_i(Bit#(1) v);
   method Action i2c1_scl_o(Bit#(1) v);
   method Action i2c1_scl_t(Bit#(1) v);
   method Action ps_clk(Bit#(1) v);
endinterface

import "BVI" processing_system7 =
module mkPS7(Ps7);
   default_clock clk(C);
   no_reset;
   input_clock serdes ()= serdes_clock;

   parameter C_NUM_F2P_INTR_INPUTS = 16;

   method CNTVALUEOUT cntvalueout();
   method cinvctrl(CINVCTRL) enable((*inhigh*) en0);
   method ldpipeen(LDPIPEEN) enable((*inhigh*) en21);

   schedule (datain, idatain, inc, ce) CF (datain, idatain, inc, ce);
endmodule
