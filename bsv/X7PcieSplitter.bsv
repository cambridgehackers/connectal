
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
import AxiCsr          :: *;
//import XbsvXilinx7DDR3      :: *;

import Connectable       ::*;
import GetPut            ::*;
import Reserved          ::*;
import DefaultValue      ::*;
import DReg              ::*;
import Gearbox           ::*;
import FIFO              ::*;
import FIFOF             ::*;
import SpecialFIFOs      ::*;

// from SceMiDefines
typedef 4 BPB;

// Interface wrapper for PCIE
interface X7PcieSplitter#(numeric type lanes);
   interface PciewrapPci_exp#(lanes) pcie;
   (* always_ready *)
   method Bit#(1)  isLinkUp();
   //method Bool isCalibrated();
   method PciId    pciId();
   interface Clock clock250;
   interface Reset reset250;
   interface Clock clock125;
   interface Reset reset125;
   interface Clock clock200;
   interface Reset reset200;
   //(* prefix = "" *)
   //interface DDR3_Pins_X7      ddr3;
   interface PcieBridge brif;
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
   provisos(Add#(1,_,lanes));

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
   FIFO#(TLPData#(8))          inFifo              <- mkFIFO(clocked_by epClock250, reset_by epReset250);
   // Connections between TLPData#(16) and a PCIE endpoint, using a gearbox
   // to match data rates between the endpoint and design clocks.
   Gearbox#(1, 2, TLPData#(8)) fifoRxData          <- mk1toNGearbox(epClock250, epReset250, epClock125, epReset125);
   Reg#(Bool)                  rOddBeat            <- mkRegA(False, clocked_by epClock250, reset_by epReset250);
   Reg#(Bool)                  rSendInvalid        <- mkRegA(False, clocked_by epClock250, reset_by epReset250);
   FIFO#(TLPData#(8))          outFifo             <- mkFIFO(clocked_by epClock250, reset_by epReset250);
   Gearbox#(2, 1, TLPData#(8)) fifoTxData          <- mkNto1Gearbox(epClock125, epReset125, epClock250, epReset250);

   rule accept_data1;
      let data <- _ep.recv();
      inFifo.enq(data);
   endrule

   rule process_incoming_packets1(!rSendInvalid);
      let data = inFifo.first; inFifo.deq;
      rOddBeat     <= !rOddBeat;
      rSendInvalid <= !rOddBeat && data.eof;
      Vector#(1, TLPData#(8)) v = defaultValue;
      v[0] = data;
      fifoRxData.enq(v);
   endrule

   rule send_invalid_packets1(rSendInvalid);
      rOddBeat     <= !rOddBeat;
      rSendInvalid <= False;
      Vector#(1, TLPData#(8)) v = defaultValue;
      v[0].eof = True;
      v[0].be  = 0;
      fifoRxData.enq(v);
   endrule

   rule send_data1;
      function TLPData#(16) combine(Vector#(2, TLPData#(8)) in);
         return TLPData {sof:   in[0].sof, eof:   in[1].eof, hit:   in[0].hit,
                         be:    { in[0].be,   in[1].be },
                         data:  { in[0].data, in[1].data } };
      endfunction
      fifoRxData.deq;
      bridge.inFromPci.put(combine(fifoRxData.first));
   endrule

   rule get_data;
      function Vector#(2, TLPData#(8)) split(TLPData#(16) in);
         Vector#(2, TLPData#(8)) v = defaultValue;
         v[0].sof  = in.sof;
         v[0].eof  = (in.be[7:0] == 0) ? in.eof : False;
         v[0].hit  = in.hit;
         v[0].be   = in.be[15:8];
         v[0].data = in.data[127:64];
         v[1].sof  = False;
         v[1].eof  = in.eof;
         v[1].hit  = in.hit;
         v[1].be   = in.be[7:0];
         v[1].data = in.data[63:0];
         return v;
      endfunction

      let data <- bridge.outToPci.get;
      fifoTxData.enq(split(data));
   endrule

   rule process_outgoing_packets;
      let data = fifoTxData.first; fifoTxData.deq;
      outFifo.enq(head(data));
   endrule

   rule send_data;
      let data = outFifo.first; outFifo.deq;
      // filter out TLPs with 00 byte enable
      if (data.be != 0)
         _ep.xmit(data);
   endrule

   //SyncFIFOIfc#(MemoryRequest#(32,256)) fMemReq <- mkSyncFIFO(1, clk, rst_n, ddr3clk);
   //SyncFIFOIfc#(MemoryResponse#(256))   fMemResp <- mkSyncFIFO(1, ddr3clk, ddr3rstn, clk);

   //let memclient = interface Client;
   //		      interface request  = toGet(fMemReq);
   //		      interface response = toPut(fMemResp);
   //		   endinterface;
			 
   //mkConnection( memclient, ddr3_ctrl.user, clocked_by ddr3clk, reset_by ddr3rstn );

   interface pcie     = _ep.pcie;
   //interface ddr3     = ddr3_ctrl.ddr3;
   interface PcieBridge brif = bridge.brif;
   method    PciId       pciId();
      return my_pciId;
   endmethod
   interface clock250 = epClock250;
   interface reset250 = epReset250;
   interface clock125 = epClock125;
   interface reset125 = epReset125;
   interface clock200 = sys_clk_200mhz_buf;
   interface reset200 = sys_clk_200mhz_reset;

   method isLinkUp    = _ep.user.lnk_up();
//   method Bool isCalibrated  = ddr3_ctrl.user.init_done;
   interface Vector msixEntry = bridge.msixEntry;
   
endmodule: mkX7PcieSplitter
