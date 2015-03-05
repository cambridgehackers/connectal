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
import PS5LIB            ::*;
import PcieEndpointS5Test ::*;

(* always_ready, always_enabled *)
interface PciewrapPci_exp#(numeric type lanes);
(* prefix="", result="tx_p" *) method Bit#(lanes) tx_p();
(* prefix="", result="rx_p" *) method Action rx_p(Bit#(lanes) rx_p);
endinterface

(* always_ready, always_enabled *)
interface PciewrapUser#(numeric type lanes);
   interface Clock clk_out;
   interface Reset reset_out;
   method Bit#(1) lnk_up();
   method Bit#(1) app_rdy();
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
   interface PcieS5HipPipe pipe;
   interface PcieS5HipCtrl ctrl;
`endif
   interface Clock epClock125;
   interface Reset epReset125;
   interface Clock epClock250;
   interface Reset epReset250;
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

`ifdef BOARD_de5
typedef 8 PcieLanes;
typedef 4 NumLeds;
`elsif BOARD_vsim
typedef 8 PcieLanes;
typedef 4 NumLeds;
`endif

//(* synthesize *)
module mkPcieEndpointS5#(Clock clk_100MHz, Clock clk_50MHz, Reset perst_n)(PcieEndpointS5#(PcieLanes));

   PCIEParams params = defaultValue;

   Clock default_clock <- exposeCurrentClock;
   Reset default_reset <- exposeCurrentReset;
   Reset reset_high <- invertCurrentReset;
   Reset npor = perst_n; //No soft reset signal from Application

   PcieS5Wrap#(12, 32, 128) pcie_ep <- mkPcieS5Wrap(clk_100MHz, clk_50MHz, npor, perst_n);

   Clock core_clk = pcie_ep.coreclkout_hip;
   Reset core_reset = pcie_ep.core_reset;
   Reset core_resetn <- mkResetInverter(pcie_ep.core_reset, clocked_by core_clk);

   // Test Altera Application
//   PcieS5App pcie_app <- mkPcieS5App(core_clk, reset_high);
//   mkConnection(pcie_app, pcie_ep);

   AlteraPcieHipRs hip_rs <- mkAlteraPcieHipRs(core_clk, core_resetn);

   Reg#(PciId) deviceReg <- mkReg(?, clocked_by core_clk, reset_by core_resetn);

   FIFOF#(AvalonStTx#(16)) fAvalonStTx <- mkBypassFIFOF(clocked_by core_clk, reset_by noReset);
   FIFOF#(AvalonStRx#(16)) fAvalonStRx <- mkBypassFIFOF(clocked_by core_clk, reset_by noReset);

   let txready = (pcie_ep.tx_st.ready != 0 && fAvalonStTx.notEmpty);

   rule drive_avalon_tx if (txready);
      let info = fAvalonStTx.first; fAvalonStTx.deq;
      pcie_ep.tx_st.valid(1);
      pcie_ep.tx_st.sop(info.sop);
      pcie_ep.tx_st.eop(info.eop);
      pcie_ep.tx_st.empty(0); //FIXME
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
      beat.be  = pcie_ep.rx_specific.be;
      // bar[7] is reserved for endpoints.
      beat.hit = pcie_ep.rx_specific.bar[6:0];

      // 128-bit interface
      // when rx_st_empty==1, rx_st_data[63:0] are valid
      if (pcie_ep.rx_st.empty[0] == 1 && pcie_ep.rx_st.eop == 1) begin
         beat.data = {64'h0, pcie_ep.rx_st.data[63:0]};
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
      pcie_ep.hip_rst.core_ready(pcie_ep.hip_rst.serdes_pll_locked);
   endrule

   rule capture_deviceid(pcie_ep.tl.cfg_add == 4'hF);
      deviceReg <= PciId {bus: pcie_ep.tl.cfg_ctl[12:5],
                          dev: pcie_ep.tl.cfg_ctl[4:0],
                          func: 0};
   endrule

   rule pertick3;
      hip_rs.dlup_exit(pcie_ep.hip_status.dlup_exit);
      hip_rs.hotrst_exit(pcie_ep.hip_status.hotrst);
      hip_rs.l2_exit(pcie_ep.hip_status.l2_exit);
      hip_rs.ltssm(pcie_ep.hip_status.ltssmstate);
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
      method Reset reset_out;
         return hip_rs.app_rstn;
      endmethod
      method Clock clk_out();
         return core_clk;
      endmethod
      method Bit#(1) lnk_up();
         return pcie_ep.hip_rst.serdes_pll_locked;
      endmethod
      method Bit#(1) app_rdy();
         return pcie_ep.hip_rst.pld_clk_inuse;
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
   //FIXME: verify epClock250 is needed.
   interface Clock epClock250 = core_clk;
   interface Clock epReset250 = core_resetn;
   interface Clock epClock125 = core_clk;
   interface Clock epReset125 = core_resetn;

   //FIXME: verify derivedClock value
   interface Clock epDerivedClock = core_clk;
   interface Reset epDerivedReset = core_resetn;

`ifdef VSIM
   interface pipe = pcie_ep.hip_pipe;
   interface ctrl = pcie_ep.hip_ctrl;
`endif

endmodule: mkPcieEndpointS5

endpackage: PcieEndpointS5
