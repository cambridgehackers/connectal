
// Copyright (c) 2012 MIT
// Copyright (c) 2012 Nokia, Inc.

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

import GetPut         ::*;
import FIFOF          ::*;
import SpecialFIFOs   ::*;
import StmtFSM        ::*;
import Assert         ::*;
import Pipe           ::*;

function Bit#(a) rtruncate(Bit#(b) x) provisos(Add#(k,a,b));
   match {.v,.*} = split(x);
   return v;
endfunction

interface AdapterToBus#(numeric type n, type a);
   interface PipeIn#(a) in;
   interface PipeOut#(Bit#(n)) out;
endinterface
   
interface AdapterFromBus#(numeric type n, type a);
   interface PipeIn#(Bit#(n)) in;
   interface PipeOut#(a) out;
endinterface

module mkAdapterToBus(AdapterToBus#(n,a))
   provisos(Bits#(a,asz),
            Add#(1, z, asz),
            Div#(asz,n,nwords),
            Mul#(n,nwords,aszn),
            Add#(n,a__,aszn),
            Add#(asz,paddingsz,aszn));
   
   Bit#(TLog#(nwords)) max  = fromInteger(valueOf(nwords) - 1);
   Bit#(paddingsz) padding = 0;

   Reg#(Bool) notEmptyReg <- mkReg(False);
   Reg#(Bit#(aszn)) bits <- mkReg(0);
   Reg#(Bit#(TLog#(nwords)))   count <- mkReg(0);
   Reg#(Bit#(TAdd#(TLog#(asz),1)))   shift <- mkReg(0);

   interface PipeIn in;
      method Action enq(a val) if (!notEmptyReg);
         bits <= {padding,pack(val)};
	 notEmptyReg <= True;
      endmethod
      method notFull = !notEmptyReg;
   endinterface
   interface PipeOut out;
      method Bit#(n) first() if (notEmptyReg);
         return rtruncate(bits);
      endmethod
      method Action deq() if (notEmptyReg);
         if (count == max)
            begin 
               count <= 0;
	       notEmptyReg <= False;
            end
         else
            begin
               count <= count + 1;
	       shift <= shift + fromInteger(valueOf(n));
	       bits <= (bits << valueOf(n));
            end   
      endmethod
      method notEmpty = notEmptyReg;
   endinterface
endmodule

module mkAdapterFromBus(AdapterFromBus#(n,a))
   provisos(Bits#(a,asz),
            Add#(1,z,asz),
            Div#(asz,n,nwords),
            Mul#(n,nwords,aszn),
            Add#(n,a__,aszn),
            Add#(asz,paddingsz,aszn));

   Bit#(TLog#(nwords)) max    = fromInteger(valueOf(nwords)-1);

   Reg#(Bit#(aszn)) fbnbuff <- mkReg(0);
   Reg#(Bit#(TLog#(nwords)))    count <- mkReg(0);
   FIFOF#(Bit#(asz)) fifo <- mkFIFOF1;

   interface PipeIn in;
      method Action enq(Bit#(n) x) if (count < max || fifo.notFull);
         Bit#(aszn) newbuff = truncate({fbnbuff,x});
         fbnbuff <= newbuff;
         if (count == max)
            begin
               count <= 0;
               fifo.enq(truncate(newbuff));
            end
         else
            begin
               count <= count+1;
            end
      endmethod
      method notFull = fifo.notFull;
   endinterface
   interface PipeOut out;
      method first = unpack(fifo.first);
      method deq = fifo.deq;
      method notEmpty = fifo.notEmpty;
   endinterface
endmodule

interface AdapterIndication;
   method Action done();
endinterface

interface AdapterTb;
   method Action start();
endinterface

module mkAdapterTb#(AdapterIndication indication)(AdapterTb);
   AdapterToBus#(32,Bit#(72)) tb32_72 <- mkAdapterToBus();
   AdapterToBus#(32,Bit#(17)) tb32_17 <- mkAdapterToBus();
   AdapterFromBus#(32,Bit#(72)) fb32_72 <- mkAdapterFromBus();
   AdapterFromBus#(32,Bit#(17)) fb32_17 <- mkAdapterFromBus();
   
   Reg#(Bit#(10)) timer <- mkReg(0);
   rule timeout;
       timer <= timer+1;
       dynamicAssert(timer < 128, "Timeout");
   endrule

   let fsm <- mkFSM(
      seq
       // test to bit-32
       tb32_72.in.enq(72'h090807060504030201);
       dynamicAssert(tb32_72.out.notEmpty, "Adapter not empty");
       dynamicAssert(!tb32_72.in.notFull, "Adapter full");
       $display("tb32_72 notEmpty %d notFull %d", tb32_72.out.notEmpty, tb32_72.in.notFull);
       $display("tb32_72 word 0 %h", tb32_72.out.first());
       dynamicAssert(tb32_72.out.first == 32'h00000009, "expecting 00000009");
       tb32_72.out.deq;
       $display("tb32_72 word 1 %h", tb32_72.out.first());
       dynamicAssert(tb32_72.out.first == 32'h08070605, "expecting 08070605");
       tb32_72.out.deq;
       $display("tb32_72 word 2 %h", tb32_72.out.first());
       dynamicAssert(tb32_72.out.first == 32'h04030201, "expecting 04030201");
       tb32_72.out.deq;
       dynamicAssert(!tb32_72.out.notEmpty && tb32_72.in.notFull, "Adapter empty and not full");
       $display("tb32_72 notEmpty %d notFull %d", tb32_72.out.notEmpty, tb32_72.in.notFull);
       dynamicAssert(!tb32_17.out.notEmpty, "tb32_17 empty");
       dynamicAssert(tb32_17.in.notFull, "tb32_17 !full");
       tb32_17.in.enq(17'h10203);
       dynamicAssert(tb32_17.out.notEmpty, "tb32_17 not empty");
       dynamicAssert(!tb32_17.in.notFull, "tb32_17 full");
       $display("tb32_17.out.first %h", tb32_17.out.first);
       dynamicAssert(tb32_17.out.first == (32'h00010203), "Expected 00010203");
       tb32_17.out.deq;
       dynamicAssert(!tb32_17.out.notEmpty, "tb32_17 empty");
       dynamicAssert(tb32_17.in.notFull, "tb32_17 !full");

       //test from bit-32
       dynamicAssert(!fb32_72.out.notEmpty, "Adapter empty");
       dynamicAssert(fb32_72.in.notFull, "Adapter not full");
       $display("fb32_72 notEmpty %d notFull %d", fb32_72.out.notEmpty, fb32_72.in.notFull);
       fb32_72.in.enq(32'h00000009);
       fb32_72.in.enq(32'h08070605);
       fb32_72.in.enq(32'h04030201);
       $display("fb32_72.out.first %h", fb32_72.out.first);
       dynamicAssert(fb32_72.out.first == 72'h090807060504030201, "Expected 090807060504030201");
       fb32_72.out.deq;
       fb32_72.in.enq(32'h09080706);
       dynamicAssert(!fb32_72.out.notEmpty, "Adapter not empty");
       dynamicAssert(fb32_72.in.notFull, "Adapter not full");
       fb32_72.in.enq(32'h05040302);
       fb32_72.in.enq(32'h01000000);
       dynamicAssert(fb32_72.out.notEmpty, "Adapter not empty");
       dynamicAssert(!fb32_72.in.notFull, "Adapter full");
       $display("fb32_72.out.first %h", fb32_72.out.first);
       dynamicAssert(fb32_72.out.first == 72'h060504030201000000, "Expected 060504030201000000");
       fb32_72.out.deq;
       $display("fb32_72 notEmpty %d notFull %d", fb32_72.out.notEmpty, fb32_72.in.notFull);
       dynamicAssert(!fb32_72.out.notEmpty, "Adapter empty");
       dynamicAssert(fb32_72.in.notFull, "Adapter not full");
       fb32_17.in.enq(32'h10203);
       dynamicAssert(fb32_17.out.notEmpty, "Adapter not empty");
       dynamicAssert(!fb32_17.in.notFull, "Adapter full");
       $display("fb32_17.out.first %h", fb32_17.out.first);
       dynamicAssert(fb32_17.out.first == 17'h10203, "Expected 10203");
       fb32_17.out.deq;
       dynamicAssert(!fb32_17.out.notEmpty, "Adapter empty");
       dynamicAssert(fb32_17.in.notFull, "Adapter not full");


       // they should be duals
       tb32_72.in.enq(72'h090807060504030201);
       fb32_72.in.enq(tb32_72.out.first);
       tb32_72.out.deq;
       fb32_72.in.enq(tb32_72.out.first);
       tb32_72.out.deq;
       fb32_72.in.enq(tb32_72.out.first);
       tb32_72.out.deq;
       dynamicAssert(fb32_72.out.first == 72'h090807060504030201, "Expected 090807060504030201");
       fb32_72.out.deq;
             
       tb32_17.in.enq(17'h10203);
       fb32_17.in.enq(tb32_17.out.first);
       tb32_17.out.deq;
       dynamicAssert(fb32_17.out.first == 17'h10203, "Expected 10203");
       fb32_17.out.deq;
       	     
       indication.done();
   endseq
   );

   method Action start();
       fsm.start();
   endmethod
endmodule
