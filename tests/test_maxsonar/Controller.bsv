
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
import Vector::*;

interface PmodPins;
   method Bit#(1) range_ctrl();
   method Action pulse_width(Bit#(1) v);
endinterface

interface MaxSonarCtrlRequest;
   method Action range_ctrl(Bit#(1) v);
endinterface

interface MaxSonarCtrlIndication;
   method Action range_ctrl(Bit#(1) v);
endinterface

interface Controller;
   interface MaxSonarCtrlRequest req;
   interface PmodPins pins;
   interface LEDS leds;
endinterface

module mkController#(MaxSonarCtrlIndication ind)(Controller);
   
   Reg#(Bit#(1)) range_ctrl_reg <- mkReg(0);

   interface MaxSonarCtrlRequest req;
      method Action range_ctrl(Bit#(1) v);
	 range_ctrl_reg <= v;
	 ind.range_ctrl(v);
      endmethod
   endinterface
   
   interface PmodPins pins;
      method Bit#(1) range_ctrl();
	 return range_ctrl_reg;
      endmethod
      method Action pulse_width(Bit#(1) v);
	 noAction;
      endmethod
   endinterface
   
   interface LEDS leds;
      method Bit#(LedsWidth) leds() = extend(range_ctrl_reg);
   endinterface

endmodule
