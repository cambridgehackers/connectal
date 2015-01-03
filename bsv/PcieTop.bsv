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
import Clocks            :: *;
import GetPut            :: *;
import FIFO              :: *;
import Connectable       :: *;
import ClientServer      :: *;
import DefaultValue      :: *;
import PcieSplitter      :: *;
import Xilinx            :: *;
import Portal            :: *;
import Leds              :: *;
import Top               :: *;
import MemSlaveEngine    :: *;
import MemMasterEngine   :: *;
import PcieCsr           :: *;
import MemTypes          :: *;
import Bscan             :: *;
`ifdef XILINX
import PcieEndpointX7    :: *;
`elsif ALTERA
import PcieEndpointS5    :: *;
`endif
import PcieHost         :: *;
import HostInterface    :: *;

`ifndef DataBusWidth
`define DataBusWidth 64
`endif
`ifndef PinType
`define PinType Empty
`endif

typedef `PinType PinType;

`ifndef BSIM
(* synthesize, no_default_clock, no_default_reset *)
`endif
`ifdef BSIM
module mkPcieTop #(Clock pci_sys_clk_p, Clock pci_sys_clk_n, Clock sys_clk_p, Clock sys_clk_n, Reset pci_sys_reset_n) (PcieTop#(PinType));
   PcieHostTop host <- mkPcieHostTop(pci_sys_clk_p, pci_sys_clk_n, sys_clk_p, sys_clk_n, pci_sys_reset_n);
`elsif XILINX
module mkPcieTop #(Clock pci_sys_clk_p, Clock pci_sys_clk_n, Clock sys_clk_p, Clock sys_clk_n, Reset pci_sys_reset_n) (PcieTop#(PinType));
   PcieHostTop host <- mkPcieHostTop(pci_sys_clk_p, pci_sys_clk_n, sys_clk_p, sys_clk_n, pci_sys_reset_n);
`elsif ALTERA
(* clock_prefix="", reset_prefix="" *)
module mkPcieTop #(Clock pcie_refclk_p, Clock osc_50_b3b, Reset pcie_perst_n) (PcieTop#(PinType));
   PcieHostTop host <- mkPcieHostTop(pcie_refclk_p, osc_50_b3b, pcie_perst_n);
`endif

`ifdef IMPORT_HOSTIF
   ConnectalTop#(PhysAddrWidth, DataBusWidth, PinType, NumberOfMasters) portalTop <- mkConnectalTop(host, clocked_by host.portalClock, reset_by host.portalReset);
`else
   ConnectalTop#(PhysAddrWidth, DataBusWidth, PinType, NumberOfMasters) portalTop <- mkConnectalTop(clocked_by host.portalClock, reset_by host.portalReset);
`endif

   mkConnection(host.tpciehost.master, portalTop.slave, clocked_by host.portalClock, reset_by host.portalReset);
   if (valueOf(NumberOfMasters) > 0) begin
      mapM(uncurry(mkConnection),zip(portalTop.masters, host.tpciehost.slave));
   end

   // going from level to edge-triggered interrupt
   Vector#(16, Reg#(Bool)) interruptRequested <- replicateM(mkReg(False, clocked_by host.portalClock, reset_by host.portalReset));
   rule interrupt_rule;
     Maybe#(Bit#(4)) intr = tagged Invalid;
     for (Integer i = 0; i < 16; i = i + 1) begin
	 if (portalTop.interrupt[i] && !interruptRequested[i])
             intr = tagged Valid fromInteger(i);
	 interruptRequested[i] <= portalTop.interrupt[i];
     end
     if (intr matches tagged Valid .intr_num) begin
        ReadOnly_MSIX_Entry msixEntry = host.tpciehost.msixEntry[intr_num];
        host.tpciehost.interruptRequest.put(tuple2({msixEntry.addr_hi, msixEntry.addr_lo}, msixEntry.msg_data));
     end
   endrule

`ifndef BSIM
   interface pcie = host.tep7.pcie;
   method Bit#(NumLeds) leds();
      return portalTop.leds.leds();
   endmethod
   interface Clock deleteme_unused_clockLeds = host.tep7.epClock125;
   interface pins = portalTop.pins;
`endif
endmodule

