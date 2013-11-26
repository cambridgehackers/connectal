// Copyright (c) 2013 Quanta Research Cambridge, Inc.

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


import GetPut::*;
import BRAM::*;
import FIFO::*;

import PortalMemory::*;
import PortalSMemory::*;
import Adapter::*;

interface ReadChan2BRAM#(type a);
   method Action start(a x);
   method ActionValue#(Bool) finished();
endinterface

module mkReadChan2BRAM#(ReadChan rc, BRAM1Port#(a,d) br)(ReadChan2BRAM#(a))
   provisos(Bits#(d,dsz),
	    Div#(64,dsz,nd),
	    Mul#(nd,dsz,64),
	    Eq#(a),
	    Ord#(a),
	    Arith#(a),
	    Bits#(a,b__),
	    Add#(a__, dsz, 64));
   
   FIFO#(void) f <- mkSizedFIFO(1);
   FromBit#(64, d) fbr <- mkFromBitR;
   Reg#(a) i <- mkReg(0);
   Reg#(a) j <- mkReg(0);
   Reg#(a) n <- mkReg(0);

   rule loadReq(i < n);
      rc.readReq.put(?);
      i <= i+fromInteger(valueOf(nd));
   endrule
   
   rule loadNeedleResp;
      let rv <- rc.readData.get;
      fbr.enq(rv);
   endrule
   
   rule loadNeedle;
      br.portA.request.put(BRAMRequest{write:True, responseOnWrite:False, address:j, datain:fbr.first});
      fbr.deq;
      j <= j+1;
   endrule
   
   method Action start(a x);
      n <= x;
      f.enq(?);
      i <= 0;
   endmethod
   
   method ActionValue#(Bool) finished() if (j == n);
      j <= 0;
      f.deq;
      return True;
   endmethod
   
endmodule
