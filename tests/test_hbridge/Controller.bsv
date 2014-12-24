
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

interface HBridge2;
   method Bit#(2) hbridge0();
   method Bit#(2) hbridge1();
endinterface

interface HBridgeCtrlRequest;
   method Action ctrl(Bit#(16) idx, Bit#(16) power, Bit#(1) direction);
endinterface

interface HBridgeCtrlIndication;
   method Action ctrl(Bit#(16) idx, Bit#(16) power, Bit#(1) direction);
endinterface

interface Controller;
   interface HBridgeCtrlRequest req;
   interface HBridge2 pins;
   interface LEDS leds;
endinterface

module mkController#(HBridgeCtrlIndication ind)(Controller);
   
   Vector#(2, Reg#(Bit#(1))) direction <- replicateM(mkReg(0));
   Vector#(2, Reg#(Bit#(1)))   enabled <- replicateM(mkReg(0));
   Vector#(2, Reg#(Bit#(11)))    power <- replicateM(mkReg(0));
   Bit#(8) leds_val =  extend({direction[0],direction[1]});   
   
   // frequency of design: 100 mHz  
   // frequency of PWM System: 2 kHz 
   // 2k design cycles == 1 PWM cycle
   Reg#(Bit#(11)) fcnt <- mkReg(0);
   
   rule pwm;
      for(Integer i = 0; i < 2; i=i+1)
	 enabled[i] <= ((power[i] > 0) && (fcnt <= power[i])) ? 1 : 0;
      fcnt <= fcnt+1;
   endrule
   
   interface HBridgeCtrlRequest req;
      method Action ctrl(Bit#(16) i, Bit#(16) p, Bit#(1) d);
	 direction[i] <= d;
	 power[i] <= truncate(p);
	 ind.ctrl(i,p,d);
      endmethod
   endinterface
   
   interface HBridge2 pins;
      method Bit#(2) hbridge0();
	 return {enabled[0],direction[0]};
      endmethod
      method Bit#(2) hbridge1();
	 return {enabled[1],direction[1]};
      endmethod
   endinterface
   
   interface LEDS leds;
      method Bit#(LedsWidth) leds() = leds_val;
   endinterface

endmodule
