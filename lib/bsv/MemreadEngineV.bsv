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
import Pipe::*;

typedef struct {ObjectPointer pointer;
		Bit#(ObjectOffsetSize) base;
		Bit#(8) burstLen;
		Bit#(32) len;
		} MemengineCmd deriving (Eq,Bits);

interface MemreadEngineV#(numeric type dataWidth, numeric type cmdQDepth, numeric type numServers);
   interface Vector#(numServers, Server#(MemengineCmd,Bool)) readServers;
   interface ObjectReadClient#(dataWidth) dmaClient;
   interface Vector#(numServers, PipeOut#(Bit#(dataWidth))) dataPipes;
endinterface


module mkMemreadEngineV(MemreadEngineV#(dataWidth, cmdQDepth, numServers))
   provisos (Div#(dataWidth,8,dataWidthBytes),
	     Mul#(dataWidthBytes,8,dataWidth),
	     Log#(dataWidthBytes,beatShift),
	     Mul#(cmdQDepth,numServers,cmdBuffSz),
	     Log#(cmdBuffSz, cmdBuffAddrSz),
	     Log#(numServers, serverIdxSz),
	     Add#(1,cmdQDepth, outCntSz),
	     Add#(1, c__, numServers),
	     Add#(b__, TLog#(numServers), cmdBuffAddrSz),
	     Add#(a__, serverIdxSz, cmdBuffAddrSz));
   
   function Bit#(cmdBuffAddrSz) hf(Integer i) = fromInteger(i*valueOf(cmdQDepth));
   Vector#(numServers, Reg#(Bit#(outCntSz)))     outs1 <- replicateM(mkReg(0));
   Vector#(numServers, Reg#(Bit#(outCntSz)))     outs0 <- replicateM(mkReg(0));
   Vector#(numServers, Reg#(Bit#(cmdBuffAddrSz))) head <- mapM(mkReg, genWith(hf));
   Vector#(numServers, Reg#(Bit#(cmdBuffAddrSz))) tail <- mapM(mkReg, genWith(hf));

   BRAM1Port#(Bit#(cmdBuffAddrSz),MemengineCmd) cmdBuf <- mkBRAM1Server(defaultValue);
   FIFO#(Bit#(serverIdxSz))                      loadf <- mkSizedFIFO(1);
   FIFO#(Tuple3#(Bit#(8),Bit#(serverIdxSz),Bool))workf <- mkSizedFIFO(32); // isthis the right size?

   Vector#(numServers, FIFO#(void))              outfs <- replicateM(mkSizedFIFO(1));
   Vector#(numServers, FIFOF#(Tuple2#(Bit#(serverIdxSz), MemengineCmd))) cmds_in <- replicateM(mkSizedFIFOF(1));
   FunnelPipe#(1, Tuple2#(Bit#(serverIdxSz), MemengineCmd),2) cmds_in_funnel <- mkFunnel1PipesPipelined(map(toPipeOut,cmds_in));
   FIFOF#(Tuple2#(Bit#(TLog#(numServers)), Tuple2#(Bit#(dataWidth),Bool))) read_data <- mkFIFOF;
   FunnelPipe#(numServers, Tuple2#(Bit#(dataWidth),Bool),2) read_data_unfunnel <- mkUnFunnel1PipesPipelined(toPipeOut(read_data));
   function PipeOut#(Bit#(dataWidth)) check_out(PipeOut#(Tuple2#(Bit#(dataWidth),Bool)) x, Integer i) = 
      (interface PipeOut;
	  method Bit#(dataWidth) first;
	     return tpl_1(x.first);
	  endmethod
	  method Action deq;
	     x.deq;
	     if (tpl_2(x.first)) 
		outfs[i].enq(?);
	  endmethod
	  method Bool notEmpty = x.notEmpty;
       endinterface);
   Vector#(numServers, PipeOut#(Bit#(dataWidth))) read_data_pipes = zipWith(check_out, read_data_unfunnel, genVector);
   
   Reg#(Bit#(8))                               respCnt <- mkReg(0);
   Reg#(Bit#(serverIdxSz))                     loadIdx <- mkReg(0);
   let beat_shift = fromInteger(valueOf(beatShift));
   let cmd_q_depth = fromInteger(valueOf(cmdQDepth));

   rule store_cmd;
      match {.idx, .cmd} <- toGet(cmds_in_funnel[0]).get;
      let new_tail = tail[idx]+1;
      if (new_tail >= extend(idx+1)*cmd_q_depth)
	 new_tail = extend(idx)*cmd_q_depth;
      tail[idx] <= new_tail;
      outs1[idx] <= outs1[idx]+1;
      cmdBuf.portA.request.put(BRAMRequest{write:True, responseOnWrite:False, address:tail[idx], datain:cmd});
      //$display("MemreadEngineV.store_cmd: %d %h", idx, tail[idx]);
   endrule
   
   rule load_ctxt;
      loadIdx <= loadIdx+1;
      if (outs1[loadIdx] > 0) begin
	 cmdBuf.portA.request.put(BRAMRequest{write:False, responseOnWrite:False, address:head[loadIdx], datain:?});
	 loadf.enq(loadIdx);
	 //$display("MemreadEngineV.load_ctxt: %d, %h", loadIdx, head[loadIdx]);
      end
   endrule
   
   Vector#(numServers, Server#(MemengineCmd,Bool)) rs;
   for(Integer i = 0; i < valueOf(numServers); i=i+1)
      rs[i] =  (interface Server#(MemengineCmd,Bool);
		   interface Put request;
		      method Action put(MemengineCmd c) if (outs0[i] < cmd_q_depth);
			 outs0[i] <= outs0[i]+1;
			 cmds_in[i].enq(tuple2(fromInteger(i),c));
 		      endmethod
		   endinterface
		   interface Get response;
		      method ActionValue#(Bool) get;
			 outfs[i].deq;
	 		 outs0[i] <= outs0[i]-1;
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
	    if (cmd.len <= extend(bl)) begin
	       last = True;
	       bl = truncate(cmd.len);
	       outs1[idx] <= outs1[idx]-1;
	       let new_head = head[idx]+1;
	       if (new_head >= extend(idx+1)*cmd_q_depth)
		  new_head = extend(idx)*cmd_q_depth;
	       head[idx] <= new_head;
	       //$display("new_head %d %d", idx, new_head);
	    end
	    let new_cmd = MemengineCmd{pointer:cmd.pointer, base:cmd.base+extend(bl), burstLen:cmd.burstLen, len:cmd.len-extend(bl)};
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
	    let l = False;
	    //$display("%h %d", d.data, idx);
	    if (new_respCnt == rc) begin
	       respCnt <= 0;
	       workf.deq;
	       //$display("eob %d", idx);
	       l = last;
	    end
	    else begin
	       respCnt <= new_respCnt;
	    end
	    read_data.enq(tuple2(idx,tuple2(d.data,l)));
	 endmethod
      endinterface
   endinterface 
   interface dataPipes = read_data_pipes;
endmodule
