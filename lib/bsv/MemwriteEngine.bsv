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
import GetPut::*;
import ClientServer::*;
import BRAM::*;
import BRAMFIFO::*;
import Connectable::*;

import Ratchet::*;
import PortalMemory::*;
import MemTypes::*;
import Pipe::*;
import MemUtils::*;


module mkMemwriteEngine(MemwriteEngineV#(dataWidth, cmdQDepth, numServers))
   provisos( Mul#(TDiv#(dataWidth, 8), 8, dataWidth)
	    ,Add#(1, a__, numServers)
	    ,Add#(b__, TLog#(numServers), TAdd#(1, TLog#(TMul#(cmdQDepth,numServers))))
	    ,Pipe::FunnelPipesPipelined#(1, numServers,Tuple2#(Bit#(TLog#(numServers)), MemTypes::MemengineCmd), TMin#(2,TLog#(numServers)))
	    ,Pipe::FunnelPipesPipelined#(1, numServers, Tuple2#(Bit#(dataWidth), Bool),TMin#(2, TLog#(numServers)))
	    ,Add#(c__, TLog#(numServers), TLog#(TMul#(cmdQDepth, numServers)))
	    ,FunnelPipesPipelined#(1, numServers,Tuple2#(Bit#(TLog#(numServers)), Bit#(dataWidth)), TMin#(2,TLog#(numServers)))
	    ,Add#(1, d__, dataWidth)
	    );
   let rv <- mkMemwriteEngineBuff(256);
   return rv;
endmodule

interface BurstFunnel#(numeric type k, numeric type w);
   method Action loadIdx(Bit#(TLog#(k)) i);
   interface Vector#(k, PipeIn#(Bit#(w))) dataIn;
   interface Vector#(k, Reg#(Bit#(8))) burstLen;
   interface PipeOut#(Tuple2#(Bit#(TLog#(k)),Bit#(w))) dataOut;
endinterface

module mkBurstFunnel(BurstFunnel#(k,w))
   provisos(Log#(k,logk),
	    Min#(2,logk,bpc),
	    FunnelPipesPipelined#(1, k, Tuple2#(Bit#(logk), Bit#(w)), bpc));
   Vector#(k, FIFOF#(Tuple2#(Bit#(logk), Bit#(w)))) data_in <- replicateM(mkFIFOF);
   Vector#(k,Reg#(Bit#(8))) burst_len <- replicateM(mkReg(0));
   Vector#(k,Reg#(Bit#(8))) inj_ctrl <- replicateM(mkReg(0));
   //TAdd#(1,logk) is because bsc is wierd about comparing literal '0' to a value of Bit#(0)
   FIFO#(Bit#(TAdd#(1,logk))) loadIdxs <- mkSizedFIFO(32);
   function PipeIn#(Bit#(w)) enter_data(FIFOF#(Tuple2#(Bit#(logk), Bit#(w))) f, Integer i) = 
      (interface PipeIn;
   	  method Bool notFull = f.notFull;
   	  method Action enq(Bit#(w) v) if (loadIdxs.first == fromInteger(i));
	     let cnt = (inj_ctrl[i] == 0) ? burst_len[i] : inj_ctrl[i];
	     let new_cnt = cnt-1;
	     inj_ctrl[i] <= new_cnt;
	     if (new_cnt == 0)
		loadIdxs.deq;
	     //$display("enq %d %d", i, inj_ctrl[i]);
	     f.enq(tuple2(fromInteger(i), v));
	  endmethod
       endinterface);
   Vector#(k, PipeIn#(Bit#(w))) data_in_pipes = zipWith(enter_data, data_in, genVector);
   FunnelPipe#(1, k, Tuple2#(Bit#(logk), Bit#(w)),bpc) data_in_funnel <- mkFunnelPipesPipelined(map(toPipeOut,data_in));
   method Action loadIdx(Bit#(logk) idx);
      loadIdxs.enq(extend(idx));
      //$display("loadIdxs %d", idx);
   endmethod
   interface burstLen = burst_len;
   interface dataIn = data_in_pipes;
   interface dataOut = data_in_funnel[0];
endmodule

module mkMemwriteEngineBuff#(Integer bufferSizeBytes)(MemwriteEngineV#(dataWidth, cmdQDepth, numServers))
   provisos ( Div#(dataWidth,8,dataWidthBytes)
	     ,Mul#(dataWidthBytes,8,dataWidth)
	     ,Log#(dataWidthBytes,beatShift)
	     ,Log#(cmdQDepth,logCmdQDepth)
	     ,Mul#(cmdQDepth,numServers,cmdBuffSz)
	     ,Log#(cmdBuffSz, cmdBuffAddrSz)
	     ,Log#(numServers, serverIdxSz)
	     ,Add#(1,logCmdQDepth, outCntSz)
	     ,Add#(1, c__, numServers)
	     ,Add#(b__, TLog#(numServers), cmdBuffAddrSz)
	     ,Add#(e__, TLog#(numServers), TAdd#(1, cmdBuffAddrSz))
	     ,Add#(a__, serverIdxSz, cmdBuffAddrSz)
	     ,Min#(2,TLog#(numServers),bpc)
	     ,FunnelPipesPipelined#(1,numServers,Tuple2#(Bit#(serverIdxSz),MemengineCmd),bpc)
	     ,FunnelPipesPipelined#(1,numServers,Tuple2#(Bit#(dataWidth),Bool),bpc)
	     ,FunnelPipesPipelined#(1, numServers, Tuple2#(Bit#(serverIdxSz),Bit#(dataWidth)), TMin#(2, serverIdxSz))
	     ,Add#(1, d__, dataWidth)
	     );
   
   
   Integer bufferSizeBeats = bufferSizeBytes/valueOf(dataWidthBytes);
   Vector#(numServers, Reg#(Bit#(outCntSz)))     outs1 <- replicateM(mkReg(0));
   Vector#(numServers, Reg#(Bit#(outCntSz)))     outs0 <- replicateM(mkReg(0));
   Vector#(numServers, Ratchet#(16))           buffCap <- replicateM(mkRatchet(0));
   MemengineCmdBuf#(numServers,cmdQDepth)       cmdBuf <- mkMemengineCmdBuf;

   FIFO#(Bit#(serverIdxSz))                       loadf_a <- mkSizedFIFO(1);
   FIFO#(Tuple2#(Bit#(serverIdxSz),MemengineCmd)) loadf_b <- mkSizedFIFO(1);
   FIFO#(Tuple3#(Bit#(8),Bit#(serverIdxSz),Bool))   workf <- mkSizedFIFO(32); // is this the right size?
   FIFO#(Tuple2#(Bit#(serverIdxSz),Bool))           donef <- mkSizedFIFO(32); // is this the right size?
   
   Vector#(numServers, FIFO#(void))              outfs <- replicateM(mkSizedFIFO(1));
   Vector#(numServers, FIFOF#(Tuple2#(Bit#(serverIdxSz), MemengineCmd))) cmds_in <- replicateM(mkSizedFIFOF(1));
   FunnelPipe#(1, numServers, Tuple2#(Bit#(serverIdxSz), MemengineCmd),bpc) cmds_in_funnel <- mkFunnelPipesPipelined(map(toPipeOut,cmds_in));
   Vector#(numServers, FIFOF#(Bit#(dataWidth)))  write_data_buffs <- replicateM(mkSizedBRAMFIFOF(bufferSizeBeats));
   Vector#(numServers, PipeOut#(Bit#(dataWidth))) foo = map(toPipeOut, write_data_buffs); 
   BurstFunnel#(numServers,dataWidth) write_data_funnel <- mkBurstFunnel;
   zipWithM(mkConnection, foo, write_data_funnel.dataIn);
      
   Reg#(Bit#(8))                               respCnt <- mkReg(0);
   Reg#(Bit#(serverIdxSz))                     loadIdx <- mkReg(0);
   let beat_shift = fromInteger(valueOf(beatShift));
   let cmd_q_depth = fromInteger(valueOf(cmdQDepth));
   
   rule store_cmd;
      match {.idx, .cmd} <- toGet(cmds_in_funnel[0]).get;
      outs1[idx] <= outs1[idx]+1;
      cmdBuf.enq(idx,cmd);
      //$display("store_cmd %d", idx);
   endrule

   rule load_ctxt_a;
      loadIdx <= loadIdx+1;
      if (outs1[loadIdx] > 0) begin
	 cmdBuf.first_req(loadIdx);
	 loadf_a.enq(loadIdx);
	 //$display("load_ctxt_a %d", loadIdx);
      end
   endrule

   rule load_ctxt_b;
      let idx <- toGet(loadf_a).get;
      let cmd <- cmdBuf.first_resp;
      //$display("%d %d", buffCap[idx].read(), cmd.burstLen>>beat_shift);
      if (outs1[idx] > 0 && buffCap[idx].read() >= unpack(extend(cmd.burstLen>>beat_shift))) begin
	 //$display("load_ctxt_b %h %d", cmd.base, idx);
	 buffCap[idx].decrement(unpack(extend(cmd.burstLen>>beat_shift)));
	 loadf_b.enq(tuple2(idx,cmd));
	 write_data_funnel.loadIdx(idx);
	 if (cmd.len <= extend(cmd.burstLen)) begin
	    outs1[idx] <= outs1[idx]-1;
	    cmdBuf.deq(idx);
	 end
	 else begin
	    let new_cmd = MemengineCmd{pointer:cmd.pointer, base:cmd.base+extend(cmd.burstLen), burstLen:cmd.burstLen, len:cmd.len-extend(cmd.burstLen)};
	    cmdBuf.upd(idx,new_cmd);
	 end
      end
   endrule
   
   function PipeIn#(Bit#(w)) check_in(FIFOF#(Bit#(w)) f, Integer i) = 
      (interface PipeIn;
   	  method Bool notFull = f.notFull;
   	  method Action enq(Bit#(w) v);
	     f.enq(v);
	     buffCap[i].increment(1);
	     //$display("check_in %d", i);
	  endmethod
       endinterface);

   
   Vector#(numServers, Server#(MemengineCmd,Bool)) rs;
   for(Integer i = 0; i < valueOf(numServers); i=i+1)
      rs[i] = (interface Server#(MemengineCmd,Bool);
		  interface Put request;
		     method Action put(MemengineCmd c) if (outs0[i] < cmd_q_depth);
			Bit#(32) bsb = fromInteger(bufferSizeBytes);
			if(extend(c.burstLen) > bsb)
			   $display("mkMemwriteEngineV::unsupportedBurstLen");
			outs0[i] <= outs0[i]+1;
			cmds_in[i].enq(tuple2(fromInteger(i),c));
			write_data_funnel.burstLen[i] <= c.burstLen >> beat_shift;
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
	    match {.idx, .cmd} <- toGet(loadf_b).get;
	    Bit#(8) bl = cmd.burstLen;
	    Bool last = False;
	    if (cmd.len <= extend(bl)) begin
	       last = True;
	       bl = truncate(cmd.len);
	    end
	    workf.enq(tuple3(truncate(bl>>beat_shift), idx, last));
	    //$display("writeReq %d, %h %h %h", idx, cmd.base, bl, last);
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
	    match {._idx, .wd} <- toGet(write_data_funnel.dataOut).get;
	    //$display("writeData %d %h", idx, wd);
	    return ObjectData{data:wd, tag:0, last: False};
	 endmethod
      endinterface
      interface Put writeDone;
	 method Action put(Bit#(6) tag);
	    match {.idx, .last} <- toGet(donef).get;
	    if (last)
	       outfs[idx].enq(?);
	    //$display("writeDone %d %d", idx, last);
	 endmethod
      endinterface
   endinterface 
   interface dataPipes = zipWith(check_in, write_data_buffs, genVector);
endmodule


