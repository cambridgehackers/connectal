
/*
   ./importbvi.py
   -o
   ALTERA_MAC_WRAPPER.bsv
   -I
   MacWrap
   -P
   MacWrap
   -c
   p0_tx_clk_clk
   -c
   p1_tx_clk_clk
   -c
   p2_tx_clk_clk
   -c
   p3_tx_clk_clk
   -c
   p0_rx_clk_clk
   -c
   p1_rx_clk_clk
   -c
   p2_rx_clk_clk
   -c
   p3_rx_clk_clk
   -c
   mgmt_clk_clk
   -r
   mgmt_reset_reset_n
   -r
   jtag_reset_reset
   -r
   p0_tx_reset_reset_n
   -r
   p1_tx_reset_reset_n
   -r
   p2_tx_reset_reset_n
   -r
   p3_tx_reset_reset_n
   -r
   p0_rx_reset_reset_n
   -r
   p1_rx_reset_reset_n
   -r
   p2_rx_reset_reset_n
   -r
   p3_rx_reset_reset_n
   -f
   p0_tx
   -f
   p0_rx
   -f
   p1_tx
   -f
   p1_rx
   -f
   p2_tx
   -f
   p2_rx
   -f
   p3_tx
   -f
   p3_rx
   -f
   p0_xgmii
   -f
   p1_xgmii
   -f
   p2_xgmii
   -f
   p3_xgmii
   -f
   p0_link_fault
   -f
   p1_link_fault
   -f
   p2_link_fault
   -f
   p3_link_fault
   ../../out/de5/synthesis/altera_mac.v
*/

import Clocks::*;
import DefaultValue::*;
import XilinxCells::*;
import GetPut::*;

(* always_ready, always_enabled *)
interface MacwrapJtag;
    method Reset     reset_reset();
endinterface
(* always_ready, always_enabled *)
(* always_ready, always_enabled *)
interface MacwrapP0_link_fault;
    method Bit#(2)     status_data();
endinterface
(* always_ready, always_enabled *)
interface MacwrapP0_rx;
    method Bit#(64)     fifo_out_data();
    method Bit#(3)     fifo_out_empty();
    method Bit#(1)     fifo_out_endofpacket();
    method Bit#(6)     fifo_out_error();
    method Action      fifo_out_ready(Bit#(1) v);
    method Bit#(1)     fifo_out_startofpacket();
    method Bit#(1)     fifo_out_valid();
    method Bit#(40)     status_data();
    method Bit#(7)     status_error();
    method Bit#(1)     status_valid();
endinterface
(* always_ready, always_enabled *)
interface MacwrapP0_tx;
    method Action      fifo_in_data(Bit#(64) v);
    method Action      fifo_in_empty(Bit#(3) v);
    method Action      fifo_in_endofpacket(Bit#(1) v);
    method Action      fifo_in_error(Bit#(1) v);
    method Bit#(1)     fifo_in_ready();
    method Action      fifo_in_startofpacket(Bit#(1) v);
    method Action      fifo_in_valid(Bit#(1) v);
    method Bit#(40)     status_data();
    method Bit#(7)     status_error();
    method Bit#(1)     status_valid();
endinterface
(* always_ready, always_enabled *)
interface MacwrapP0_xgmii;
    method Action      rx_data(Bit#(72) v);
    method Bit#(72)     tx_data();
endinterface
(* always_ready, always_enabled *)
interface MacwrapP1_link_fault;
    method Bit#(2)     status_data();
endinterface
(* always_ready, always_enabled *)
interface MacwrapP1_rx;
    method Bit#(64)     fifo_out_data();
    method Bit#(3)     fifo_out_empty();
    method Bit#(1)     fifo_out_endofpacket();
    method Bit#(6)     fifo_out_error();
    method Action      fifo_out_ready(Bit#(1) v);
    method Bit#(1)     fifo_out_startofpacket();
    method Bit#(1)     fifo_out_valid();
    method Bit#(40)     status_data();
    method Bit#(7)     status_error();
    method Bit#(1)     status_valid();
endinterface
(* always_ready, always_enabled *)
interface MacwrapP1_tx;
    method Action      fifo_in_data(Bit#(64) v);
    method Action      fifo_in_empty(Bit#(3) v);
    method Action      fifo_in_endofpacket(Bit#(1) v);
    method Action      fifo_in_error(Bit#(1) v);
    method Bit#(1)     fifo_in_ready();
    method Action      fifo_in_startofpacket(Bit#(1) v);
    method Action      fifo_in_valid(Bit#(1) v);
    method Bit#(40)     status_data();
    method Bit#(7)     status_error();
    method Bit#(1)     status_valid();
endinterface
(* always_ready, always_enabled *)
interface MacwrapP1_xgmii;
    method Action      rx_data(Bit#(72) v);
    method Bit#(72)     tx_data();
endinterface
(* always_ready, always_enabled *)
interface MacwrapP2_link_fault;
    method Bit#(2)     status_data();
endinterface
(* always_ready, always_enabled *)
interface MacwrapP2_rx;
    method Bit#(64)     fifo_out_data();
    method Bit#(3)     fifo_out_empty();
    method Bit#(1)     fifo_out_endofpacket();
    method Bit#(6)     fifo_out_error();
    method Action      fifo_out_ready(Bit#(1) v);
    method Bit#(1)     fifo_out_startofpacket();
    method Bit#(1)     fifo_out_valid();
    method Bit#(40)     status_data();
    method Bit#(7)     status_error();
    method Bit#(1)     status_valid();
endinterface
(* always_ready, always_enabled *)
interface MacwrapP2_tx;
    method Action      fifo_in_data(Bit#(64) v);
    method Action      fifo_in_empty(Bit#(3) v);
    method Action      fifo_in_endofpacket(Bit#(1) v);
    method Action      fifo_in_error(Bit#(1) v);
    method Bit#(1)     fifo_in_ready();
    method Action      fifo_in_startofpacket(Bit#(1) v);
    method Action      fifo_in_valid(Bit#(1) v);
    method Bit#(40)     status_data();
    method Bit#(7)     status_error();
    method Bit#(1)     status_valid();
endinterface
(* always_ready, always_enabled *)
interface MacwrapP2_xgmii;
    method Action      rx_data(Bit#(72) v);
    method Bit#(72)     tx_data();
endinterface
(* always_ready, always_enabled *)
interface MacwrapP3_link_fault;
    method Bit#(2)     status_data();
endinterface
(* always_ready, always_enabled *)
interface MacwrapP3_rx;
    method Bit#(64)     fifo_out_data();
    method Bit#(3)     fifo_out_empty();
    method Bit#(1)     fifo_out_endofpacket();
    method Bit#(6)     fifo_out_error();
    method Action      fifo_out_ready(Bit#(1) v);
    method Bit#(1)     fifo_out_startofpacket();
    method Bit#(1)     fifo_out_valid();
    method Bit#(40)     status_data();
    method Bit#(7)     status_error();
    method Bit#(1)     status_valid();
endinterface
(* always_ready, always_enabled *)
interface MacwrapP3_tx;
    method Action      fifo_in_data(Bit#(64) v);
    method Action      fifo_in_empty(Bit#(3) v);
    method Action      fifo_in_endofpacket(Bit#(1) v);
    method Action      fifo_in_error(Bit#(1) v);
    method Bit#(1)     fifo_in_ready();
    method Action      fifo_in_startofpacket(Bit#(1) v);
    method Action      fifo_in_valid(Bit#(1) v);
    method Bit#(40)     status_data();
    method Bit#(7)     status_error();
    method Bit#(1)     status_valid();
endinterface
(* always_ready, always_enabled *)
interface MacwrapP3_xgmii;
    method Action      rx_data(Bit#(72) v);
    method Bit#(72)     tx_data();
endinterface
(* always_ready, always_enabled *)
interface MacWrap;
    interface MacwrapJtag     jtag;
    interface MacwrapP0_link_fault     p0_link_fault;
    interface MacwrapP0_rx     p0_rx;
    interface MacwrapP0_tx     p0_tx;
    interface MacwrapP0_xgmii     p0_xgmii;
    interface MacwrapP1_link_fault     p1_link_fault;
    interface MacwrapP1_rx     p1_rx;
    interface MacwrapP1_tx     p1_tx;
    interface MacwrapP1_xgmii     p1_xgmii;
    interface MacwrapP2_link_fault     p2_link_fault;
    interface MacwrapP2_rx     p2_rx;
    interface MacwrapP2_tx     p2_tx;
    interface MacwrapP2_xgmii     p2_xgmii;
    interface MacwrapP3_link_fault     p3_link_fault;
    interface MacwrapP3_rx     p3_rx;
    interface MacwrapP3_tx     p3_tx;
    interface MacwrapP3_xgmii     p3_xgmii;
endinterface
import "BVI" altera_mac =
module mkMacWrap#(Clock mgmt_clk_clk, Clock p0_rx_clk_clk, Clock p0_tx_clk_clk, Clock p1_rx_clk_clk, Clock p1_tx_clk_clk, Clock p2_rx_clk_clk, Clock p2_tx_clk_clk, Clock p3_rx_clk_clk, Clock p3_tx_clk_clk, Reset mgmt_clk_clk_reset, Reset mgmt_reset_reset_n, Reset p0_rx_clk_clk_reset, Reset p0_rx_reset_reset_n, Reset p0_tx_clk_clk_reset, Reset p0_tx_reset_reset_n, Reset p1_rx_clk_clk_reset, Reset p1_rx_reset_reset_n, Reset p1_tx_clk_clk_reset, Reset p1_tx_reset_reset_n, Reset p2_rx_clk_clk_reset, Reset p2_rx_reset_reset_n, Reset p2_tx_clk_clk_reset, Reset p2_tx_reset_reset_n, Reset p3_rx_clk_clk_reset, Reset p3_rx_reset_reset_n, Reset p3_tx_clk_clk_reset, Reset p3_tx_reset_reset_n)(MacWrap);
    default_clock clk();
    default_reset rst();
        input_clock mgmt_clk_clk(mgmt_clk_clk) = mgmt_clk_clk;
        input_reset mgmt_clk_clk_reset() = mgmt_clk_clk_reset; /* from clock*/
        input_reset mgmt_reset_reset_n(mgmt_reset_reset_n) = mgmt_reset_reset_n;
        input_clock p0_rx_clk_clk(p0_rx_clk_clk) = p0_rx_clk_clk;
        input_reset p0_rx_clk_clk_reset() = p0_rx_clk_clk_reset; /* from clock*/
        input_reset p0_rx_reset_reset_n(p0_rx_reset_reset_n) = p0_rx_reset_reset_n;
        input_clock p0_tx_clk_clk(p0_tx_clk_clk) = p0_tx_clk_clk;
        input_reset p0_tx_clk_clk_reset() = p0_tx_clk_clk_reset; /* from clock*/
        input_reset p0_tx_reset_reset_n(p0_tx_reset_reset_n) = p0_tx_reset_reset_n;
        input_clock p1_rx_clk_clk(p1_rx_clk_clk) = p1_rx_clk_clk;
        input_reset p1_rx_clk_clk_reset() = p1_rx_clk_clk_reset; /* from clock*/
        input_reset p1_rx_reset_reset_n(p1_rx_reset_reset_n) = p1_rx_reset_reset_n;
        input_clock p1_tx_clk_clk(p1_tx_clk_clk) = p1_tx_clk_clk;
        input_reset p1_tx_clk_clk_reset() = p1_tx_clk_clk_reset; /* from clock*/
        input_reset p1_tx_reset_reset_n(p1_tx_reset_reset_n) = p1_tx_reset_reset_n;
        input_clock p2_rx_clk_clk(p2_rx_clk_clk) = p2_rx_clk_clk;
        input_reset p2_rx_clk_clk_reset() = p2_rx_clk_clk_reset; /* from clock*/
        input_reset p2_rx_reset_reset_n(p2_rx_reset_reset_n) = p2_rx_reset_reset_n;
        input_clock p2_tx_clk_clk(p2_tx_clk_clk) = p2_tx_clk_clk;
        input_reset p2_tx_clk_clk_reset() = p2_tx_clk_clk_reset; /* from clock*/
        input_reset p2_tx_reset_reset_n(p2_tx_reset_reset_n) = p2_tx_reset_reset_n;
        input_clock p3_rx_clk_clk(p3_rx_clk_clk) = p3_rx_clk_clk;
        input_reset p3_rx_clk_clk_reset() = p3_rx_clk_clk_reset; /* from clock*/
        input_reset p3_rx_reset_reset_n(p3_rx_reset_reset_n) = p3_rx_reset_reset_n;
        input_clock p3_tx_clk_clk(p3_tx_clk_clk) = p3_tx_clk_clk;
        input_reset p3_tx_clk_clk_reset() = p3_tx_clk_clk_reset; /* from clock*/
        input_reset p3_tx_reset_reset_n(p3_tx_reset_reset_n) = p3_tx_reset_reset_n;
    interface MacwrapJtag     jtag;
        output_reset reset_reset(jtag_reset_reset);
    endinterface
    interface MacwrapP0_link_fault     p0_link_fault;
        method p0_link_fault_status_data status_data();
    endinterface
    interface MacwrapP0_rx     p0_rx;
        method p0_rx_fifo_out_data fifo_out_data() clocked_by (p0_rx_clk_clk) reset_by (p0_rx_clk_clk_reset);
        method p0_rx_fifo_out_empty fifo_out_empty() clocked_by (p0_rx_clk_clk) reset_by (p0_rx_clk_clk_reset);
        method p0_rx_fifo_out_endofpacket fifo_out_endofpacket() clocked_by (p0_rx_clk_clk) reset_by (p0_rx_clk_clk_reset);
        method p0_rx_fifo_out_error fifo_out_error() clocked_by (p0_rx_clk_clk) reset_by (p0_rx_clk_clk_reset);
        method fifo_out_ready(p0_rx_fifo_out_ready) clocked_by (p0_rx_clk_clk) reset_by (p0_rx_clk_clk_reset) enable((*inhigh*) EN_p0_rx_fifo_out_ready);
        method p0_rx_fifo_out_startofpacket fifo_out_startofpacket() clocked_by (p0_rx_clk_clk) reset_by (p0_rx_clk_clk_reset);
        method p0_rx_fifo_out_valid fifo_out_valid() clocked_by (p0_rx_clk_clk) reset_by (p0_rx_clk_clk_reset);
        method p0_rx_status_data status_data() clocked_by (p0_rx_clk_clk) reset_by (p0_rx_clk_clk_reset);
        method p0_rx_status_error status_error() clocked_by (p0_rx_clk_clk) reset_by (p0_rx_clk_clk_reset);
        method p0_rx_status_valid status_valid() clocked_by (p0_rx_clk_clk) reset_by (p0_rx_clk_clk_reset);
    endinterface
    interface MacwrapP0_tx     p0_tx;
        method fifo_in_data(p0_tx_fifo_in_data) clocked_by (p0_tx_clk_clk) reset_by (p0_tx_clk_clk_reset) enable((*inhigh*) EN_p0_tx_fifo_in_data);
        method fifo_in_empty(p0_tx_fifo_in_empty) clocked_by (p0_tx_clk_clk) reset_by (p0_tx_clk_clk_reset) enable((*inhigh*) EN_p0_tx_fifo_in_empty);
        method fifo_in_endofpacket(p0_tx_fifo_in_endofpacket) clocked_by (p0_tx_clk_clk) reset_by (p0_tx_clk_clk_reset) enable((*inhigh*) EN_p0_tx_fifo_in_endofpacket);
        method fifo_in_error(p0_tx_fifo_in_error) clocked_by (p0_tx_clk_clk) reset_by (p0_tx_clk_clk_reset) enable((*inhigh*) EN_p0_tx_fifo_in_error);
        method p0_tx_fifo_in_ready fifo_in_ready() clocked_by (p0_tx_clk_clk) reset_by (p0_tx_clk_clk_reset);
        method fifo_in_startofpacket(p0_tx_fifo_in_startofpacket) clocked_by (p0_tx_clk_clk) reset_by (p0_tx_clk_clk_reset) enable((*inhigh*) EN_p0_tx_fifo_in_startofpacket);
        method fifo_in_valid(p0_tx_fifo_in_valid) clocked_by (p0_tx_clk_clk) reset_by (p0_tx_clk_clk_reset) enable((*inhigh*) EN_p0_tx_fifo_in_valid);
        method p0_tx_status_data status_data() clocked_by (p0_tx_clk_clk) reset_by (p0_tx_clk_clk_reset);
        method p0_tx_status_error status_error() clocked_by (p0_tx_clk_clk) reset_by (p0_tx_clk_clk_reset);
        method p0_tx_status_valid status_valid() clocked_by (p0_tx_clk_clk) reset_by (p0_tx_clk_clk_reset);
    endinterface
    interface MacwrapP0_xgmii     p0_xgmii;
        method rx_data(p0_xgmii_rx_data) enable((*inhigh*) EN_p0_xgmii_rx_data);
        method p0_xgmii_tx_data tx_data();
    endinterface
    interface MacwrapP1_link_fault     p1_link_fault;
        method p1_link_fault_status_data status_data();
    endinterface
    interface MacwrapP1_rx     p1_rx;
        method p1_rx_fifo_out_data fifo_out_data() clocked_by (p1_rx_clk_clk) reset_by (p1_rx_clk_clk_reset);
        method p1_rx_fifo_out_empty fifo_out_empty() clocked_by (p1_rx_clk_clk) reset_by (p1_rx_clk_clk_reset);
        method p1_rx_fifo_out_endofpacket fifo_out_endofpacket() clocked_by (p1_rx_clk_clk) reset_by (p1_rx_clk_clk_reset);
        method p1_rx_fifo_out_error fifo_out_error() clocked_by (p1_rx_clk_clk) reset_by (p1_rx_clk_clk_reset);
        method fifo_out_ready(p1_rx_fifo_out_ready) clocked_by (p1_rx_clk_clk) reset_by (p1_rx_clk_clk_reset) enable((*inhigh*) EN_p1_rx_fifo_out_ready);
        method p1_rx_fifo_out_startofpacket fifo_out_startofpacket() clocked_by (p1_rx_clk_clk) reset_by (p1_rx_clk_clk_reset);
        method p1_rx_fifo_out_valid fifo_out_valid() clocked_by (p1_rx_clk_clk) reset_by (p1_rx_clk_clk_reset);
        method p1_rx_status_data status_data() clocked_by (p1_rx_clk_clk) reset_by (p1_rx_clk_clk_reset);
        method p1_rx_status_error status_error() clocked_by (p1_rx_clk_clk) reset_by (p1_rx_clk_clk_reset);
        method p1_rx_status_valid status_valid() clocked_by (p1_rx_clk_clk) reset_by (p1_rx_clk_clk_reset);
    endinterface
    interface MacwrapP1_tx     p1_tx;
        method fifo_in_data(p1_tx_fifo_in_data) clocked_by (p1_tx_clk_clk) reset_by (p1_tx_clk_clk_reset) enable((*inhigh*) EN_p1_tx_fifo_in_data);
        method fifo_in_empty(p1_tx_fifo_in_empty) clocked_by (p1_tx_clk_clk) reset_by (p1_tx_clk_clk_reset) enable((*inhigh*) EN_p1_tx_fifo_in_empty);
        method fifo_in_endofpacket(p1_tx_fifo_in_endofpacket) clocked_by (p1_tx_clk_clk) reset_by (p1_tx_clk_clk_reset) enable((*inhigh*) EN_p1_tx_fifo_in_endofpacket);
        method fifo_in_error(p1_tx_fifo_in_error) clocked_by (p1_tx_clk_clk) reset_by (p1_tx_clk_clk_reset) enable((*inhigh*) EN_p1_tx_fifo_in_error);
        method p1_tx_fifo_in_ready fifo_in_ready() clocked_by (p1_tx_clk_clk) reset_by (p1_tx_clk_clk_reset);
        method fifo_in_startofpacket(p1_tx_fifo_in_startofpacket) clocked_by (p1_tx_clk_clk) reset_by (p1_tx_clk_clk_reset) enable((*inhigh*) EN_p1_tx_fifo_in_startofpacket);
        method fifo_in_valid(p1_tx_fifo_in_valid) clocked_by (p1_tx_clk_clk) reset_by (p1_tx_clk_clk_reset) enable((*inhigh*) EN_p1_tx_fifo_in_valid);
        method p1_tx_status_data status_data() clocked_by (p1_tx_clk_clk) reset_by (p1_tx_clk_clk_reset);
        method p1_tx_status_error status_error() clocked_by (p1_tx_clk_clk) reset_by (p1_tx_clk_clk_reset);
        method p1_tx_status_valid status_valid() clocked_by (p1_tx_clk_clk) reset_by (p1_tx_clk_clk_reset);
    endinterface
    interface MacwrapP1_xgmii     p1_xgmii;
        method rx_data(p1_xgmii_rx_data) enable((*inhigh*) EN_p1_xgmii_rx_data);
        method p1_xgmii_tx_data tx_data();
    endinterface
    interface MacwrapP2_link_fault     p2_link_fault;
        method p2_link_fault_status_data status_data();
    endinterface
    interface MacwrapP2_rx     p2_rx;
        method p2_rx_fifo_out_data fifo_out_data() clocked_by (p2_rx_clk_clk) reset_by (p2_rx_clk_clk_reset);
        method p2_rx_fifo_out_empty fifo_out_empty() clocked_by (p2_rx_clk_clk) reset_by (p2_rx_clk_clk_reset);
        method p2_rx_fifo_out_endofpacket fifo_out_endofpacket() clocked_by (p2_rx_clk_clk) reset_by (p2_rx_clk_clk_reset);
        method p2_rx_fifo_out_error fifo_out_error() clocked_by (p2_rx_clk_clk) reset_by (p2_rx_clk_clk_reset);
        method fifo_out_ready(p2_rx_fifo_out_ready) clocked_by (p2_rx_clk_clk) reset_by (p2_rx_clk_clk_reset) enable((*inhigh*) EN_p2_rx_fifo_out_ready);
        method p2_rx_fifo_out_startofpacket fifo_out_startofpacket() clocked_by (p2_rx_clk_clk) reset_by (p2_rx_clk_clk_reset);
        method p2_rx_fifo_out_valid fifo_out_valid() clocked_by (p2_rx_clk_clk) reset_by (p2_rx_clk_clk_reset);
        method p2_rx_status_data status_data() clocked_by (p2_rx_clk_clk) reset_by (p2_rx_clk_clk_reset);
        method p2_rx_status_error status_error() clocked_by (p2_rx_clk_clk) reset_by (p2_rx_clk_clk_reset);
        method p2_rx_status_valid status_valid() clocked_by (p2_rx_clk_clk) reset_by (p2_rx_clk_clk_reset);
    endinterface
    interface MacwrapP2_tx     p2_tx;
        method fifo_in_data(p2_tx_fifo_in_data) clocked_by (p2_tx_clk_clk) reset_by (p2_tx_clk_clk_reset) enable((*inhigh*) EN_p2_tx_fifo_in_data);
        method fifo_in_empty(p2_tx_fifo_in_empty) clocked_by (p2_tx_clk_clk) reset_by (p2_tx_clk_clk_reset) enable((*inhigh*) EN_p2_tx_fifo_in_empty);
        method fifo_in_endofpacket(p2_tx_fifo_in_endofpacket) clocked_by (p2_tx_clk_clk) reset_by (p2_tx_clk_clk_reset) enable((*inhigh*) EN_p2_tx_fifo_in_endofpacket);
        method fifo_in_error(p2_tx_fifo_in_error) clocked_by (p2_tx_clk_clk) reset_by (p2_tx_clk_clk_reset) enable((*inhigh*) EN_p2_tx_fifo_in_error);
        method p2_tx_fifo_in_ready fifo_in_ready() clocked_by (p2_tx_clk_clk) reset_by (p2_tx_clk_clk_reset);
        method fifo_in_startofpacket(p2_tx_fifo_in_startofpacket) clocked_by (p2_tx_clk_clk) reset_by (p2_tx_clk_clk_reset) enable((*inhigh*) EN_p2_tx_fifo_in_startofpacket);
        method fifo_in_valid(p2_tx_fifo_in_valid) clocked_by (p2_tx_clk_clk) reset_by (p2_tx_clk_clk_reset) enable((*inhigh*) EN_p2_tx_fifo_in_valid);
        method p2_tx_status_data status_data() clocked_by (p2_tx_clk_clk) reset_by (p2_tx_clk_clk_reset);
        method p2_tx_status_error status_error() clocked_by (p2_tx_clk_clk) reset_by (p2_tx_clk_clk_reset);
        method p2_tx_status_valid status_valid() clocked_by (p2_tx_clk_clk) reset_by (p2_tx_clk_clk_reset);
    endinterface
    interface MacwrapP2_xgmii     p2_xgmii;
        method rx_data(p2_xgmii_rx_data) enable((*inhigh*) EN_p2_xgmii_rx_data);
        method p2_xgmii_tx_data tx_data();
    endinterface
    interface MacwrapP3_link_fault     p3_link_fault;
        method p3_link_fault_status_data status_data();
    endinterface
    interface MacwrapP3_rx     p3_rx;
        method p3_rx_fifo_out_data fifo_out_data() clocked_by (p3_rx_clk_clk) reset_by (p3_rx_clk_clk_reset);
        method p3_rx_fifo_out_empty fifo_out_empty() clocked_by (p3_rx_clk_clk) reset_by (p3_rx_clk_clk_reset);
        method p3_rx_fifo_out_endofpacket fifo_out_endofpacket() clocked_by (p3_rx_clk_clk) reset_by (p3_rx_clk_clk_reset);
        method p3_rx_fifo_out_error fifo_out_error() clocked_by (p3_rx_clk_clk) reset_by (p3_rx_clk_clk_reset);
        method fifo_out_ready(p3_rx_fifo_out_ready) clocked_by (p3_rx_clk_clk) reset_by (p3_rx_clk_clk_reset) enable((*inhigh*) EN_p3_rx_fifo_out_ready);
        method p3_rx_fifo_out_startofpacket fifo_out_startofpacket() clocked_by (p3_rx_clk_clk) reset_by (p3_rx_clk_clk_reset);
        method p3_rx_fifo_out_valid fifo_out_valid() clocked_by (p3_rx_clk_clk) reset_by (p3_rx_clk_clk_reset);
        method p3_rx_status_data status_data() clocked_by (p3_rx_clk_clk) reset_by (p3_rx_clk_clk_reset);
        method p3_rx_status_error status_error() clocked_by (p3_rx_clk_clk) reset_by (p3_rx_clk_clk_reset);
        method p3_rx_status_valid status_valid() clocked_by (p3_rx_clk_clk) reset_by (p3_rx_clk_clk_reset);
    endinterface
    interface MacwrapP3_tx     p3_tx;
        method fifo_in_data(p3_tx_fifo_in_data) clocked_by (p3_tx_clk_clk) reset_by (p3_tx_clk_clk_reset) enable((*inhigh*) EN_p3_tx_fifo_in_data);
        method fifo_in_empty(p3_tx_fifo_in_empty) clocked_by (p3_tx_clk_clk) reset_by (p3_tx_clk_clk_reset) enable((*inhigh*) EN_p3_tx_fifo_in_empty);
        method fifo_in_endofpacket(p3_tx_fifo_in_endofpacket) clocked_by (p3_tx_clk_clk) reset_by (p3_tx_clk_clk_reset) enable((*inhigh*) EN_p3_tx_fifo_in_endofpacket);
        method fifo_in_error(p3_tx_fifo_in_error) clocked_by (p3_tx_clk_clk) reset_by (p3_tx_clk_clk_reset) enable((*inhigh*) EN_p3_tx_fifo_in_error);
        method p3_tx_fifo_in_ready fifo_in_ready() clocked_by (p3_tx_clk_clk) reset_by (p3_tx_clk_clk_reset);
        method fifo_in_startofpacket(p3_tx_fifo_in_startofpacket) clocked_by (p3_tx_clk_clk) reset_by (p3_tx_clk_clk_reset) enable((*inhigh*) EN_p3_tx_fifo_in_startofpacket);
        method fifo_in_valid(p3_tx_fifo_in_valid) clocked_by (p3_tx_clk_clk) reset_by (p3_tx_clk_clk_reset) enable((*inhigh*) EN_p3_tx_fifo_in_valid);
        method p3_tx_status_data status_data() clocked_by (p3_tx_clk_clk) reset_by (p3_tx_clk_clk_reset);
        method p3_tx_status_error status_error() clocked_by (p3_tx_clk_clk) reset_by (p3_tx_clk_clk_reset);
        method p3_tx_status_valid status_valid() clocked_by (p3_tx_clk_clk) reset_by (p3_tx_clk_clk_reset);
    endinterface
    interface MacwrapP3_xgmii     p3_xgmii;
        method rx_data(p3_xgmii_rx_data) enable((*inhigh*) EN_p3_xgmii_rx_data);
        method p3_xgmii_tx_data tx_data();
    endinterface
    schedule (p0_link_fault.status_data, p0_rx.fifo_out_data, p0_rx.fifo_out_empty, p0_rx.fifo_out_endofpacket, p0_rx.fifo_out_error, p0_rx.fifo_out_ready, p0_rx.fifo_out_startofpacket, p0_rx.fifo_out_valid, p0_rx.status_data, p0_rx.status_error, p0_rx.status_valid, p0_tx.fifo_in_data, p0_tx.fifo_in_empty, p0_tx.fifo_in_endofpacket, p0_tx.fifo_in_error, p0_tx.fifo_in_ready, p0_tx.fifo_in_startofpacket, p0_tx.fifo_in_valid, p0_tx.status_data, p0_tx.status_error, p0_tx.status_valid, p0_xgmii.rx_data, p0_xgmii.tx_data, p1_link_fault.status_data, p1_rx.fifo_out_data, p1_rx.fifo_out_empty, p1_rx.fifo_out_endofpacket, p1_rx.fifo_out_error, p1_rx.fifo_out_ready, p1_rx.fifo_out_startofpacket, p1_rx.fifo_out_valid, p1_rx.status_data, p1_rx.status_error, p1_rx.status_valid, p1_tx.fifo_in_data, p1_tx.fifo_in_empty, p1_tx.fifo_in_endofpacket, p1_tx.fifo_in_error, p1_tx.fifo_in_ready, p1_tx.fifo_in_startofpacket, p1_tx.fifo_in_valid, p1_tx.status_data, p1_tx.status_error, p1_tx.status_valid, p1_xgmii.rx_data, p1_xgmii.tx_data, p2_link_fault.status_data, p2_rx.fifo_out_data, p2_rx.fifo_out_empty, p2_rx.fifo_out_endofpacket, p2_rx.fifo_out_error, p2_rx.fifo_out_ready, p2_rx.fifo_out_startofpacket, p2_rx.fifo_out_valid, p2_rx.status_data, p2_rx.status_error, p2_rx.status_valid, p2_tx.fifo_in_data, p2_tx.fifo_in_empty, p2_tx.fifo_in_endofpacket, p2_tx.fifo_in_error, p2_tx.fifo_in_ready, p2_tx.fifo_in_startofpacket, p2_tx.fifo_in_valid, p2_tx.status_data, p2_tx.status_error, p2_tx.status_valid, p2_xgmii.rx_data, p2_xgmii.tx_data, p3_link_fault.status_data, p3_rx.fifo_out_data, p3_rx.fifo_out_empty, p3_rx.fifo_out_endofpacket, p3_rx.fifo_out_error, p3_rx.fifo_out_ready, p3_rx.fifo_out_startofpacket, p3_rx.fifo_out_valid, p3_rx.status_data, p3_rx.status_error, p3_rx.status_valid, p3_tx.fifo_in_data, p3_tx.fifo_in_empty, p3_tx.fifo_in_endofpacket, p3_tx.fifo_in_error, p3_tx.fifo_in_ready, p3_tx.fifo_in_startofpacket, p3_tx.fifo_in_valid, p3_tx.status_data, p3_tx.status_error, p3_tx.status_valid, p3_xgmii.rx_data, p3_xgmii.tx_data) CF (p0_link_fault.status_data, p0_rx.fifo_out_data, p0_rx.fifo_out_empty, p0_rx.fifo_out_endofpacket, p0_rx.fifo_out_error, p0_rx.fifo_out_ready, p0_rx.fifo_out_startofpacket, p0_rx.fifo_out_valid, p0_rx.status_data, p0_rx.status_error, p0_rx.status_valid, p0_tx.fifo_in_data, p0_tx.fifo_in_empty, p0_tx.fifo_in_endofpacket, p0_tx.fifo_in_error, p0_tx.fifo_in_ready, p0_tx.fifo_in_startofpacket, p0_tx.fifo_in_valid, p0_tx.status_data, p0_tx.status_error, p0_tx.status_valid, p0_xgmii.rx_data, p0_xgmii.tx_data, p1_link_fault.status_data, p1_rx.fifo_out_data, p1_rx.fifo_out_empty, p1_rx.fifo_out_endofpacket, p1_rx.fifo_out_error, p1_rx.fifo_out_ready, p1_rx.fifo_out_startofpacket, p1_rx.fifo_out_valid, p1_rx.status_data, p1_rx.status_error, p1_rx.status_valid, p1_tx.fifo_in_data, p1_tx.fifo_in_empty, p1_tx.fifo_in_endofpacket, p1_tx.fifo_in_error, p1_tx.fifo_in_ready, p1_tx.fifo_in_startofpacket, p1_tx.fifo_in_valid, p1_tx.status_data, p1_tx.status_error, p1_tx.status_valid, p1_xgmii.rx_data, p1_xgmii.tx_data, p2_link_fault.status_data, p2_rx.fifo_out_data, p2_rx.fifo_out_empty, p2_rx.fifo_out_endofpacket, p2_rx.fifo_out_error, p2_rx.fifo_out_ready, p2_rx.fifo_out_startofpacket, p2_rx.fifo_out_valid, p2_rx.status_data, p2_rx.status_error, p2_rx.status_valid, p2_tx.fifo_in_data, p2_tx.fifo_in_empty, p2_tx.fifo_in_endofpacket, p2_tx.fifo_in_error, p2_tx.fifo_in_ready, p2_tx.fifo_in_startofpacket, p2_tx.fifo_in_valid, p2_tx.status_data, p2_tx.status_error, p2_tx.status_valid, p2_xgmii.rx_data, p2_xgmii.tx_data, p3_link_fault.status_data, p3_rx.fifo_out_data, p3_rx.fifo_out_empty, p3_rx.fifo_out_endofpacket, p3_rx.fifo_out_error, p3_rx.fifo_out_ready, p3_rx.fifo_out_startofpacket, p3_rx.fifo_out_valid, p3_rx.status_data, p3_rx.status_error, p3_rx.status_valid, p3_tx.fifo_in_data, p3_tx.fifo_in_empty, p3_tx.fifo_in_endofpacket, p3_tx.fifo_in_error, p3_tx.fifo_in_ready, p3_tx.fifo_in_startofpacket, p3_tx.fifo_in_valid, p3_tx.status_data, p3_tx.status_error, p3_tx.status_valid, p3_xgmii.rx_data, p3_xgmii.tx_data);
endmodule
