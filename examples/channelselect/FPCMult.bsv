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


// This module implements a fixed point complex multiplication
// that is intended to map smoothly onto the DSP slices in Xilinx
// FPGAs.  To this end, the signal path is 18 bits (2 bits of integer
// and 16 bits of fraction), the coefficient path is 25 bits (2 bits
// of integer and 23 bits of fraction), and the product is 43 bits
// 4 bits of integer and 39 bits of fraction).  The multiplier
// in a DSP slice is actually 18 x 25 -> 45 bits.  The additional two
// product bits are for overflow, since the complex multipler adds
// four intermediate results.

// Signal inputs and outputs are Pipe datatypes, to provide flow control.
// The module is intended for use in environments where there may be
// one result per cycle, but at slow signal rates, clock cycles may
// be skipped.  Because the logic is pipelined, there are valid
// bits that follow the signal path.  The signal is assumed to be provided
// intermittently, while the coefficients are provided on demand up to
// one per cycle.

// Because one intended application is a Channel Select filter with
// downconversion, the coefficient path supplies a "filter phase" boolean
// which indicates the start of a new sample period at the output
// intermediate frequency.

import FIFOF::*;
import SpecialFIFOs::*;
import Complex::*;
import FixedPoint::*;
import Pipe::*;
import FIFOF::*;
import SpecialFIFOs::*;
import SDRTypes::*;

typedef struct {
		Complex#(Coeff) a;
		Bit#(1) filterPhase;
		} CoeffData deriving(Bits);

typedef struct {
		Complex#(Product) y;
		Bit#(1) filterPhase;
		} ProductData deriving(Bits);

typedef struct {
		Product arxr;
		Product arxi;
		Product aixr;
		Product aixi;
		Bit#(1) filterPhase;
		} MulData deriving(Bits);

interface FPCMult;
   interface PipeIn#(Complex#(Signal)) x;
   interface PipeIn#(CoeffData) a;
   interface PipeOut#(ProductData) y;
endinterface
   
module mkFPCMult(FPCMult)
  provisos(Bits#(CoeffData, a__),
     Bits#(ProductData, b__),
     Bits#(MulData, c__));
   /* input registers */
   FIFOF#(CoeffData) ain <- mkPipelineFIFOF();
   FIFOF#(Complex#(Signal)) xin <- mkPipelineFIFOF();
   /* pipeline registers at output of multipliers */
   Reg#(MulData) ax <- mkReg(?);
   /* result registers */
   FIFOF#(ProductData) yout <- mkPipelineFIFOF();

   rule work;
      /* compute multiplies */

      Product arxr = fxptMult(ain.first().a.rel, xin.first.rel);
      Product aixi = fxptMult(ain.first().a.img, xin.first.img);
      Product arxi = fxptMult(ain.first().a.rel, xin.first.img);
      Product aixr = fxptMult(ain.first().a.img, xin.first.rel);
      ain.deq();
      xin.deq();

      ax <= MulData{arxr: arxr, aixi: aixi, arxi: arxi, aixr: aixr,
	 filterPhase: ain.first().filterPhase};
      /* pipeline and combine into outputs */
      yout.enq(ProductData{y: Complex{rel: ax.arxr - ax.aixi, img: ax.arxi + ax.aixr}, filterPhase: ax.filterPhase});
   endrule
   
   interface PipeOut y = toPipeOut(yout);
   interface PipeIn x = toPipeIn(xin);
   interface PipeIn a = toPipeIn(ain);
   
endmodule
