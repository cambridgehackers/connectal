
/*
   ./importbvi.py
   -o
   ALTERA_XCVR_RECONFIG_WRAPPER.bsv
   -I
   XcvrReconfigWrap
   -P
   XcvrReconfigWrap
   -c
   mgmt_clk_clk
   -r
   mgmt_rst_reset
   -f
   reconfig_mgmt
   -f
   mgmt
   ../../out/de5/synthesis/alt_xcvr_reconfig_wrapper.v
*/

import Clocks::*;
import DefaultValue::*;
import XilinxCells::*;
import GetPut::*;

(* always_ready, always_enabled *)
(* always_ready, always_enabled *)
interface XcvrreconfigwrapReconfig;
    method Bit#(1)     busy();
    method Action      from_xcvr(Bit#(460) v);
    method Bit#(700)     to_xcvr();
endinterface
(* always_ready, always_enabled *)
interface XcvrreconfigwrapReconfig_mgmt;
    method Action      address(Bit#(7) v);
    method Action      read(Bit#(1) v);
    method Bit#(32)     readdata();
    method Bit#(1)     waitrequest();
    method Action      write(Bit#(1) v);
    method Action      writedata(Bit#(32) v);
endinterface
(* always_ready, always_enabled *)
interface XcvrReconfigWrap;
    interface XcvrreconfigwrapReconfig     reconfig;
    interface XcvrreconfigwrapReconfig_mgmt     reconfig_mgmt;
endinterface
import "BVI" alt_xcvr_reconfig_wrapper =
module mkXcvrReconfigWrap#(Clock mgmt_clk_clk, Reset mgmt_clk_clk_reset, Reset mgmt_rst_reset)(XcvrReconfigWrap);
    default_clock clk();
    default_reset rst();
        input_clock mgmt_clk_clk(mgmt_clk_clk) = mgmt_clk_clk;
        input_reset mgmt_clk_clk_reset() = mgmt_clk_clk_reset; /* from clock*/
        input_reset mgmt_rst_reset(mgmt_rst_reset) = mgmt_rst_reset;
    interface XcvrreconfigwrapReconfig     reconfig;
        method reconfig_busy busy();
        method from_xcvr(reconfig_from_xcvr) enable((*inhigh*) EN_reconfig_from_xcvr);
        method reconfig_to_xcvr to_xcvr();
    endinterface
    interface XcvrreconfigwrapReconfig_mgmt     reconfig_mgmt;
        method address(reconfig_mgmt_address) enable((*inhigh*) EN_reconfig_mgmt_address);
        method read(reconfig_mgmt_read) enable((*inhigh*) EN_reconfig_mgmt_read);
        method reconfig_mgmt_readdata readdata();
        method reconfig_mgmt_waitrequest waitrequest();
        method write(reconfig_mgmt_write) enable((*inhigh*) EN_reconfig_mgmt_write);
        method writedata(reconfig_mgmt_writedata) enable((*inhigh*) EN_reconfig_mgmt_writedata);
    endinterface
    schedule (reconfig.busy, reconfig.from_xcvr, reconfig.to_xcvr, reconfig_mgmt.address, reconfig_mgmt.read, reconfig_mgmt.readdata, reconfig_mgmt.waitrequest, reconfig_mgmt.write, reconfig_mgmt.writedata) CF (reconfig.busy, reconfig.from_xcvr, reconfig.to_xcvr, reconfig_mgmt.address, reconfig_mgmt.read, reconfig_mgmt.readdata, reconfig_mgmt.waitrequest, reconfig_mgmt.write, reconfig_mgmt.writedata);
endmodule
