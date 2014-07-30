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

import Complex::*;
import FixedPoint::*;
import Pipe::*;

typedef FixedPoint#(2,16) Signal;
typedef FixedPoint#(2,23) Coeff;
typedef FixedPoint#(4,39) Product;

interface FPCMult;
   interface PipeIn#(Complex#(Signal)) x;
   interface PipeIn#(Complex#(Coeff)) a;
   interface PipeOut#(Complex#(Product)) y;
endinterface
   
module mkFPCMult(FPCMult);
   /* input registers */
   Reg#(Complex#(Signal)) xin <- mkReg(?);
   Reg#(Complex#(Coeff)) ain <- mkReg(?);
   /* pipeline registers at output of multipliers */
   Reg#(Product) arxr <- mkReg(?);
   Reg#(Product) aixi <- mkReg(?);
   Reg#(Product) arxi <- mkReg(?);
   Reg#(Product) aixr <- mkReg(?);
   /* result registers */
   Reg#(Complex#(Product)) yout <- mkReg(?);

   rule work;
      /* compute multiplies */
      arxr <= fxptMult(ain.r, xin.r);
      aixi <= fxptMult(ain.i, xin.i);
      arxi <= fxptMult(ain.r, xin.i);
      aixr <= fxptMult(ain.i, xin.r);
      /* combine into outputs */
      yout <= Complex{r: arxr - aixi, i: arxi + aixr};
   endrule
   
   interface PipeOut y = toPipeOut(yout);
   interface PipeIn x;
      method Action enq(Complex#(Signal) v);
         xin <= v;
      endmethod
      method Bool notFull();
         return (True);
      endmethod
   endinterface
   interface PipeIn a;
      method Action enq(Complex#(Coeff) v);
         ain <= v;
      endmethod
      method Bool notFull();
         return (True);
      endmethod
   endinterface
   
   
endmodule;