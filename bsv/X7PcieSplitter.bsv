
// Copyright (c) 2008- 2009 Bluespec, Inc.  All rights reserved.
// $Revision$
// $Date$
// Copyright (c) 2013 Quanta Research Cambridge, Inc.

// PCI-Express for Xilinx 7
// FPGAs.

import Vector          :: *;
import GetPut          :: *;
import PCIE            :: *;
import Clocks          :: *;
import DefaultValue    :: *;
import TieOff          :: *;
import XilinxCells     :: *;
import PcieSplitter :: *;
import XbsvXilinx7Pcie :: *;
import PCIEWRAPPER     :: *;
import PcieConnection  :: *;
import AxiCsr          :: *;
//import XbsvXilinx7DDR3      :: *;

// from SceMiDefines
typedef 4 BPB;

// Interface wrapper for PCIE
interface X7PcieSplitter#(numeric type lanes);
   interface PciewrapPci_exp#(lanes) pcie;
   (* always_ready *)
   method Bool isLinkUp();
   //method Bool isCalibrated();
   interface Clock clock250;
   interface Reset reset250;
   interface Clock clock125;
   interface Reset reset125;
   interface Clock clock200;
   interface Reset reset200;
   (* prefix = "" *)
   //interface DDR3_Pins_X7      ddr3;
   interface GetPut#(TLPData#(16)) master; // to the portal dma
   interface GetPut#(TLPData#(16)) slave;  // to the portal control
   interface Put#(TimestampedTlpData) trace;
   interface Reset portalReset;
   interface ReadOnly#(PciId) pciId;
   interface Vector#(16, MSIX_Entry) msixEntry;
endinterface

// This module builds the transactor hierarchy, the clock
// generation logic and the PCIE-to-port logic.
(* no_default_clock, no_default_reset *)
//, synthesize *)
module mkX7PcieSplitter#( Clock pci_sys_clk_p, Clock pci_sys_clk_n
		       , Clock sys_clk_p,    Clock sys_clk_n
		       , Reset pci_sys_reset
		       )
		       (X7PcieSplitter#(lanes))
   provisos(Add#(1,_,lanes), XbsvXilinx7Pcie::MkXilinx7PCIE#(lanes));

   Clock sys_clk_200mhz <- mkClockIBUFDS(sys_clk_p, sys_clk_n);
   Clock sys_clk_200mhz_buf <- mkClockBUFG(clocked_by sys_clk_200mhz);
   Reset sys_clk_200mhz_reset <- mkAsyncReset(2, pci_sys_reset, sys_clk_200mhz_buf);

   ClockGenerator7Params clk_params = defaultValue();
   clk_params.clkin1_period     = 5.000;       // 200 MHz reference
   clk_params.clkin_buffer      = False;       // necessary buffer is instanced above
   clk_params.reset_stages      = 0;           // no sync on reset so input clock has pll as only load
   clk_params.clkfbout_mult_f   = 5.000;       // 1000 MHz VCO
   clk_params.clkout0_divide_f  = 10;          // unused clock 
   clk_params.clkout1_divide    = 5;           // ddr3 reference clock (200 MHz)

   ClockGenerator7 clk_gen <- mkClockGenerator7(clk_params, clocked_by sys_clk_200mhz, reset_by pci_sys_reset);

   Clock clk = clk_gen.clkout0;
   Reset rst_n <- mkAsyncReset( 1, pci_sys_reset, clk );
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
   XbsvXilinx7Pcie::PCIExpressX7#(lanes) _ep
       <- XbsvXilinx7Pcie::mkPCIExpressEndpointX7( defaultValue
						  , clocked_by pci_clk_100mhz_buf
						  , reset_by pci_sys_reset
						  );
   // note our PCI ID
   PciId my_id = PciId { bus:  _ep.zz1cfg.bus_number()
		       , dev:  _ep.zz1cfg.device_number()
		       , func: _ep.zz1cfg.function_number()
		       };

   // The PCIE endpoint is processing TLPWord#(8)s at 250MHz.  The
   // AXI bridge is accepting TLPWord#(16)s at 125 MHz. The
   // connection between the endpoint and the AXI contains GearBox
   // instances for the TLPWord#(8)@250 <--> TLPWord#(16)@125
   // conversion.

   // The PCIe endpoint exports full (250MHz) and half-speed (125MHz) clocks
   Clock epClock250 = _ep.trn.clk;
   Reset epReset250 <- mkAsyncReset(4, _ep.trn.reset_n, epClock250);
   Clock epClock125 = _ep.trn.clk2;
   Reset epReset125 <- mkAsyncReset(4, _ep.trn.reset_n, epClock125);

   // Extract some status info from the PCIE endpoint. These values are
   // all in the epClock250 domain, so we have to cross them into the
   // epClock125 domain.

   Bool link_is_up = (_ep.trn.link_up() != 0);
   UInt#(8)  read_completion_boundary_250 = 64 << _ep.zz1cfg.lcommand[3];

   // Build the PCIe-to-AXI bridge
   PcieSplitter#(BPB)  bridge <- mkPcieSplitter(my_id, clocked_by epClock125, reset_by epReset125);
   mkConnectionWithClocks(_ep.trn_rx, tpl_2(bridge.tlps), epClock250, epReset250, epClock125, epReset125);
   mkConnectionWithClocks(_ep.trn_tx, tpl_1(bridge.tlps), epClock250, epReset250, epClock125, epReset125);

   //SyncFIFOIfc#(MemoryRequest#(32,256)) fMemReq <- mkSyncFIFO(1, clk, rst_n, ddr3clk);
   //SyncFIFOIfc#(MemoryResponse#(256))   fMemResp <- mkSyncFIFO(1, ddr3clk, ddr3rstn, clk);

   //let memclient = interface Client;
   //		      interface request  = toGet(fMemReq);
   //		      interface response = toPut(fMemResp);
   //		   endinterface;
			 
   //mkConnection( memclient, ddr3_ctrl.user, clocked_by ddr3clk, reset_by ddr3rstn );

   interface pcie     = _ep.pcie;
   //interface ddr3     = ddr3_ctrl.ddr3;
   interface master   = bridge.master;
   interface slave    = bridge.slave;
   interface trace    = bridge.trace;
   interface portalReset = bridge.portalReset;
   interface ReadOnly pciId;
      method PciId _read();
         return my_id;
      endmethod
   endinterface
   interface clock250 = epClock250;
   interface reset250 = epReset250;
   interface clock125 = epClock125;
   interface reset125 = epReset125;
   interface clock200 = sys_clk_200mhz_buf;
   interface reset200 = sys_clk_200mhz_reset;

   method Bool isLinkUp        = link_is_up;
//   method Bool isCalibrated  = ddr3_ctrl.user.init_done;
   interface Vector msixEntry = bridge.msixEntry;
   
endmodule: mkX7PcieSplitter
