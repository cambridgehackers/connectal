// Copyright (c) 2015 The Connectal Project

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
import FIFO          ::*;

interface Exporter;
   method ActionValue#(Bool) e;
endinterface		

(* synthesize *)
module  mkExporter(Exporter);
   FIFO#(Bool) efifo <- mkFIFO;

   method ActionValue#(Bool) e;
       efifo.deq;
       return efifo.first;
   endmethod
endmodule

interface Importer;
   method Action i(Bool v);
endinterface		

(* synthesize *)
module  mkImporter(Importer);
   FIFO#(Bool) ififo <- mkFIFO;

   method Action i(Bool v);
      ififo.enq(v);
   endmethod
endmodule

interface MethodRequest;
   method Action startme;
endinterface
interface Method;
   interface MethodRequest request;
endinterface

module mkMethod(Method);
   Exporter einst <- mkExporter;
   Importer iinst <- mkImporter;

   rule toprule;
      let v <- einst.e;
      iinst.i(v);
   endrule

   interface MethodRequest request;
      method Action startme;
      endmethod
   endinterface
endmodule
