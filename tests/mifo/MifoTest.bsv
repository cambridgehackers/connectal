
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
import MIFO::*;
import Vector::*;

interface MifoTestIndication;
    method Action mifo32(Bit#(32) v);
    method Action mifo64(Bit#(32) v, Bit#(32) w);
endinterface

interface MifoTestRequest;
   method Action mifo32(Bit#(32) n, Bit#(32) v0, Bit#(32) v1, Bit#(32) v2, Bit#(32) v3);
   method Action mifo64(Bit#(32) n, Bit#(32) v0, Bit#(32) v1, Bit#(32) v2, Bit#(32) v3);
endinterface

module mkMifoTestRequest#(MifoTestIndication indication)(MifoTestRequest);

   MIFO#(4,1,4,Bit#(32)) mifo1 <- mkMIFO();
   MIFO#(4,2,4,Bit#(32)) mifo2 <- mkMIFO();
   
   rule mifo32out if (mifo1.deqReady());
      let v = mifo1.first();
      mifo1.deq();
      indication.mifo32(v[0]);
   endrule
   rule mifo64out if (mifo2.deqReady());
      let v = mifo2.first();
      mifo2.deq();
      indication.mifo64(v[0], v[1]);
   endrule
   

   method Action mifo32(Bit#(32) n, Bit#(32) v0, Bit#(32) v1, Bit#(32) v2, Bit#(32) v3);
      Vector#(4, Bit#(32)) vec = newVector();
      vec[0] = v0;
      vec[1] = v1;
      vec[2] = v2;
      vec[3] = v3;
      mifo1.enq(unpack(truncate(n)), vec);
   endmethod
   method Action mifo64(Bit#(32) n, Bit#(32) v0, Bit#(32) v1, Bit#(32) v2, Bit#(32) v3);
      Vector#(4, Bit#(32)) vec = newVector();
      vec[0] = v0;
      vec[1] = v1;
      vec[2] = v2;
      vec[3] = v3;
      mifo2.enq(unpack(truncate(n)), vec);
   endmethod

endmodule