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
import LinkerLib::*;
import GetPut::*;
import FIFO::*;

interface Inverter;
    method Action m(Bool v);
    method ActionValue#(Bool) mInv;
endinterface		

(* synthesize *)
module  mkInverter(Inverter);
    PutInverter#(Bool) inv <- mkPutInverter();

    method Action m(Bool v);
        inv.mod.put(v);
    endmethod
    method ActionValue#(Bool) mInv;
        let v <- inv.inverse.get;
        return v;
    endmethod
endmodule

interface Invertm;
    method Action actual(Bool v);
endinterface

(* synthesize *)
module mkInvertm(Invertm);
    FIFO#(Bool) fifo <- mkFIFO;
    method Action actual(Bool v);
        fifo.enq(v);
    endmethod
endmodule

interface MethodRequest;
   method Action startme;
endinterface
interface Method;
   interface MethodRequest request;
endinterface

(* synthesize *)
module mkMethod(Method);
   Inverter einst <- mkInverter;
   Invertm eact <- mkInvertm;
   FIFO#(Bool) fifo <- mkFIFO;

   rule invoke_rule;
      einst.m(fifo.first);
   endrule

   PutInverter#(Bool) conn <- mkPutInverter();
   rule connect_rule1;
      let v <- einst.mInv;
      conn.mod.put(v);
   endrule
   rule connect_rule2;
      let v <- conn.inverse.get();
      eact.actual(v);
   endrule

   interface MethodRequest request;
      method Action startme;
      endmethod
   endinterface
endmodule
