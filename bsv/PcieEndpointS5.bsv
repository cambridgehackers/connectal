// Copyright (c) 2014 Cornell University

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

package PcieEndpointS5;

import ConnectalConfig   ::*;
import Clocks            ::*;
import Vector            ::*;
import Connectable       ::*;
import GetPut            ::*;
import Reserved          ::*;
import TieOff            ::*;
import DefaultValue      ::*;
import DReg              ::*;
import Gearbox           ::*;
import FIFO              ::*;
import FIFOF             ::*;
import SpecialFIFOs      ::*;
import ClientServer      ::*;
import Real              ::*;

import PCIE              ::*;

`include "ConnectalProjectConfig.bsv"

`ifdef BOARD_de5
import PS5LIB            ::*;
`elsif BOARD_vsim
import PS5LIB            ::*;
//import PcieEndpointS5Test ::*;
`elsif BOARD_htg4
import PS4LIB            ::*;
`endif

(* always_ready, always_enabled *)
interface PciewrapPci_exp#(numeric type lanes);
(* prefix="", result="tx_p" *) method Bit#(lanes) tx_p();
(* prefix="", result="rx_p" *) method Action rx_p(Bit#(lanes) rx_p);
endinterface

(* always_ready, always_enabled *)
interface PciewrapUser#(numeric type lanes);
   interface Clock clk_out;
endinterface

(* always_ready, always_enabled *)
interface PciewrapCfg#(numeric type lanes);
   method Bit#(8) bus_number();
   method Bit#(5) device_number();
   method Bit#(3) function_number();
endinterface

////////////////////////////////////////////////////////////////////////////////
/// Interfaces
////////////////////////////////////////////////////////////////////////////////

interface PcieEndpointS5#(numeric type lanes);
   interface PciewrapPci_exp#(lanes)   pcie;
   interface PciewrapUser#(lanes)      user;
   interface Server#(TLPData#(16), TLPData#(16)) tlp;
`ifdef VSIM
   interface PcieHipPipe pipe;
`endif
   interface Clock epPcieClock;
   interface Reset epPcieReset;
   interface Clock epPortalClock;
   interface Reset epPortalReset;
   interface Clock epDerivedClock;
   interface Reset epDerivedReset;
   method PciId device;
endinterface

typedef struct {
   Bit#(1)               sop;
   Bit#(1)               eop;
   Bit#(7)               hit;
   Bit#(bytes)           be;
   Bit#(TMul#(bytes, 8)) data;
} AvalonStRx#(type bytes) deriving (Bits, Eq);

typedef struct {
   Bit#(1)               sop;
   Bit#(1)               eop;
   Bit#(bytes)           be;
   Bit#(TMul#(bytes, 8)) data;
} AvalonStTx#(type bytes) deriving (Bits, Eq);

(* synthesize *)
module mkPcieEndpointS5#(Clock clk_100MHz, Clock clk_50MHz, Reset perst_n)(PcieEndpointS5#(PcieLanes));

   PCIEParams params = defaultValue;

   Clock default_clock <- exposeCurrentClock;
   Reset default_reset <- exposeCurrentReset;
   Reset reset_high <- invertCurrentReset;
   Reset npor = perst_n; //No soft reset signal from Application

`ifdef BOARD_de5
   PcieWrap#(12, 32, 128) pcie_ep <- mkPcieS5Wrap(clk_100MHz, clk_50MHz, npor, perst_n);
`elsif BOARD_htg4
   PcieWrap#(12, 32, 128) pcie_ep <- mkPcieS4Wrap(clk_100MHz, clk_50MHz, clk_100MHz, npor, perst_n);
`endif

`ifdef BOARD_vsim
   PcieWrap#(12, 32, 128) pcie_ep <- mkPcieS5Wrap(clk_100MHz, clk_50MHz, npor, perst_n);
`endif

   Clock core_clk = pcie_ep.coreclkout_hip;
   Reset core_reset = pcie_ep.core_reset;
   Reset core_resetn <- mkResetInverter(pcie_ep.core_reset, clocked_by core_clk);

   Reg#(PciId) deviceReg <- mkReg(?, clocked_by core_clk, reset_by core_resetn);

   FIFOF#(AvalonStTx#(16)) fAvalonStTx <- mkBypassFIFOF(clocked_by core_clk, reset_by noReset);
   FIFOF#(AvalonStRx#(16)) fAvalonStRx <- mkBypassFIFOF(clocked_by core_clk, reset_by noReset);

   let txready = (pcie_ep.tx_st.ready != 0 && fAvalonStTx.notEmpty);

   function Bit#(2) getTxStEmpty (Bit#(16) be);
      if (be == 16'h000f || be == 16'h00ff) begin
         return 2'b1;
      end
      else begin
         return 2'b0;
      end
   endfunction

   rule drive_avalon_tx if (txready);
      let info = fAvalonStTx.first; fAvalonStTx.deq;
      pcie_ep.tx_st.valid(1);
      pcie_ep.tx_st.sop(info.sop);
      pcie_ep.tx_st.eop(info.eop);
      let txStEmpty = getTxStEmpty(info.be);
`ifdef BOARD_de5
      pcie_ep.tx_st.empty(txStEmpty);
`elsif BOARD_htg4
      pcie_ep.tx_st.empty(txStEmpty[0]);
`endif
      pcie_ep.tx_st.err(0);
      pcie_ep.tx_st.data(info.data);
   endrule

   (* fire_when_enabled, no_implicit_conditions *)
   rule drive_avalon_tx2 if (!txready);
      pcie_ep.tx_st.valid(0);
      pcie_ep.tx_st.sop(0);
      pcie_ep.tx_st.eop(0);
      pcie_ep.tx_st.empty(0);
      pcie_ep.tx_st.err(0);
      pcie_ep.tx_st.data(0);
   endrule

   (* fire_when_enabled *)
   rule sink_avalon_rx if (pcie_ep.rx_st.valid != 0);
      AvalonStRx#(16) beat;
      beat.sop = pcie_ep.rx_st.sop;
      beat.eop = pcie_ep.rx_st.eop;
      beat.be  = pcie_ep.rx_st.be;
      // bar[7] is reserved for endpoints.
      beat.hit = pcie_ep.rx_st.bar[6:0];

      // 128-bit interface
      // when rx_st_empty==1, rx_st_data[63:0] are valid
      if (pcie_ep.rx_st.empty[0] == 1 && pcie_ep.rx_st.eop == 1) begin
         if (pcie_ep.rx_st.be == 16'h000f) begin
            beat.data = {96'h0, pcie_ep.rx_st.data[31:0]};
         end
         else if (pcie_ep.rx_st.be == 16'h00ff) begin
            beat.data = {64'h0, pcie_ep.rx_st.data[63:0]};
         end
         else begin
            beat.data = pcie_ep.rx_st.data;
         end
      end
      // else, rx_st_data[127:0] are valid
      else begin
         beat.data = pcie_ep.rx_st.data;
      end
      // 256-bit interface requires a more complex decoder.
      fAvalonStRx.enq(beat);
   endrule

   rule pertick1;
      pcie_ep.rx_st.ready(pack(fAvalonStRx.notFull));
      //pcie_ep.hip_rst.core_ready(pcie_ep.hip_rst.serdes_pll_locked);
   endrule

   rule every1;
      pcie_ep.hip_ctrl.test_in({26'h2, 1'b1, 5'b01000});
   endrule

   rule capture_deviceid(pcie_ep.tl_cfg.add == 4'hF);
      deviceReg <= PciId {bus: pcie_ep.tl_cfg.ctl[12:5],
                          dev: pcie_ep.tl_cfg.ctl[4:0],
                          func: 0};
   endrule

   // The PCIE endpoint is processing TLPData#(16)s at 125MHz.  The
   // AXI bridge is accepting TLPData#(16)s at 125 MHz. For gen1 and
   // gen2, there is no need for gearbox conversion.
   // coreclkout_hip depends on link width, data rate and width of APP/TL interface
   // Link Width  |  Link Rate  |   Avalon Interface Width  |  coreclkout_hip
   //     x8            gen1                128 bit               125 Mhz
   //     x8            gen2                128 bit               250 Mhz
   //     x8            gen3                256 bit               250 Mhz
   Server#(TLPData#(16), TLPData#(16)) tlp16 = (interface Server;
      interface Put request;
         method Action put(TLPData#(16) data);
            fAvalonStTx.enq(AvalonStTx {
               eop: pack(data.eof),
               sop: pack(data.sof),
               be:  dwordSwap128BE(data.be),
               data: dwordSwap128(data.data)
            });
         endmethod
      endinterface
      interface Get response;
         method ActionValue#(TLPData#(16)) get();
            let info <- toGet(fAvalonStRx).get;
            TLPData#(16) retval = defaultValue;
            retval.sof = (info.sop == 1);
            retval.eof = (info.eop == 1);
            retval.be  = dwordSwap128BE(info.be);
            retval.hit = info.hit;
            retval.data = dwordSwap128(info.data);
            return retval;
         endmethod
      endinterface
   endinterface);

   method PciId device = deviceReg;

   interface PciewrapUser user;
      method Clock clk_out();
         return core_clk;
      endmethod
   endinterface

   interface PciewrapPci_exp pcie;
      Bit#(PcieLanes) vt = pack(pcie_ep.tx.out);
      method Bit#(PcieLanes) tx_p();
         return vt;
      endmethod
      method Action rx_p(Bit#(PcieLanes) v);
         action
            pcie_ep.rx.in(unpack(v));
         endaction
      endmethod
   endinterface


   interface tlp = tlp16;
   interface Clock epPcieClock = core_clk;
   interface Reset epPcieReset = core_resetn;
   interface Clock epPortalClock = core_clk;
   interface Reset epPortalReset = core_resetn;
   //FIXME: verify derivedClock value
   interface Clock epDerivedClock = core_clk;
   interface Reset epDerivedReset = core_resetn;

`ifdef VSIM
   interface pipe = pcie_ep.hip_pipe;
`endif

endmodule: mkPcieEndpointS5

endpackage: PcieEndpointS5
