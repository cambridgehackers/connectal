
/*
   /home/jamey/connectal.clean/generated/scripts/importbvi.py
   -o
   GigEthPcsPma.bsv
   -P
   GigEthPcsPmaBvi
   -I
   GigEthPcsPmaBvi
   -c
   gtrefclk_out
   -c
   userclk_out
   -c
   userclk2_out
   -c
   rxuserclk_out
   -c
   rxuserclk2_out
   -c
   independent_clock_bufg
   -r
   pma_reset_out
   -r
   reset
   -c
   gt0_qplloutclk_out
   -c
   gt0_qplloutrefclk_out
   ../FPGA/rtl/vc709/gig_ethernet_pcs_pma_0/gig_ethernet_pcs_pma_0_stub.v
*/

import Clocks::*;
import DefaultValue::*;
import XilinxCells::*;
import GetPut::*;

(* always_ready, always_enabled *)
interface GigethpcspmabviAn;
    method Action      adv_config_val(Bit#(1) v);
    method Action      adv_config_vector(Bit#(16) v);
    method Bit#(1)     interrupt();
    method Action      restart_config(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface GigethpcspmabviConfiguration;
    method Action      valid(Bit#(1) v);
    method Action      vector(Bit#(5) v);
endinterface
(* always_ready, always_enabled *)
interface GigethpcspmabviGmii;
    method Bit#(1)     isolate();
    method Bit#(1)     rx_dv();
    method Bit#(1)     rx_er();
    method Bit#(8)     rxd();
    method Action      tx_en(Bit#(1) v);
    method Action      tx_er(Bit#(1) v);
    method Action      txd(Bit#(8) v);
endinterface
(* always_ready, always_enabled *)
interface GigethpcspmabviGt;
    interface Clock     qplloutclk_out;
    interface Clock     qplloutrefclk_out;
endinterface
(* always_ready, always_enabled *)
interface GigethpcspmabviGtrefclk;
    method Action      n(Bit#(1) v);
    interface Clock     out;
    method Action      p(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
(* always_ready, always_enabled *)
interface GigethpcspmabviMdio;
    method Action      i(Bit#(1) v);
    method Bit#(1)     o();
    method Bit#(1)     t();
endinterface
(* always_ready, always_enabled *)
interface GigethpcspmabviMmcm;
    method Bit#(1)     locked_out();
endinterface
(* always_ready, always_enabled *)
interface GigethpcspmabviPma;
    method Reset     reset_out();
endinterface
(* always_ready, always_enabled *)
interface GigethpcspmabviRxuserclk;
    interface Clock     out;
endinterface
(* always_ready, always_enabled *)
interface GigethpcspmabviSignal;
    method Action      detect(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface GigethpcspmabviStatus;
    method Bit#(16)     vector();
endinterface
(* always_ready, always_enabled *)
interface GigethpcspmabviUserclk;
    interface Clock     out;
endinterface
(* always_ready, always_enabled *)
interface GigEthPcsPmaBvi;
    interface GigethpcspmabviAn     an;
    interface GigethpcspmabviConfiguration     configuration;
    interface GigethpcspmabviGmii     gmii;
    interface GigethpcspmabviGt     gt0;
    interface GigethpcspmabviGtrefclk     gtrefclk;
    method Action      mdc(Bit#(1) v);
    interface GigethpcspmabviMdio     mdio;
    interface GigethpcspmabviMmcm     mmcm;
    interface GigethpcspmabviPma     pma;
    method Bit#(1)     resetdone();
    method Action      rxn(Bit#(1) v);
    method Action      rxp(Bit#(1) v);
    interface GigethpcspmabviRxuserclk     rxuserclk2;
    interface GigethpcspmabviRxuserclk     rxuserclk;
    interface GigethpcspmabviSignal     signal;
    interface GigethpcspmabviStatus     status;
    method Bit#(1)     txn();
    method Bit#(1)     txp();
    interface GigethpcspmabviUserclk     userclk2;
    interface GigethpcspmabviUserclk     userclk;
endinterface
import "BVI" gig_ethernet_pcs_pma_0 =
module mkGigEthPcsPmaBvi#(Clock independent_clock_bufg, Reset reset_n)(GigEthPcsPmaBvi);
   let invertedReset <- mkResetInverter(reset_n, clocked_by independent_clock_bufg);
   default_clock clk();
   default_reset rst_n();
   input_clock independent_clock_bufg(independent_clock_bufg) = independent_clock_bufg;
   input_reset reset(reset) clocked_by (independent_clock_bufg) = invertedReset;
    interface GigethpcspmabviAn     an;
        method adv_config_val(an_adv_config_val) enable((*inhigh*) EN_an_adv_config_val);
        method adv_config_vector(an_adv_config_vector) enable((*inhigh*) EN_an_adv_config_vector);
        method an_interrupt interrupt();
        method restart_config(an_restart_config) enable((*inhigh*) EN_an_restart_config);
    endinterface
    interface GigethpcspmabviConfiguration     configuration;
        method valid(configuration_valid) enable((*inhigh*) EN_configuration_valid);
        method vector(configuration_vector) enable((*inhigh*) EN_configuration_vector);
    endinterface
    interface GigethpcspmabviGmii     gmii;
        method gmii_isolate isolate();
        method gmii_rx_dv rx_dv();
        method gmii_rx_er rx_er();
        method gmii_rxd rxd();
        method tx_en(gmii_tx_en) enable((*inhigh*) EN_gmii_tx_en);
        method tx_er(gmii_tx_er) enable((*inhigh*) EN_gmii_tx_er);
        method txd(gmii_txd) enable((*inhigh*) EN_gmii_txd);
    endinterface
    interface GigethpcspmabviGt     gt0;
        output_clock qplloutclk_out(gt0_qplloutclk_out);
        output_clock qplloutrefclk_out(gt0_qplloutrefclk_out);
    endinterface
    interface GigethpcspmabviGtrefclk     gtrefclk;
        method n(gtrefclk_n) enable((*inhigh*) EN_gtrefclk_n);
        output_clock out(gtrefclk_out);
        method p(gtrefclk_p) enable((*inhigh*) EN_gtrefclk_p);
    endinterface
    method mdc(mdc) enable((*inhigh*) EN_mdc);
    interface GigethpcspmabviMdio     mdio;
        method i(mdio_i) enable((*inhigh*) EN_mdio_i);
        method mdio_o o();
        method mdio_t t();
    endinterface
    interface GigethpcspmabviMmcm     mmcm;
        method mmcm_locked_out locked_out();
    endinterface
    interface GigethpcspmabviPma     pma;
        output_reset reset_out(pma_reset_out);
    endinterface
    method resetdone resetdone();
    method rxn(rxn) enable((*inhigh*) EN_rxn);
    method rxp(rxp) enable((*inhigh*) EN_rxp);
    interface GigethpcspmabviRxuserclk     rxuserclk2;
        output_clock out(rxuserclk2_out);
    endinterface
    interface GigethpcspmabviRxuserclk     rxuserclk;
        output_clock out(rxuserclk_out);
    endinterface
    interface GigethpcspmabviSignal     signal;
        method detect(signal_detect) enable((*inhigh*) EN_signal_detect);
    endinterface
    interface GigethpcspmabviStatus     status;
        method status_vector vector();
    endinterface
    method txn txn();
    method txp txp();
    interface GigethpcspmabviUserclk     userclk2;
        output_clock out(userclk2_out);
    endinterface
    interface GigethpcspmabviUserclk     userclk;
        output_clock out(userclk_out);
    endinterface
    schedule (an.adv_config_val, an.adv_config_vector, an.interrupt, an.restart_config, configuration.valid, configuration.vector, gmii.isolate, gmii.rx_dv, gmii.rx_er, gmii.rxd, gmii.tx_en, gmii.tx_er, gmii.txd, gtrefclk.n, gtrefclk.p, mdc, mdio.i, mdio.o, mdio.t, mmcm.locked_out, resetdone, rxn, rxp, signal.detect, status.vector, txn, txp) CF (an.adv_config_val, an.adv_config_vector, an.interrupt, an.restart_config, configuration.valid, configuration.vector, gmii.isolate, gmii.rx_dv, gmii.rx_er, gmii.rxd, gmii.tx_en, gmii.tx_er, gmii.txd, gtrefclk.n, gtrefclk.p, mdc, mdio.i, mdio.o, mdio.t, mmcm.locked_out, resetdone, rxn, rxp, signal.detect, status.vector, txn, txp);
endmodule

(* always_ready, always_enabled *)
interface GigEthPcsPmaPins;
    method Action      rxn(Bit#(1) v);
    method Action      rxp(Bit#(1) v);
    method Bit#(1)     txn();
    method Bit#(1)     txp();
    method Action      gtrefclkp(Bit#(1) v);
    method Action      gtrefclkn(Bit#(1) v);
endinterface

(* always_ready, always_enabled *)
interface GigEthPcsPmaTxPins;
    method Bit#(1)     txn();
    method Bit#(1)     txp();
endinterface

interface GigEthPcsPmaDebug;
    method Bit#(1)     locked_out();
    method Bit#(16)    status();
    method Bit#(1)     resetdone();
endinterface

interface GigEthPcsPma;
   method Action      mdc(Bit#(1) v);
   interface GigethpcspmabviMdio     mdio;
   interface GigethpcspmabviGmii     gmii;
   interface GigEthPcsPmaPins        pins;
   interface GigEthPcsPmaDebug       debug;
   interface Clock                   gtrefclk;
   method Bit#(1) interrupt();
endinterface

module mkGigEthPcsPma#(Clock independent_clock_bufg, Reset reset)(GigEthPcsPma);
   GigEthPcsPmaBvi bvi <- mkGigEthPcsPmaBvi(independent_clock_bufg, reset);

   rule rl_detect;
      bvi.signal.detect(1);
   endrule

   method      mdc = bvi.mdc;
   interface mdio = bvi.mdio;
   interface gmii = bvi.gmii;
   interface gtrefclk = bvi.gtrefclk.out;
   interface GigEthPcsPmaPins pins;
      method rxn = bvi.rxn;
      method rxp = bvi.rxp;
      method txn = bvi.txn;
      method txp = bvi.txp;
      method gtrefclkp = bvi.gtrefclk.p;
      method gtrefclkn = bvi.gtrefclk.n;
   endinterface
   method interrupt = bvi.an.interrupt;
   interface GigEthPcsPmaDebug debug;
      method locked_out = bvi.mmcm.locked_out;
      method status = bvi.status.vector();
      method resetdone  = bvi.resetdone;
   endinterface

endmodule
