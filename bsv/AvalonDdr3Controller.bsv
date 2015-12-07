// Copyright (c) 2015 Connectal Project

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

import Clocks          ::*;
import GetPut          ::*;
import ClientServer    ::*;
import ConnectalClocks ::*;
import ALTERA_DDR3_WRAPPER::*;
`include "ConnectalProjectConfig.bsv"

typedef 25 Ddr3AddrWidth;
typedef 512 Ddr3DataWidth;

interface Ddr3Pins;
   (* prefix="" *)
   interface Ddr3 ddr3;
   method Action osc_50(Bit#(1) b3d, Bit#(1) b4a, Bit#(1) b4d, Bit#(1) b7a, Bit#(1) b7d, Bit#(1) b8a, Bit#(1) b8d);
endinterface

interface Ddr3;
   interface Avalonddr3Mem ddr3b;
   (* prefix="" *)
   interface Avalonddr3Oct rzq_4;
   interface Clock sysclk_deleteme_unused_clock;
   interface Reset sysrst_deleteme_unused_reset;
endinterface

(* synthesize *)
module mkDdr3#(Clock clk50)(Ddr3);
   let clock <- exposeCurrentClock();
   let reset <- exposeCurrentReset();

   Reset rst50 <- mkAsyncReset( 10, reset, clk50 );

   AvalonDdr3 mc <- mkAvalonDdr3(clk50, reset, noReset);

   interface ddr3b = mc.mem;
   interface rzq_4 = mc.oct;
   interface sysclk_deleteme_unused_clock = clock; //fixme
   interface sysrst_deleteme_unused_reset = reset; //fixme
endmodule
