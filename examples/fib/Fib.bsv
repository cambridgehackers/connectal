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

import Stack::*;

interface FibIndication;
    method Action fibresult(Bit#(32) v);
endinterface

interface FibRequest;
   method Action fib(Bit#(32) v);
endinterface


module mkFibRequest#(FibIndication indication)(FibRequest);


   /* stack frame */
   Reg#(Bit#(16)) fibn <- mkReg(0);
   Reg#(Bit#(16)) fibtmp1 <- mkReg(0);
   Reg#(Bit#(16)) fibstate <- mkReg(0);

   /* function variables that do not need to be saved or restored */
   Reg#(Bit#(16)) fibresult <- mkReg(0);
   
   typedef enum {fibstateidle, fibstate1, fibstate2, fibstate3, fibstatecomplete} fsstate
   deriving (Eq, Bits);
   
   /* offsets in stack frame */
   Bits#(2) fsoffsetn = 0;
   Bits#(2) fsoffsettmp1 = 1;
   Bits#(2) fsoffsetnext = 2;
   
   Stack#(128, 3, Bit#(16)) stack <- mkStack();
   
   /* experiment: recursive fibonnaci
    * fib(n):
    *   int tmp1, tmp2;
    *   if n == 0 return 1  // fibstate1
    *   if n == 1 return 1
    *   tmp1 = fib(n-1)
    *   tmp2 = fib(n-2      // fibstate2
    *   return tmp1 + tmp2  // fibstate3
    *
    * with explicit stack:
    * struct fsf {
    *   int level;
    *   int tmp1;
    *   int n;
    *   int next_state;
    * } stack[N]
    * 
    */
   
   function Action callfib(Bit#(16) arg, Bit#(6) returnto);
      stack.store(fsoffsetn, fibn);
      stack.store(fsoffsettmp1, tmp1);
      stack.store(fsoffsetnext, returnto);
      stack.push();
      fibn <= arg;
      fibstate <= fibstate1;
   endfunction
   
   function Action fibreturn(Bit#(16) returnval);
      fsresult <= returnval;      
      stack.pop();
      fibn <= stack.load(fsoffsetn);
      fibtmp1 <= stack.load(fsoffsettmp1);
      fibstate <= stack.load(fsoffsetnext);
   endfunction

  rule fib1 (fibstate == fs1):
     if ((fibn == 0)) || (fibn == 1)) 
	begin
	   fibreturn(1);
	end
     else
	begin
	   callfib(fibn - 1, fibstate2);
	end
     endrule

   rule fib2 (fibstate == fibstate2):
      callfib(fibn - 2, fibstate3);
   endrule
   
   rule fib3 (fibstate == fibstate3);
      fibreturn(fibtmp1 + fibresult);
   endrule;
      
   rule fibcomplete (fibstate == fibstatecomplete)
      $display("fib completion");
      indication.fibresult(zeroExtend(fibresult));
      fibstate <= fibidle;
   endrule
   
   method Action fib(Bit#(32) v);
      $display("request fib");
      fibn <= truncate(v);
      callfib(truncate(v), fibstatecomplete);
   endmethod
      
endmodule

