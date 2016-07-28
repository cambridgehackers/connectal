
/*
   ../../generated/scripts/importbvi.py
   -I
   APRP
   -P
   APRP
   -r
   axi_aresetn
   -c
   axi_aclk_out
   -c
   axi_ctl_aclk_out
   -c
   REFCLK
   -o
   AxiPcieRootPort.bsv
   /home/jamey/miniitx100/miniitx100.srcs/sources_1/ip/axi_pcie_0/axi_pcie_0_stub.v
*/

import Clocks::*;
import DefaultValue::*;
import XilinxCells::*;
import GetPut::*;
import AxiBits::*;
import NvmeIfc::*; // for PcieDataBusWidth

(* always_ready, always_enabled *)
interface AprpAxi;
    interface Clock     aclk_out;
    interface Clock     ctl_aclk_out;
endinterface
(* always_ready, always_enabled *)
interface AprpInterrupt;
    method Bit#(1)     out();
endinterface
(* always_ready, always_enabled *)
interface AprpIntx;
    method Bit#(1)     msi_grant();
    method Action      msi_request(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface AprpM_axi;
    method Bit#(32)     araddr();
    method Bit#(2)     arburst();
    method Bit#(4)     arcache();
    method Bit#(8)     arlen();
    method Bit#(1)     arlock();
    method Bit#(3)     arprot();
    method Action      arready(Bit#(1) v);
    method Bit#(3)     arsize();
    method Bit#(1)     arvalid();
    method Bit#(32)     awaddr();
    method Bit#(2)     awburst();
    method Bit#(4)     awcache();
    method Bit#(8)     awlen();
    method Bit#(1)     awlock();
    method Bit#(3)     awprot();
    method Action      awready(Bit#(1) v);
    method Bit#(3)     awsize();
    method Bit#(1)     awvalid();
    method Bit#(1)     bready();
    method Action      bresp(Bit#(2) v);
    method Action      bvalid(Bit#(1) v);
    method Action      rdata(Bit#(PcieDataBusWidth) v);
    method Action      rlast(Bit#(1) v);
    method Bit#(1)     rready();
    method Action      rresp(Bit#(2) v);
    method Action      rvalid(Bit#(1) v);
    method Bit#(PcieDataBusWidth)     wdata();
    method Bit#(1)     wlast();
    method Action      wready(Bit#(1) v);
    method Bit#(TDiv#(PcieDataBusWidth,8))     wstrb();
    method Bit#(1)     wvalid();
endinterface
(* always_ready, always_enabled *)
interface AprpMmcm;
    method Bit#(1)     lock();
endinterface
(* always_ready, always_enabled *)
interface AprpMsi;
    method Bit#(1)     enable();
    method Action      vector_num(Bit#(5) v);
    method Bit#(3)     vector_width();
endinterface
(* always_ready, always_enabled *)
interface AprpPci;
    method Action      exp_rxn(Bit#(4) v);
    method Action      exp_rxp(Bit#(4) v);
    method Bit#(4)     exp_txn();
    method Bit#(4)     exp_txp();
endinterface
(* always_ready, always_enabled *)
interface AprpS_axi;
    method Action      araddr(Bit#(32) v);
    method Action      arburst(Bit#(2) v);
    method Action      arid(Bit#(4) v);
    method Action      arlen(Bit#(8) v);
    method Bit#(1)     arready();
    method Action      arregion(Bit#(4) v);
    method Action      arsize(Bit#(3) v);
    method Action      arvalid(Bit#(1) v);
    method Action      awaddr(Bit#(32) v);
    method Action      awburst(Bit#(2) v);
    method Action      awid(Bit#(4) v);
    method Action      awlen(Bit#(8) v);
    method Bit#(1)     awready();
    method Action      awregion(Bit#(4) v);
    method Action      awsize(Bit#(3) v);
    method Action      awvalid(Bit#(1) v);
    method Bit#(4)     bid();
    method Action      bready(Bit#(1) v);
    method Bit#(2)     bresp();
    method Bit#(1)     bvalid();
    method Bit#(PcieDataBusWidth)     rdata();
    method Bit#(4)     rid();
    method Bit#(1)     rlast();
    method Action      rready(Bit#(1) v);
    method Bit#(2)     rresp();
    method Bit#(1)     rvalid();
    method Action      wdata(Bit#(PcieDataBusWidth) v);
    method Action      wlast(Bit#(1) v);
    method Bit#(1)     wready();
    method Action      wstrb(Bit#(TDiv#(PcieDataBusWidth,8)) v);
    method Action      wvalid(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface AprpS_axi_ctl;
    method Action      araddr(Bit#(32) v);
    method Bit#(1)     arready();
    method Action      arvalid(Bit#(1) v);
    method Action      awaddr(Bit#(32) v);
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
interface APRP;
    interface AprpAxi     axi;
    interface AprpInterrupt     interrupt;
    interface AprpIntx     intx;
    interface AprpM_axi     m_axi;
    interface AprpMmcm     mmcm;
    interface AprpMsi     msi;
    interface AprpPci     pci;
    interface AprpS_axi     s_axi;
    interface AprpS_axi_ctl     s_axi_ctl;
endinterface
import "BVI" axi_pcie_rp =
module mkAPRP#(Clock refclk, Reset reset, Clock axi_aclk, Reset axi_aresetn, Clock axi_ctl_aclk, Reset axi_ctl_aresetn)(APRP);
    default_clock clk();
    default_reset rst();
    input_clock axi_aclk() = axi_aclk;
    input_clock axi_ctl_aclk() = axi_ctl_aclk;
        input_reset reset(axi_aresetn) = reset;
        input_reset axi_aresetn() clocked_by (axi_aclk) = axi_aresetn;
	input_reset axi_ctl_aresetn() clocked_by (axi_ctl_aclk) = axi_ctl_aresetn;
    input_clock refclk(REFCLK) = refclk;
    interface AprpAxi     axi;
        output_clock aclk_out(axi_aclk_out);
        output_clock ctl_aclk_out(axi_ctl_aclk_out);
    endinterface
    interface AprpInterrupt     interrupt;
        method interrupt_out out();
    endinterface
    interface AprpIntx     intx;
        method INTX_MSI_Grant msi_grant();
        method msi_request(INTX_MSI_Request) enable((*inhigh*) EN_INTX_MSI_Request);
    endinterface
    interface AprpM_axi     m_axi;
        method m_axi_araddr araddr();
        method m_axi_arburst arburst();
        method m_axi_arcache arcache();
        method m_axi_arlen arlen();
        method m_axi_arlock arlock();
        method m_axi_arprot arprot();
        method arready(m_axi_arready) enable((*inhigh*) EN_m_axi_arready);
        method m_axi_arsize arsize();
        method m_axi_arvalid arvalid();
        method m_axi_awaddr awaddr();
        method m_axi_awburst awburst();
        method m_axi_awcache awcache();
        method m_axi_awlen awlen();
        method m_axi_awlock awlock();
        method m_axi_awprot awprot();
        method awready(m_axi_awready) enable((*inhigh*) EN_m_axi_awready);
        method m_axi_awsize awsize();
        method m_axi_awvalid awvalid();
        method m_axi_bready bready();
        method bresp(m_axi_bresp) enable((*inhigh*) EN_m_axi_bresp);
        method bvalid(m_axi_bvalid) enable((*inhigh*) EN_m_axi_bvalid);
        method rdata(m_axi_rdata) enable((*inhigh*) EN_m_axi_rdata);
        method rlast(m_axi_rlast) enable((*inhigh*) EN_m_axi_rlast);
        method m_axi_rready rready();
        method rresp(m_axi_rresp) enable((*inhigh*) EN_m_axi_rresp);
        method rvalid(m_axi_rvalid) enable((*inhigh*) EN_m_axi_rvalid);
        method m_axi_wdata wdata();
        method m_axi_wlast wlast();
        method wready(m_axi_wready) enable((*inhigh*) EN_m_axi_wready);
        method m_axi_wstrb wstrb();
        method m_axi_wvalid wvalid();
    endinterface
    interface AprpMmcm     mmcm;
        method mmcm_lock lock();
    endinterface
    interface AprpMsi     msi;
        method MSI_enable enable();
        method vector_num(MSI_Vector_Num) enable((*inhigh*) EN_MSI_Vector_Num);
        method MSI_Vector_Width vector_width();
    endinterface
    interface AprpPci     pci;
        method exp_rxn(pci_exp_rxn) enable((*inhigh*) EN_pci_exp_rxn);
        method exp_rxp(pci_exp_rxp) enable((*inhigh*) EN_pci_exp_rxp);
        method pci_exp_txn exp_txn();
        method pci_exp_txp exp_txp();
    endinterface
    interface AprpS_axi     s_axi;
        method araddr(s_axi_araddr) enable((*inhigh*) EN_s_axi_araddr) clocked_by(axi_aclk) reset_by (axi_aresetn);
        method arburst(s_axi_arburst) enable((*inhigh*) EN_s_axi_arburst) clocked_by(axi_aclk) reset_by (axi_aresetn);
        method arid(s_axi_arid) enable((*inhigh*) EN_s_axi_arid) clocked_by(axi_aclk) reset_by (axi_aresetn);
        method arlen(s_axi_arlen) enable((*inhigh*) EN_s_axi_arlen) clocked_by(axi_aclk) reset_by (axi_aresetn);
        method s_axi_arready arready() clocked_by(axi_aclk) reset_by (axi_aresetn);
        method arregion(s_axi_arregion) enable((*inhigh*) EN_s_axi_arregion) clocked_by(axi_aclk) reset_by (axi_aresetn);
        method arsize(s_axi_arsize) enable((*inhigh*) EN_s_axi_arsize) clocked_by(axi_aclk) reset_by (axi_aresetn);
        method arvalid(s_axi_arvalid) enable((*inhigh*) EN_s_axi_arvalid) clocked_by(axi_aclk) reset_by (axi_aresetn);
        method awaddr(s_axi_awaddr) enable((*inhigh*) EN_s_axi_awaddr) clocked_by(axi_aclk) reset_by (axi_aresetn);
        method awburst(s_axi_awburst) enable((*inhigh*) EN_s_axi_awburst) clocked_by(axi_aclk) reset_by (axi_aresetn);
        method awid(s_axi_awid) enable((*inhigh*) EN_s_axi_awid) clocked_by(axi_aclk) reset_by (axi_aresetn);
        method awlen(s_axi_awlen) enable((*inhigh*) EN_s_axi_awlen) clocked_by(axi_aclk) reset_by (axi_aresetn);
        method s_axi_awready awready() clocked_by(axi_aclk) reset_by (axi_aresetn);
        method awregion(s_axi_awregion) enable((*inhigh*) EN_s_axi_awregion) clocked_by(axi_aclk) reset_by (axi_aresetn);
        method awsize(s_axi_awsize) enable((*inhigh*) EN_s_axi_awsize) clocked_by(axi_aclk) reset_by (axi_aresetn);
        method awvalid(s_axi_awvalid) enable((*inhigh*) EN_s_axi_awvalid) clocked_by(axi_aclk) reset_by (axi_aresetn);
        method s_axi_bid bid() clocked_by(axi_aclk) reset_by (axi_aresetn);
        method bready(s_axi_bready) enable((*inhigh*) EN_s_axi_bready) clocked_by(axi_aclk) reset_by (axi_aresetn);
        method s_axi_bresp bresp() clocked_by(axi_aclk) reset_by (axi_aresetn);
        method s_axi_bvalid bvalid() clocked_by(axi_aclk) reset_by (axi_aresetn);
        method s_axi_rdata rdata() clocked_by(axi_aclk) reset_by (axi_aresetn);
        method s_axi_rid rid() clocked_by(axi_aclk) reset_by (axi_aresetn);
        method s_axi_rlast rlast() clocked_by(axi_aclk) reset_by (axi_aresetn);
        method rready(s_axi_rready) enable((*inhigh*) EN_s_axi_rready) clocked_by(axi_aclk) reset_by (axi_aresetn);
        method s_axi_rresp rresp() clocked_by(axi_aclk) reset_by (axi_aresetn);
        method s_axi_rvalid rvalid() clocked_by(axi_aclk) reset_by (axi_aresetn);
        method wdata(s_axi_wdata) enable((*inhigh*) EN_s_axi_wdata) clocked_by(axi_aclk) reset_by (axi_aresetn);
        method wlast(s_axi_wlast) enable((*inhigh*) EN_s_axi_wlast) clocked_by(axi_aclk) reset_by (axi_aresetn);
        method s_axi_wready wready() clocked_by(axi_aclk) reset_by (axi_aresetn);
        method wstrb(s_axi_wstrb) enable((*inhigh*) EN_s_axi_wstrb) clocked_by(axi_aclk) reset_by (axi_aresetn);
        method wvalid(s_axi_wvalid) enable((*inhigh*) EN_s_axi_wvalid) clocked_by(axi_aclk) reset_by (axi_aresetn);
    endinterface
    interface AprpS_axi_ctl     s_axi_ctl;
        method araddr(s_axi_ctl_araddr) enable((*inhigh*) EN_s_axi_ctl_araddr) clocked_by(axi_ctl_aclk) reset_by(axi_ctl_aresetn);
        method s_axi_ctl_arready arready() clocked_by(axi_ctl_aclk) reset_by(axi_ctl_aresetn);
        method arvalid(s_axi_ctl_arvalid) enable((*inhigh*) EN_s_axi_ctl_arvalid) clocked_by(axi_ctl_aclk) reset_by(axi_ctl_aresetn);
        method awaddr(s_axi_ctl_awaddr) enable((*inhigh*) EN_s_axi_ctl_awaddr) clocked_by(axi_ctl_aclk) reset_by(axi_ctl_aresetn);
        method s_axi_ctl_awready awready() clocked_by(axi_ctl_aclk) reset_by(axi_ctl_aresetn);
        method awvalid(s_axi_ctl_awvalid) enable((*inhigh*) EN_s_axi_ctl_awvalid) clocked_by(axi_ctl_aclk) reset_by(axi_ctl_aresetn);
        method bready(s_axi_ctl_bready) enable((*inhigh*) EN_s_axi_ctl_bready) clocked_by(axi_ctl_aclk) reset_by(axi_ctl_aresetn);
        method s_axi_ctl_bresp bresp() clocked_by(axi_ctl_aclk) reset_by(axi_ctl_aresetn);
        method s_axi_ctl_bvalid bvalid() clocked_by(axi_ctl_aclk) reset_by(axi_ctl_aresetn);
        method s_axi_ctl_rdata rdata() clocked_by(axi_ctl_aclk) reset_by(axi_ctl_aresetn);
        method rready(s_axi_ctl_rready) enable((*inhigh*) EN_s_axi_ctl_rready) clocked_by(axi_ctl_aclk) reset_by(axi_ctl_aresetn);
        method s_axi_ctl_rresp rresp() clocked_by(axi_ctl_aclk) reset_by(axi_ctl_aresetn);
        method s_axi_ctl_rvalid rvalid() clocked_by(axi_ctl_aclk) reset_by(axi_ctl_aresetn);
        method wdata(s_axi_ctl_wdata) enable((*inhigh*) EN_s_axi_ctl_wdata) clocked_by(axi_ctl_aclk) reset_by(axi_ctl_aresetn);
        method s_axi_ctl_wready wready() clocked_by(axi_ctl_aclk) reset_by(axi_ctl_aresetn);
        method wstrb(s_axi_ctl_wstrb) enable((*inhigh*) EN_s_axi_ctl_wstrb) clocked_by(axi_ctl_aclk) reset_by(axi_ctl_aresetn);
        method wvalid(s_axi_ctl_wvalid) enable((*inhigh*) EN_s_axi_ctl_wvalid) clocked_by(axi_ctl_aclk) reset_by(axi_ctl_aresetn);
    endinterface
    schedule (interrupt.out, intx.msi_grant, intx.msi_request, m_axi.araddr, m_axi.arburst, m_axi.arcache, m_axi.arlen, m_axi.arlock, m_axi.arprot, m_axi.arready, m_axi.arsize, m_axi.arvalid, m_axi.awaddr, m_axi.awburst, m_axi.awcache, m_axi.awlen, m_axi.awlock, m_axi.awprot, m_axi.awready, m_axi.awsize, m_axi.awvalid, m_axi.bready, m_axi.bresp, m_axi.bvalid, m_axi.rdata, m_axi.rlast, m_axi.rready, m_axi.rresp, m_axi.rvalid, m_axi.wdata, m_axi.wlast, m_axi.wready, m_axi.wstrb, m_axi.wvalid, mmcm.lock, msi.enable, msi.vector_num, msi.vector_width, pci.exp_rxn, pci.exp_rxp, pci.exp_txn, pci.exp_txp, s_axi.araddr, s_axi.arburst, s_axi.arid, s_axi.arlen, s_axi.arready, s_axi.arregion, s_axi.arsize, s_axi.arvalid, s_axi.awaddr, s_axi.awburst, s_axi.awid, s_axi.awlen, s_axi.awready, s_axi.awregion, s_axi.awsize, s_axi.awvalid, s_axi.bid, s_axi.bready, s_axi.bresp, s_axi.bvalid, s_axi.rdata, s_axi.rid, s_axi.rlast, s_axi.rready, s_axi.rresp, s_axi.rvalid, s_axi.wdata, s_axi.wlast, s_axi.wready, s_axi.wstrb, s_axi.wvalid, s_axi_ctl.araddr, s_axi_ctl.arready, s_axi_ctl.arvalid, s_axi_ctl.awaddr, s_axi_ctl.awready, s_axi_ctl.awvalid, s_axi_ctl.bready, s_axi_ctl.bresp, s_axi_ctl.bvalid, s_axi_ctl.rdata, s_axi_ctl.rready, s_axi_ctl.rresp, s_axi_ctl.rvalid, s_axi_ctl.wdata, s_axi_ctl.wready, s_axi_ctl.wstrb, s_axi_ctl.wvalid) CF (interrupt.out, intx.msi_grant, intx.msi_request, m_axi.araddr, m_axi.arburst, m_axi.arcache, m_axi.arlen, m_axi.arlock, m_axi.arprot, m_axi.arready, m_axi.arsize, m_axi.arvalid, m_axi.awaddr, m_axi.awburst, m_axi.awcache, m_axi.awlen, m_axi.awlock, m_axi.awprot, m_axi.awready, m_axi.awsize, m_axi.awvalid, m_axi.bready, m_axi.bresp, m_axi.bvalid, m_axi.rdata, m_axi.rlast, m_axi.rready, m_axi.rresp, m_axi.rvalid, m_axi.wdata, m_axi.wlast, m_axi.wready, m_axi.wstrb, m_axi.wvalid, mmcm.lock, msi.enable, msi.vector_num, msi.vector_width, pci.exp_rxn, pci.exp_rxp, pci.exp_txn, pci.exp_txp, s_axi.araddr, s_axi.arburst, s_axi.arid, s_axi.arlen, s_axi.arready, s_axi.arregion, s_axi.arsize, s_axi.arvalid, s_axi.awaddr, s_axi.awburst, s_axi.awid, s_axi.awlen, s_axi.awready, s_axi.awregion, s_axi.awsize, s_axi.awvalid, s_axi.bid, s_axi.bready, s_axi.bresp, s_axi.bvalid, s_axi.rdata, s_axi.rid, s_axi.rlast, s_axi.rready, s_axi.rresp, s_axi.rvalid, s_axi.wdata, s_axi.wlast, s_axi.wready, s_axi.wstrb, s_axi.wvalid, s_axi_ctl.araddr, s_axi_ctl.arready, s_axi_ctl.arvalid, s_axi_ctl.awaddr, s_axi_ctl.awready, s_axi_ctl.awvalid, s_axi_ctl.bready, s_axi_ctl.bresp, s_axi_ctl.bvalid, s_axi_ctl.rdata, s_axi_ctl.rready, s_axi_ctl.rresp, s_axi_ctl.rvalid, s_axi_ctl.wdata, s_axi_ctl.wready, s_axi_ctl.wstrb, s_axi_ctl.wvalid);
endmodule
