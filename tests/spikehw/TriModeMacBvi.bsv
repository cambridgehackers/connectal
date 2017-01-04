
/*
   /home/jamey/connectal.clean/generated/scripts/importbvi.py
   -o
   TriModeMacBvi.bsv
   -P
   TriModeMac
   -I
   TriModeMacBvi
   -c
   gtx_clk
   -r
   glbl_rstn
   -r
   rx_axi_rstn
   -r
   tx_axi_rstn
   -c
   rx_mac_aclk
   -r
   rx_reset
   -c
   tx_mac_aclk
   -r
   tx_reset
   -c
   s_axi_aclk
   -r
   s_axi_resetn
   -f
   rx_axis_mac
   -f
   tx_axis_mac
   -n
   speedis100
   -n
   speedis10100
   cores/nfsume/tri_mode_ethernet_mac_0/tri_mode_ethernet_mac_0_stub.v
*/

`include "ConnectalProjectConfig.bsv"
import Clocks::*;
import DefaultValue::*;
import XilinxCells::*;
import GetPut::*;
import AxiBits::*;
import AxiStream::*;

(* always_ready, always_enabled *)
interface TrimodemacGmii;
    method Action      rx_dv(Bit#(1) v);
    method Action      rx_er(Bit#(1) v);
    method Action      rxd(Bit#(8) v);
    method Bit#(1)     tx_en();
    method Bit#(1)     tx_er();
    method Bit#(8)     txd();
endinterface
(* always_ready, always_enabled *)
(* always_ready, always_enabled *)
interface TrimodemacMac;
    method Bit#(1)     irq();
endinterface
(* always_ready, always_enabled *)
interface TrimodemacMdio;
    method Action      i(Bit#(1) v);
    method Bit#(1)     o();
    method Bit#(1)     t();
endinterface
(* always_ready, always_enabled *)
interface TrimodemacPause;
    method Action      req(Bit#(1) v);
    method Action      val(Bit#(16) v);
endinterface
(* always_ready, always_enabled *)
interface TrimodemacRx;
    method Bit#(5)     axis_filter_tuser();
    interface Clock     mac_aclk;
    method Reset     reset();
    method Bit#(1)     statistics_valid();
    method Bit#(28)     statistics_vector();
endinterface
(* always_ready, always_enabled *)
interface TrimodemacRx_axis_mac;
    method Bit#(8)     tdata();
    method Bit#(1)     tlast();
    method Bit#(1)     tuser();
    method Bit#(1)     tvalid();
endinterface
(* always_ready, always_enabled *)
interface TrimodemacS_axi;
    method Action      araddr(Bit#(12) v);
    method Bit#(1)     arready();
    method Action      arvalid(Bit#(1) v);
    method Action      awaddr(Bit#(12) v);
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
    method Action      wvalid(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface TrimodemacTx;
    method Action      ifg_delay(Bit#(8) v);
    interface Clock     mac_aclk;
    method Reset     reset();
    method Bit#(1)     statistics_valid();
    method Bit#(32)     statistics_vector();
endinterface
(* always_ready, always_enabled *)
interface TrimodemacTx_axis_mac;
    method Action      tdata(Bit#(8) v);
    method Action      tlast(Bit#(1) v);
    method Bit#(1)     tready();
    method Action      tuser(Bit#(1) v);
    method Action      tvalid(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface TriModeMac;
    interface TrimodemacGmii     gmii;
    interface TrimodemacMac     mac;
    method Bit#(1)     mdc();
    interface TrimodemacMdio     mdio;
    interface TrimodemacPause     pause;
    interface TrimodemacRx     rx;
    interface TrimodemacRx_axis_mac    rx_axis_mac;
    interface TrimodemacS_axi     s_axi;
    method Bit#(1)     speedis100();
    method Bit#(1)     speedis10100();
    interface TrimodemacTx     tx;
    interface TrimodemacTx_axis_mac     tx_axis_mac;
endinterface
import "BVI" tri_mode_ethernet_mac_0 =
module mkTriModeMacBvi#(Clock gtx_clk, Clock s_axi_aclk, Reset glbl_rstn, Reset rx_axi_rstn, Reset s_axi_resetn, Reset tx_axi_rstn)(TriModeMac);
    default_clock clk();
    default_reset rst();
        input_reset glbl_rstn(glbl_rstn) = glbl_rstn;
        input_clock gtx_clk(gtx_clk) = gtx_clk;
        input_reset rx_axi_rstn(rx_axi_rstn) = rx_axi_rstn;
        input_clock s_axi_aclk(s_axi_aclk) = s_axi_aclk;
        input_reset s_axi_resetn(s_axi_resetn) = s_axi_resetn;
        input_reset tx_axi_rstn(tx_axi_rstn) = tx_axi_rstn;
    interface TrimodemacGmii     gmii;
        method rx_dv(gmii_rx_dv) enable((*inhigh*) EN_gmii_rx_dv);
        method rx_er(gmii_rx_er) enable((*inhigh*) EN_gmii_rx_er);
        method rxd(gmii_rxd) enable((*inhigh*) EN_gmii_rxd);
        method gmii_tx_en tx_en();
        method gmii_tx_er tx_er();
        method gmii_txd txd();
    endinterface
    interface TrimodemacMac     mac;
        method mac_irq irq() clocked_by (s_axi_aclk) reset_by (s_axi_resetn);
    endinterface
    method mdc mdc();
    interface TrimodemacMdio     mdio;
        method i(mdio_i) enable((*inhigh*) EN_mdio_i);
        method mdio_o o();
        method mdio_t t();
    endinterface
    interface TrimodemacRx     rx;
        output_clock mac_aclk(rx_mac_aclk);
        output_reset reset(rx_reset) clocked_by (rx_mac_aclk);
        method rx_axis_filter_tuser axis_filter_tuser() clocked_by (rx_mac_aclk) reset_by (rx_reset);
        method rx_statistics_valid statistics_valid() clocked_by (rx_mac_aclk) reset_by (rx_reset);
        method rx_statistics_vector statistics_vector() clocked_by (rx_mac_aclk) reset_by (rx_reset);
    endinterface
    interface TrimodemacRx_axis_mac rx_axis_mac;
       method rx_axis_mac_tdata tdata() clocked_by (rx_mac_aclk) reset_by (rx_reset);
       method rx_axis_mac_tlast tlast() clocked_by (rx_mac_aclk) reset_by (rx_reset);
       method rx_axis_mac_tuser tuser() clocked_by (rx_mac_aclk) reset_by (rx_reset);
       method rx_axis_mac_tvalid tvalid() clocked_by (rx_mac_aclk) reset_by (rx_reset);
    endinterface
    interface TrimodemacS_axi     s_axi;
        method araddr(s_axi_araddr) clocked_by (s_axi_aclk) reset_by (s_axi_resetn) enable((*inhigh*) EN_s_axi_araddr);
        method s_axi_arready arready() clocked_by (s_axi_aclk) reset_by (s_axi_resetn);
        method arvalid(s_axi_arvalid) clocked_by (s_axi_aclk) reset_by (s_axi_resetn) enable((*inhigh*) EN_s_axi_arvalid);
        method awaddr(s_axi_awaddr) clocked_by (s_axi_aclk) reset_by (s_axi_resetn) enable((*inhigh*) EN_s_axi_awaddr);
        method s_axi_awready awready() clocked_by (s_axi_aclk) reset_by (s_axi_resetn);
        method awvalid(s_axi_awvalid) clocked_by (s_axi_aclk) reset_by (s_axi_resetn) enable((*inhigh*) EN_s_axi_awvalid);
        method bready(s_axi_bready) clocked_by (s_axi_aclk) reset_by (s_axi_resetn) enable((*inhigh*) EN_s_axi_bready);
        method s_axi_bresp bresp() clocked_by (s_axi_aclk) reset_by (s_axi_resetn);
        method s_axi_bvalid bvalid() clocked_by (s_axi_aclk) reset_by (s_axi_resetn);
        method s_axi_rdata rdata() clocked_by (s_axi_aclk) reset_by (s_axi_resetn);
        method rready(s_axi_rready) clocked_by (s_axi_aclk) reset_by (s_axi_resetn) enable((*inhigh*) EN_s_axi_rready);
        method s_axi_rresp rresp() clocked_by (s_axi_aclk) reset_by (s_axi_resetn);
        method s_axi_rvalid rvalid() clocked_by (s_axi_aclk) reset_by (s_axi_resetn);
        method wdata(s_axi_wdata) clocked_by (s_axi_aclk) reset_by (s_axi_resetn) enable((*inhigh*) EN_s_axi_wdata);
        method s_axi_wready wready() clocked_by (s_axi_aclk) reset_by (s_axi_resetn);
        method wvalid(s_axi_wvalid) clocked_by (s_axi_aclk) reset_by (s_axi_resetn) enable((*inhigh*) EN_s_axi_wvalid);
    endinterface
    method speedis100 speedis100();
    method speedis10100 speedis10100();
    interface TrimodemacTx     tx;
        output_clock mac_aclk(tx_mac_aclk);
        output_reset reset(tx_reset) clocked_by (tx_mac_aclk);
        method ifg_delay(tx_ifg_delay) enable((*inhigh*) EN_tx_ifg_delay) clocked_by (tx_mac_aclk) reset_by (tx_reset);
        method tx_statistics_valid statistics_valid() clocked_by (tx_mac_aclk) reset_by (tx_reset);
        method tx_statistics_vector statistics_vector() clocked_by (tx_mac_aclk) reset_by (tx_reset);
    endinterface
    interface TrimodemacTx_axis_mac     tx_axis_mac;
        method tdata(tx_axis_mac_tdata) enable((*inhigh*) EN_tx_axis_mac_tdata) clocked_by (tx_mac_aclk) reset_by (tx_reset);
        method tlast(tx_axis_mac_tlast) enable((*inhigh*) EN_tx_axis_mac_tlast) clocked_by (tx_mac_aclk) reset_by (tx_reset);
        method tx_axis_mac_tready tready() clocked_by (tx_mac_aclk) reset_by (tx_reset);
        method tuser(tx_axis_mac_tuser) enable((*inhigh*) EN_tx_axis_mac_tuser) clocked_by (tx_mac_aclk) reset_by (tx_reset);
        method tvalid(tx_axis_mac_tvalid) enable((*inhigh*) EN_tx_axis_mac_tvalid) clocked_by (tx_mac_aclk) reset_by (tx_reset);
    endinterface
    interface TrimodemacPause     pause;
        method req(pause_req) enable((*inhigh*) EN_pause_req) clocked_by (tx_mac_aclk) reset_by (tx_reset);
        method val(pause_val) enable((*inhigh*) EN_pause_val) clocked_by (tx_mac_aclk) reset_by (tx_reset);
    endinterface
    schedule (gmii.rx_dv, gmii.rx_er, gmii.rxd, gmii.tx_en, gmii.tx_er, gmii.txd, mac.irq, mdc, mdio.i, mdio.o, mdio.t, pause.req, pause.val, rx.axis_filter_tuser, rx.statistics_valid, rx.statistics_vector, rx_axis_mac.tdata, rx_axis_mac.tlast, rx_axis_mac.tuser, rx_axis_mac.tvalid, s_axi.araddr, s_axi.arready, s_axi.arvalid, s_axi.awaddr, s_axi.awready, s_axi.awvalid, s_axi.bready, s_axi.bresp, s_axi.bvalid, s_axi.rdata, s_axi.rready, s_axi.rresp, s_axi.rvalid, s_axi.wdata, s_axi.wready, s_axi.wvalid, speedis100, speedis10100, tx.ifg_delay, tx.statistics_valid, tx.statistics_vector, tx_axis_mac.tdata, tx_axis_mac.tlast, tx_axis_mac.tready, tx_axis_mac.tuser, tx_axis_mac.tvalid) CF (gmii.rx_dv, gmii.rx_er, gmii.rxd, gmii.tx_en, gmii.tx_er, gmii.txd, mac.irq, mdc, mdio.i, mdio.o, mdio.t, pause.req, pause.val, rx.axis_filter_tuser, rx.statistics_valid, rx.statistics_vector, rx_axis_mac.tdata, rx_axis_mac.tlast, rx_axis_mac.tuser, rx_axis_mac.tvalid, s_axi.araddr, s_axi.arready, s_axi.arvalid, s_axi.awaddr, s_axi.awready, s_axi.awvalid, s_axi.bready, s_axi.bresp, s_axi.bvalid, s_axi.rdata, s_axi.rready, s_axi.rresp, s_axi.rvalid, s_axi.wdata, s_axi.wready, s_axi.wvalid, speedis100, speedis10100, tx.ifg_delay, tx.statistics_valid, tx.statistics_vector, tx_axis_mac.tdata, tx_axis_mac.tlast, tx_axis_mac.tready, tx_axis_mac.tuser, tx_axis_mac.tvalid);
endmodule

`ifdef FLUTE
import TLM3         :: *;
import Axi4         :: *;
import AxiDefines   ::*;

instance ToAxi4LRdWrSlave#(TrimodemacS_axi);
   function Axi4LRdWrSlave#(`SoC_PRM) toAxi4LRdWrSlave(TrimodemacS_axi s);
      return (interface Axi4LRdWrSlave#(`SoC_PRM);
         interface Axi4LRdSlave read;
	    method Action arADDR(AxiAddr#(`SoC_PRM) addr); s.araddr(truncate(addr)); endmethod
	    method arREADY = unpack(s.arready());
	    method Action arVALID(Bool v); s.arvalid(pack(v)); endmethod
	     method rDATA = extend(s.rdata);
	     method Action rREADY(Bool r); s.rready(pack(r)); endmethod
	     method rRESP = unpack(s.rresp);
	     method rVALID = unpack(s.rvalid);
	 endinterface: read
         interface Axi4LWrSlave write;
	     method Action awADDR(AxiAddr#(`SoC_PRM) addr); s.awaddr(truncate(addr)); endmethod
	     method awREADY = unpack(s.awready);
	     method Action awVALID(Bool v); s.awvalid(pack(v)); endmethod
	     method Action bREADY(Bool r); s.bready(pack(r)); endmethod
	     method bRESP = unpack(s.bresp);
	     method bVALID = unpack(s.bvalid);
	     method Action wDATA(AxiData#(`SoC_PRM) d); s.wdata(truncate(d)); endmethod
	     method wREADY = unpack(s.wready);
	     method Action wVALID(Bool v); s.wvalid(pack(v)); endmethod
	 endinterface: write
	 endinterface);
   endfunction
endinstance

interface TriModeMacMac;
    method Bit#(1)     mdc();
   interface TrimodemacMdio          mdio;
   interface TrimodemacGmii          gmii;
   interface Server #(SoC_Req, SoC_Rsp) bus_ifc;
   interface TrimodemacTx            s_axis_tx;
   interface TrimodemacRx            m_axis_rx;
   interface Clock     mm2s_aclk;
   interface Clock     s2mm_aclk;
   method Bit#(1) interrupt();
endinterface

(* synthesize *)
module mkTriModeMacMac#(Clock gtx_clock)(TriModeMacMac);
   let clock <- exposeCurrentClock;
   let reset <- exposeCurrentReset;

   let gtx_reset = reset;

   let axiEth <- mkTriModeMacBvi(gtx_clock, clock, reset, reset, reset, reset);
   Axi4LRdWrSlave#(`SoC_PRM) axiRdWrSlave = toAxi4LRdWrSlave(axiEth.s_axi);
   let tlmRecv <- mkTLMRecvFromAxi4LSlave(axiRdWrSlave);

   method    mdc     = axiEth.mdc;
   interface mdio    = axiEth.mdio;
   interface bus_ifc = tlmRecv;
   interface gmii    = axiEth.gmii;
   method interrupt  = axiEth.mac.irq;
   interface s_axis_tx = axiEth.tx;
   interface m_axis_rx = axiEth.rx;
   interface mm2s_aclk = axiEth.rx.mac_aclk;
   interface s2mm_aclk = axiEth.tx.mac_aclk;
endmodule
`endif //FLUTE

instance ToAxi4SlaveBits#(Axi4SlaveLiteBits#(12,32), TrimodemacS_axi);
   function Axi4SlaveLiteBits#(12,32) toAxi4SlaveBits(TrimodemacS_axi s);
      return (interface Axi4SlaveLiteBits#(12,32);
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
	    //s.wstrb(pack(replicate(v)));
	 endmethod
	 endinterface);
   endfunction
endinstance
