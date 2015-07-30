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
import Pipe::*;
import Vector::*;

interface MifoTestIndication;
    method Action mifo32(Bit#(32) v);
    method Action mifo64(Bit#(32) v, Bit#(32) w);
    method Action fimo64(Bit#(32) v0, Bit#(32) v1);
    method Action fimo96(Bit#(32) v0, Bit#(32) v1, Bit#(32) v2);
    method Action fimo128(Bit#(32) v0, Bit#(32) v1, Bit#(32) v2, Bit#(32) v3);
endinterface

interface MifoTestRequest;
   method Action mifo32(Bit#(32) n, Bit#(32) v0, Bit#(32) v1, Bit#(32) v2, Bit#(32) v3);
   method Action mifo64(Bit#(32) n, Bit#(32) v0, Bit#(32) v1, Bit#(32) v2, Bit#(32) v3);
   method Action fimo32(Bit#(32) v0);
endinterface

interface MifoTest;
   interface MifoTestRequest request;
endinterface

module mkMifoTest#(MifoTestIndication indication)(MifoTest);
   MIFO#(4,1,4,Bit#(32)) mifo1 <- mkMIFO();
   MIFO#(4,2,4,Bit#(32)) mifo2 <- mkMIFO();
   FIMO#(1,4,4,Bit#(32)) fimo1 <- mkFIMO();
   FIMO#(1,4,4,Bit#(32)) fimo2 <- mkFIMO();
   FIMO#(1,4,4,Bit#(32)) fimo3 <- mkFIMO();

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

   rule fimo64out;
      let v = fimo1.out[2].first();
      fimo1.out[2].deq();
      $display("fimo32 value: %h", v);
      indication.fimo64(v[0], v[1]);
   endrule
   rule fimo96out;
      let v = fimo2.out[3].first();
      fimo2.out[3].deq();
      $display("fimo96 value: %h", v);
      indication.fimo96(v[0], v[1], v[2]);
   endrule
   rule fimo128out;
      let v = fimo3.out[4].first();
      fimo3.out[4].deq();
      $display("fimo128 value: %h", v);
      indication.fimo128(v[0], v[1], v[2], v[3]);
   endrule

   interface MifoTestRequest request;
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

   method Action fimo32(Bit#(32) v);
      Vector#(1, Bit#(32)) vec = replicate(v);
      fimo1.in.enq(vec);
      fimo2.in.enq(vec);
      fimo3.in.enq(vec);
   endmethod
   endinterface
endmodule
