
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

interface MaxSonarPins;
   method Bit#(1) range_ctrl();
   method Action pulse(Bit#(1) v);
endinterface

interface MaxSonarCtrlRequest;
   method Action range_ctrl(Bit#(1) v);
   method Action pulse_width();
endinterface

interface MaxSonarCtrlIndication;
   method Action range_ctrl(Bit#(1) v);
   method Action pulse_width(Bit#(32) v);
endinterface

interface MaxSonarController;
   interface MaxSonarCtrlRequest req;
   interface MaxSonarPins pins;
   interface LEDS leds;
endinterface

module mkMaxSonarController#(MaxSonarCtrlIndication ind)(MaxSonarController);
   
   Reg#(Bit#(1)) range_ctrl_reg <- mkReg(0);
   Vector#(2,Reg#(Bit#(32))) high_cnt <- replicateM(mkReg(0));
   Reg#(Bit#(1)) last_pulse <- mkReg(0);

   interface MaxSonarCtrlRequest req;
      method Action range_ctrl(Bit#(1) v);
	 range_ctrl_reg <= v;
	 ind.range_ctrl(v);
      endmethod
      method Action pulse_width();
	 ind.pulse_width(high_cnt[1]);
      endmethod
   endinterface
   
   // pulse width modulation
   interface MaxSonarPins pins;
      method Bit#(1) range_ctrl();
	 return range_ctrl_reg;
      endmethod
      method Action pulse(Bit#(1) v);
	 last_pulse <= v;
	 if (last_pulse == 1 && v == 0) begin // end of pulse
	    high_cnt[1] <= high_cnt[0];
	    high_cnt[0] <= 0;
	 end
	 else if (v == 1) begin
	    high_cnt[0] <= high_cnt[0]+1;
	 end
      endmethod
   endinterface
   
   interface LEDS leds;
      method Bit#(LedsWidth) leds() = extend(range_ctrl_reg);
   endinterface

endmodule
