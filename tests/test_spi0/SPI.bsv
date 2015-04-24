
// Copyright (c) 2015 Quanta Research Cambridge, Inc.

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

import Vector::*;
import ConnectalXilinxCells::*;
import PPS7LIB::*;
import FrequencyCounter::*;
import ConnectalClocks::*;
import XilinxCells::*;
import Clocks::*;

interface SPIRequest;
   method Action cnt_cycle_req(Bit#(32) v);
   method Action set_spew_en(Bit#(1) v);
endinterface

interface SPIResponse;
   method Action cnt_cycle_resp(Bit#(32) v);
   method Action emio_sample(Bit#(32) v);
endinterface

interface Controller;
   interface SPIRequest req;
endinterface

module mkController#(SPIResponse ind, Pps7Emiospi spi)(Controller);
   
   B2C1 b2c <- mkB2C1();
   Clock spi_clk <- mkClockBUFG(clocked_by b2c.c);
   // this module implements a slave device: ground .sclki and ignore .sclktn
   rule tx_spi_clk;
      b2c.inputclock(spi.sclko);
      spi.sclki(0);
   endrule
   Reset def_rst <- exposeCurrentReset();
   Reset spi_rst <- mkAsyncReset(2, def_rst, spi_clk);
   FrequencyCounter fc <- mkFrequencyCounter(spi_clk, spi_rst);
   Reg#(Bit#(1)) spew_en <- mkReg(0);
   
   rule cnt_cycle_resp_rule;
      let v <- fc.elapsedCycles;
      ind.cnt_cycle_resp(v);
   endrule
   
   interface SPIRequest req;
      method Action cnt_cycle_req(Bit#(32) v);
	 fc.start(v);
      endmethod
      method Action set_spew_en(Bit#(1) v);
	 spew_en <= v;
      endmethod
   endinterface

endmodule


