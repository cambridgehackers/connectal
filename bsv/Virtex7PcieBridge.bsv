// Copyright (c) 2008- 2009 Bluespec, Inc.  All rights reserved.
// $Revision$
// $Date$
// Copyright (c) 2013 Quanta Research Cambridge, Inc.

package Virtex7PcieBridge;

// PCI-Express for Virtex 7
// FPGAs.

import Clocks               :: *;
import Connectable          :: *;
import TieOff               :: *;
import DefaultValue         :: *;
import BUtils               :: *;
import Xilinx               :: *;
import XilinxPCIE           :: *;
import XilinxCells          :: *;
import GetPut               :: *;
import ClientServer         :: *;
import Memory               :: *;
import BlueNoC              :: *;
import PcieToAxiBridge      :: *;
import XbsvXilinxVirtex7Pcie :: *;
import XilinxVirtex7DDR3    :: *;
import AxiMasterSlave       :: *;
// from SceMiDefines
typedef 4 BPB;

// Interface wrapper for PCIE
interface V7PcieBridgeIfc#(numeric type lanes);
   interface PCIE_EXP#(lanes) pcie;
   (* always_ready *)
   method Bool isLinkUp();
   method Bool isCalibrated();
   (* always_ready *)
   method Action interrupt();
   interface Clock clock250;
   interface Reset reset250;
   interface Clock clock125;
   interface Reset reset125;
   (* prefix = "" *)
   //interface DDR3_Pins_V7      ddr3;
   interface Axi3Master#(32,32,4,12) portal0;
   interface GetPut#(TLPData#(16)) slave; // to the axi slave engine
   interface Put#(TimestampedTlpData) trace;
   interface Reg#(Bit#(4)) numPortals;
   interface ReadOnly#(PciId) pciId;
endinterface

// This module builds the transactor hierarchy, the clock
// generation logic and the PCIE-to-port logic.
(* no_default_clock, no_default_reset *)
module mkV7PcieBridge#( Clock pci_sys_clk_p, Clock pci_sys_clk_n
		       , Clock sys_clk_p,    Clock sys_clk_n
		       , Reset pci_sys_reset
                       , Bit#(64) contentId
		       )
		       (V7PcieBridgeIfc#(lanes))
   provisos(Add#(1,_,lanes), XbsvXilinxVirtex7Pcie::SelectVirtex7PCIE#(lanes));

   if (valueOf(lanes) != 8)
      errorM("Only 8-lane PCIe is supported on V7.");

   Clock sys_clk <- mkClockIBUFDS(sys_clk_p, sys_clk_n);

   ClockGenerator7Params clk_params = defaultValue();
   clk_params.clkin1_period     = 5.000;       // 200 MHz reference
   clk_params.clkin_buffer      = False;       // necessary buffer is instanced above
   clk_params.reset_stages      = 0;           // no sync on reset so input clock has pll as only load
   clk_params.clkfbout_mult_f   = 5.000;       // 1000 MHz VCO
   clk_params.clkout0_divide_f  = `SCEMI_CLOCK_PERIOD;
   clk_params.clkout1_divide    = 5;           // ddr3 reference clock (200 MHz)

   ClockGenerator7 clk_gen <- mkClockGenerator7(clk_params, clocked_by sys_clk, reset_by pci_sys_reset);

   Clock clk = clk_gen.clkout0;
   Reset rst_n <- mkAsyncReset( 1, pci_sys_reset, clk );
   Reset ddr3ref_rst_n <- mkAsyncReset( 1, rst_n, clk_gen.clkout1 );
   
   DDR3_Configure_V7 ddr3_cfg;
   ddr3_cfg.num_reads_in_flight = 2;   // adjust as needed
   ddr3_cfg.fast_train_sim_only = False; // adjust if simulating
   
   //DDR3_Controller_V7 ddr3_ctrl <- mkVirtex7DDR3Controller(ddr3_cfg, clocked_by clk_gen.clkout1, reset_by ddr3ref_rst_n);

   // ddr3_ctrl.user needs to connect to user logic and should use ddr3clk and ddr3rstn
   //Clock ddr3clk = ddr3_ctrl.user.clock;
   //Reset ddr3rstn = ddr3_ctrl.user.reset_n;
   
   // Buffer clocks and reset before they are used
   Clock pci_sys_clk_buf <- mkClockIBUFDS_GTE2(True, pci_sys_clk_p, pci_sys_clk_n);

   // Instantiate the PCIE endpoint
   XbsvXilinxVirtex7Pcie::PCIExpressV7#(lanes) _ep
       <- XbsvXilinxVirtex7Pcie::mkPCIExpressEndpointV7( defaultValue
						      , clocked_by pci_sys_clk_buf
						      , reset_by pci_sys_reset
						      );
   mkTieOff(_ep.cfg);
   mkTieOff(_ep.cfg_interrupt);
   mkTieOff(_ep.cfg_err);
   mkTieOff(_ep.pl);

   // note our PCI ID
   PciId my_id = PciId { bus:  _ep.cfg.bus_number()
		       , dev:  _ep.cfg.device_number()
		       , func: _ep.cfg.function_number()
		       };

   // The PCIE endpoint is processing TLPWord#(8)s at 250MHz.  The
   // NoC bridge is accepting TLPWord#(16)s at 125 MHz. The
   // connection between the endpoint and the NoC contains GearBox
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

   Bool link_is_up = _ep.trn.link_up();
   UInt#(13) max_read_req_bytes_250       = 128 << _ep.cfg.dcommand[14:12];
   UInt#(13) max_payload_bytes_250        = 128 << _ep.cfg.dcommand[7:5];
   UInt#(8)  read_completion_boundary_250 = 64 << _ep.cfg.lcommand[3];
   Bool      msix_enable_250              = (_ep.cfg_interrupt.msixenable() == 1);
   Bool      msix_masked_250              = (_ep.cfg_interrupt.msixfm()     == 1);

   CrossingReg#(UInt#(13)) max_rd_req_cr  <- mkNullCrossingReg(epClock125, 128,   clocked_by epClock250, reset_by epReset250);
   CrossingReg#(UInt#(13)) max_payload_cr <- mkNullCrossingReg(epClock125, 128,   clocked_by epClock250, reset_by epReset250);
   CrossingReg#(UInt#(8))  rcb_cr         <- mkNullCrossingReg(epClock125, 128,   clocked_by epClock250, reset_by epReset250);
   CrossingReg#(Bool)      msix_enable_cr <- mkNullCrossingReg(epClock125, False, clocked_by epClock250, reset_by epReset250);
   CrossingReg#(Bool)      msix_masked_cr <- mkNullCrossingReg(epClock125, True,  clocked_by epClock250, reset_by epReset250);

   Reg#(UInt#(13)) max_read_req_bytes <- mkReg(128,   clocked_by epClock125, reset_by epReset125);
   Reg#(UInt#(13)) max_payload_bytes  <- mkReg(128,   clocked_by epClock125, reset_by epReset125);
   Reg#(Bit#(7))   rcb_mask           <- mkReg(7'h3f, clocked_by epClock125, reset_by epReset125);
   Reg#(Bool)      msix_enable        <- mkReg(False, clocked_by epClock125, reset_by epReset125);
   Reg#(Bool)      msix_masked        <- mkReg(True,  clocked_by epClock125, reset_by epReset125);

   (* fire_when_enabled, no_implicit_conditions *)
   rule cross_config_values;
      max_rd_req_cr  <= max_read_req_bytes_250;
      max_payload_cr <= max_payload_bytes_250;
      rcb_cr         <= read_completion_boundary_250;
      msix_enable_cr <= msix_enable_250;
      msix_masked_cr <= msix_masked_250;
   endrule

   (* fire_when_enabled, no_implicit_conditions *)
   rule register_config_values;
      max_read_req_bytes <= max_rd_req_cr.crossed();
      max_payload_bytes  <= max_payload_cr.crossed();
      rcb_mask           <= (rcb_cr.crossed() == 64) ? 7'h3f : 7'h7f;
      msix_enable        <= msix_enable_cr.crossed();
      msix_masked        <= msix_masked_cr.crossed();
   endrule

   // setup PCIe interrupt for MSI-X
   // this rule executes in the epClock250 domain
   (* fire_when_enabled, no_implicit_conditions *)
   rule intr_ifc_ctl;
      _ep.cfg_interrupt.di('0);      // tied off for MSI-X
      _ep.cfg_interrupt.assrt('0);  // tied off for MSI-X
      _ep.cfg_interrupt.req(0);      // tied off for MSI-X
   endrule: intr_ifc_ctl

   // Build the PCIe-to-NoC bridge
   PcieToAxiBridge#(BPB)  bridge <- mkPcieToAxiBridge_4( contentId
						       , my_id
						       , max_read_req_bytes
						       , max_payload_bytes
						       , rcb_mask
						       , msix_enable
						       , msix_masked
						       , False // no MSI, only MSI-X
						       , clocked_by epClock125, reset_by epReset125
						       );
   mkConnectionWithClocks(_ep.trn_rx, tpl_2(bridge.tlps), epClock250, epReset250, epClock125, epReset125);
   mkConnectionWithClocks(_ep.trn_tx, tpl_1(bridge.tlps), epClock250, epReset250, epClock125, epReset125);

   //mkConnection(_dut.noc_src,bridge.noc);
   mkTieOff(bridge.noc);

   //SyncFIFOIfc#(MemoryRequest#(32,256)) fMemReq <- mkSyncFIFO(1, clk, rst_n, ddr3clk);
   //SyncFIFOIfc#(MemoryResponse#(256))   fMemResp <- mkSyncFIFO(1, ddr3clk, ddr3rstn, clk);

   //let memclient = interface Client;
   //		      interface request  = toGet(fMemReq);
   //		      interface response = toPut(fMemResp);
   //		   endinterface;
			 
   //mkConnection( memclient, ddr3_ctrl.user, clocked_by ddr3clk, reset_by ddr3rstn );

   interface pcie     = _ep.pcie;
   //interface ddr3     = ddr3_ctrl.ddr3;
   interface portal0  = bridge.portal0;
   interface slave    = bridge.slave;
   interface trace    = bridge.trace;
   interface numPortals = bridge.numPortals;
   interface ReadOnly pciId;
      method PciId _read();
         return my_id;
      endmethod
   endinterface
   interface clock250 = epClock250;
   interface reset250 = epReset250;
   interface clock125 = epClock125;
   interface reset125 = epReset125;

   method Bool isLinkUp        = link_is_up;
//   method Bool isCalibrated  = ddr3_ctrl.user.init_done;
   method Action interrupt     = bridge.interrupt;
   
endmodule: mkV7PcieBridge

instance Connectable#(MemoryClient#(32, 256), DDR3_User_V7);
   module mkConnection#(MemoryClient#(32, 256) client, DDR3_User_V7 ddr3)(Empty);
      rule connect_requests;
	 let request <- client.request.get;
	 Bit#(28) address = truncate(request.address) << 2;
	 Bool     addrhi  = unpack(request.address[0]);
	 Bit#(64) writeen = addrhi ? zeroExtend(request.byteen) << 32 : zeroExtend(request.byteen);
	 Bit#(512) datain = duplicate(request.data);
	 if (request.write) begin
	    ddr3.request(address, writeen, datain);
	 end
	 else begin
	    ddr3.request(address, 0, ?);
	 end
      endrule
      
      rule connect_responses;
	 let response <- ddr3.read_data;
	 Bit#(256) data = truncate(response);
	 client.response.put(unpack(data));
      endrule
   endmodule
endinstance

endpackage: Virtex7PcieBridge
