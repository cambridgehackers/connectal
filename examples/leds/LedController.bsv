
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

import FIFO::*;
import GetPut::*;
import Leds::*;

typedef struct {
   Bit#(8) leds;
   Bit#(32) duration;
   } LedControllerCmd deriving (Bits);

interface LedControllerRequest;
   method Action setLeds(Bit#(8) v, Bit#(32) duration);
endinterface

interface LedPins;
   interface LEDS leds;
   interface Clock deleteme_unused_clock;
   interface Reset deleteme_unused_reset;
endinterface

interface LedController;
   interface LedControllerRequest request;
   interface LedPins leds;
endinterface

module mkLedController(LedController);
   Clock defaultClock <- exposeCurrentClock();
   Reset defaultReset <- exposeCurrentReset();
   Reg#(Bit#(8)) ledsValue <- mkReg(0);
   Reg#(Bit#(32)) remainingDuration <- mkReg(0);

   FIFO#(LedControllerCmd) ledsCmdFifo <- mkSizedFIFO(32);

   rule updateLeds;
      let duration = remainingDuration;
      if (duration == 0) begin
	 let cmd <- toGet(ledsCmdFifo).get();
	 $display("ledsValue <= %b", cmd.leds);
	 ledsValue <= cmd.leds;
	 duration = cmd.duration;
      end
      else begin
	 duration = duration - 1;
      end
      remainingDuration <= duration;
   endrule

   interface LedControllerRequest request;
       method Action setLeds(Bit#(8) v, Bit#(32) duration);
	  $display("Enqueing v=%d duration=%d", v, duration);
	  ledsCmdFifo.enq(LedControllerCmd { leds: v, duration: duration });
       endmethod
   endinterface
   interface LedPins leds;
      interface LEDS leds;
         method leds = truncate(ledsValue._read);
      endinterface
      interface deleteme_unused_clock = defaultClock;
      interface deleteme_unused_reset = defaultReset;
   endinterface
endmodule
