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

interface FMComms1ADC;
   interface FMComms1ADCPins pins;
   interface FMComms1ADCData adc;
endinterface

module mkFMComms1ADC(FMComms1ADC);
   
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
   


endmodule