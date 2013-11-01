
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

function Bit#(a) rtruncate(Bit#(b) x) provisos(Add#(k,a,b));
   match {.v,.*} = split(x);
   return v;
endfunction

interface ToBit32#(type a);
   method Action enq(a v);          
   method Bit#(32) first;
   method Action deq();
   method Bool notEmpty();
   method Bool notFull();
endinterface
   
interface FromBit32#(type a);
   method Action enq(Bit#(32) v);
   method a first();
   method Action deq();
   method Bool notEmpty();
   method Bool notFull();
endinterface

module mkToBit32(ToBit32#(a))
   provisos(Bits#(a,asz),
            Add#(1, z, asz),
            Div#(asz,32,nwords),
            Mul#(32,nwords,asz32),
            Add#(32,a__,asz32),
            Add#(asz,paddingsz,asz32));
   
   Bit#(32) size = fromInteger(valueOf(asz));
   Bit#(32) max  = fromInteger(valueOf(nwords)) - 1;
   Bit#(paddingsz) padding = 0;

   FIFOF#(Bit#(asz32)) fifo <- mkFIFOF1();
   Reg#(Bit#(32))   count <- mkReg(0);

   method Action enq(a val);
      fifo.enq({padding,pack(val)});
   endmethod

   method Bit#(32) first() if (fifo.notEmpty);
      return rtruncate(fifo.first << (count*32));
   endmethod

   method Action deq() if (fifo.notEmpty);
      if (count == max)
         begin 
            count <= 0;
            fifo.deq;
         end
      else
         begin
            count <= count + 1;
         end   
   endmethod
   method Bool notEmpty = fifo.notEmpty;
   method Bool notFull = fifo.notFull;
endmodule

module mkFromBit32(FromBit32#(a))
   provisos(Bits#(a,asz),
            Add#(1,z,asz),
            Div#(asz,32,nwords),
            Mul#(32,nwords,asz32),
            Add#(32,a__,asz32),
            Add#(asz,paddingsz,asz32));

   Bit#(32) size   = fromInteger(valueOf(asz));
   Bit#(32) max    = fromInteger(valueOf(nwords))-1;

   Reg#(Bit#(asz32)) fb32buff <- mkReg(0);
   Reg#(Bit#(32))    count <- mkReg(0);
   FIFOF#(Bit#(asz)) fifo <- mkFIFOF1;

   method Action enq(Bit#(32) x) if (count < max || fifo.notFull);
      Bit#(asz32) newbuff = truncate({fb32buff,x});
      fb32buff <= newbuff;
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

   method a first;
       return unpack(fifo.first);
   endmethod

   method Action deq;
       fifo.deq;
   endmethod

   method Bool notEmpty() = fifo.notEmpty;
   method Bool notFull() = fifo.notFull;
endmodule

module mkAdapterTb(Empty);
   ToBit32#(Bit#(72)) tb32_72 <- mkToBit32();
   ToBit32#(Bit#(17)) tb32_17 <- mkToBit32();

   FromBit32#(Bit#(72)) fb32_72 <- mkFromBit32();
   FromBit32#(Bit#(17)) fb32_17 <- mkFromBit32();

   Reg#(Bit#(10)) timer <- mkReg(0);
   rule timeout;
       timer <= timer+1;
       dynamicAssert(timer < 128, "Timeout");
   endrule

   mkAutoFSM(
      seq
      
       // test to bit-32
       tb32_72.enq(72'h090807060504030201);
       dynamicAssert(tb32_72.notEmpty, "Adapter not empty");
       dynamicAssert(!tb32_72.notFull, "Adapter full");
       $display("tb32_72 notEmpty %d notFull %d", tb32_72.notEmpty, tb32_72.notFull);
       $display("tb32_72 word 0 %h", tb32_72.first());
       dynamicAssert(tb32_72.first == 32'h00000009, "expecting 00000009");
       tb32_72.deq;
       $display("tb32_72 word 1 %h", tb32_72.first());
       dynamicAssert(tb32_72.first == 32'h08070605, "expecting 08070605");
       tb32_72.deq;
       $display("tb32_72 word 2 %h", tb32_72.first());
       dynamicAssert(tb32_72.first == 32'h04030201, "expecting 04030201");
       tb32_72.deq;
       dynamicAssert(!tb32_72.notEmpty && tb32_72.notFull, "Adapter empty and not full");
       $display("tb32_72 notEmpty %d notFull %d", tb32_72.notEmpty, tb32_72.notFull);
       dynamicAssert(!tb32_17.notEmpty, "tb32_17 empty");
       dynamicAssert(tb32_17.notFull, "tb32_17 !full");
       tb32_17.enq(17'h10203);
       dynamicAssert(tb32_17.notEmpty, "tb32_17 not empty");
       dynamicAssert(!tb32_17.notFull, "tb32_17 full");
       $display("tb32_17.first %h", tb32_17.first);
       dynamicAssert(tb32_17.first == (32'h00010203), "Expected 00010203");
       tb32_17.deq;
       dynamicAssert(!tb32_17.notEmpty, "tb32_17 empty");
       dynamicAssert(tb32_17.notFull, "tb32_17 !full");

       //test from bit-32
       dynamicAssert(!fb32_72.notEmpty, "Adapter empty");
       dynamicAssert(fb32_72.notFull, "Adapter not full");
       $display("fb32_72 notEmpty %d notFull %d", fb32_72.notEmpty, fb32_72.notFull);
       fb32_72.enq(32'h00000009);
       fb32_72.enq(32'h08070605);
       fb32_72.enq(32'h04030201);
       $display("fb32_72.first %h", fb32_72.first);
       dynamicAssert(fb32_72.first == 72'h090807060504030201, "Expected 090807060504030201");
       fb32_72.deq;
       fb32_72.enq(32'h09080706);
       dynamicAssert(!fb32_72.notEmpty, "Adapter not empty");
       dynamicAssert(fb32_72.notFull, "Adapter not full");
       fb32_72.enq(32'h05040302);
       fb32_72.enq(32'h01000000);
       dynamicAssert(fb32_72.notEmpty, "Adapter not empty");
       dynamicAssert(!fb32_72.notFull, "Adapter full");
       $display("fb32_72.first %h", fb32_72.first);
       dynamicAssert(fb32_72.first == 72'h060504030201000000, "Expected 060504030201000000");
       fb32_72.deq;
       $display("fb32_72 notEmpty %d notFull %d", fb32_72.notEmpty, fb32_72.notFull);
       dynamicAssert(!fb32_72.notEmpty, "Adapter empty");
       dynamicAssert(fb32_72.notFull, "Adapter not full");
       fb32_17.enq(32'h10203);
       dynamicAssert(fb32_17.notEmpty, "Adapter not empty");
       dynamicAssert(!fb32_17.notFull, "Adapter full");
       $display("fb32_17.first %h", fb32_17.first);
       dynamicAssert(fb32_17.first == 17'h10203, "Expected 10203");
       fb32_17.deq;
       dynamicAssert(!fb32_17.notEmpty, "Adapter empty");
       dynamicAssert(fb32_17.notFull, "Adapter not full");


       // they should be duals
       tb32_72.enq(72'h090807060504030201);
       fb32_72.enq(tb32_72.first);
       tb32_72.deq;
       fb32_72.enq(tb32_72.first);
       tb32_72.deq;
       fb32_72.enq(tb32_72.first);
       tb32_72.deq;
       dynamicAssert(fb32_72.first == 72'h090807060504030201, "Expected 090807060504030201");
       fb32_72.deq;
             
       tb32_17.enq(17'h10203);
       fb32_17.enq(tb32_17.first);
       tb32_17.deq;
       dynamicAssert(fb32_17.first == 17'h10203, "Expected 10203");
       fb32_17.deq;
       	     
       $finish(0);
   endseq
   );

endmodule
