
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
   method Bit#(2) range_ctrl();
   method Action pulse(Bit#(2) v);
endinterface

interface MaxSonarCtrlRequest;
   method Action range_ctrl(Bit#(2) v);
   method Action pulse_width();
endinterface

interface MaxSonarCtrlIndication;
   method Action range_ctrl(Bit#(2) v);
   method Action pulse_width(Vector#(2,Bit#(32)) v);
endinterface

interface Controller;
   interface MaxSonarCtrlRequest req;
   interface PmodPins pins;
   interface LEDS leds;
endinterface

module mkController#(MaxSonarCtrlIndication ind)(Controller);
   
   Reg#(Bit#(2)) range_ctrl_reg <- mkReg(0);
   Vector#(2,Vector#(2,Reg#(Bit#(32)))) high_cnt <- replicateM(replicateM(mkReg(0)));
   Vector#(2,Reg#(Bit#(1))) last_pulse <- replicateM(mkReg(0));

   interface MaxSonarCtrlRequest req;
      method Action range_ctrl(Bit#(2) v);
	 range_ctrl_reg <= v;
	 ind.range_ctrl(v);
      endmethod
      method Action pulse_width();
	 ind.pulse_width(readVReg(map(last,high_cnt)));
      endmethod
   endinterface
   
   interface PmodPins pins;
      method Bit#(2) range_ctrl();
	 return range_ctrl_reg;
      endmethod
      method Action pulse(Bit#(2) v);
	 for(Integer i = 0; i < 2; i=i+1) begin
	    last_pulse[i] <= v[i];
	    if (last_pulse[i] == 1 && v[i] == 0) begin // end of pulse
	       high_cnt[i][1] <= high_cnt[i][0];
	       high_cnt[i][0] <= 0;
	    end
	    else if (v[i] == 1) begin
	       high_cnt[i][0] <= high_cnt[i][0]+1;
	    end
	 end
      endmethod
   endinterface
   
   interface LEDS leds;
      method Bit#(LedsWidth) leds() = extend(range_ctrl_reg);
   endinterface

endmodule
