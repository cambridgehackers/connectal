
/*
   ../../generated/scripts/importbvi.py
   -I
   AxiSpiBvi
   -P
   AxiSpi
   -c
   ext_spi_clk
   -c
   s_axi_aclk
   -r
   s_axi_aresetn
   -n
   ip2intc_irpt
   -o
   AxiSpiBvi.bsv
   cores/nfsume/axi_spi_0/axi_spi_0_stub.v
*/

import Clocks::*;
import DefaultValue::*;
import XilinxCells::*;
import GetPut::*;
import Vector::*;
import AxiBits::*;

(* always_ready, always_enabled *)
(* always_ready, always_enabled *)
interface AxispiIo;
    method Action      i(Bit#(1) v);
    method Bit#(1)     o();
    method Bit#(1)     t();
endinterface
(* always_ready, always_enabled *)
interface AxispiS_axi;
    method Action      araddr(Bit#(7) v);
    method Bit#(1)     arready();
    method Action      arvalid(Bit#(1) v);
    method Action      awaddr(Bit#(7) v);
    method Bit#(1)     awready();
    method Action      awvalid(Bit#(1) v);
    method Action      bready(Bit#(1) v);
    method Bit#(2)     bresp();
    method Bit#(1)     bvalid();
    method Bit#(32)     rdata();
    method Action      rready(Bit#(1) v);
    method Bit#(2)     rresp();
    method Bit#(1)     rvalid();
    method Action      wdata(Bit#(32) v);
    method Bit#(1)     wready();
    method Action      wstrb(Bit#(4) v);
    method Action      wvalid(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface AxispiSck;
    method Action      i(Bit#(1) v);
    method Bit#(1)     o();
    method Bit#(1)     t();
endinterface
(* always_ready, always_enabled *)
interface AxispiSs;
    method Action      i(Bit#(1) v);
    method Bit#(1)     o();
    method Bit#(1)     t();
endinterface
(* always_ready, always_enabled *)
interface AxiSpiBvi;
    interface AxispiIo     io0;
    interface AxispiIo     io1;
    method Bit#(1)     ip2intc_irpt();
    interface AxispiS_axi     s_axi;
    interface AxispiSck     sck;
    interface AxispiSs     ss;
endinterface
import "BVI" axi_spi_0 =
module mkAxiSpiBvi#(Clock ext_spi_clk, Clock s_axi_aclk, Reset s_axi_aresetn)(AxiSpiBvi);
    default_clock clk();
    default_reset rst();
        input_clock ext_spi_clk(ext_spi_clk) = ext_spi_clk;
        input_clock s_axi_aclk(s_axi_aclk) = s_axi_aclk;
        input_reset s_axi_aresetn(s_axi_aresetn) = s_axi_aresetn;
    interface AxispiIo     io0;
        method i(io0_i) enable((*inhigh*) EN_io0_i);
        method io0_o o();
        method io0_t t();
    endinterface
    interface AxispiIo     io1;
        method i(io1_i) enable((*inhigh*) EN_io1_i);
        method io1_o o();
        method io1_t t();
    endinterface
    method ip2intc_irpt ip2intc_irpt();
    interface AxispiS_axi     s_axi;
        method araddr(s_axi_araddr) clocked_by (s_axi_aclk) reset_by (s_axi_aresetn) enable((*inhigh*) EN_s_axi_araddr);
        method s_axi_arready arready() clocked_by (s_axi_aclk) reset_by (s_axi_aresetn);
        method arvalid(s_axi_arvalid) clocked_by (s_axi_aclk) reset_by (s_axi_aresetn) enable((*inhigh*) EN_s_axi_arvalid);
        method awaddr(s_axi_awaddr) clocked_by (s_axi_aclk) reset_by (s_axi_aresetn) enable((*inhigh*) EN_s_axi_awaddr);
        method s_axi_awready awready() clocked_by (s_axi_aclk) reset_by (s_axi_aresetn);
        method awvalid(s_axi_awvalid) clocked_by (s_axi_aclk) reset_by (s_axi_aresetn) enable((*inhigh*) EN_s_axi_awvalid);
        method bready(s_axi_bready) clocked_by (s_axi_aclk) reset_by (s_axi_aresetn) enable((*inhigh*) EN_s_axi_bready);
        method s_axi_bresp bresp() clocked_by (s_axi_aclk) reset_by (s_axi_aresetn);
        method s_axi_bvalid bvalid() clocked_by (s_axi_aclk) reset_by (s_axi_aresetn);
        method s_axi_rdata rdata() clocked_by (s_axi_aclk) reset_by (s_axi_aresetn);
        method rready(s_axi_rready) clocked_by (s_axi_aclk) reset_by (s_axi_aresetn) enable((*inhigh*) EN_s_axi_rready);
        method s_axi_rresp rresp() clocked_by (s_axi_aclk) reset_by (s_axi_aresetn);
        method s_axi_rvalid rvalid() clocked_by (s_axi_aclk) reset_by (s_axi_aresetn);
        method wdata(s_axi_wdata) clocked_by (s_axi_aclk) reset_by (s_axi_aresetn) enable((*inhigh*) EN_s_axi_wdata);
        method s_axi_wready wready() clocked_by (s_axi_aclk) reset_by (s_axi_aresetn);
        method wstrb(s_axi_wstrb) clocked_by (s_axi_aclk) reset_by (s_axi_aresetn) enable((*inhigh*) EN_s_axi_wstrb);
        method wvalid(s_axi_wvalid) clocked_by (s_axi_aclk) reset_by (s_axi_aresetn) enable((*inhigh*) EN_s_axi_wvalid);
    endinterface
    interface AxispiSck     sck;
        method i(sck_i) enable((*inhigh*) EN_sck_i);
        method sck_o o();
        method sck_t t();
    endinterface
    interface AxispiSs     ss;
        method i(ss_i) enable((*inhigh*) EN_ss_i);
        method ss_o o();
        method ss_t t();
    endinterface
    schedule (io0.i, io0.o, io0.t, io1.i, io1.o, io1.t, ip2intc_irpt, s_axi.araddr, s_axi.arready, s_axi.arvalid, s_axi.awaddr, s_axi.awready, s_axi.awvalid, s_axi.bready, s_axi.bresp, s_axi.bvalid, s_axi.rdata, s_axi.rready, s_axi.rresp, s_axi.rvalid, s_axi.wdata, s_axi.wready, s_axi.wstrb, s_axi.wvalid, sck.i, sck.o, sck.t, ss.i, ss.o, ss.t) CF (io0.i, io0.o, io0.t, io1.i, io1.o, io1.t, ip2intc_irpt, s_axi.araddr, s_axi.arready, s_axi.arvalid, s_axi.awaddr, s_axi.awready, s_axi.awvalid, s_axi.bready, s_axi.bresp, s_axi.bvalid, s_axi.rdata, s_axi.rready, s_axi.rresp, s_axi.rvalid, s_axi.wdata, s_axi.wready, s_axi.wstrb, s_axi.wvalid, sck.i, sck.o, sck.t, ss.i, ss.o, ss.t);
endmodule

instance ToAxi4SlaveBits#(Axi4SlaveLiteBits#(7,32), AxispiS_axi);
   function Axi4SlaveLiteBits#(7,32) toAxi4SlaveBits(AxispiS_axi s);
      return (interface Axi4SlaveLiteBits#(7,32);
	 method araddr = s.araddr;
	 method arready = s.arready;
	 method arvalid = s.arvalid;
	 method awaddr = s.awaddr;
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
