// Copyright (c) 2014 Quanta Research Cambridge, Inc.

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
import Connectable       :: *;
import Xilinx            :: *;
import Portal            :: *;
import Leds              :: *;
import Top               :: *;
import PcieTop           :: *;

(* synthesize *)
module mkSynthesizeablePortalTop(PortalTop#(40, 64, Empty));
   let top <- mkPortalTop();
   interface ctrl = top.ctrl;
   interface read_client = top.read_client;
   interface write_client = top.write_client;
   interface interrupt = top.interrupt;
   interface leds = top.leds;
   interface pins = top.pins;
endmodule

module mkPcieTop #(Clock pci_sys_clk_p, Clock pci_sys_clk_n,
   Clock sys_clk_p,     Clock sys_clk_n,
   Reset pci_sys_reset_n)
   (PcieTop#(Empty));

   let top <- mkPcieTopFromPortal(pci_sys_clk_p, pci_sys_clk_n, sys_clk_p, sys_clk_n, pci_sys_reset_n,
				  mkSynthesizeablePortalTop);
   return top;
endmodule: mkPcieTop
