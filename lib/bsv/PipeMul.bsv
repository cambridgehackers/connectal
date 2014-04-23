import FIFO::*;
import SpecialFIFOs::*;
import Complex::*;
import FIFOF::*;
import Vector::*;
import StmtFSM::*;


interface PipeMul#(numeric type stages, numeric type dsz);
   method Action put(UInt#(dsz) x, UInt#(dsz) y);
   method ActionValue#(UInt#(dsz)) get();
endinterface	     

module mkPipeMul(PipeMul#(stages,dsz))
   provisos(Mul#(2,dsz,buff_width),
	    Add#(a__,dsz,buff_width));

   Vector#(stages, Reg#(UInt#(buff_width))) mul_data <- replicateM(mkReg(0));
   Vector#(TAdd#(stages,1),FIFO#(void)) mul_ctrl <- replicateM(mkLFIFO);
	    
   Reg#(UInt#(dsz))  a <- mkRegU;
   Reg#(UInt#(dsz))  b <- mkRegU;
   FIFO#(UInt#(dsz)) out <- mkLFIFO;
   FIFO#(UInt#(dsz)) inx <- mkLFIFO;
   FIFO#(UInt#(dsz)) iny <- mkLFIFO;
      
   rule do_mul;
      UInt#(buff_width) bits = extend(b) * extend(a);
      mul_data[0] <= bits;
      for(Integer i = 1; i < valueOf(stages); i = i+1)
      	 mul_data[i] <= mul_data[i-1];
   endrule
   
   for(Integer i = 0; i < valueOf(stages); i = i+1)
      rule do_ctrl;
   	 mul_ctrl[i+1].enq(?);
   	 mul_ctrl[i].deq;
      endrule
   
   rule final_xfer;
      mul_ctrl[valueOf(stages)].deq;
      UInt#(buff_width) bits = mul_data[valueOf(stages)-1];
      UInt#(dsz) rv  = truncate(bits);
      out.enq(rv);
   endrule
   
   rule start;
      inx.deq;
      iny.deq;				
      a <= inx.first;
      b <= iny.first;
      mul_ctrl[0].enq(?);
   endrule

   method Action put(UInt#(dsz) x, UInt#(dsz) y);
      inx.enq(x);
      iny.enq(y);
   endmethod
   
   method ActionValue#(UInt#(dsz)) get();
      out.deq;
      return out.first;
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


