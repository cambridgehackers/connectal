
/*
   /home/jamey/connectal.clean/generated/scripts/importbvi.py
   -o
   TriModeEthMacBvi.bsv
   -P
   TriModeEthBvi
   -I
   TriModeEthBvi
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
   -n
   speedis100
   -n
   speedis10100
   ../FPGA/rtl/vc709/tri_mode_ethernet_mac_0/tri_mode_ethernet_mac_0_stub.v
*/

import Clocks::*;
import DefaultValue::*;
import XilinxCells::*;
import GetPut::*;
import Connectable::*;
import Vector::*;
import GetPut::*;
import ClientServer::*;
import TLM3         :: *;
import Axi4         :: *;
import AxiDefines   ::*;

import AxiStream  :: *;
import SoC_Defs   :: *;
import SysConfigs :: *;
import Utils      :: *;

import GigEthPcsPma :: *;

`include "SoC.defines"


(* always_ready, always_enabled *)
(* always_ready, always_enabled *)
interface TrimodeethbviGmii;
    method Action      rx_dv(Bit#(1) v);
    method Action      rx_er(Bit#(1) v);
    method Action      rxd(Bit#(8) v);
    method Bit#(1)     tx_en();
    method Bit#(1)     tx_er();
    method Bit#(8)     txd();
endinterface
(* always_ready, always_enabled *)
(* always_ready, always_enabled *)
interface TrimodeethbviMac;
    method Bit#(1)     irq();
endinterface
(* always_ready, always_enabled *)
interface TrimodeethbviMdio;
    method Action      i(Bit#(1) v);
    method Bit#(1)     o();
    method Bit#(1)     t();
endinterface
(* always_ready, always_enabled *)
interface TrimodeethbviPause;
    method Action      req(Bit#(1) v);
    method Action      val(Bit#(16) v);
endinterface
(* always_ready, always_enabled *)
interface TrimodeethbviRx;
    method Bit#(5)     axis_filter_tuser();
    method Bit#(8)     axis_mac_tdata();
    method Bit#(1)     axis_mac_tlast();
    method Bit#(1)     axis_mac_tuser();
    method Bit#(1)     axis_mac_tvalid();
    interface Clock     mac_aclk;
    method Reset     reset();
    method Bit#(1)     statistics_valid();
    method Bit#(28)     statistics_vector();
endinterface
(* always_ready, always_enabled *)
interface TrimodeethbviS_axi;
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
interface TrimodeethbviTx;
    method Action      axis_mac_tdata(Bit#(8) v);
    method Action      axis_mac_tlast(Bit#(1) v);
    method Bit#(1)     axis_mac_tready();
    method Action      axis_mac_tuser(Bit#(1) v);
    method Action      axis_mac_tvalid(Bit#(1) v);
    method Action      ifg_delay(Bit#(8) v);
    interface Clock     mac_aclk;
    method Reset     reset();
    method Bit#(1)     statistics_valid();
    method Bit#(32)     statistics_vector();
endinterface
(* always_ready, always_enabled *)
interface TriModeEthBvi;
    interface TrimodeethbviGmii     gmii;
    interface TrimodeethbviMac     mac;
    method Bit#(1)     mdc();
    interface TrimodeethbviMdio     mdio;
    interface TrimodeethbviPause     pause;
    interface TrimodeethbviRx     rx;
    interface TrimodeethbviS_axi     s_axi;
    method Bit#(1)     speedis100();
    method Bit#(1)     speedis10100();
    interface TrimodeethbviTx     tx;
endinterface
import "BVI" tri_mode_ethernet_mac_0 =
module mkTriModeEthBvi#(Clock gtx_clk, Clock s_axi_aclk, Reset glbl_rstn, Reset rx_axi_rstn, Reset s_axi_resetn, Reset tx_axi_rstn)(TriModeEthBvi);
        input_reset glbl_rstn(glbl_rstn) = glbl_rstn;
        input_clock gtx_clk(gtx_clk) = gtx_clk;
        input_reset rx_axi_rstn(rx_axi_rstn) = rx_axi_rstn;
        default_clock s_axi_aclk(s_axi_aclk) = s_axi_aclk;
        default_reset s_axi_resetn(s_axi_resetn) = s_axi_resetn;
        input_reset tx_axi_rstn(tx_axi_rstn) = tx_axi_rstn;
    interface TrimodeethbviGmii     gmii;
        method rx_dv(gmii_rx_dv) enable((*inhigh*) EN_gmii_rx_dv);
        method rx_er(gmii_rx_er) enable((*inhigh*) EN_gmii_rx_er);
        method rxd(gmii_rxd) enable((*inhigh*) EN_gmii_rxd);
        method gmii_tx_en tx_en();
        method gmii_tx_er tx_er();
        method gmii_txd txd();
    endinterface
    interface TrimodeethbviMac     mac;
        method mac_irq irq();
    endinterface
    method mdc mdc();
    interface TrimodeethbviMdio     mdio;
        method i(mdio_i) enable((*inhigh*) EN_mdio_i);
        method mdio_o o();
        method mdio_t t();
    endinterface
    interface TrimodeethbviPause     pause;
        method req(pause_req) enable((*inhigh*) EN_pause_req);
        method val(pause_val) enable((*inhigh*) EN_pause_val);
    endinterface
    interface TrimodeethbviRx     rx;
        method rx_axis_filter_tuser axis_filter_tuser();
        method rx_axis_mac_tdata axis_mac_tdata();
        method rx_axis_mac_tlast axis_mac_tlast();
        method rx_axis_mac_tuser axis_mac_tuser();
        method rx_axis_mac_tvalid axis_mac_tvalid();
        output_clock mac_aclk(rx_mac_aclk);
        output_reset reset(rx_reset);
        method rx_statistics_valid statistics_valid();
        method rx_statistics_vector statistics_vector();
    endinterface
    interface TrimodeethbviS_axi     s_axi;
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
    interface TrimodeethbviTx     tx;
        method axis_mac_tdata(tx_axis_mac_tdata) enable((*inhigh*) EN_tx_axis_mac_tdata);
        method axis_mac_tlast(tx_axis_mac_tlast) enable((*inhigh*) EN_tx_axis_mac_tlast);
        method tx_axis_mac_tready axis_mac_tready();
        method axis_mac_tuser(tx_axis_mac_tuser) enable((*inhigh*) EN_tx_axis_mac_tuser);
        method axis_mac_tvalid(tx_axis_mac_tvalid) enable((*inhigh*) EN_tx_axis_mac_tvalid);
        method ifg_delay(tx_ifg_delay) enable((*inhigh*) EN_tx_ifg_delay);
        output_clock mac_aclk(tx_mac_aclk);
        output_reset reset(tx_reset);
        method tx_statistics_valid statistics_valid();
        method tx_statistics_vector statistics_vector();
    endinterface
    schedule (gmii.rx_dv, gmii.rx_er, gmii.rxd, gmii.tx_en, gmii.tx_er, gmii.txd, mac.irq, mdc, mdio.i, mdio.o, mdio.t, pause.req, pause.val, rx.axis_filter_tuser, rx.axis_mac_tdata, rx.axis_mac_tlast, rx.axis_mac_tuser, rx.axis_mac_tvalid, rx.statistics_valid, rx.statistics_vector, s_axi.araddr, s_axi.arready, s_axi.arvalid, s_axi.awaddr, s_axi.awready, s_axi.awvalid, s_axi.bready, s_axi.bresp, s_axi.bvalid, s_axi.rdata, s_axi.rready, s_axi.rresp, s_axi.rvalid, s_axi.wdata, s_axi.wready, s_axi.wvalid, speedis100, speedis10100, tx.axis_mac_tdata, tx.axis_mac_tlast, tx.axis_mac_tready, tx.axis_mac_tuser, tx.axis_mac_tvalid, tx.ifg_delay, tx.statistics_valid, tx.statistics_vector) CF (gmii.rx_dv, gmii.rx_er, gmii.rxd, gmii.tx_en, gmii.tx_er, gmii.txd, mac.irq, mdc, mdio.i, mdio.o, mdio.t, pause.req, pause.val, rx.axis_filter_tuser, rx.axis_mac_tdata, rx.axis_mac_tlast, rx.axis_mac_tuser, rx.axis_mac_tvalid, rx.statistics_valid, rx.statistics_vector, s_axi.araddr, s_axi.arready, s_axi.arvalid, s_axi.awaddr, s_axi.awready, s_axi.awvalid, s_axi.bready, s_axi.bresp, s_axi.bvalid, s_axi.rdata, s_axi.rready, s_axi.rresp, s_axi.rvalid, s_axi.wdata, s_axi.wready, s_axi.wvalid, speedis100, speedis10100, tx.axis_mac_tdata, tx.axis_mac_tlast, tx.axis_mac_tready, tx.axis_mac_tuser, tx.axis_mac_tvalid, tx.ifg_delay, tx.statistics_valid, tx.statistics_vector);
endmodule

instance ToAxi4LRdWrSlave#(TrimodeethbviS_axi);
   function Axi4LRdWrSlave#(`SoC_PRM) toAxi4LRdWrSlave(TrimodeethbviS_axi s);
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

instance Connectable#(TrimodeethbviGmii,GigethpcspmabviGmii);
   module mkConnection#(TrimodeethbviGmii mac, GigethpcspmabviGmii phy)(Empty);
      rule rx;
	 mac.rx_dv(phy.rx_dv());
	 mac.rx_er(phy.rx_er());
	 mac.rxd(phy.rxd());
      endrule
      rule tx;
	 phy.tx_en(mac.tx_en());
	 phy.tx_er(mac.tx_er());
	 phy.txd(mac.txd());
      endrule
   endmodule
endinstance

instance Connectable#(TrimodeethbviMdio,GigethpcspmabviMdio);
   module mkConnection#(TrimodeethbviMdio macMdio, GigethpcspmabviMdio phyMdio)(Empty);
      rule rl_mdio;
	 macMdio.i(phyMdio.o());
	 phyMdio.i(macMdio.o());
      endrule
   endmodule
endinstance


interface TriModeEthMac;
    method Bit#(1)     mdc();
   interface TrimodeethbviMdio          mdio;
   interface TrimodeethbviGmii          gmii;
   interface Server #(SoC_Req, SoC_Rsp) bus_ifc;
   interface TrimodeethbviTx            s_axis_tx;
   interface TrimodeethbviRx            m_axis_rx;
   interface Clock     mm2s_aclk;
   interface Clock     s2mm_aclk;
   method Bit#(1) interrupt();
endinterface

instance Connectable#(TriModeEthMac,GigEthPcsPma);
   module mkConnection#(TriModeEthMac mac, GigEthPcsPma phy)(Empty);
      let mdcCnx  <- mkConnection(phy.mdc,  mac.mdc); // should be a clock, but PHY is providing a clock to MAC and this would make a cycle
      let mdioCnx <- mkConnection(mac.mdio, phy.mdio);
      let gmiiCnx <- mkConnection(mac.gmii, phy.gmii);
   endmodule
endinstance

instance Connectable#(TrimodeethbviRx,AxiStreamSlave#(32));
   module mkConnection#(TrimodeethbviRx from, AxiStreamSlave#(32) to)(Empty);
      rule rl_axi_stream;
	 to.tdata(extend(from.axis_mac_tdata()));
	 to.tkeep(1); // only 8 bits valid
	 to.tlast(from.axis_mac_tlast());
	 to.tvalid(from.axis_mac_tvalid());
	 //from.axis_mac_tready(to.tready()); no tready
      endrule
   endmodule
endinstance

instance Connectable#(AxiStreamMaster#(32),TrimodeethbviTx);
   module mkConnection#(AxiStreamMaster#(32) from, TrimodeethbviTx to)(Empty);
      rule rl_axi_stream;
	 to.axis_mac_tdata(truncate(from.tdata()));
	 // tkeep unused
	 to.axis_mac_tlast(from.tlast());
	 to.axis_mac_tvalid(from.tvalid());
	 from.tready(to.axis_mac_tready());
      endrule
   endmodule
endinstance

(* synthesize *)
module mkTriModeEthMac#(Clock gtx_clock)(TriModeEthMac);
   let clock <- exposeCurrentClock;
   let reset <- exposeCurrentReset;

   let gtx_reset = reset;

   let axiEth <- mkTriModeEthBvi(gtx_clock, clock, reset, reset, reset, reset);
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

