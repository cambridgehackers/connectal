// Copyright (c) 2017 Accelerated Tech, Inc.

// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use, copy,
// modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
// BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
// ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
import Vector            :: *;
import Clocks            :: *;
import GetPut            :: *;
import FIFO              :: *;
import Connectable       :: *;
import ClientServer      :: *;
import DefaultValue      :: *;
import Real              :: *;

import ConnectalConfig::*;
`include "ConnectalProjectConfig.bsv"
import Xilinx            :: *;
import Portal            :: *;
import Top               :: *;
import ConnectalMemTypes          :: *;
import ConnectalClocks   :: *;
import GetPutWithClocks  :: *;
import HostInterface     :: *;
import `PinTypeInclude::*;
import Platform          :: *;

`ifndef DataBusWidth
`define DataBusWidth 64
`endif

interface UntetheredTop#(type pintype);
   (* prefix="" *)
   interface pintype pins;
endinterface

interface UntetheredHost;
   interface Clock portalClock;
   interface Reset portalReset;
   interface Clock derivedClock;
   interface Reset derivedReset;
endinterface

`ifdef VirtexUltrascale
`define SYS_CLK_PARAM Clock sys_clk1_300_p, Clock sys_clk1_300_n, Clock sys_clk2_300_p, Clock sys_clk2_300_n, 
`define SYS_CLK_ARG sys_clk1_300_p, sys_clk1_300_n, sys_clk2_300_p, sys_clk2_300_n, 
`else
`define SYS_CLK_PARAM
`define SYS_CLK_ARG 
`endif

(* synthesize, no_default_clock, no_default_reset, reset_prefix="RST" *)
module mkUntetheredTop #(Clock sys_clk_p, Clock sys_clk_n, `SYS_CLK_PARAM Reset cpu_reset) (UntetheredTop#(`PinType));

   Clock sys_clk_200mhz <- mkClockIBUFDS(
`ifdef ClockDefaultParam
       defaultValue,
`endif
       sys_clk_p, sys_clk_n);
   Clock sys_clk_200mhz_buf <- mkClockBUFG(clocked_by sys_clk_200mhz);
   Reset sys_reset_n <- mkResetInverter(cpu_reset, clocked_by sys_clk_200mhz_buf);

   ClockGenerator7Params     clkgenParams = defaultValue;
   clkgenParams.clkin1_period    = 5.000; //  200MHz
   clkgenParams.clkin_buffer     = False;
   clkgenParams.clkfbout_mult_f  = 5.000; // 1000MHz
   clkgenParams.clkout0_divide_f = derivedClockPeriod;
   clkgenParams.clkout1_divide     = round(mainClockPeriod);
   clkgenParams.clkout1_duty_cycle = 0.5;
   clkgenParams.clkout1_phase      = 0.0000;
   clkgenParams.clkout2_divide     = 4; // 250MHz
   clkgenParams.clkout2_duty_cycle = 0.5;
   clkgenParams.clkout2_phase      = 0.0000;
   ClockGenerator7           clkgen <- mkClockGenerator7(clkgenParams, clocked_by sys_clk_200mhz_buf, reset_by sys_reset_n);
   Clock portalClock;
   Reset portalReset;
   if (mainClockPeriod == 5) begin
      portalClock = sys_clk_200mhz_buf;
      portalReset = sys_reset_n;
   end
   else begin
      portalClock = clkgen.clkout1;
      portalReset <- mkSyncReset(5, sys_reset_n, portalClock);
   end
   Clock derivedClock = clkgen.clkout0;
   Reset derivedReset <- mkSyncReset(5, sys_reset_n, derivedClock);

   UntetheredHost host = (interface UntetheredHost;
			  interface portalClock = portalClock;
			  interface portalReset = portalReset;
			  interface derivedClock = derivedClock;
			  interface derivedReset = derivedReset;
			  endinterface);

   Vector#(NumberOfUserTiles,ConnectalTop#(`PinType)) tile <- replicateM(mkConnectalTop(
`ifdef IMPORT_HOSTIF // no synthesis boundary
      host,
`else                // enables synthesis boundary
`ifdef IMPORT_HOST_CLOCKS
       host.derivedClock, host.derivedReset,
`endif
`endif
       clocked_by host.portalClock, reset_by host.portalReset));
   Platform portalTop <- mkPlatform(tile, clocked_by host.portalClock, reset_by host.portalReset);

   interface pins = portalTop.pins;
endmodule

