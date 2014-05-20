
// Copyright (c) 2013 Nokia, Inc.

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

interface SimpleIndication;
    method Action heard1(Bit#(32) v);
endinterface

interface SimpleResponse;
   method ActionValue#(Bit#(32)) heard1();
endinterface

interface SimpleRequest;
    method Action say1(Bit#(32) v);
endinterface


interface Simple;
   interface SimpleRequest request;
   interface SimpleResponse response;
endinterface

// Because mkSimple has a synthesis boundary, it cannot take
// SimpleIndication as an interface parameter. Therefore, it exports a
// complementary interface: SimpleResponse, where each Action method
// from SimpleIndication has a corresponding ActionValue method.

(* synthesize *)
module mkSimple(Simple);
   FIFO#(Bit#(32)) vFifo <- mkFIFO();
   interface SimpleRequest request;
      method Action say1(Bit#(32) v);
	 vFifo.enq(v);
      endmethod
   endinterface
   interface SimpleResponse response;
      method ActionValue#(Bit#(32)) heard1();
	 vFifo.deq();
	 return vFifo.first();
      endmethod
   endinterface
endmodule