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
import FloatingPoint::*;
import GetPut::*;
import ClientServer::*;
import FpOps::*;

interface FpRequest;
   method Action add(Float a, Float b);
endinterface
interface FpIndication;
   method Action added(Float a);
endinterface

interface FpTest;
   interface FpRequest request;
endinterface

module mkFpTest#(FpIndication indication)(FpTest);
   Server#(Tuple2#(Float,Float),Float) adder <- mkXilinxFPAdder();

   rule result;
      let v <- adder.response.get();
      indication.added(v);
   endrule

   interface FpRequest request;
   method Action add(Float a, Float b);
      adder.request.put(tuple2(a, b));
   endmethod
   endinterface
endmodule
