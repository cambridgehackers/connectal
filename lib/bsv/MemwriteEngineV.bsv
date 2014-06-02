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

interface MemwriteEngineV#(numeric type dataWidth, numeric type cmdQDepth, numeric type numServers);
   interface Vector#(numServers, Server#(MemengineCmd,Bool)) writeServers;
   interface ObjectWriteClient#(dataWidth) dmaClient;
   interface Vector#(numServers, PipeIn#(Bit#(dataWidth))) dataPipes;
endinterface

interface BurstFunnel#(numeric type k, numeric type w);
   method Action loadIdx(Bit#(TLog#(k)) i);
   interface Vector#(k, PipeIn#(Bit#(w))) dataIn;
   interface Vector#(k, Reg#(Bit#(8))) burstLen;
   interface PipeOut#(Tuple2#(Bit#(TLog#(k)),Bit#(w))) dataOut;
endinterface

module mkBurstFunnel(BurstFunnel#(k,w))
   provisos(Log#(k,logk));
   Vector#(k, FIFOF#(Tuple2#(Bit#(logk), Bit#(w)))) data_in <- replicateM(mkFIFOF);
   Vector#(k,Reg#(Bit#(8))) burst_len <- replicateM(mkReg(0));
   Vector#(k,Reg#(Bit#(8))) inj_ctrl <- replicateM(mkReg(0));
   FIFO#(Bit#(logk)) loadIdxs <- mkSizedFIFO(1);
   function PipeIn#(Bit#(w)) enter_data(FIFOF#(Tuple2#(Bit#(logk), Bit#(w))) f, Integer i) = 
      (interface PipeIn;
   	  method Bool notFull = f.notFull;
   	  method Action enq(Bit#(w) v) if (inj_ctrl[i] > 0);
	     //$display("enq %d %d", i, inj_ctrl[i]);
	     f.enq(tuple2(fromInteger(i), v));
	     let new_inj_ctrl = inj_ctrl[i]-1;
	     inj_ctrl[i] <= new_inj_ctrl;
	     if(new_inj_ctrl==0) begin
		//$display("endBurst %d", i);
		loadIdxs.deq;
	     end
	  endmethod
       endinterface);
   Vector#(k, PipeIn#(Bit#(w))) data_in_pipes = zipWith(enter_data, data_in, genVector);
   FunnelPipe#(1, Tuple2#(Bit#(logk), Bit#(w)),2) data_in_funnel <- mkFunnel1PipesPipelined(map(toPipeOut,data_in));
   method Action loadIdx(Bit#(logk) idx);
      loadIdxs.enq(idx);
      inj_ctrl[idx] <= burst_len[idx];
      //$display("loadIdx %d", idx);
   endmethod
   interface burstLen = burst_len;
   interface dataIn = data_in_pipes;
   interface dataOut = data_in_funnel[0];
endmodule

module mkMemwriteEngineV(MemwriteEngineV#(dataWidth, cmdQDepth, numServers))
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
   FIFO#(Tuple3#(Bit#(8),Bit#(serverIdxSz),Bool))workf <- mkSizedFIFO(32); // is this the right size?
   FIFO#(Tuple2#(Bit#(serverIdxSz),Bool))        donef <- mkSizedFIFO(32); // is this the right size?

   Vector#(numServers, FIFO#(void))              outfs <- replicateM(mkSizedFIFO(1));
   Vector#(numServers, FIFOF#(Tuple2#(Bit#(serverIdxSz), MemengineCmd))) cmds_in <- replicateM(mkSizedFIFOF(1));
   FunnelPipe#(1, Tuple2#(Bit#(serverIdxSz), MemengineCmd),2) cmds_in_funnel <- mkFunnel1PipesPipelined(map(toPipeOut,cmds_in));
   BurstFunnel#(numServers,dataWidth) write_data <- mkBurstFunnel;
      
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
   endrule
   
   rule load_ctxt;
      loadIdx <= loadIdx+1;
      if (outs1[loadIdx] > 0) begin
	 write_data.loadIdx(loadIdx);
	 cmdBuf.portA.request.put(BRAMRequest{write:False, responseOnWrite:False, address:head[loadIdx], datain:?});
	 loadf.enq(loadIdx);
      end
   endrule
   
   Vector#(numServers, Server#(MemengineCmd,Bool)) rs;
   for(Integer i = 0; i < valueOf(numServers); i=i+1)
      rs[i] =  (interface Server#(MemengineCmd,Bool);
		   interface Put request;
		      method Action put(MemengineCmd c) if (outs0[i] < cmd_q_depth);
			 outs0[i] <= outs0[i]+1;
			 cmds_in[i].enq(tuple2(fromInteger(i),c));
			 write_data.burstLen[i] <= c.burstLen >> beat_shift;
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
   interface writeServers = rs;
   interface ObjectWriteClient dmaClient;
      interface Get writeReq;
	 method ActionValue#(ObjectRequest) get();
	    let cmd <- cmdBuf.portA.response.get;
	    let idx <- toGet(loadf).get;
	    Bit#(8) bl = cmd.burstLen;
	    Bool last = False;
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
      interface Get writeData;
	 method ActionValue#(ObjectData#(dataWidth)) get;
	    match {.rc, .idx, .last} = workf.first;
	    let new_respCnt = respCnt+1;
	    if (new_respCnt == rc) begin
	       respCnt <= 0;
	       workf.deq;
	       donef.enq(tuple2(idx,last));
	    end
	    else begin
	       respCnt <= new_respCnt;
	    end
	    match {._idx, .wd} <- toGet(write_data.dataOut).get;
	    dynamicAssert(idx==_idx, "MemwriteEngineV::dmaClient::writeData");
	    return ObjectData{data:wd, tag:0};
	 endmethod
      endinterface
      interface Put writeDone;
	 method Action put(Bit#(6) tag);
	    match {.idx, .last} <- toGet(donef).get;
	    if (last)
	       outfs[idx].enq(?);
	 endmethod
      endinterface
   endinterface 
   interface dataPipes = write_data.dataIn;
endmodule
