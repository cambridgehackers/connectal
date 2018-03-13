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

import XilinxCells::*;
import ConnectalXilinxCells::*;
import ConnectalClocks::*;
import Gearbox::*;
import Pipe::*;
import FIFO::*;
import BRAMFIFO::*;
import Vector::*;
import Clocks::*;
import DefaultValue::*;


import ExtraXilinxCells::*;

(* always_enabled *)
interface FMComms1DACPins;
   method Bit#(14) io_dac_data_p();
   method Bit#(14) io_dac_data_n();
   method Action io_dac_dco_p(Bit#(1) v);
   method Action io_dac_dco_n(Bit#(1) v);
   method Bit#(1) io_dac_dci_p();
   method Bit#(1) io_dac_dci_n();
   method Clock deleteme_unused_clock;
   method Reset deleteme_unused_reset;
endinterface

typedef struct {
   Bit#(16) data_i;
   Bit#(16) data_q;
   } OIQ deriving (Bits);

interface FMComms1DAC;
   interface FMComms1DACPins pins;
   interface PipeIn#(Bit#(64)) dac;
endinterface

/* This module drives an Analog Devices FMComms1
 * evaluation board Digital to Analog Converter, it accepts
 * the data as a PipeIn type on the default clock.
 * The FMComms1 supplies the DAC clock as a differential pair
 * 
 * Output is double data rate, with clock supplied by the FMComms1
 * Output data is 14 bits twos-complement or offset binary
 * 
 * Differential outputs are converted from single ended by using Xilinx OBUFDS
 * cells. The clock is converted to single ended by an IBUFGDS cell
 * 
 * DDR data is convered from SDR using ODDR cells
 * At this point, the data is a 14 bit in-phase data signal, 
 * plus a 14 bit quadrature signal, interleaved
 * 
 * The SDR data is a 32-bit OIQ datatype
 * 
 * The 32-bit data is converted from 64-bits by a Gearbox
 * 
 * Clock conversion happens 64-bits wide using a SyncBRAMFIFO, which
 * presents a PipeIn channel to the rest of the logic.
 */


module mkFMComms1DAC(FMComms1DAC);
   
   Clock def_clock <- exposeCurrentClock;
   Reset def_reset <- exposeCurrentReset;
   Clock dac_dco; 
   Wire#(Bit#(1)) dac_dco_p <- mkDWire(0);
   Wire#(Bit#(1)) dac_dco_n <- mkDWire(0);

   dac_dco <- mkConnectalClockIBUFDS(dac_dco_p, dac_dco_n);
   Reset dac_reset <- mkAsyncReset(3, def_reset, dac_dco);
   
   SyncFIFOIfc#(Vector#(2, OIQ)) outfifo <- mkSyncBRAMFIFO(128, def_clock, def_reset, dac_dco, dac_reset);

   Gearbox#(2, 1, OIQ) gb <- mkNto1Gearbox(dac_dco, dac_reset, dac_dco, dac_reset);
   ODDRParams#(Bit#(14)) oddrparams = defaultValue;
//   oddrparams.ddr_clk_edge = "SAME_EDGE_PIPELINED";
      oddrparams.ddr_clk_edge = "SAME_EDGE";

   ODDR#(Bit#(14)) dac_ddr <- mkODDR(oddrparams, clocked_by (dac_dco));

   Vector#(14, Wire#(Bit#(1))) dac_ddr_data <- replicateM(mkDWire(0));
   
   Vector#(14, DiffOut) dac_out = newVector;
   
   for (Integer i = 0; i < 14; i = i + 1)
      dac_out[i] <- mkxOBUFDS(dac_ddr_data[i]);
   
   C2B dac_dco_as_bit <- mkC2B(dac_dco);
   Wire#(Bit#(1)) dac_dci_wire <- mkDWire(0);
   
   rule senddown_clk;
      dac_dci_wire <= dac_dco_as_bit.o();
   endrule
   
   DiffOut dac_dci <- mkxOBUFDS(dac_dci_wire);
   
   rule senddown_gb;
      outfifo.deq();
      gb.enq(outfifo.first());
   endrule

   rule senddown_oddr;
      let d = gb.first;
      gb.deq();
      dac_ddr.d1(d[0].data_i[15:2]);
      dac_ddr.d2(d[0].data_q[15:2]);
   endrule

   rule alwaysenable;
      dac_ddr.ce(True);
      dac_ddr.s(False);
   endrule

   function Bit#(1) foo_p(DiffOut v);
      return (v.read_p());
   endfunction

   function Bit#(1) foo_n(DiffOut v);
      return (v.read_n());
   endfunction

   function Bit#(14) get_p(Vector#(14, DiffOut) v);
      return(pack(map(foo_p, v)));
   endfunction
   
   function Bit#(14) get_n(Vector#(14, DiffOut) v);
      return(pack(map(foo_n, v)));
   endfunction
   
   interface FMComms1DACPins pins;
      
      method Bit#(14) io_dac_data_p();
         return(get_p(dac_out));
      endmethod
      
      method Bit#(14) io_dac_data_n();
         return(get_n(dac_out));
      endmethod

      method Bit#(1) io_dac_dci_p();
         return(dac_dci.read_p());
      endmethod
      
      method Bit#(1) io_dac_dci_n();
         return(dac_dci.read_n());
      endmethod

      method Action io_dac_dco_p(Bit#(1) v);
	 dac_dco_p <= v;
      endmethod
      
      method Action io_dac_dco_n(Bit#(1) v);
	 dac_dco_n <= v;
      endmethod
      interface deleteme_unused_clock = dac_dco;
      interface deleteme_unused_reset = dac_reset;

   endinterface
   
   interface PipeIn dac;
   
      method Action enq(Bit#(64) v);
	 outfifo.enq(unpack(pack(v)));
      endmethod
      
      method Bool notFull() = outfifo.notFull;
      
   endinterface

endmodule
