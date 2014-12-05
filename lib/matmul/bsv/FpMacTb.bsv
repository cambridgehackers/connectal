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
// bsv libraries
import SpecialFIFOs::*;
import Vector::*;
import StmtFSM::*;
import FIFO::*;
import Connectable::*;
import FloatingPoint::*;
import ClientServer::*;
import GetPut::*;
import DefaultValue::*;
import FIFOF::*;

// Connectal libraries
import RbmTypes::*;
import FpMac::*;
import FloatOps::*;

interface FpMacRequest;
   method Action mac(Bit#(32) x, Bit#(32) y);
endinterface

interface FpMacIndication;
   method Action res(Bit#(32) v, Bit#(32) e);
endinterface

module mkFpMacRequest#(FpMacIndication indication) (FpMacRequest);
   
   let fpmac <- mkFloatMac(Rnd_Nearest_Even); //defaultValue
   Reg#(Float) accum <- mkReg(0);
   
   rule res;
      let resp <- fpmac.response.get;
      accum <= tpl_1(resp);
      indication.res(pack(tpl_1(resp)), extend(pack(tpl_2(resp))));
   endrule
   
   method Action mac(Bit#(32) x, Bit#(32) y);
      fpmac.request.put(tuple3(tagged Valid accum, unpack(x), unpack(y)));
   endmethod

endmodule


interface FpMulRequest;
   method Action mul_req(Bit#(32) x, Bit#(32) y);
endinterface

interface FpMulIndication;
   method Action mul_resp(Bit#(32) v);
endinterface

module mkFpMulRequest#(FpMulIndication indication) (FpMulRequest);
   
   FloatAlu mul   <- mkFloatMultiplier(defaultValue);
   Reg#(Float) accum <- mkReg(0);
   Reg#(int) cycles <- mkReg(0);
   Reg#(int) last_mul <- mkReg(0);
   Reg#(int) num_reqs <- mkReg(0);
   Reg#(int) num_resps <- mkReg(0);
   let req_fifo <- mkFIFOF;
   
   rule cycle;
      cycles <= cycles+1;
   endrule
   
   rule feed if (num_reqs > 0);
      num_reqs <= num_reqs-1;
      mul.request.put(req_fifo.first);
   endrule
   
   rule drain;
      match {.resp,.*} <- mul.response.get;
      accum <= resp;      
      num_resps <= num_resps-1;
      last_mul <= cycles;
      $display("drain %d", cycles-last_mul);
   endrule
      
   rule res if (num_reqs == 0 && req_fifo.notEmpty);
      indication.mul_resp(pack(accum));
      req_fifo.deq;
   endrule
   
   method Action mul_req(Bit#(32) x, Bit#(32) y);
      req_fifo.enq(tuple2(unpack(x), unpack(y)));
      num_reqs <= 64;
      num_resps <= 64;
   endmethod

endmodule

