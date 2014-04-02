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

typedef enum {FIBSTATEIDLE, FIBSTATE1, FIBSTATE2, 
   FIBSTATE3, FIBSTATECOMPLETE} FSState
deriving (Eq, Bits);

module mkFibRequest#(FibIndication indication)(FibRequest)
   provisos(Literal#(FSState));


   /* stack frame */
   Reg#(Bit#(16)) fibn <- mkReg(0);
   Reg#(Bit#(16)) fibtmp1 <- mkReg(0);
   Reg#(FSState) fibstate <- mkReg(0);

   /* function variables that do not need to be saved or restored */
   Reg#(Bit#(16)) fibretval <- mkReg(0);
   
   
   /* offsets in stack frame */
   Bit#(2) fsoffsetn = 0;
   Bit#(2) fsoffsettmp1 = 1;
   Bit#(2) fsoffsetnext = 2;
   
   Stack#(128, 3, Bit#(16)) stack <- mkStack(128 ,3);
   
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
   
   function Action callfib(Bit#(16) arg,  FSState returnto);
      return action
		stack.store(fsoffsetn, fibn);
		stack.store(fsoffsettmp1, fibtmp1);
		stack.store(fsoffsetnext, zeroExtend(pack(returnto)));
		stack.push();
		fibn <= arg;
		fibstate <= FIBSTATE1;
	     endaction;
   endfunction
   
   function Action fibreturn(Bit#(16) returnval);
      return action
		let ta = ?;
		let tb = ?;
		let tc = ?;
		fibretval <= returnval;      
		stack.pop();
		ta <- stack.load(fsoffsetn);
		tb <- stack.load(fsoffsettmp1);
		tc <- stack.load(fsoffsetnext);
		fibn <= ta;
		fibtmp1 <= tb;
		fibstate <= unpack(truncate(tc));
	     endaction;
   endfunction

   rule fib1 (fibstate == FIBSTATE1);
     if (fibn == 0)
	fibreturn(1);
     else if (fibn == 1)
	fibreturn(1);
     else
	callfib(fibn - 1, FIBSTATE2);
     endrule

   rule fib2 (fibstate == FIBSTATE2);
      callfib(fibn - 2, FIBSTATE3);
   endrule
   
   rule fib3 (fibstate == FIBSTATE3);
      fibreturn(fibtmp1 + fibretval);
   endrule
      
   rule fibcomplete (fibstate == FIBSTATECOMPLETE);
      $display("fib completion");
      indication.fibresult(zeroExtend(fibretval));
      fibstate <= FIBSTATEIDLE;
   endrule
   
   method Action fib(Bit#(32) v);
      $display("request fib");
      fibn <= truncate(v);
      callfib(truncate(v), FIBSTATECOMPLETE);
   endmethod
      
endmodule

