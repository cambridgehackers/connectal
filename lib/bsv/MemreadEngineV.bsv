// Copyright (c) 2013 Quanta Research Cambridge, Inc.

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

import Vector::*;
import FIFOF::*;
import FIFO::*;
import GetPut::*;
import Assert::*;
import ClientServer::*;
import BRAM::*;

import PortalMemory::*;
import Dma::*;

typedef struct {ObjectPointer pointer;
		Bit#(ObjectOffsetSize) base;
		Bit#(8) burstLen;
		Bit#(32) readLen;
		} MemengineCmd deriving (Eq,Bits);

interface MemreadEngineV#(numeric type dataWidth, numeric type cmdQDepth, numeric type numServers);
   interface Vector#(numServers, Server#(MemengineCmd,Bool)) readServers;
   interface ObjectReadClient#(dataWidth) dmaClient;
endinterface

interface Funnel#(numeric type numInputs, type a);
   interface Vector#(numInputs, Put#(a)) inputs;
   interface Get#(Tuple2#(Bit#(TLog#(numInputs)), a)) out;
endinterface

module mkFunnel(Funnel#(numInputs,a))
   provisos (Log#(numInputs, logNumInputs),
	     Bits#(a,a__));
   
   Vector#(TAdd#(logNumInputs,1), Vector#(numInputs, FIFO#(Tuple2#(Bit#(logNumInputs),a)))) infss <- replicateM(replicateM(mkFIFO));
   for(Integer j = valueOf(logNumInputs); j > 0; j=j-1) 
      for(Integer i = 0; i < 2**j; i=i+1) 
	 rule xfer;
	    let x <- toGet(infss[j][i]).get;
	    infss[j-1][i/2].enq(x);
	 endrule
   
   function Put#(a) my_toPut(FIFO#(Tuple2#(Bit#(logNumInputs),a)) f, Integer i) = 
      (interface Put;
	  method Action put(a x);
	     f.enq(tuple2(fromInteger(i),x));
	  endmethod
       endinterface);
   interface Vector inputs = zipWith(my_toPut, infss[valueOf(logNumInputs)], genVector);
   interface out = toGet(infss[0][0]);
endmodule

module mkMemreadEngineV#(Vector#(numServers, FIFOF#(Bit#(dataWidth))) fs) (MemreadEngineV#(dataWidth, cmdQDepth, numServers))
   provisos (Div#(dataWidth,8,dataWidthBytes),
	     Mul#(dataWidthBytes,8,dataWidth),
	     Log#(dataWidthBytes,beatShift),
	     Mul#(cmdQDepth,numServers,cmdBuffSz),
	     Log#(cmdBuffSz, cmdBuffAddrSz),
	     Log#(numServers, serverIdxSz),
	     Add#(1,cmdQDepth, outCntSz),
	     Add#(b__, TLog#(numServers), cmdBuffAddrSz),
	     Add#(a__, serverIdxSz, cmdBuffAddrSz));
   
   function Bit#(cmdBuffAddrSz) hf(Integer i) = fromInteger(i*valueOf(cmdQDepth));
   Vector#(numServers, Reg#(Bit#(outCntSz)))     outs1 <- replicateM(mkReg(0));
   Vector#(numServers, Reg#(Bit#(outCntSz)))     outs0 <- replicateM(mkReg(0));
   Vector#(numServers, Reg#(Bit#(cmdBuffAddrSz))) head <- mapM(mkReg, genWith(hf));
   Vector#(numServers, Reg#(Bit#(cmdBuffAddrSz))) tail <- mapM(mkReg, genWith(hf));
   Funnel#(numServers, MemengineCmd)              infs <- mkFunnel;

   BRAM1Port#(Bit#(cmdBuffAddrSz),MemengineCmd) cmdBuf <- mkBRAM1Server(defaultValue);
   FIFO#(Bit#(serverIdxSz))                       outf <- mkSizedFIFO(1);   
   FIFO#(Bit#(serverIdxSz))                      loadf <- mkSizedFIFO(1);
   FIFO#(Tuple3#(Bit#(8),Bit#(serverIdxSz),Bool))workf <- mkSizedFIFO(32); // isthis the right size?
   
   Reg#(Bit#(8))                               respCnt <- mkReg(0);
   Reg#(Bit#(serverIdxSz))                     loadIdx <- mkReg(0);
   let beat_shift = fromInteger(valueOf(beatShift));
   let cmd_q_depth = fromInteger(valueOf(cmdQDepth));

   rule store_cmd;
      match {.idx, .cmd} <- infs.out.get;
      let new_tail = tail[idx]+1;
      if (new_tail >= extend(idx+1)*cmd_q_depth)
	 new_tail = extend(idx)*cmd_q_depth;
      tail[idx] <= new_tail;
      outs1[idx] <= outs1[idx]+1;
      cmdBuf.portA.request.put(BRAMRequest{write:True, responseOnWrite:False, address:tail[idx], datain:cmd});
      $display("store_cmd: %d %h", idx, tail[idx]);
   endrule
   
   rule load_ctxt;
      loadIdx <= loadIdx+1;
      if (outs1[loadIdx] > 0) begin
	 cmdBuf.portA.request.put(BRAMRequest{write:False, responseOnWrite:False, address:head[loadIdx], datain:?});
	 loadf.enq(loadIdx);
	 //$display("load_ctxt %d, %h", loadIdx, head[loadIdx]);
      end
   endrule
   
   Vector#(numServers, Server#(MemengineCmd,Bool)) rs;
   for(Integer i = 0; i < valueOf(numServers); i=i+1)
      rs[i] =  (interface Server#(MemengineCmd,Bool);
		   interface Put request;
		      method Action put(MemengineCmd c) if (outs0[i] < cmd_q_depth);
			 outs0[i] <= outs0[i]+1;
			 infs.inputs[i].put(c);
 		      endmethod
		   endinterface
		   interface Get response;
		      method ActionValue#(Bool) get if (outf.first == fromInteger(i));
			 outf.deq;
	 		 outs0[outf.first] <= outs0[outf.first]-1;
			 return True;
		      endmethod
		   endinterface
		endinterface);
   interface readServers = rs;
   interface ObjectReadClient dmaClient;
      interface Get readReq;
	 method ActionValue#(ObjectRequest) get();
	    let cmd <- cmdBuf.portA.response.get;
	    let idx <- toGet(loadf).get;
	    Bit#(8) bl = cmd.burstLen;
	    let last = False;
	    if (cmd.readLen <= extend(bl)) begin
	       last = True;
	       bl = truncate(cmd.readLen);
	       outs1[idx] <= outs1[idx]-1;
	       let new_head = head[idx]+1;
	       if (new_head >= extend(idx+1)*cmd_q_depth)
		  new_head = extend(idx)*cmd_q_depth;
	       head[idx] <= new_head;
	       //$display("new_head %d %d", idx, new_head);
	    end
	    let new_cmd = MemengineCmd{pointer:cmd.pointer, base:cmd.base+extend(bl), burstLen:cmd.burstLen, readLen:cmd.readLen-extend(bl)};
	    cmdBuf.portA.request.put(BRAMRequest{write:True, responseOnWrite:False, address:head[idx], datain:new_cmd});
	    workf.enq(tuple3(truncate(bl>>beat_shift), idx, last));
	    //$display("readReq %d, %h %h %h", idx, cmd.base, bl, last);
	    return ObjectRequest { pointer: cmd.pointer, offset: cmd.base, burstLen:bl, tag: 0 };
	 endmethod
      endinterface
      interface Put readData;
	 method Action put(ObjectData#(dataWidth) d);
	    match {.rc, .idx, .last} = workf.first;
	    let new_respCnt = respCnt+1;
	    //$display("%h %d", d.data, idx);
	    if (new_respCnt == rc) begin
	       respCnt <= 0;
	       workf.deq;
	       //$display("eob %d", idx);
	       if(last) begin
		  outf.enq(idx);
		  //$display("eob %d", idx);
	       end
	    end
	    else begin
	       respCnt <= new_respCnt;
	    end
	    fs[idx].enq(d.data);
	 endmethod
      endinterface
   endinterface   
endmodule
