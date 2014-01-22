
// Copyright (c) 2013 Nokia, Inc.
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

import FIFO::*;

interface SinkIndication;
   method Action returnTokens(Bit#(32) v);
endinterface

interface SinkRequest;
   method Action init(Bit#(32) v);
   method Action put(Bit#(32) v);
endinterface

module mkSinkRequest#(SinkIndication indication)(SinkRequest);
      
   Bit#(32) threshold = 4;
   Bit#(32) capacity = 24;
   Reg#(Bit#(32)) count <- mkReg(0);

   rule consume (count >= threshold);
      indication.returnTokens(count);
      count <= 0;
   endrule
   
   method Action init(Bit#(32) v);
      indication.returnTokens(capacity);
   endmethod

   method Action put(Bit#(32) v) if (count < capacity);
      count <= count+1;
   endmethod

endmodule





