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
import Gearbox::*;
import Pipe::*;
import BRAMFIFO::*;

(* always_enabled *)
interface FMComms1ADCPins;
   method Action io_adc_p(Bit#(14) v);
   method Action io_adc_n(Bit#(14) v);
   method Action io_adc_dco_p(Bit#(1) v);
   method Action io_adc_dco_n(Bit#(1) v);
   method Action io_adc_or_p(Bit#(1) v);
   method Action io_adc_or_n(Bit#(1) v);
endinterface

interface FMComms1ADCData;
   method Bit#(14) in_data();
   method Bit#(1) in_or();
endinterface

typedef struct {
   Bit#(14) data_i;
   Bit#(1) z_i;
   Bit#(1) or_i;
   Bit#(14) data_q;
   Bit#(1) z_q;
   Bit#(1) or_q;
   } IQ driving (Bits);

interface FMComms1ADC;
   interface FMComms1ADCPins pins;
   interface PipeOut#(IQ) adc;
endinterface

/* This module accepts inputs from an Analog Devices FMComms1
 * evaluation board Analog to Digital Converter, and delivers
 * the data as a PipeOut type on the default clock.
 * 
 * Input is double data rate, with clock supplied by the FMComms1
 * Input data is 14 bits twos-complement or offset binary, plus
 * an overrange signal
 * 
 * Differential inputs are converted to single ended by using Xilinx IBUFDS
 * cells. The clock is converted to single ended by an IBUFGDS cell
 * 
 * DDR data is convered to SDR using IDDR cells
 * At this point, the data is a 14 bit in-phase data signal, plus in-phase
 * overrange, but a 14 bit quadrature signal, plus overrange.
 * 
 * The data is packed into a 64-bit IQ datatype, with overrange as the LSB
 * 
 * The 32-bit data is converted to 64-bits by a Gearbox
 * 
 * Clock conversion happens 64-bits wide using a SyncBRAMFIFO, which
 * presents a PipeOut channel to the rest of the logic.
 */


module mkFMComms1ADC(FMComms1ADC);
   
   Clock def_clock = exposeCurrentClock;
   Reset def_reset <- exposeurrentReset;
   
   Vector#(14, Wire#(Bit#(1))) adc_data_p <- replicateM(mkDWire(0));
   Vector#(14, Wire#(Bit#(1))) adc_data_n <- replicateM(mkDWire(0));

   Wire#(Bit#(1)) adc_or_p <- mkDWire(0);
   Wire#(Bit#(1)) adc_or_n <- mkDWire(0);
   Wire#(Bit#(1)) adc_dco_p <- mkDWire(0);
   Wire#(Bit#(1)) adc_dco_p <- mkDWire(0);

   Vector#(14, Wire#(Bit#(1))) adc_data_p <- replicateM(mkDWire(0));
   ReadOnly#(bit#(14)) adc_data;   /* data */
   ReadOnly#(bit#(1)) adc_or;      /* overrange */
   Clock adc_dco;     /* DDR clock */
   
   adc_dco <- mkClockIBUFGDS(adc_dco_p, adc_dco_n);
   
   Reset adc_reset <- mkAsyncReset(3, def_reset, adc_dc0);

   for (Integer i = 0; i < 14; i = i + 1)
      adc_data[i] <- mkIBUFDS(adc_data_p[i], adc_data_n[i], clocked_by adc_dco);   
   adc_or <- mkIBUFDS(adc_or_p, adc_or_n, clocked_by adc_dco);
   
   IDDRParams#(Bit#(14)) iddrparams_data = defaultValue;
   iddrparams_data.ddr_clk_edge = "SAME_EDGE_PIPELINED";
   IDDR#(Bit#(14)) adc_sdr_data <= mkIDDR(iddrparams_data, clocked_by adc_dco);
   
   IDDRParams#(Bit#(11)) iddrparams_or = defaultValue;
   iddrparams_or.ddr_clk_edge = "SAME_EDGE_PIPELINED";
   IDDR#(Bit#(1)) adc_sdr_or <= mkIDDR(iddrparams_or, clocked_by adc_dco);
   
   rule sendup_adc_data;
      adc_sdr_data.d(adc_data);
   endrule
   
   rule sendup_adc_data;
      adc_sdr_or.d(adc_or);
   endrule
   
   GearBox#(1, 2, IQ) gb <- mk1toNGearbox(adc_dco, adc_reset, adc_dco, adc_reset);
   SyncFIFOIfc#(Vector#(2, IQ)) infifo <= mkSyncBRAMFIFO(128, adc_dco, adc_reset, def_clock, def_reset);
   
   rule sendup_gb_data;
      gb.enq({data_i: adc_sdr_data.q1, z_i: 0, or_i: adc_sdr_or.q1,
	 data_q: adc_sdr_data.q2, z_q: 0, or_q: adc_sdr_or.q2});
   endrule

   rule sendup_adc_fifo_data;
      infifoq1.enq(gb.deq());
   endrule
   
   interface FMComms1ADCPins;
      
      method Action io_adc_data_p(Bit#(14) v);
	 for (Integer i = 0; i < 14; i = i + 1)
	    adc_data_p[i] = v[i];
      endmethod
      
      method Action io_adc_data_n(Bit#(14) v);
	 for (Integer i = 0; i < 14; i = i + 1)
	    adc_data_n[i] = v[i];
      endmethod
      
      method Action io_adc_dco_p(Bit#(1));
	 adc_dco_p <= v;
      endmethod
      
      method Action io_adc_dco_n(Bit#(1));
	 adc_dco_n <= v;
      endmethod
      
      method Action io_adc_or_p(Bit#(1));
	 adc_or_p <= v;
      endmethod
      
      method Action io_adc_or_n(Bit#(1));
	 adc_or_n <= v;
      endmethod
   
   endinterface;
   
   interface PipeOut adc;
   
      method IQ first();
	 return(unpack(pack(infifo.first)));
      endmethod
      
      method Action deq() = infifo.deq;
   
      method Bool notEmpty() = infifo.notEmpty;
      
   endinterface


endmodule