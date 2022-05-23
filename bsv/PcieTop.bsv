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

import ConnectalConfig::*;
`include "ConnectalProjectConfig.bsv"
import PcieSplitter      :: *;
import Xilinx            :: *;
import Portal            :: *;
import Top               :: *;
import PcieCsr           :: *;
import ConnectalMemTypes          :: *;
import Bscan             :: *;
import ConnectalClocks   :: *;
import GetPutWithClocks  :: *;
`ifdef XILINX
`ifdef PCIE3
`ifdef XilinxUltrascale
import PCIEWRAPPER3u     ::*;
`else
import PCIEWRAPPER3      :: *;
`endif
import Pcie3EndpointX7   :: *;
`endif
`ifdef PCIE2
import PCIEWRAPPER2       :: *;
import Pcie2EndpointX7 :: *;
`endif // pcie2
`ifdef PCIE1
import PCIEWRAPPER       :: *;
import Pcie1EndpointX7   :: *;
`endif // pcie2
`elsif ALTERA
import PcieEndpointS5    :: *;
`endif
import PcieHost          :: *;
import HostInterface     :: *;
import `PinTypeInclude::*;
import Platform          :: *;

`ifndef DataBusWidth
`define DataBusWidth 64
`endif

`ifdef XILINX_SYS_CLK
 `ifdef VirtexUltrascalePlus
   `define SYS_CLK_PARAM Clock sys_clk_p, Clock sys_clk_n, Clock sys_clk_300_p, Clock sys_clk_300_n, Clock sys_clk1_250_p, Clock sys_clk1_250_n, Clock sys_clk2_250_p, Clock sys_clk2_250_n, 
   `define SYS_CLK_ARG sys_clk_p, sys_clk_n, sys_clk_300_p, sys_clk_300_n, sys_clk1_250_p, sys_clk1_250_n, sys_clk2_250_p, sys_clk2_250_n, 
 `else
   `ifdef VirtexUltrascale
     `define SYS_CLK_PARAM Clock sys_clk_p, Clock sys_clk_n, Clock sys_clk1_300_p, Clock sys_clk1_300_n, Clock sys_clk2_300_p, Clock sys_clk2_300_n, 
     `define SYS_CLK_ARG sys_clk_p, sys_clk_n, sys_clk1_300_p, sys_clk1_300_n, sys_clk2_300_p, sys_clk2_300_n, 
   `else
     `define SYS_CLK_PARAM Clock sys_clk_p, Clock sys_clk_n,
     `define SYS_CLK_ARG sys_clk_p, sys_clk_n,
   `endif
  `endif
`else
  `define SYS_CLK_PARAM
  `define SYS_CLK_ARG
`endif

// `ifdef XILINX_SYS_CLK
// `ifdef VirtexUltrascale
// `define SYS_CLK_PARAM Clock sys_clk_p, Clock sys_clk_n, Clock sys_clk1_300_p, Clock sys_clk1_300_n, Clock sys_clk2_300_p, Clock sys_clk2_300_n, 
// `define SYS_CLK_ARG sys_clk_p, sys_clk_n, sys_clk1_300_p, sys_clk1_300_n, sys_clk2_300_p, sys_clk2_300_n, 
// `else
// `define SYS_CLK_PARAM Clock sys_clk_p, Clock sys_clk_n, 
// `define SYS_CLK_ARG sys_clk_p, sys_clk_n,
// `endif
// `else
// `define SYS_CLK_PARAM
// `define SYS_CLK_ARG
// `endif


(* synthesize, no_default_clock, no_default_reset *)
`ifdef XILINX
module mkPcieTop #(Clock pci_sys_clk_p, Clock pci_sys_clk_n, `SYS_CLK_PARAM Reset pci_sys_reset_n) (PcieTop#(`PinType));
   PcieHostTop host <- mkPcieHostTop(pci_sys_clk_p, pci_sys_clk_n, `SYS_CLK_ARG pci_sys_reset_n);
`elsif ALTERA
(* clock_prefix="", reset_prefix="" *)
module mkPcieTop #(Clock pcie_refclk_p, Clock osc_50_b3b, Reset pcie_perst_n) (PcieTop#(`PinType));
   PcieHostTop host <- mkPcieHostTop(pcie_refclk_p, osc_50_b3b, pcie_perst_n);
`endif
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

   if (mainClockPeriod == pcieClockPeriod) begin
       mkConnection(host.tpciehost.master, portalTop.slave, clocked_by host.portalClock, reset_by host.portalReset);
       if (valueOf(NumberOfMasters) > 0) begin
          for ( Integer i = 0; i < valueOf(NumberOfMasters); i = i + 1) begin
             `ifndef USE_WIDE_WIDTH
	         mkConnection(portalTop.masters[i], host.tpciehost.slave[i]);
             `else
             let memCnx <- GetPutWithClocks::mkConnectionWithGearbox(host.portalClock, host.portalReset,
			                                           host.pcieClock, host.pcieReset,
			                                           portalTop.masters[i], host.tpciehost.slave[i]);
             `endif
          end
       end
   end
   else begin
       let portalCnx <- GetPutWithClocks::mkConnectionWithClocks(host.pcieClock, host.pcieReset,
								 host.portalClock, host.portalReset,
								 host.tpciehost.master, portalTop.slave);
      if (valueOf(NumberOfMasters) > 0) begin
	  //zipWithM_(GetPutWithClocks::mkConnectionWithClocks2, portalTop.masters, host.tpciehost.slave);
	     for (Integer i = 0; i < valueOf(NumberOfMasters); i = i + 1) begin
            
            `ifndef USE_WIDE_WIDTH
	        GetPutWithClocks::mkConnectionWithClocks(host.portalClock, host.portalReset,
			                                         host.pcieClock, host.pcieReset,
			                                         portalTop.masters[i], host.tpciehost.slave[i]);
            `else
            let memCnx <- GetPutWithClocks::mkConnectionWithGearbox(host.portalClock, host.portalReset,
			                                                        host.pcieClock, host.pcieReset,
			                                                        portalTop.masters[i], host.tpciehost.slave[i]);
            `endif
         end
      end
   end

   // going from level to edge-triggered interrupt
   FIFO#(Bit#(4)) intrFifo <- mkFIFO(clocked_by host.portalClock, reset_by host.portalReset);
   //(8, host.portalClock, host.portalReset, host.pcieClock);
   Vector#(16, Reg#(Bool)) interruptRequested <- replicateM(mkReg(False, clocked_by host.portalClock, reset_by host.portalReset));
   rule interrupt_rule;
     Maybe#(Bit#(4)) intr = tagged Invalid;
     for (Integer i = 0; i < 16; i = i + 1) begin
	 if (portalTop.interrupt[i] && !interruptRequested[i])
             intr = tagged Valid fromInteger(i);
	 interruptRequested[i] <= portalTop.interrupt[i];
     end
     if (intr matches tagged Valid .intr_num) begin
	intrFifo.enq(intr_num);
     end
   endrule
   Put#(Bit#(4)) intrPut = (interface Put;
      method Action put(Bit#(4) intr_num);
	ReadOnly_MSIX_Entry msixEntry = host.tpciehost.msixEntry[intr_num];
	host.tpciehost.interruptRequest.put(tuple2({msixEntry.addr_hi, msixEntry.addr_lo}, msixEntry.msg_data));
      endmethod
      endinterface);

   GetPutWithClocks::mkConnectionWithClocks(host.portalClock, host.portalReset,
					    host.pcieClock, host.pcieReset,
					    toGet(intrFifo),
					    intrPut);

   interface pcie = host.tep7.pcie;
   interface pins = portalTop.pins;
endmodule

