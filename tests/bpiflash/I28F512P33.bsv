
/*
   ../../generated/scripts/importbvi.py
   -o
   I28F512P33.bsv
   -I
   I28f512p33
   -P
   StrataFlash
   -c
   CLK
   -r
   RSTNeg
   i28f512p33.v
*/

import Clocks::*;
import DefaultValue::*;
import XilinxCells::*;
import GetPut::*;
import AxiBits::*;

(* always_ready, always_enabled *)
interface I28f512p33;
    method Action      addr(Bit#(25) v);
    method Action      advneg(Bit#(1) v);
    method Action      ceneg(Bit#(1) v);
    interface Inout#(Bit#(16))     dq;
    method Action      oeneg(Bit#(1) v);
    method Action      vpp(Bit#(1) v);
    method Bit#(1)     waitout();
    method Action      weneg(Bit#(1) v);
    method Action      wpneg(Bit#(1) v);
endinterface
import "BVI" i28f512p33 =
module mkI28f512p33Load#(String memFileName)(I28f512p33);
    parameter mem_file_name = memFileName;
    parameter mem_file_name_1 = memFileName;
    parameter UserPreload = 1;
    default_clock clk(CLK);
    default_reset rstneg(RSTNeg);
    method addr(Addr) enable((*inhigh*) EN_Addr);
    method advneg(ADVNeg) enable((*inhigh*) EN_ADVNeg);
    method ceneg(CENeg) enable((*inhigh*) EN_CENeg);
    ifc_inout dq(DQ);
    method oeneg(OENeg) enable((*inhigh*) EN_OENeg);
    method vpp(VPP) enable((*inhigh*) EN_VPP);
    method WAITOut waitout();
    method weneg(WENeg) enable((*inhigh*) EN_WENeg);
    method wpneg(WPNeg) enable((*inhigh*) EN_WPNeg);
    schedule (addr, advneg, ceneg, oeneg, vpp, waitout, weneg, wpneg) CF (addr, advneg, ceneg, oeneg, vpp, waitout, weneg, wpneg);
endmodule

module mkI28f512p33(I28f512p33);
   (* hide *)let flash <- mkI28f512p33Load("none");
   return flash;
endmodule