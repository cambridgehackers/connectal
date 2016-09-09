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
`include "ConnectalProjectConfig.bsv"
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

`ifdef SIMULATION
`ifndef BOARD_xsim
`define USE_BSV_FP
`endif // xsim
`else // !SIMULATION
`ifndef XILINX
`define USE_BSV_FP
`endif // !XILINX
`endif // !SIMULATION

interface FloatAlu;
   interface Put#(Tuple2#(Float,Float)) request;
   interface Get#(Tuple2#(Float,Exception)) response;
endinterface

(* synthesize *)
module mkDoubleToFloat(Server#(Double,Float));
   FIFO#(Double) requestFifo <- mkFIFO();
   FIFO#(Float) responseFifo <- mkFIFO();
   rule cvt;
      Double d <- toGet(requestFifo).get();
      Tuple2#(Float,Exception) tpl = convert(d, defaultValue, False);
      match { .f, .exc } = tpl;
      responseFifo.enq(f);
   endrule
   interface Put request = toPut(requestFifo);
   interface Get response = toGet(responseFifo);
endmodule

(* synthesize *)
module mkFloatToDouble(Server#(Float,Double));
   FIFO#(Float)  requestFifo <- mkFIFO();
   FIFO#(Double) responseFifo <- mkFIFO();
   rule cvt;
      Float f <- toGet(requestFifo).get();
      Tuple2#(Double,Exception) tpl = convert(f, defaultValue, False);
      match { .d, .exc } = tpl;
      responseFifo.enq(d);
   endrule
   interface Put request = toPut(requestFifo);
   interface Get response = toGet(responseFifo);
endmodule

(* synthesize *)
module mkFloatAdder#(RoundMode rmode)(FloatAlu);
`ifdef USE_BSV_FP
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
`ifdef USE_BSV_FP
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
`ifdef USE_BSV_FP
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
/*********** missing fromInt32()
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
*/

