/* Copyright (c) 2014 Quanta Research Cambridge, Inc
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included
 * in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */
import FIFO::*;
import SpecialFIFOs::*;
import Complex::*;
import FIFOF::*;
import Vector::*;
import StmtFSM::*;


interface PipeMul#(numeric type stages, numeric type dsz, type marker);
   method Action put(UInt#(dsz) x, UInt#(dsz) y, marker m);
   method ActionValue#(Tuple2#(UInt#(dsz),marker)) get();
endinterface	     

module mkPipeMul(PipeMul#(stages,dsz,marker))
   provisos(Mul#(2,dsz,buff_width),
	    Add#(a__,dsz,buff_width),
	    Bits#(marker, b__));

   Vector#(stages, Reg#(UInt#(buff_width))) mul_data <- replicateM(mkReg(0));
   Vector#(TAdd#(stages,1),FIFO#(marker)) mul_ctrl <- replicateM(mkLFIFO);
	    
   Reg#(UInt#(dsz))  a <- mkRegU;
   Reg#(UInt#(dsz))  b <- mkRegU;
   FIFO#(UInt#(dsz)) out <- mkLFIFO;
   FIFO#(Tuple3#(UInt#(dsz),UInt#(dsz),marker)) inf <- mkLFIFO;
   FIFO#(Tuple2#(UInt#(dsz),marker)) outf <- mkLFIFO;
      
   rule do_mul;
      UInt#(buff_width) bits = extend(b) * extend(a);
      mul_data[0] <= bits;
      for(Integer i = 1; i < valueOf(stages); i = i+1)
      	 mul_data[i] <= mul_data[i-1];
   endrule
   
   for(Integer i = 0; i < valueOf(stages); i = i+1)
      rule do_ctrl;
   	 mul_ctrl[i+1].enq(mul_ctrl[i].first);
   	 mul_ctrl[i].deq;
      endrule
   
   rule final_xfer;
      mul_ctrl[valueOf(stages)].deq;
      UInt#(buff_width) bits = mul_data[valueOf(stages)-1];
      UInt#(dsz) rv  = truncate(bits);
      outf.enq(tuple2(rv,mul_ctrl[valueOf(stages)].first));
   endrule
   
   rule start;
      inf.deq;
      a <= tpl_1(inf.first);
      b <= tpl_2(inf.first);
      mul_ctrl[0].enq(tpl_3(inf.first));
   endrule

   method Action put(UInt#(dsz) x, UInt#(dsz) y, marker m);
      inf.enq(tuple3(x,y,m));
   endmethod
   
   method ActionValue#(Tuple2#(UInt#(dsz),marker)) get();
      outf.deq;
      return outf.first;
   endmethod
   
endmodule

interface PipeMul2#(numeric type stages, numeric type dsz, type marker);
   method Action put(UInt#(dsz) x, UInt#(dsz) y, marker m);
   method ActionValue#(Tuple2#(UInt#(TMul#(dsz,2)),marker)) get();
endinterface	     

module mkPipeMul2(PipeMul2#(2,dsz,marker))
   provisos(Add#(2,0,stages),
	    Mul#(2,dsz,odsz),
	    Add#(16,aszm16,dsz),
	    Add#(16,c__,odsz),
	    Add#(a__,dsz,odsz),
	    Bits#(marker, b__));

   Vector#(stages, Reg#(Tuple2#(UInt#(odsz),UInt#(odsz)))) mul_data <- replicateM(mkReg(unpack(0)));
   Vector#(TAdd#(stages,1),FIFO#(marker)) mul_ctrl <- replicateM(mkLFIFO);
	    
   Reg#(UInt#(dsz))  a <- mkRegU;
   Reg#(UInt#(dsz))  b <- mkRegU;
   FIFO#(UInt#(dsz)) out <- mkLFIFO;
   FIFO#(Tuple3#(UInt#(dsz),UInt#(dsz),marker)) inf <- mkLFIFO;
   FIFO#(Tuple2#(UInt#(odsz),marker)) outf <- mkLFIFO;
      
   rule do_mul;
      UInt#(odsz) lsbits = extend(b) * extend(unpack(pack(a)[15:0]));
      UInt#(odsz) amsbits = unpack(pack(a)[valueOf(dsz)-1:16]);
      UInt#(odsz) msbits = extend(b) * amsbits;
      mul_data[0] <= tuple2(lsbits,msbits);
   endrule
   rule do_add;
      match { .lsbits, .msbits } = mul_data[0];
      UInt#(odsz) prod = lsbits + (msbits << 16);
      mul_data[1] <= tuple2(0, prod);
   endrule
   
   for(Integer i = 0; i < valueOf(stages); i = i+1)
      rule do_ctrl;
   	 mul_ctrl[i+1].enq(mul_ctrl[i].first);
   	 mul_ctrl[i].deq;
      endrule
   
   rule final_xfer;
      mul_ctrl[valueOf(stages)].deq;
      match { .zero, .rv } = mul_data[valueOf(stages)-1];
      outf.enq(tuple2(rv,mul_ctrl[valueOf(stages)].first));
   endrule
   
   rule start;
      inf.deq;
      a <= tpl_1(inf.first);
      b <= tpl_2(inf.first);
      mul_ctrl[0].enq(tpl_3(inf.first));
   endrule

   method Action put(UInt#(dsz) x, UInt#(dsz) y, marker m);
      inf.enq(tuple3(x,y,m));
   endmethod
   
   method ActionValue#(Tuple2#(UInt#(odsz),marker)) get();
      outf.deq;
      return outf.first;
   endmethod
   
endmodule

// module mkTestBench();
//    PipeMul#(1,FixedPoint#(8,24)) multiplier <- mkPipeMul;
//    Stmt test = 
//    seq
//       multiplier.put(fromReal(-1.0),fromReal(2.0));
//       action
// 	 let rv <- multiplier.get;
// 	 $write("mul: ");
// 	 dispFP824(rv);
//       endaction
//    endseq;
//    mkAutoFSM(test);
// endmodule


