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

import StackReg::*;
import StmtFSM::*;

interface FibIndication;
    method Action fibresult(Bit#(32) v);
endinterface

interface FibRequest;
   method Action fib(Bit#(32) v);
endinterface

interface Fib;
   interface FibRequest request;
endinterface

typedef enum {FIBSTATEIDLE, FIBSTATE1, FIBSTATE2, 
   FIBSTATE3, FIBSTATECOMPLETE} FSState
deriving (Bits,Eq);


module mkFib#(FibIndication indication)(Fib);

   /* pc, args, vars */
   StackReg#(128, FSState, Bit#(16), Bit#(16)) frame <- mkStackReg(128, FIBSTATEIDLE);

   /* function variables that do not need to be saved or restored 
    *    in the pseudocode below, this is tmp2
    */
   Reg#(Bit#(16)) fibretval <- mkReg(0);
      
   /* experiment: recursive fibonnaci
    * fib(n):
    *   int tmp1, tmp2;
    *   if n == 0 return 0  // fibstate1
    *   if n == 1 return 1
    *   tmp1 = fib(n-1)
    *   tmp2 = fib(n-2)     // fibstate2
    *   return tmp1 + tmp2  // fibstate3
    */

   rule fib1 (frame.pc == FIBSTATE1);
      //$display("FIBSTATE1 %d", frame.args);
      if (frame.args == 0)
	 begin
	    fibretval <= 0;
	    frame.doreturn();
	 end
     else if (frame.args == 1)
	begin
	   fibretval <= 1;
	   frame.doreturn();
	end
     else
	// call FIBSTATE1 and return to FIBSTATE2
	// call with argument frame.args -1 and tmp2 = 0
	frame.docall(FIBSTATE1, FIBSTATE2, frame.args - 1, 0);
     endrule

   rule fib2 (frame.pc == FIBSTATE2);
      //$display("FIBSTATE2 (retval %d)", fibretval);
      // frame.vars <= fibretval; subsumed in docall
      frame.docall(FIBSTATE1, FIBSTATE3, frame.args - 2, fibretval);
   endrule
      
   rule fib3 (frame.pc == FIBSTATE3);
      //$display("FIBSTATE3 tmp1 %d fibretval %d return %d", frame.vars, fibretval, frame.vars + fibretval);
      fibretval <= frame.vars + fibretval;
      frame.doreturn();
   endrule
      
   rule fibcomplete (frame.pc == FIBSTATECOMPLETE);
      //$display("FIBSTATECOMPLETE %d %d", frame.args, fibretval);
      indication.fibresult(zeroExtend(fibretval));
      // our work here is done
      frame.nextpc(FIBSTATEIDLE);
   endrule

   interface FibRequest request;

      method Action fib(Bit#(32) v);
         //$display("request fib %d", v);
         // call FIBSTATE1 and return to FIBSTATECOMPLETE
         // with argument v
         frame.docall(FIBSTATE1, FIBSTATECOMPLETE, truncate(v), 0);
      endmethod

   endinterface
      
endmodule

