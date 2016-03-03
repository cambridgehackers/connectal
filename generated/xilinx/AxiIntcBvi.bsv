
/*
   ../scripts/importbvi.py
   -P
   AxiIntc
   -I
   AxiIntc
   -c
   s_axi_aclk
   -r
   s_axi_aresetn
   -o
   AxiIntcBvi.bsv
   ../../out/vc709/axi_intc_0/axi_intc_0_stub.v
*/

import Clocks::*;
import DefaultValue::*;
import XilinxCells::*;
import GetPut::*;
import Vector::*;
import AxiBits::*;

(* always_ready, always_enabled *)
interface AxiintcbviS_axi;
    method Action      araddr(Bit#(9) v);
    method Bit#(1)     arready();
    method Action      arvalid(Bit#(1) v);
    method Action      awaddr(Bit#(9) v);
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
interface AxiIntc;
    method Action      intr(Bit#(16) v);
    method Bit#(1)     irq();
    interface AxiintcbviS_axi s_axi;
endinterface
import "BVI" axi_intc_0 =
module mkAxiIntcBvi#(Clock s_axi_aclk, Reset s_axi_aresetn)(AxiIntc);
    default_clock clk();
    default_reset rst();
        input_clock s_axi_aclk(s_axi_aclk) = s_axi_aclk;
        input_reset s_axi_aresetn(s_axi_aresetn) = s_axi_aresetn;
    method intr(intr) enable((*inhigh*) EN_intr) clocked_by (s_axi_aclk) reset_by (s_axi_aresetn);
    method irq irq() clocked_by (s_axi_aclk) reset_by (s_axi_aresetn);
    interface AxiintcbviS_axi s_axi;
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
    schedule (intr, irq, s_axi.araddr, s_axi.arready, s_axi.arvalid, s_axi.awaddr, s_axi.awready, s_axi.awvalid, s_axi.bready, s_axi.bresp, s_axi.bvalid, s_axi.rdata, s_axi.rready, s_axi.rresp, s_axi.rvalid, s_axi.wdata, s_axi.wready, s_axi.wstrb, s_axi.wvalid) CF (intr, irq, s_axi.araddr, s_axi.arready, s_axi.arvalid, s_axi.awaddr, s_axi.awready, s_axi.awvalid, s_axi.bready, s_axi.bresp, s_axi.bvalid, s_axi.rdata, s_axi.rready, s_axi.rresp, s_axi.rvalid, s_axi.wdata, s_axi.wready, s_axi.wstrb, s_axi.wvalid);
endmodule

instance ToAxi4SlaveBits#(Axi4SlaveLiteBits#(9,32), AxiintcbviS_axi);
   function Axi4SlaveLiteBits#(9,32) toAxi4SlaveBits(AxiintcbviS_axi s);
      return (interface Axi4SlaveLiteBits#(9,32);
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
