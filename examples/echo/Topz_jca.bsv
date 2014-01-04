// bsv libraries
import Clocks :: *;
import GetPut::*;
import GetPutWithClocks::*;

// portz libraries
import AxiMasterSlave::*;
import CtrlMux::*;
import Leds::*;
import Top::*;
import PPS7::*;
import PS7::*;
import PS7Helper::*;
import Portal::*;

(* always_ready, always_enabled *)
interface EchoPins;
    (* prefix="" *)
    interface ZynqPins zynq;
    (* prefix="GPIO" *)
    interface LEDS                          leds;
endinterface

module mkZynqTop(EchoPins);
    Clock defaultClock <- exposeCurrentClock();
    Reset defaultReset <- exposeCurrentReset();
    let axiTop <- mkPortalTop();
    StdPS7 ps7 <- mkPS7Slave(defaultClock, defaultReset, axiTop);

interface ZynqPins zynq;
    interface Inout addr = ps7.ddr.addr;
    interface Inout bankaddr = ps7.ddr.bankaddr;
    interface Inout cas_n = ps7.ddr.cas_n;
    interface Inout cke = ps7.ddr.cke;
    interface Inout cs_n = ps7.ddr.cs_n;
    interface Inout clk_n = ps7.ddr.clk_n;
    interface Inout clk = ps7.ddr.clk;
    interface Inout dm = ps7.ddr.dm;
    interface Inout dq = ps7.ddr.dq;
    interface Inout dqs_n = ps7.ddr.dqs_n;
    interface Inout dqs = ps7.ddr.dqs;
    interface Inout drstb = ps7.ddr.drstb;
    interface Inout odt = ps7.ddr.odt;
    interface Inout ras_n = ps7.ddr.ras_n;
    interface Inout vrn = ps7.ddr.vrn;
    interface Inout vrp = ps7.ddr.vrp;
    interface Inout web = ps7.ddr.web;
    interface Inout   mio = ps7.mio;
    interface Pps7Ps  ps = ps7.ps;
    interface Clock   fclk_clk0 = ps7.fclk.clk0;
    interface Bit     fclk_reset0_n = ps7.fclk_reset[0].n;
endinterface
    interface LEDS    leds = axiTop.leds;
endmodule : mkZynqTop
