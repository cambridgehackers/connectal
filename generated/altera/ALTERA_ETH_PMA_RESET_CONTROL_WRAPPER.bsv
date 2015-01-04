
/*
   ./importbvi.py
   -o
   ALTERA_ETH_PMA_RESET_CONTROL_WRAPPER.bsv
   -I
   EthXcvrResetWrap
   -P
   EthXcvrResetWrap
   -c
   clock
   -r
   reset
   -f
   pll
   -f
   tx
   -f
   rx
   ../../out/de5/synthesis/altera_xcvr_reset_control_wrapper.v
*/

import Clocks::*;
import DefaultValue::*;
import XilinxCells::*;
import GetPut::*;

(* always_ready, always_enabled *)
interface EthxcvrresetwrapPll;
    method Action      locked(Bit#(4) v);
    method Bit#(4)     powerdown();
    method Action      select(Bit#(2) v);
endinterface
(* always_ready, always_enabled *)
interface EthxcvrresetwrapRx;
    method Bit#(4)     analogreset();
    method Action      cal_busy(Bit#(4) v);
    method Bit#(4)     digitalreset();
    method Action      is_lockedtodata(Bit#(4) v);
    method Bit#(4)     ready();
endinterface
(* always_ready, always_enabled *)
interface EthxcvrresetwrapTx;
    method Bit#(4)     analogreset();
    method Action      cal_busy(Bit#(4) v);
    method Bit#(4)     digitalreset();
    method Bit#(4)     ready();
endinterface
(* always_ready, always_enabled *)
interface EthXcvrResetWrap;
    interface EthxcvrresetwrapPll     pll;
    interface EthxcvrresetwrapRx     rx;
    interface EthxcvrresetwrapTx     tx;
endinterface
import "BVI" altera_xcvr_reset_control_wrapper =
module mkEthXcvrResetWrap#(Clock clock, Reset clock_reset, Reset reset)(EthXcvrResetWrap);
    default_clock clk();
    default_reset rst();
    input_clock clock(clock) = clock;
    input_reset clock_reset() = clock_reset; /* from clock*/
    input_reset reset(reset) = reset;
    interface EthxcvrresetwrapPll     pll;
        method locked(pll_locked) enable((*inhigh*) EN_pll_locked);
        method pll_powerdown powerdown();
        method select(pll_select) enable((*inhigh*) EN_pll_select);
    endinterface
    interface EthxcvrresetwrapRx     rx;
        method rx_analogreset analogreset();
        method cal_busy(rx_cal_busy) enable((*inhigh*) EN_rx_cal_busy);
        method rx_digitalreset digitalreset();
        method is_lockedtodata(rx_is_lockedtodata) enable((*inhigh*) EN_rx_is_lockedtodata);
        method rx_ready ready();
    endinterface
    interface EthxcvrresetwrapTx     tx;
        method tx_analogreset analogreset();
        method cal_busy(tx_cal_busy) enable((*inhigh*) EN_tx_cal_busy);
        method tx_digitalreset digitalreset();
        method tx_ready ready();
    endinterface
    schedule (pll.locked, pll.powerdown, pll.select, rx.analogreset, rx.cal_busy, rx.digitalreset, rx.is_lockedtodata, rx.ready, tx.analogreset, tx.cal_busy, tx.digitalreset, tx.ready) CF (pll.locked, pll.powerdown, pll.select, rx.analogreset, rx.cal_busy, rx.digitalreset, rx.is_lockedtodata, rx.ready, tx.analogreset, tx.cal_busy, tx.digitalreset, tx.ready);
endmodule
