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

/*
 * Implementation of:
 *    simple stack
 */

import BRAM::*;


/* the methods for load are split.  loadstart puts a request to the BRAM
 * and loadfinish gets the result
 */

interface Stack#(numeric type stackSize, numeric type frameSize, type a);
   method Action store(Bit#(TLog#(frameSize)) offset, a v);
   method Action loadstart(Bit#(TLog#(frameSize)) offset);
   method ActionValue#(a) loadfinish();
   method Action push();
   method Action pop();
   method Action reset();
endinterface

module mkStack#(int stackSize, int frameSize)(Stack#(stackSize, frameSize, a))
   provisos(Log#(stackSize, fpBits),
	    Log#(frameSize, frameBits),
	    Add#(fpBits, frameBits, addressBits),
            Literal#(a),
            Bits#(a, a__));

   BRAM1Port#(Bit#(addressBits), a) stack  <- mkBRAM1Server(defaultValue);
   Reg#(UInt#(fpBits)) fp <- mkReg(0);
   
   method Action reset();
      fp <= 0;
   endmethod

   method Action push();
      fp <= min(fp+1, maxBound);
   endmethod

   method Action pop();
      fp <= max(fp-1, 0);
   endmethod

   method Action store(Bit#(TLog#(frameSize)) offset, a v);
     stack.portA.request.put(BRAMRequest{write: True, 
	responseOnWrite: False, 
	address: {pack(fp), offset}, datain: v});
   endmethod
   
   /* read a value from current stack frame */
   method Action loadstart(Bit#(TLog#(frameSize)) offset);
      stack.portA.request.put(BRAMRequest{write: False, 
	 responseOnWrite: False, 
	 address: {pack(fp), offset}, datain: 0});
   endmethod
   
   /* maybe this should just expose a server interface? */
   
   method ActionValue#(a) loadfinish();
      let v = ?;
      v <- stack.portA.response.get();
      return(v);
   endmethod
   

endmodule
