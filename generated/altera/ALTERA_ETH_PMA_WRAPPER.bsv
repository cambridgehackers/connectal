
/*
   ./importbvi.py
   -o
   ALTERA_ETH_PMA_WRAPPER.bsv
   -I
   EthXcvrWrap
   -P
   EthXcvrWrap
   -f
   pll
   -f
   tx
   -f
   rx
   -f
   reconfig
   ../../out/de5/synthesis/altera_xcvr_native_sv_wrapper.v
*/

import Clocks::*;
import DefaultValue::*;
import XilinxCells::*;
import GetPut::*;

(* always_ready, always_enabled *)
interface EthxcvrwrapPll;
    method Bit#(4)     locked();
    method Action      powerdown(Bit#(4) v);
endinterface
(* always_ready, always_enabled *)
interface EthxcvrwrapReconfig;
    method Bit#(368)     from_xcvr();
    method Action      to_xcvr(Bit#(560) v);
endinterface
(* always_ready, always_enabled *)
interface EthxcvrwrapRx;
    method Action      analogreset(Bit#(4) v);
    method Bit#(4)     cal_busy();
    method Action      cdr_refclk(Bit#(1) v);
    method Action      digitalreset(Bit#(4) v);
    method Bit#(4)     is_lockedtodata();
    method Bit#(4)     is_lockedtoref();
    method Bit#(4)     pma_clkout();
    method Bit#(160)     pma_parallel_data();
    method Action      serial_data(Bit#(4) v);
    method Action      seriallpbken(Bit#(4) v);
endinterface
(* always_ready, always_enabled *)
interface EthxcvrwrapTx;
    method Action      analogreset(Bit#(4) v);
    method Bit#(4)     cal_busy();
    method Action      digitalreset(Bit#(4) v);
    method Action      pll_refclk(Bit#(1) v);
    method Bit#(4)     pma_clkout();
    method Action      pma_parallel_data(Bit#(160) v);
    method Bit#(4)     serial_data();
endinterface
(* always_ready, always_enabled *)
interface EthxcvrwrapUnused;
    method Bit#(160)     rx_pma_parallel_data();
    method Action      tx_pma_parallel_data(Bit#(160) v);
endinterface
(* always_ready, always_enabled *)
interface EthXcvrWrap;
    interface EthxcvrwrapPll     pll;
    interface EthxcvrwrapReconfig     reconfig;
    interface EthxcvrwrapRx     rx;
    interface EthxcvrwrapTx     tx;
    interface EthxcvrwrapUnused     unused;
endinterface
import "BVI" altera_xcvr_native_sv_wrapper =
module mkEthXcvrWrap(EthXcvrWrap);
    default_clock clk();
    default_reset rst();
    interface EthxcvrwrapPll     pll;
        method pll_locked locked();
        method powerdown(pll_powerdown) enable((*inhigh*) EN_pll_powerdown);
    endinterface
    interface EthxcvrwrapReconfig     reconfig;
        method reconfig_from_xcvr from_xcvr();
        method to_xcvr(reconfig_to_xcvr) enable((*inhigh*) EN_reconfig_to_xcvr);
    endinterface
    interface EthxcvrwrapRx     rx;
        method analogreset(rx_analogreset) enable((*inhigh*) EN_rx_analogreset);
        method rx_cal_busy cal_busy();
        method cdr_refclk(rx_cdr_refclk) enable((*inhigh*) EN_rx_cdr_refclk);
        method digitalreset(rx_digitalreset) enable((*inhigh*) EN_rx_digitalreset);
        method rx_is_lockedtodata is_lockedtodata();
        method rx_is_lockedtoref is_lockedtoref();
        method rx_pma_clkout pma_clkout();
        method rx_pma_parallel_data pma_parallel_data();
        method serial_data(rx_serial_data) enable((*inhigh*) EN_rx_serial_data);
        method seriallpbken(rx_seriallpbken) enable((*inhigh*) EN_rx_seriallpbken);
    endinterface
    interface EthxcvrwrapTx     tx;
        method analogreset(tx_analogreset) enable((*inhigh*) EN_tx_analogreset);
        method tx_cal_busy cal_busy();
        method digitalreset(tx_digitalreset) enable((*inhigh*) EN_tx_digitalreset);
        method pll_refclk(tx_pll_refclk) enable((*inhigh*) EN_tx_pll_refclk);
        method tx_pma_clkout pma_clkout();
        method pma_parallel_data(tx_pma_parallel_data) enable((*inhigh*) EN_tx_pma_parallel_data);
        method tx_serial_data serial_data();
    endinterface
    interface EthxcvrwrapUnused     unused;
        method unused_rx_pma_parallel_data rx_pma_parallel_data();
        method tx_pma_parallel_data(unused_tx_pma_parallel_data) enable((*inhigh*) EN_unused_tx_pma_parallel_data);
    endinterface
    schedule (pll.locked, pll.powerdown, reconfig.from_xcvr, reconfig.to_xcvr, rx.analogreset, rx.cal_busy, rx.cdr_refclk, rx.digitalreset, rx.is_lockedtodata, rx.is_lockedtoref, rx.pma_clkout, rx.pma_parallel_data, rx.serial_data, rx.seriallpbken, tx.analogreset, tx.cal_busy, tx.digitalreset, tx.pll_refclk, tx.pma_clkout, tx.pma_parallel_data, tx.serial_data, unused.rx_pma_parallel_data, unused.tx_pma_parallel_data) CF (pll.locked, pll.powerdown, reconfig.from_xcvr, reconfig.to_xcvr, rx.analogreset, rx.cal_busy, rx.cdr_refclk, rx.digitalreset, rx.is_lockedtodata, rx.is_lockedtoref, rx.pma_clkout, rx.pma_parallel_data, rx.serial_data, rx.seriallpbken, tx.analogreset, tx.cal_busy, tx.digitalreset, tx.pll_refclk, tx.pma_clkout, tx.pma_parallel_data, tx.serial_data, unused.rx_pma_parallel_data, unused.tx_pma_parallel_data);
endmodule
