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
import StmtFSM::*;

interface FibIndication;
    method Action fibresult(Bit#(32) v);
    method Action fibnote(Bit#(32) v);
endinterface

interface FibRequest;
   method Action fib(Bit#(32) v);
endinterface

typedef enum {FIBSTATEIDLE, FIBSTATE1, FIBSTATE2, 
   FIBSTATE3, FIBSTATECOMPLETE, FIBCALLING, FIBRETURNING} FSState
deriving (Bits,Eq);

module mkFibRequest#(FibIndication indication)(FibRequest);
//   provisos(Literal#(FSState));


   /* stack frame */
   Reg#(Bit#(16)) fibn <- mkReg(0);
   Reg#(Bit#(16)) fibtmp1 <- mkReg(0);
   Reg#(FSState) fibstate <- mkReg(FIBSTATEIDLE);

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
   
   Reg#(Bit#(16)) fibcallarg <- mkReg(0);
   Reg#(FSState) fibcallreturnto <- mkReg(FIBSTATEIDLE);
   
   Stmt callfibstmt =
   seq
//      $display("FIBCALL");
      stack.store(fsoffsetn, fibn);
      stack.store(fsoffsettmp1, fibtmp1);
      stack.store(fsoffsetnext, zeroExtend(pack(fibcallreturnto)));
//      par
	 stack.push();
	 fibn <= fibcallarg;
	 fibstate <= FIBSTATE1;
//      endpar
   endseq;
   
   FSM callFibFSM <- mkFSM(callfibstmt);
   
   Stmt fibreturnstmt =
   seq
//      $display("FIBRETURN");
      stack.pop();
//      $display("FIBRETURN pop");
      stack.loadstart(fsoffsetn);
      action
	 let t <- stack.loadfinish();
	 stack.loadstart(fsoffsettmp1);
	 fibn <= t;
      endaction
//      $display("FIBRETURN n");
      action
	 let t <- stack.loadfinish();
	 stack.loadstart(fsoffsetnext);
	 fibtmp1 <= t;
      endaction
//      $display("FIBRETURN tmp1");
      action
	 let t <- stack.loadfinish();
//	 $display("FIBRETURN set state %d", t);
	 fibstate <= unpack(truncate(t));
      endaction
   endseq;

   FSM fibreturnFSM <- mkFSM(fibreturnstmt);

   function Action callfib(Bit#(16) arg,  FSState returnto);
   return action
	     fibstate <= FIBCALLING;
	     fibcallarg <= arg;
	     fibcallreturnto <= returnto;
	     callFibFSM.start();
	  endaction;
   endfunction
   
   
   
   function Action fibreturn(Bit#(16) returnval);
      return action
		fibstate <= FIBRETURNING;
		fibretval <= returnval;      
		fibreturnFSM.start();
	     endaction;
   endfunction

   rule fib1 (fibstate == FIBSTATE1);
//      $display("FIBSTATE1");
     if (fibn == 0)
	fibreturn(0);
     else if (fibn == 1)
	fibreturn(1);
     else
	callfib(fibn - 1, FIBSTATE2);
     endrule

   rule fib2 (fibstate == FIBSTATE2);
//      $display("FIBSTATE2");
      fibtmp1 <= fibretval;
      callfib(fibn - 2, FIBSTATE3);
   endrule
   
   rule fib3 (fibstate == FIBSTATE3);
//      $display("FIBSTATE3 fibtmp1 %d fibretval %d return %d", fibtmp1, fibretval, fibtmp1 + fibretval);
      fibreturn(fibtmp1 + fibretval);
   endrule
      
   rule fibcomplete (fibstate == FIBSTATECOMPLETE);
//      $display("FIBSTATECOMPLETE %d %d", fibn, fibretval);
      indication.fibresult(zeroExtend(fibretval));
      fibstate <= FIBSTATEIDLE;
   endrule
   
   method Action fib(Bit#(32) v);
      $display("request fib %d", v);
      fibn <= truncate(v);
      indication.fibnote(8);
      callfib(truncate(v), FIBSTATECOMPLETE);
   endmethod
      
endmodule

