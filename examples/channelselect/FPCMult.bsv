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

typedef struct {
		Complex#(Coeff) a;
		Bit#(1) filterPhase;
		} CoeffData;

typedef struct {
		Complex#(Product) y;
		Bit#(1) filterPhase;
		} ProductData;

interface FPCMult;
   interface PipeIn#(Complex#(Signal)) x;
   interface PipeIn#(CoeffData) a;
   interface PipeOut#(ProductData) y;
endinterface
   
module mkFPCMult(FPCMult)
  provisos(Bits#(CoeffData, a__),
     Bits#(ProductData, b__));
   /* input registers */
   Reg#(Complex#(Signal)) xin <- mkReg(?);
   Reg#(CoeffData) ain <- mkReg(?);
   /* pipeline registers at output of multipliers */
   Reg#(Product) arxr <- mkReg(?);
   Reg#(Product) aixi <- mkReg(?);
   Reg#(Product) arxi <- mkReg(?);
   Reg#(Product) aixr <- mkReg(?);
   Reg#(Bit#(1)) multstage <- mkReg(?);
   /* result registers */
   Reg#(ProductData) yout <- mkReg(?);

   rule work;
      /* compute multiplies */
      arxr <= fxptMult(ain.a.rel, xin.rel);
      aixi <= fxptMult(ain.a.img, xin.img);
      arxi <= fxptMult(ain.a.rel, xin.img);
      aixr <= fxptMult(ain.a.img, xin.rel);
      multstage <= ain.filterPhase;
      /* combine into outputs */
      yout <= ProductData{y: Complex{rel: arxr - aixi, img: arxi + aixr}, filterPhase: multstage};
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
      method Action enq(CoeffData v);
         ain <= v;
      endmethod
      method Bool notFull();
         return (True);
      endmethod
   endinterface
   
   
endmodule
