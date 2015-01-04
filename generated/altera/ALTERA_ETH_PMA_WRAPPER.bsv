
/*
   ./importbvi.py
   -o
   ALTERA_ETH_PMA_WRAPPER.bsv
   -I
   EthXcvrWrap
   -P
   EthXcvrWrap
   -c
   rx_pma_clkout
   -c
   tx_pma_clkout
   -c
   tx_pll_refclk
   -c
   rx_cdr_refclk
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
    method Action      digitalreset(Bit#(4) v);
    method Bit#(4)     is_lockedtodata();
    method Bit#(4)     is_lockedtoref();
    interface Clock     pma_clkout;
    method Bit#(320)     pma_parallel_data();
    method Action      serial_data(Bit#(4) v);
    method Action      set_locktodata(Bit#(4) v);
    method Action      set_locktoref(Bit#(4) v);
endinterface
(* always_ready, always_enabled *)
interface EthxcvrwrapTx;
    method Action      analogreset(Bit#(4) v);
    method Bit#(4)     cal_busy();
    method Action      digitalreset(Bit#(4) v);
    interface Clock     pma_clkout;
    method Action      pma_parallel_data(Bit#(320) v);
    method Bit#(4)     serial_data();
endinterface
(* always_ready, always_enabled *)
interface EthXcvrWrap;
    interface EthxcvrwrapPll     pll;
    interface EthxcvrwrapReconfig     reconfig;
    interface EthxcvrwrapRx     rx;
    interface EthxcvrwrapTx     tx;
endinterface
import "BVI" altera_xcvr_native_sv_wrapper =
module mkEthXcvrWrap#(Clock rx_cdr_refclk, Clock tx_pll_refclk, Reset rx_cdr_refclk_reset, Reset tx_pll_refclk_reset)(EthXcvrWrap);
    default_clock clk();
    default_reset rst();
        input_clock rx_cdr_refclk(rx_cdr_refclk) = rx_cdr_refclk;
        input_reset rx_cdr_refclk_reset() = rx_cdr_refclk_reset; /* from clock*/
        input_clock tx_pll_refclk(tx_pll_refclk) = tx_pll_refclk;
        input_reset tx_pll_refclk_reset() = tx_pll_refclk_reset; /* from clock*/
    interface EthxcvrwrapPll     pll;
        method pll_locked locked();
        method powerdown(pll_powerdown) enable((*inhigh*) EN_pll_powerdown);
    endinterface
    interface EthxcvrwrapReconfig     reconfig;
        method reconfig_from_xcvr from_xcvr();
        method to_xcvr(reconfig_to_xcvr) enable((*inhigh*) EN_reconfig_to_xcvr);
    endinterface
    interface EthxcvrwrapRx     rx;
        method analogreset(rx_analogreset) clocked_by (rx_cdr_refclk) reset_by (rx_cdr_refclk_reset) enable((*inhigh*) EN_rx_analogreset);
        method rx_cal_busy cal_busy() clocked_by (rx_cdr_refclk) reset_by (rx_cdr_refclk_reset);
        method digitalreset(rx_digitalreset) clocked_by (rx_cdr_refclk) reset_by (rx_cdr_refclk_reset) enable((*inhigh*) EN_rx_digitalreset);
        method rx_is_lockedtodata is_lockedtodata() clocked_by (rx_cdr_refclk) reset_by (rx_cdr_refclk_reset);
        method rx_is_lockedtoref is_lockedtoref() clocked_by (rx_cdr_refclk) reset_by (rx_cdr_refclk_reset);
        output_clock pma_clkout(rx_pma_clkout);
        method rx_pma_parallel_data pma_parallel_data() clocked_by (rx_cdr_refclk) reset_by (rx_cdr_refclk_reset);
        method serial_data(rx_serial_data) clocked_by (rx_cdr_refclk) reset_by (rx_cdr_refclk_reset) enable((*inhigh*) EN_rx_serial_data);
        method set_locktodata(rx_set_locktodata) clocked_by (rx_cdr_refclk) reset_by (rx_cdr_refclk_reset) enable((*inhigh*) EN_rx_set_locktodata);
        method set_locktoref(rx_set_locktoref) clocked_by (rx_cdr_refclk) reset_by (rx_cdr_refclk_reset) enable((*inhigh*) EN_rx_set_locktoref);
    endinterface
    interface EthxcvrwrapTx     tx;
        method analogreset(tx_analogreset) clocked_by (tx_pll_refclk) reset_by (tx_pll_refclk_reset) enable((*inhigh*) EN_tx_analogreset);
        method tx_cal_busy cal_busy() clocked_by (tx_pll_refclk) reset_by (tx_pll_refclk_reset);
        method digitalreset(tx_digitalreset) clocked_by (tx_pll_refclk) reset_by (tx_pll_refclk_reset) enable((*inhigh*) EN_tx_digitalreset);
        output_clock pma_clkout(tx_pma_clkout);
        method pma_parallel_data(tx_pma_parallel_data) clocked_by (tx_pll_refclk) reset_by (tx_pll_refclk_reset) enable((*inhigh*) EN_tx_pma_parallel_data);
        method tx_serial_data serial_data() clocked_by (tx_pll_refclk) reset_by (tx_pll_refclk_reset);
    endinterface
    schedule (pll.locked, pll.powerdown, reconfig.from_xcvr, reconfig.to_xcvr, rx.analogreset, rx.cal_busy, rx.digitalreset, rx.is_lockedtodata, rx.is_lockedtoref, rx.pma_parallel_data, rx.serial_data, rx.set_locktodata, rx.set_locktoref, tx.analogreset, tx.cal_busy, tx.digitalreset, tx.pma_parallel_data, tx.serial_data) CF (pll.locked, pll.powerdown, reconfig.from_xcvr, reconfig.to_xcvr, rx.analogreset, rx.cal_busy, rx.digitalreset, rx.is_lockedtodata, rx.is_lockedtoref, rx.pma_parallel_data, rx.serial_data, rx.set_locktodata, rx.set_locktoref, tx.analogreset, tx.cal_busy, tx.digitalreset, tx.pma_parallel_data, tx.serial_data);
endmodule
