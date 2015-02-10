
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

import Leds::*;

interface PmodPins;
   method Bit#(8) pmod();
endinterface

interface PmodControllerRequest;
   method Action rst(Bit#(32) v);
endinterface

interface PmodControllerIndication;
   method Action rst(Bit#(32) v);
endinterface

interface Controller;
   interface PmodControllerRequest req;
   interface PmodPins pins;
   interface LEDS leds;
endinterface

module mkController#(PmodControllerIndication ind)(Controller);
   
   Reg#(Bit#(8)) data_reg <- mkReg(0);
   Reg#(Bit#(8)) leds_reg <- mkReg(0);
   Reg#(Bool)     rst_reg <- mkReg(False);
   
   rule count;
      if (rst_reg) begin
	 rst_reg <= False;
	 data_reg <= 0;
	 leds_reg <= data_reg;
      end
      else begin
	 data_reg <= data_reg+1;
      end
   endrule
   
   interface PmodControllerRequest req;
      method Action rst(Bit#(32) v);
	 rst_reg <= True;
	 ind.rst(v);
      endmethod
   endinterface
   
   interface PmodPins pins;
      method Bit#(8) pmod() = data_reg._read;
   endinterface
   
   interface LEDS leds;
      method Bit#(LedsWidth) leds() = truncate(leds_reg);
   endinterface

endmodule
