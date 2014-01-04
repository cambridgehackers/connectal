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
interface EchoDdr#(numeric type c_dm_width, numeric type c_dq_width, numeric type c_dqs_width, numeric type data_width, numeric type gpio_width, numeric type id_width, numeric type mio_width);
    (* prefix="DDR_Addr" *) interface Inout#(Bit#(15))     addr;
    (* prefix="DDR_BankAddr" *) interface Inout#(Bit#(3))     bankaddr;
    (* prefix="DDR_CAS_n" *) interface Inout#(Bit#(1))     cas_n;
    (* prefix="DDR_CKE" *) interface Inout#(Bit#(1))     cke;
    (* prefix="DDR_CS_n" *) interface Inout#(Bit#(1))     cs_n;
    (* prefix="DDR_Clk_n" *) interface Inout#(Bit#(1))     clk_n;
    (* prefix="DDR_Clk_p" *) interface Inout#(Bit#(1))     clk;
    (* prefix="DDR_DM" *) interface Inout#(Bit#(c_dm_width))     dm;
    (* prefix="DDR_DQ" *) interface Inout#(Bit#(c_dq_width))     dq;
    (* prefix="DDR_DQS_n" *) interface Inout#(Bit#(c_dqs_width))     dqs_n;
    (* prefix="DDR_DQS_p" *) interface Inout#(Bit#(c_dqs_width))     dqs;
    (* prefix="DDR_DRSTB" *) interface Inout#(Bit#(1))     drstb;
    (* prefix="DDR_ODT" *) interface Inout#(Bit#(1))     odt;
    (* prefix="DDR_RAS_n" *) interface Inout#(Bit#(1))     ras_n;
    (* prefix="FIXED_IO_ddr_vrn" *) interface Inout#(Bit#(1))     vrn;
    (* prefix="FIXED_IO_ddr_vrp" *) interface Inout#(Bit#(1))     vrp;
    (* prefix="DDR_WEB" *) interface Inout#(Bit#(1))     web;
endinterface
(* always_ready, always_enabled *)
interface EchoPins#(numeric type mio_width);
    (* prefix="" *)
    interface EchoDdr#(4, 32, 4, 64, 64, 12, 54) ddr;
    (* prefix="FIXED_IO_mio" *)
    interface Inout#(Bit#(mio_width))       mio;
    (* prefix="FIXED_IO_ps" *)
    interface Pps7Ps#(4, 32, 4, 64, 64, 12, 54) ps;
    (* prefix="GPIO" *)
    interface LEDS                          leds;
    interface Clock                         fclk_clk0;
    interface Bit#(1)                       fclk_reset0_n;
endinterface

module mkZynqTop(EchoPins#(54));
    Clock defaultClock <- exposeCurrentClock();
    Reset defaultReset <- exposeCurrentReset();
    let axiTop <- mkPortalTop();
    StdPS7 ps7 <- mkPS7Slave(defaultClock, defaultReset, axiTop);

    interface EchoDdr ddr;
        method addr = ps7.ddr.addr;
        method bankaddr = ps7.ddr.bankaddr;
        method cas_n = ps7.ddr.cas_n;
        method cke = ps7.ddr.cke;
        method cs_n = ps7.ddr.cs_n;
        method clk_n = ps7.ddr.clk_n;
        method clk = ps7.ddr.clk;
        method dm = ps7.ddr.dm;
        method dq = ps7.ddr.dq;
        method dqs_n = ps7.ddr.dqs_n;
        method dqs = ps7.ddr.dqs;
        method drstb = ps7.ddr.drstb;
        method odt = ps7.ddr.odt;
        method ras_n = ps7.ddr.ras_n;
        method vrn = ps7.ddr.vrn;
        method vrp = ps7.ddr.vrp;
        method web = ps7.ddr.web;
    endinterface
    interface Inout   mio = ps7.mio;
    interface Pps7Ps  ps = ps7.ps;
    interface LEDS    leds = axiTop.leds;
    interface Clock   fclk_clk0 = ps7.fclk.clk0;
    interface Bit     fclk_reset0_n = ps7.fclk_reset[0].n;
endmodule : mkZynqTop
