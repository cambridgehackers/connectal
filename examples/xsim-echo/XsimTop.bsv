
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
import Clocks::*;
import Leds::*;
import StmtFSM::*;
import Echo::*;

typedef enum {EchoIndicationIF, EchoRequestIF} IfcNames deriving (Eq,Bits);

interface VEcho;
   method Bit#(32) heard();
endinterface

import "BVI" echo =
module mkVEcho#(Bit#(32) say)(VEcho);
   default_clock clk();
   default_reset rst();
   port say = say;
   path(say,heard);
   method heard heard() clocked_by(clk) reset_by (rst);
endmodule

module mkXsim(Empty);
   let indication = (interface EchoIndication;
	  method Action heard(Bit#(32) v);
	     $display("heard v=%d", v);
	  endmethod
	  method Action heard2(Bit#(16) a, Bit#(16) b);
	     $display("heard2 a=%d b=%d", a, b);
	  endmethod
      endinterface);
   let echo <- mkEchoRequestInternal(indication);
   
   Reg#(Bit#(32)) echoReg <- mkReg(0);
   let vecho <- mkVEcho(echoReg);

   mkAutoFSM(seq
      $display("hello");
      echo.ifc.say(42);
      echo.ifc.say2(68,27);
      $display(".");
      echoReg <= 22;
      $display("vecho %d", vecho.heard());
      echoReg <= 42;
      $display("vecho %d", vecho.heard());
      $display(".");
      $display(".");
      endseq);
endmodule

(* no_default_clock, no_default_reset *)
module mkXsimTop(Empty);
   Clock c <- mkAbsoluteClock(10,10);
   Reset r <- mkInitialReset(2, clocked_by c);
   let xsim <- mkXsim(clocked_by c, reset_by r);
endmodule
