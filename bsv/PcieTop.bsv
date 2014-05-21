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
import Clocks          :: *;
import GetPut            :: *;
import Connectable       :: *;
import Xilinx            :: *;
import DefaultValue    :: *;
import PcieSplitter      :: *;
import X7PcieSplitter    :: *;
import XbsvXilinx7Pcie   :: *;
import PCIEWRAPPER       :: *;
import Portal            :: *;
import Leds              :: *;
import Top               :: *;
import AxiSlaveEngine    :: *;
import AxiMasterEngine   :: *;
import AxiMasterSlave    :: *;
import AxiDma            :: *;
import AxiCsr            :: *;

typedef (function Module#(PortalTop#(40, dsz, ipins,nMasters)) mkPortalTop()) MkPortalTop#(numeric type dsz, type ipins, numeric type nMasters);

`ifdef Artix7
typedef 4 PcieLanes;
typedef 4 NumLeds;
`else
typedef 8 PcieLanes;
typedef 8 NumLeds;
`endif

interface PcieTop#(type ipins);
   (* prefix="PCIE" *)
   interface PciewrapPci_exp#(PcieLanes) pcie;
   (* always_ready *)
   method Bit#(NumLeds) leds();
   interface ipins       pins;
endinterface

(* no_default_clock, no_default_reset *)
module [Module] mkPcieTopFromPortal #(Clock pci_sys_clk_p, Clock pci_sys_clk_n,
				      Clock sys_clk_p,     Clock sys_clk_n,
				      Reset pci_sys_reset_n,
				      MkPortalTop#(dsz, ipins, nMasters) mkPortalTop)
   (PcieTop#(ipins))
   provisos (Mul#(TDiv#(dsz, 32), 32, dsz),
	     Add#(b__, 32, dsz),
	     Add#(c__, dsz, 256),
	     Add#(d__, TMul#(8, TDiv#(dsz, 32)), 64),
	     Add#(e__, TMul#(32, TDiv#(dsz, 32)), 256),
	     Add#(f__, TDiv#(dsz, 32), 8),
	     Mul#(TDiv#(dsz, 8), 8, dsz),
	     Add#(g__, nMasters, 1)
      );

   Clock sys_clk_200mhz <- mkClockIBUFDS(sys_clk_p, sys_clk_n);
   Clock sys_clk_200mhz_buf <- mkClockBUFG(clocked_by sys_clk_200mhz);
   Reset sys_clk_200mhz_reset <- mkAsyncReset(2, pci_sys_reset_n, sys_clk_200mhz_buf);

   ClockGenerator7Params clk_params = defaultValue();
   clk_params.clkin1_period     = 5.000;       // 200 MHz reference
   clk_params.clkin_buffer      = False;       // necessary buffer is instanced above
   clk_params.reset_stages      = 0;           // no sync on reset so input clock has pll as only load
   clk_params.clkfbout_mult_f   = 5.000;       // 1000 MHz VCO
   clk_params.clkout0_divide_f  = 10;          // unused clock 
   clk_params.clkout1_divide    = 5;           // ddr3 reference clock (200 MHz)

   ClockGenerator7 clk_gen <- mkClockGenerator7(clk_params, clocked_by sys_clk_200mhz, reset_by pci_sys_reset_n);

   Clock clk = clk_gen.clkout0;
   Reset rst_n <- mkAsyncReset( 1, pci_sys_reset_n, clk );
   Reset ddr3ref_rst_n <- mkAsyncReset( 1, rst_n, clk_gen.clkout1 );
   
   //DDR3_Configure_X7 ddr3_cfg;
   //ddr3_cfg.num_reads_in_flight = 2;   // adjust as needed
   //ddr3_cfg.fast_train_sim_only = False; // adjust if simulating
   
   //DDR3_Controller_X7 ddr3_ctrl <- mkXilinx7DDR3Controller(ddr3_cfg, clocked_by clk_gen.clkout1, reset_by ddr3ref_rst_n);

   // ddr3_ctrl.user needs to connect to user logic and should use ddr3clk and ddr3rstn
   //Clock ddr3clk = ddr3_ctrl.user.clock;
   //Reset ddr3rstn = ddr3_ctrl.user.reset_n;
   
   // Buffer clocks and reset before they are used
   Clock pci_clk_100mhz_buf <- mkClockIBUFDS_GTE2(True, pci_sys_clk_p, pci_sys_clk_n);

   // Instantiate the PCIE endpoint
   XbsvXilinx7Pcie::PCIExpressX7#(PcieLanes) _ep
       <- XbsvXilinx7Pcie::mkPCIExpressEndpointX7( defaultValue
						  , clocked_by pci_clk_100mhz_buf
						  , reset_by pci_sys_reset_n
						  );

   // The PCIE endpoint is processing TLPWord#(8)s at 250MHz.  The
   // AXI bridge is accepting TLPWord#(16)s at 125 MHz. The
   // connection between the endpoint and the AXI contains GearBox
   // instances for the TLPWord#(8)@250 <--> TLPWord#(16)@125
   // conversion.

   // The PCIe endpoint exports full (250MHz) and half-speed (125MHz) clocks
   Clock epClock250 = _ep.user.clk_out;
   Reset user_reset_n <- mkResetInverter(_ep.user.reset_out);
   Reset epReset250 <- mkAsyncReset(4, user_reset_n, epClock250);

   ClockGenerator7Params     params = defaultValue;
   params.clkin1_period    = 4.000;
   params.clkin_buffer     = False;
   params.clkfbout_mult_f  = 4.000;
   params.clkout0_divide_f = 8.000;
   ClockGenerator7           clkgen <- mkClockGenerator7(params, clocked_by _ep.user.clk_out, reset_by user_reset_n);
   Clock epClock125 = clkgen.clkout0; /* half speed user_clk */
   Reset epReset125 <- mkAsyncReset(4, user_reset_n, epClock125);

   // Extract some status info from the PCIE endpoint. These values are
   // all in the epClock250 domain, so we have to cross them into the
   // epClock125 domain.

   let my_pciId = PciId { bus:  _ep.cfg.bus_number(),
	 dev: _ep.cfg.device_number(), func: _ep.cfg.function_number()};

   // Build the PCIe-to-AXI bridge
   PcieSplitter#(BPB)  bridge <- mkPcieSplitter(my_pciId, clocked_by epClock125, reset_by epReset125);

   X7PcieSplitter#(PcieLanes) x7pcie <- mkX7PcieSplitter(
//pci_sys_clk_p, pci_sys_clk_n, sys_clk_p, sys_clk_n, pci_sys_reset_n, 
epClock250, epReset250, epClock125, epReset125, _ep, bridge);
   
   // instantiate user portals
   let portalTop <- mkPortalTop(clocked_by epClock125, reset_by bridge.brif.portalReset);
   AxiSlaveEngine#(dsz) axiSlaveEngine <- mkAxiSlaveEngine(my_pciId, clocked_by epClock125, reset_by epReset125);
   AxiMasterEngine axiMasterEngine <- mkAxiMasterEngine(my_pciId, clocked_by epClock125, reset_by epReset125);

   mkConnection(bridge.brif.outToAxi, axiSlaveEngine.inFromPci, clocked_by epClock125, reset_by epReset125);
   mkConnection(axiSlaveEngine.outToPci, bridge.brif.inFromAxi, clocked_by epClock125, reset_by epReset125);
   Vector#(nMasters,Axi3Master#(40,dsz,6)) m_axis;   
   if(valueOf(nMasters) > 0) begin
      m_axis[0] <- mkAxiDmaMaster(portalTop.masters[0],clocked_by epClock125, reset_by bridge.brif.portalReset);
      mkConnection(m_axis[0], axiSlaveEngine.slave, clocked_by epClock125, reset_by epReset125);
   end

   mkConnection(bridge.brif.outToPortal, axiMasterEngine.inFromTlp);
   mkConnection(axiMasterEngine.outToTlp, bridge.brif.inFromPortal);

   Axi3Slave#(32,32,12) ctrl <- mkAxiDmaSlave(portalTop.slave, clocked_by epClock125, reset_by epReset125);
   mkConnection(axiMasterEngine.master, ctrl, clocked_by epClock125, reset_by epReset125);

   // going from level to edge-triggered interrupt
   Vector#(15, Reg#(Bool)) interruptRequested <- replicateM(mkReg(False, clocked_by epClock125, reset_by epReset125));
   for (Integer i = 0; i < 15; i = i + 1) begin
      // intr_num 0 for the directory
      Integer intr_num = i+1;
      MSIX_Entry msixEntry = bridge.msixEntry[intr_num];
      rule interruptRequest;
	 if (portalTop.interrupt[i] && !interruptRequested[i])
	    axiMasterEngine.interruptRequest.put(tuple2({msixEntry.addr_hi, msixEntry.addr_lo}, msixEntry.msg_data));
	 interruptRequested[i] <= portalTop.interrupt[i];
      endrule
   end

   interface pcie = _ep.pcie;
   method Bit#(NumLeds) leds();
      return extend({_ep.user.lnk_up(),3'd2});
   endmethod
   interface pins = portalTop.pins;

endmodule: mkPcieTopFromPortal

`ifndef DataBusWidth
`define DataBusWidth 64
`endif
`ifndef NumberOfMasters
`define NumberOfMasters 1
`endif
(* synthesize *)
module mkSynthesizeablePortalTop(PortalTop#(40, `DataBusWidth, Empty, `NumberOfMasters));
   let top <- mkPortalTop();
   interface masters = top.masters;
   interface slave = top.slave;
   interface interrupt = top.interrupt;
   interface leds = top.leds;
   interface pins = top.pins;
endmodule

`ifndef PinType
`define PinType Empty
`endif
module mkPcieTop #(Clock pci_sys_clk_p, Clock pci_sys_clk_n,
   Clock sys_clk_p,     Clock sys_clk_n,
   Reset pci_sys_reset_n)
   (PcieTop#(`PinType));
   let top <- mkPcieTopFromPortal(pci_sys_clk_p, pci_sys_clk_n, sys_clk_p, sys_clk_n, pci_sys_reset_n,mkSynthesizeablePortalTop);
   return top;
endmodule: mkPcieTop
