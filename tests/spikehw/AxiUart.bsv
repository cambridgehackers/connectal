
/*
   /home/jamey/connectal.clean/generated/scripts/importbvi.py
   -P
   AxiUart
   -I
   AxiUart
   -c
   s_axi_aclk
   -r
   s_axi_aresetn
   -n
   ip2intc_irpt
   -n
   out1n
   -n
   out2n
   -o
   AxiUart.bsv
   cores/vc709/axi_uart16550_1/axi_uart16550_1_stub.v
*/

import Clocks::*;
import DefaultValue::*;
import XilinxCells::*;
import GetPut::*;
import AxiBits::*;
import Vector::*;

(* always_ready, always_enabled *)
interface AxiuartS_axi;
    method Action      araddr(Bit#(13) v);
    method Bit#(1)     arready();
    method Action      arvalid(Bit#(1) v);
    method Action      awaddr(Bit#(13) v);
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
interface AxiUart;
    method Bit#(1)     baudoutn();
    method Action      ctsn(Bit#(1) v);
    method Action      dcdn(Bit#(1) v);
    method Bit#(1)     ddis();
    method Action      dsrn(Bit#(1) v);
    method Bit#(1)     dtrn();
    method Action      freeze(Bit#(1) v);
    method Bit#(1)     ip2intc_irpt();
    method Bit#(1)     out1n();
    method Bit#(1)     out2n();
    method Action      rin(Bit#(1) v);
    method Bit#(1)     rtsn();
    method Bit#(1)     rxrdyn();
    interface AxiuartS_axi     s_axi;
    method Action      sin(Bit#(1) v);
    method Bit#(1)     sout();
    method Bit#(1)     txrdyn();
    method Bit#(1)     xout();
endinterface
import "BVI" axi_uart16550_1 =
module mkAxiUartBvi#(Clock s_axi_aclk, Reset s_axi_aresetn, Clock uartClk)(AxiUart);
    default_clock clk();
    default_reset rst();
        input_clock s_axi_aclk(s_axi_aclk) = s_axi_aclk;
        input_reset s_axi_aresetn(s_axi_aresetn) = s_axi_aresetn;
    input_clock xin(xin) = uartClk;
    method baudoutn baudoutn();
    method ctsn(ctsn) enable((*inhigh*) EN_ctsn);
    method dcdn(dcdn) enable((*inhigh*) EN_dcdn);
    method ddis ddis();
    method dsrn(dsrn) enable((*inhigh*) EN_dsrn);
    method dtrn dtrn();
    method freeze(freeze) enable((*inhigh*) EN_freeze);
    method ip2intc_irpt ip2intc_irpt();
    method out1n out1n();
    method out2n out2n();
    method rin(rin) enable((*inhigh*) EN_rin);
    method rtsn rtsn();
    method rxrdyn rxrdyn();
    interface AxiuartS_axi     s_axi;
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
    method sin(sin) enable((*inhigh*) EN_sin);
    method sout sout();
    method txrdyn txrdyn();
    method xout xout();
    schedule (baudoutn, ctsn, dcdn, ddis, dsrn, dtrn, freeze, ip2intc_irpt, out1n, out2n, rin, rtsn, rxrdyn, s_axi.araddr, s_axi.arready, s_axi.arvalid, s_axi.awaddr, s_axi.awready, s_axi.awvalid, s_axi.bready, s_axi.bresp, s_axi.bvalid, s_axi.rdata, s_axi.rready, s_axi.rresp, s_axi.rvalid, s_axi.wdata, s_axi.wready, s_axi.wstrb, s_axi.wvalid, sin, sout, txrdyn, xout) CF (baudoutn, ctsn, dcdn, ddis, dsrn, dtrn, freeze, ip2intc_irpt, out1n, out2n, rin, rtsn, rxrdyn, s_axi.araddr, s_axi.arready, s_axi.arvalid, s_axi.awaddr, s_axi.awready, s_axi.awvalid, s_axi.bready, s_axi.bresp, s_axi.bvalid, s_axi.rdata, s_axi.rready, s_axi.rresp, s_axi.rvalid, s_axi.wdata, s_axi.wready, s_axi.wstrb, s_axi.wvalid, sin, sout, txrdyn, xout);
endmodule

instance ToAxi4SlaveBits#(Axi4SlaveLiteBits#(12,32), AxiuartS_axi);
   function Axi4SlaveLiteBits#(12,32) toAxi4SlaveBits(AxiuartS_axi s);
      return (interface Axi4SlaveLiteBits#(12,32);
	 method Action araddr(Bit#(12) addr); s.araddr(extend(addr)); endmethod
	 method arready = s.arready;
	 method arvalid = s.arvalid;
	 method Action awaddr(Bit#(12) addr); s.awaddr(extend(addr)); endmethod
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
