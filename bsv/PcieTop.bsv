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

import Connectable       :: *;
import Xilinx            :: *;
import XilinxPCIE        :: *;
import Xilinx7PcieBridge :: *;
import PcieToAxiBridge   :: *;
import Portal            :: *;
import Leds              :: *;
import Top               :: *;

typedef (function Module#(PortalTop#(ipins)) mkPortalTop()) MkPortalTop#(type ipins);

interface PcieTop#(type ipins);
   (* prefix=""*)
   interface VC707_FPGA fpga;
   interface ipins       pins;
endinterface
	    
(* no_default_clock, no_default_reset *)
module [Module] mkPcieTopFromPortal #(Clock pci_sys_clk_p, Clock pci_sys_clk_n,
				      Clock sys_clk_p,     Clock sys_clk_n,
				      Reset pci_sys_reset_n,
				      MkPortalTop#(ipins) mkPortalTop)
   (PcieTop#(ipins));

   let contentId = 0;

   X7PcieBridgeIfc#(8) x7pcie <- mkX7PcieBridge( pci_sys_clk_p, pci_sys_clk_n, sys_clk_p, sys_clk_n, pci_sys_reset_n,
                                                 contentId );
   
   Reg#(Bool) interruptRequested <- mkReg(False, clocked_by x7pcie.clock125, reset_by x7pcie.reset125);

   // instantiate user portals
   let portalTop <- mkPortalTop(clocked_by x7pcie.clock125, reset_by x7pcie.reset125);

   mkConnection(x7pcie.portal0, portalTop.ctrl, clocked_by x7pcie.clock125, reset_by x7pcie.reset125);

   rule requestInterrupt;
      if (portalTop.interrupt && !interruptRequested)
	 x7pcie.interrupt();
      interruptRequested <= portalTop.interrupt;
   endrule

   interface VC707_FPGA fpga;
      interface pcie = x7pcie.pcie;
      //interface ddr3 = x7pcie.ddr3;
      method Bit#(8) leds();
	 return 0;
      endmethod
   endinterface
   interface pins = portalTop.pins;

endmodule: mkPcieTopFromPortal

module mkPcieTop #(Clock pci_sys_clk_p, Clock pci_sys_clk_n,
                          Clock sys_clk_p,     Clock sys_clk_n,
                          Reset pci_sys_reset_n)
                         (VC707_FPGA);

   let top <- mkPcieTopFromPortal(pci_sys_clk_p, pci_sys_clk_n, sys_clk_p, sys_clk_n, pci_sys_reset_n,
				  mkPortalTop);
   return top.fpga;
endmodule: mkPcieTop
