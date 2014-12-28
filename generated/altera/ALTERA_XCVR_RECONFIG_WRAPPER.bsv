
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
   reconfig
   -f
   mgmt
   ../../out/de5/synthesis/alt_xcvr_reconfig.v
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
import "BVI" alt_xcvr_reconfig =
module mkXcvrReconfigWrap#(Clock mgmtclk_clk, Reset mgmtclk_clk_reset, Reset mgmtrst_reset)(XcvrReconfigWrap);
    default_clock clk();
    default_reset rst();
        input_clock mgmtclk_clk(mgmtclk_clk) = mgmtclk_clk;
        input_reset mgmtclk_clk_reset() = mgmtclk_clk_reset; /* from clock*/
        input_reset mgmtrst_reset(mgmtrst_reset) = mgmtrst_reset;
    interface XcvrreconfigwrapReconfig     reconfig;
        method reconfigbusy busy();
        method from_xcvr(reconfigfrom_xcvr) enable((*inhigh*) EN_reconfigfrom_xcvr);
        method reconfigto_xcvr to_xcvr();
    endinterface
    interface XcvrreconfigwrapReconfig_mgmt     reconfig_mgmt;
        method address(reconfig_mgmtaddress) enable((*inhigh*) EN_reconfig_mgmtaddress);
        method read(reconfig_mgmtread) enable((*inhigh*) EN_reconfig_mgmtread);
        method reconfig_mgmtreaddata readdata();
        method reconfig_mgmtwaitrequest waitrequest();
        method write(reconfig_mgmtwrite) enable((*inhigh*) EN_reconfig_mgmtwrite);
        method writedata(reconfig_mgmtwritedata) enable((*inhigh*) EN_reconfig_mgmtwritedata);
    endinterface
    schedule (reconfig.busy, reconfig.from_xcvr, reconfig.to_xcvr, reconfig_mgmt.address, reconfig_mgmt.read, reconfig_mgmt.readdata, reconfig_mgmt.waitrequest, reconfig_mgmt.write, reconfig_mgmt.writedata) CF (reconfig.busy, reconfig.from_xcvr, reconfig.to_xcvr, reconfig_mgmt.address, reconfig_mgmt.read, reconfig_mgmt.readdata, reconfig_mgmt.waitrequest, reconfig_mgmt.write, reconfig_mgmt.writedata);
endmodule
