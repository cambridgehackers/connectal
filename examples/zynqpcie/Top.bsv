/* Copyright (c) 2014 Quanta Research Cambridge, Inc
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included
 * in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */
`include "ConnectalProjectConfig.bsv"
import Clocks::*;
import Vector::*;
import FIFO::*;
import Connectable::*;
import GetPutWithClocks::*;
import CtrlMux::*;
import Portal::*;
import ConnectalConfig::*;
import ConnectalMemTypes::*;
import PcieHost ::*;
`ifndef SIMULATION
import PCIEWRAPPER          ::*;
import PcieEndpointX7       ::*;
import ConnectalXilinxCells ::*;
`endif
import Simple::*;
import ZynqPcieTestRequest::*;
import ZynqPcieTestIndication::*;
import ZynqPcieTestIF::*;
import SimpleIF::*;

typedef enum {IfcNames_SimpleRequest, IfcNames_SimpleIndication, IfcNames_ZynqPcieTestRequest, IfcNames_ZynqPcieTestIndication} IfcNames deriving (Eq,Bits);

interface ZynqPcie;
   (* prefix="PCIE" *)
   interface PciewrapPci_exp#(PcieLanes) pcie;
   method Action pcie_sys_clk(Bit#(1) p, Bit#(1) n);
   method Action sys_clk(Bit#(1) p, Bit#(1) n);
   method Action pcie_sys_reset(Bit#(1) n);
   interface Clock deleteme_unused_clockFoo;
   interface Clock deleteme_unused_clockPortal;
   interface Clock deleteme_unused_clock100mhz;
endinterface

//
// This module is just to put a synthesis boundary around
// mkPcieHostTop, which does not currently have one.  The Makefile
// uses this line to synthesize this module into its own
// netlist. We're not going to change it, so on subsequent rebuilds,
// buildcache will use the previous synthesis result.
//
//    CONNECTALFLAGS += -P mkPcieHostTopSynth
//
(* synthesize *)
module mkPcieHostTopSynth#(Clock pcie_sys_clk_p, Clock pcie_sys_clk_n, Clock sys_clk_p, Clock sys_clk_n, Reset pcie_sys_reset_n)(PcieHostTop);
   (*hide*) let host <- mkPcieHostTop(pcie_sys_clk_p, pcie_sys_clk_n, sys_clk_p, sys_clk_n, pcie_sys_reset_n);
   return host;
endmodule

//
// This design exposes a PCIe interface via its "pins"
//
module mkConnectalTop(ConnectalTop);

   Clock defaultClock <- exposeCurrentClock();
   Reset defaultReset <- exposeCurrentReset();

   // Clock laundering facility:
   //
   // Bluespec does have a way for exposed interfaces to be a source
   // for clocks so we use B2C (bit to clock) to convert bits to
   // clocks.
   B2C1 b2c_pcie_sys_clk_p <- mkB2C1();
   B2C1 b2c_pcie_sys_clk_n <- mkB2C1();
   B2C b2c_pcie_sys_reset_n <- mkB2C();
   B2C1 b2c_sys_clk_p <- mkB2C1();
   B2C1 b2c_sys_clk_n <- mkB2C1();

   //
   // Instantiate a PcieHostTop, so that we can connect it to a set of portals.
   //
   PcieHostTop host <- mkPcieHostTopSynth(b2c_pcie_sys_clk_p.c, b2c_pcie_sys_clk_n.c, b2c_sys_clk_p.c, b2c_sys_clk_n.c, b2c_pcie_sys_reset_n.r);

   // The PCIe portals and Zynq portals are in different clock domains, so synchronize bits that are provided to mkZynqPcieTest
   SyncBitIfc#(Bit#(1)) resetBit <- mkSyncBit(b2c_pcie_sys_reset_n.c, b2c_pcie_sys_reset_n.r, defaultClock);
   SyncBitIfc#(Bit#(1)) resetSeenBit <- mkSyncBit(b2c_pcie_sys_reset_n.c, b2c_pcie_sys_reset_n.r, defaultClock);
   SyncBitIfc#(Bit#(1)) linkUpBit <- mkSyncBit(host.portalClock, host.portalReset, defaultClock);
   // This register is in the PCIe portal clock domain
   Reg#(Bit#(1)) resetSeenReg <- mkReg(0, clocked_by b2c_pcie_sys_reset_n.c, reset_by b2c_pcie_sys_reset_n.r);

   // instantiate zynq-side user portals
   ZynqPcieTestIndicationProxy zynqPcieTestIndicationProxy <- mkZynqPcieTestIndicationProxy(IfcNames_ZynqPcieTestIndication);
   ZynqPcieTest zynqPcieTest <- mkZynqPcieTest(linkUpBit, resetBit, resetSeenBit, zynqPcieTestIndicationProxy.ifc);
   ZynqPcieTestRequestWrapper zynqPcieTestRequestWrapper <- mkZynqPcieTestRequestWrapper(IfcNames_ZynqPcieTestRequest,zynqPcieTest.request);

   // Connect the exposed BRAM client to the trace BRAM server in the PcieHost
   mkConnectionWithClocks2(zynqPcieTest.traceBramClient, host.tpciehost.traceBramServer);

   // send the value of the lnk_up signal from the PCIE endpoint to the Zynq portal clock domain
   rule updateLinkBit;
      linkUpBit.send(host.tep7.user.lnk_up());
   endrule

   // Construct the vector of zynq portals
   Vector#(2,StdPortal) zynqPortals;
   zynqPortals[0] = zynqPcieTestIndicationProxy.portalIfc;
   zynqPortals[1] = zynqPcieTestRequestWrapper.portalIfc;
   let ctrl_mux <- mkSlaveMux(zynqPortals);
   
   // LED values
   // led0: toggles once a second as a board heartbeat
   // led1: Indicates PCIE link is up
   // led2: Indicates current value of the PCIE reset signal from the host
   // led3: Indicates that a 0-to-1 transition was detected on the PCIE reset signal from the host
   Reg#(Bit#(4)) ledsValue <- mkReg(5);
   Reg#(Bit#(32)) remainingDuration <- mkReg(100000000);

   rule updateLeds;
      let duration = remainingDuration;
      let bits = ledsValue;
      bits[3] = resetSeenBit.read();
      bits[2] = resetBit.read();
      bits[1] = linkUpBit.read();
      
      if (duration == 0) begin
	 bits[0] = ~bits[0];
	 duration = 100000000;
      end
      else begin
	 duration = duration - 1;
      end
      ledsValue <= bits;
      remainingDuration <= duration;
   endrule

   //
   // Instantiate Simple portals as the test case connected to the x86 host via PCIe
   //
   SimpleProxy simpleIndicationProxy <- mkSimpleProxy(IfcNames_SimpleIndication, clocked_by host.portalClock, reset_by host.portalReset);
   Simple simpleRequest <- mkSimple(simpleIndicationProxy.ifc, clocked_by host.portalClock, reset_by host.portalReset);
   SimpleWrapper simpleRequestWrapper <- mkSimpleWrapper(IfcNames_SimpleRequest,simpleRequest, clocked_by host.portalClock, reset_by host.portalReset);
   
   Vector#(2,StdPortal) pcieportals;
   pcieportals[0] = simpleIndicationProxy.portalIfc;
   pcieportals[1] = simpleRequestWrapper.portalIfc;
   PhysMemSlave#(32,32) pcie_ctrl_mux <- mkSlaveMux(pcieportals, clocked_by host.portalClock, reset_by host.portalReset);
   // manually connect the PCIe host PhysMemMaster to the pcie_ctrl_mux PhysMemSlave
   mkConnection(host.tpciehost.master, pcie_ctrl_mux, clocked_by host.portalClock, reset_by host.portalReset);

   // Construct the ZynqPcie interface
   ZynqPcie zpcie = (interface ZynqPcie;
		     method Action pcie_sys_clk(Bit#(1) p, Bit#(1) n);

		        // This is a bit of sleight of hand. We depend
		        // on the way the bluespec compiler generates
		        // verilog for the following method invocation
		        // to connect the input clock signals via the
		        // B2C to the 100Mhz pcie system clock input
		        // of the PcieHost.
			b2c_pcie_sys_clk_p.inputclock(p);
			b2c_pcie_sys_clk_n.inputclock(n);
		     endmethod
		     method Action sys_clk(Bit#(1) p, Bit#(1) n);
			// same for the 200MHz system clock
			b2c_sys_clk_p.inputclock(p);
			b2c_sys_clk_n.inputclock(n);
		     endmethod
		     method Action pcie_sys_reset(Bit#(1) n);
			if (n == 1)
			   resetSeenReg <= 1;
			resetSeenBit.send(resetSeenReg);
			resetBit.send(n);
			// same for the reset
			b2c_pcie_sys_reset_n.inputreset(n);
		     endmethod
		     interface pcie = host.tep7.pcie;
		     // The Bluespec compiler requires that the clocks
		     // used by exported methods/pins also be
		     // exposed. Because of the b2c, some of the clock
		     // pins were not visible to the compiler, so we
		     // export them here.
		     //
		     // We do not have FPGA pins to which we want to
		     // connect them, so we rename them
		     // "deleteme_unused_clock..." so that the
		     // synthesis script will disconnect them from the
		     // ports of the toplevel netlist.
		     interface Clock deleteme_unused_clockFoo = b2c_pcie_sys_reset_n.c;
		     interface Clock deleteme_unused_clockPortal = host.portalClock;
		     interface Clock deleteme_unused_clock100mhz = host.tpci_clk_100mhz_buf;
		     endinterface);

   // connect the standard LEDS interface
   //LEDS ledsIF = (interface LEDS; method Bit#(LedsWidth) leds(); return truncate(ledsValue); endmethod endinterface);

   // export the interfaces from the Zynq portals
   interface interrupt = getInterruptVector(zynqPortals);
   interface slave = ctrl_mux;
   interface masters = nil;
   //interface leds = ledsIF;
   // expose the pcie interface as pins
   interface pins = zpcie;
endmodule : mkConnectalTop
