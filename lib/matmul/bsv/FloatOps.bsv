import FIFOF::*;
import GetPut::*;
import ClientServer::*;
import FloatingPoint::*;
import DefaultValue::*;
import Randomizable::*;
import Vector::*;
import StmtFSM::*;
import Pipe::*;
import FIFO::*;
import FpMac::*;

interface FloatAlu;
   interface Put#(Tuple2#(Float,Float)) request;
   interface Get#(Tuple2#(Float,Exception)) response;
endinterface

(* synthesize *)
module mkFloatAdder#(RoundMode rmode)(FloatAlu);
`ifdef BSIM
   let adder <- mkFPAdder(rmode);
`else
   let adder <- mkXilinxFPAdder(rmode);
`endif
   interface Put request;
      method Action put(Tuple2#(Float,Float) req);
	 match { .a, .b } = req;
	 let tpl3 = tuple3(a, b, rmode);
         adder.request.put(req);
      endmethod
   endinterface
   interface Get response;
      method ActionValue#(Tuple2#(Float,Exception)) get();
	 let resp <- adder.response.get();
	 return resp;
      endmethod
   endinterface
endmodule

module mkFloatAddPipe#(PipeOut#(Tuple2#(Float,Float)) xypipe)(PipeOut#(Float));
   let adder <- mkFloatAdder(defaultValue);
   FIFOF#(Float) fifo <- mkFIFOF();
   rule consumexy;
      let xy = xypipe.first();
      xypipe.deq;
      adder.request.put(tuple2(tpl_1(xy),tpl_2(xy)));
   endrule
   rule enqout;
      let resp <- adder.response.get();
      fifo.enq(tpl_1(resp));
   endrule
   return toPipeOut(fifo);
endmodule

(* synthesize *)
module mkFloatSubtracter#(RoundMode rmode)(FloatAlu);
`ifdef BSIM
   let adder <- mkFPAdder(rmode);
`else
   let adder <- mkXilinxFPAdder(rmode);
`endif
   interface Put request;
      method Action put(Tuple2#(Float,Float) req);
	 match { .a, .b } = req;
	 let tpl3 = tuple3(a, negate(b), rmode);
         adder.request.put(req);
      endmethod
   endinterface
   interface Get response;
      method ActionValue#(Tuple2#(Float,Exception)) get();
	 let resp <- adder.response.get();
	 return resp;
      endmethod
   endinterface
endmodule

module mkFloatSubPipe#(PipeOut#(Tuple2#(Float,Float)) xypipe)(PipeOut#(Float));
   let subtracter <- mkFloatSubtracter(defaultValue);
   FIFOF#(Float) fifo <- mkFIFOF();
   rule consumexy;
      let xy = xypipe.first();
      xypipe.deq;
      subtracter.request.put(tuple2(tpl_1(xy),tpl_2(xy)));
   endrule
   rule enqout;
      let resp <- subtracter.response.get();
      fifo.enq(tpl_1(resp));
   endrule
   return toPipeOut(fifo);
endmodule

(* synthesize *)
module mkFloatMultiplier#(RoundMode rmode)(FloatAlu);
`ifdef BSIM
   let multiplier <- mkFPMultiplier(rmode);
`else
   let multiplier <- mkXilinxFPMultiplier(rmode);
`endif
   interface Put request;
      method Action put(Tuple2#(Float,Float) req);
         multiplier.request.put(req);
      endmethod
   endinterface
   interface Get response;
      method ActionValue#(Tuple2#(Float,Exception)) get();
	 let resp <- multiplier.response.get();
	 return resp;
      endmethod
   endinterface
endmodule

(* synthesize *)
module mkRandomPipe(PipeOut#(Float));
   let randomizer <- mkConstrainedRandomizer(0, 1024);

   Reg#(Bool) initted <- mkReg(False);
   rule first if (!initted);
      randomizer.cntrl.init();
      initted <= True;
   endrule

   let pipe_out <- mkPipeOut(interface Get#(Float);
				method ActionValue#(Float) get();
				   let v <- randomizer.next();
				   Float f = fromInt32(v); 
				   return f;
				endmethod
			     endinterface);
   return pipe_out;
endmodule

