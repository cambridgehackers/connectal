
/*
   ./importbvi.py
   -o
   ALTERA_ETH_PMA_RECONFIG_WRAPPER.bsv
   -I
   EthXcvrReconfigWrap
   -P
   EthXcvrReconfigWrap
   -c
   mgmt_clk_clk
   -r
   mgmt_rst_reset
   -f
   reconfig
   ../../out/de5/synthesis/altera_xgbe_pma_reconfig_wrapper.v
*/

import Clocks::*;
import DefaultValue::*;
import XilinxCells::*;
import GetPut::*;

(* always_ready, always_enabled *)
(* always_ready, always_enabled *)
interface EthxcvrreconfigwrapReconfig;
    method Bit#(1)     busy();
    method Action      from_xcvr(Bit#(368) v);
    method Action      mgmt_address(Bit#(7) v);
    method Action      mgmt_read(Bit#(1) v);
    method Bit#(32)     mgmt_readdata();
    method Bit#(1)     mgmt_waitrequest();
    method Action      mgmt_write(Bit#(1) v);
    method Action      mgmt_writedata(Bit#(32) v);
    method Bit#(560)     to_xcvr();
endinterface
(* always_ready, always_enabled *)
interface EthXcvrReconfigWrap;
    interface EthxcvrreconfigwrapReconfig     reconfig;
endinterface
import "BVI" altera_xgbe_pma_reconfig_wrapper =
module mkEthXcvrReconfigWrap#(Clock mgmt_clk_clk, Reset mgmt_clk_clk_reset, Reset mgmt_rst_reset)(EthXcvrReconfigWrap);
    default_clock clk();
    default_reset rst();
        input_clock mgmt_clk_clk(mgmt_clk_clk) = mgmt_clk_clk;
        input_reset mgmt_clk_clk_reset() = mgmt_clk_clk_reset; /* from clock*/
        input_reset mgmt_rst_reset(mgmt_rst_reset) = mgmt_rst_reset;
    interface EthxcvrreconfigwrapReconfig     reconfig;
        method reconfig_busy busy();
        method from_xcvr(reconfig_from_xcvr) enable((*inhigh*) EN_reconfig_from_xcvr);
        method mgmt_address(reconfig_mgmt_address) enable((*inhigh*) EN_reconfig_mgmt_address);
        method mgmt_read(reconfig_mgmt_read) enable((*inhigh*) EN_reconfig_mgmt_read);
        method reconfig_mgmt_readdata mgmt_readdata();
        method reconfig_mgmt_waitrequest mgmt_waitrequest();
        method mgmt_write(reconfig_mgmt_write) enable((*inhigh*) EN_reconfig_mgmt_write);
        method mgmt_writedata(reconfig_mgmt_writedata) enable((*inhigh*) EN_reconfig_mgmt_writedata);
        method reconfig_to_xcvr to_xcvr();
    endinterface
    schedule (reconfig.busy, reconfig.from_xcvr, reconfig.mgmt_address, reconfig.mgmt_read, reconfig.mgmt_readdata, reconfig.mgmt_waitrequest, reconfig.mgmt_write, reconfig.mgmt_writedata, reconfig.to_xcvr) CF (reconfig.busy, reconfig.from_xcvr, reconfig.mgmt_address, reconfig.mgmt_read, reconfig.mgmt_readdata, reconfig.mgmt_waitrequest, reconfig.mgmt_write, reconfig.mgmt_writedata, reconfig.to_xcvr);
endmodule
