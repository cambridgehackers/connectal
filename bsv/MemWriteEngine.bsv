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
import ClientServer::*;
import BRAM::*;
import BRAMFIFO::*;
import Connectable::*;
import ConfigCounter::*;
import ConnectalMemory::*;
import MemTypes::*;
import Pipe::*;
import MemUtils::*;

module mkMemWriteEngine(MemWriteEngine#(dataWidth, cmdQDepth, numServers))
   provisos( Mul#(TDiv#(dataWidth, 8), 8, dataWidth)
	    ,Add#(1, a__, numServers)
	    ,Add#(b__, TLog#(numServers), TAdd#(1, TLog#(TMul#(cmdQDepth,numServers))))
	    ,Pipe::FunnelPipesPipelined#(1, numServers,Tuple2#(Bit#(TLog#(numServers)), MemTypes::MemengineCmd), TMin#(2,TLog#(numServers)))
	    ,Pipe::FunnelPipesPipelined#(1, numServers,Tuple2#(Bit#(dataWidth),Bool),TMin#(2, TLog#(numServers)))
	    ,Add#(c__, TLog#(numServers), TLog#(TMul#(cmdQDepth, numServers)))
	    ,Add#(1, d__, dataWidth)
	    ,FunnelPipesPipelined#(1, numServers, Tuple3#(Bit#(2),Bit#(dataWidth),Bool), TMin#(2, TLog#(numServers)))
	    ,FunnelPipesPipelined#(1, numServers,Tuple3#(Bit#(TLog#(numServers)), Bit#(dataWidth), Bool), TMin#(2,TLog#(numServers)))
	    ,Add#(e__, TLog#(numServers), 6)
	    );
   let rv <- mkMemWriteEngineBuff(valueOf(TExp#(BurstLenSize)));
   return rv;
endmodule

interface BurstFunnel#(numeric type k, numeric type w);
   method Action loadIdx(Bit#(TLog#(k)) i);
   interface Vector#(k, PipeIn#(Bit#(w))) dataIn;
   interface Vector#(k, Reg#(Bit#(BurstLenSize))) burstLen;
   interface PipeOut#(Tuple2#(Bit#(TLog#(k)),Bit#(w))) dataOut;
endinterface

module mkBurstFunnel#(Integer maxBurstLen)(BurstFunnel#(k,w))
   provisos( Log#(k,logk)
	    ,Min#(2,logk,bpc)
	    ,FunnelPipesPipelined#(1, k, Tuple3#(Bit#(2),Bit#(w),Bool), bpc)
	    );

   Reg#(Bit#(2)) nameGen <- mkReg(0);
   UGBramFifos#(4,16,Tuple2#(Bit#(w),Bool)) complBuff <- mkUGBramFifos;
   Vector#(4, ConfigCounter#(16)) compCnts <- replicateM(mkConfigCounter(0));
   Vector#(k,FIFOF#(Tuple3#(Bit#(2), Bit#(w), Bool))) data_in <- replicateM(mkFIFOF);
   Vector#(k,Reg#(Bit#(BurstLenSize))) burst_len <- replicateM(mkReg(0));
   Vector#(k,Reg#(Bit#(BurstLenSize))) drain_cnt <- replicateM(mkReg(0));
   Reg#(Bit#(BurstLenSize)) inj_ctrl <- mkReg(0);
   FIFO#(Tuple2#(Bit#(TAdd#(1,logk)),Bit#(2))) loadIdxs <- mkSizedBRAMFIFO(32);
   FIFO#(Tuple2#(Bit#(TAdd#(1,logk)),Bit#(2))) inFlight <- mkSizedBRAMFIFO(4);
   FunnelPipe#(1, k, Tuple3#(Bit#(2),Bit#(w),Bool),bpc) data_in_funnel <- mkFunnelPipesPipelined(map(toPipeOut,data_in));
   Reg#(Bit#(BurstLenSize)) drainCnt <- mkReg(0);
   FIFOF#(Tuple2#(Bit#(TLog#(k)),Bit#(w))) exit_data <- mkFIFOF;
   FIFO#(Bit#(logk)) drainRename <- mkFIFO;
   
   Reg#(Bit#(32)) cycle <- mkReg(0);
   Reg#(Bit#(32)) last_entry <- mkReg(0);
   
   rule cyc;
      cycle <= cycle+1;
   endrule
   
   function PipeIn#(Bit#(w)) enter_data(FIFOF#(Tuple3#(Bit#(2), Bit#(w), Bool)) f, Integer i) = 
      (interface PipeIn;
   	  method Bool notFull = f.notFull;
   	  method Action enq(Bit#(w) v) if (tpl_1(loadIdxs.first) == fromInteger(i));
	     last_entry <= cycle;
	     match {.old_name, .new_name} = loadIdxs.first;
	     let first = inj_ctrl == 0;
	     let cnt = first ? burst_len[i] : inj_ctrl;
	     let new_cnt = cnt-1;
	     let last = new_cnt == 0;
	     inj_ctrl <= new_cnt;
	     if (first)
		inFlight.enq(loadIdxs.first);
	     if (last) 
		loadIdxs.deq;
	     f.enq(tuple3(new_name, v, last));
	     //$display("%d enq %d", cycle-last_entry, i);
	  endmethod
       endinterface);
   Vector#(k, PipeIn#(Bit#(w))) data_in_pipes = zipWith(enter_data, data_in, genVector);

   function Reg#(Bit#(BurstLenSize)) check(Reg#(Bit#(BurstLenSize)) r) =
      (interface Reg;
	  method Action _write(Bit#(BurstLenSize) v);
	     if(v > 16) begin
		$display("ERROR mkBurstFunnel: burstLen too large");
		$finish;
	     end
	     r <= v;
	  endmethod
	  method Bit#(BurstLenSize) _read = r._read;
       endinterface);

   rule drain_funnel;
      match{.new_name,.data,.last} = data_in_funnel[0].first;
      data_in_funnel[0].deq;
      complBuff.enq(new_name,tuple2(data,last));
      compCnts[new_name].increment(1);
   endrule
      
   
   rule drain_req (compCnts[tpl_2(inFlight.first)].read > 0);
      match {.old_name, .new_name} = inFlight.first;
      let new_drainCnt = drainCnt-1;
      if (drainCnt == 0) begin
	 new_drainCnt = burst_len[old_name]-1;
	 drainRename.enq(truncate(old_name));
      end
      if (new_drainCnt == 0) begin
	 inFlight.deq;
      end
      complBuff.first_req(new_name);
      drainCnt <= new_drainCnt;
      compCnts[new_name].decrement(1);
      complBuff.deq(new_name);
   endrule
      
   rule drain_resp;
      match {.data,.last} <- complBuff.first_resp;
      if (last)
	 drainRename.deq;
      exit_data.enq(tuple2(drainRename.first,data));
   endrule
      
   method Action loadIdx(Bit#(logk) idx);
      loadIdxs.enq(tuple2(extend(idx),nameGen));
      nameGen <= nameGen+1;
   endmethod
   interface burstLen = map(check,burst_len);
   interface dataIn = data_in_pipes;
   interface PipeOut dataOut = toPipeOut(exit_data);
endmodule

module mkMemWriteEngineBuff#(Integer bufferSizeBytes)(MemWriteEngine#(dataWidth, cmdQDepth, numServers))
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
	     ,FunnelPipesPipelined#(1, numServers, Tuple3#(Bit#(2),Bit#(dataWidth),Bool), TMin#(2, serverIdxSz))
	     ,Add#(1, d__, dataWidth)
	     ,FunnelPipesPipelined#(1, numServers, Tuple3#(Bit#(serverIdxSz),Bit#(dataWidth), Bool), TMin#(2, serverIdxSz))
	     ,Add#(f__, TLog#(numServers), TAdd#(1, serverIdxSz))
	     ,Add#(g__, serverIdxSz, 6)
	     );
   
   
   Integer bufferSizeBeats = bufferSizeBytes/valueOf(dataWidthBytes);
   Vector#(numServers, Reg#(Bool))               outs1 <- replicateM(mkReg(False));
   Vector#(numServers, ConfigCounter#(16))        buffCap <- replicateM(mkConfigCounter(0));
   Vector#(numServers, Reg#(MemengineCmd))        cmdRegs <- replicateM(mkReg(unpack(0)));

   Reg#(Bool) load_in_progress <- mkReg(False);
   FIFO#(Tuple3#(MemengineCmd,Bool,Bool))         loadf_b <- mkFIFO1();
   FIFO#(Tuple2#(Bit#(serverIdxSz),MemengineCmd)) loadf_c <- mkSizedFIFO(valueOf(cmdQDepth));
   FIFO#(Tuple3#(Bit#(8),Bit#(MemTagSize),Bool))    workf <- mkSizedFIFO(valueOf(cmdQDepth));
   FIFO#(Tuple2#(Bit#(serverIdxSz),Bool))           donef <- mkSizedFIFO(valueOf(cmdQDepth));
   
   Vector#(numServers, FIFO#(Bool))              outfs <- replicateM(mkSizedFIFO(1));
   Vector#(numServers, FIFOF#(MemengineCmd))    cmds_in <- replicateM(mkSizedFIFOF(1));
   Vector#(numServers, FIFOF#(Bit#(dataWidth)))  write_data_buffs <- replicateM(mkSizedBRAMFIFOF(bufferSizeBeats));
      
   Reg#(Bit#(8))                    respCnt <- mkReg(0);
   Reg#(Bit#(TAdd#(1,serverIdxSz))) loadIdx <- mkReg(0);
   let beat_shift = fromInteger(valueOf(beatShift));
   let cmd_q_depth = fromInteger(valueOf(cmdQDepth));
   
   function Action incr_loadIdx =
      (action
       if(loadIdx+1 >= fromInteger(valueOf(numServers)))
	  loadIdx <= 0;
       else
	  loadIdx <= loadIdx+1;
       endaction);

   for (Integer idx = 0; idx < valueOf(numServers); idx = idx + 1)
      rule store_cmd if (!outs1[idx]);
	 let cmd <- toGet(cmds_in[idx]).get();
	 outs1[idx] <= True;
	 cmdRegs[idx] <= cmd;
      endrule

   rule load_ctxt_a if (!load_in_progress);
      if (outs1[loadIdx]) begin
	 load_in_progress <= True;
	 let cmd = cmdRegs[loadIdx];
	 let cond0 <- buffCap[loadIdx].maybeDecrement(unpack(extend(cmd.burstLen>>beat_shift)));
	 let cond1 = cmd.len <= extend(cmd.burstLen);
	 loadf_b.enq(tuple3(cmd,cond0,cond1));
      end
      else begin
	 incr_loadIdx;
      end
   endrule
   
   rule load_ctxt_b if (load_in_progress);
      load_in_progress <= False;
      incr_loadIdx;
      match {.cmd,.cond0,.cond1} <- toGet(loadf_b).get;
      if  (cond0) begin
	 //$display("load_ctxt_b %h %d", cmd.base, idx);
	 let x = cmd.burstLen;
	 if (cmd.len < extend(cmd.burstLen))
	    x = truncate(cmd.len);
	 loadf_c.enq(tuple2(truncate(loadIdx),cmd));
	 if (cond1) begin
	    outs1[loadIdx] <= False;
	 end
	 else begin
	    let new_cmd = MemengineCmd{sglId:cmd.sglId, base:cmd.base+extend(cmd.burstLen), burstLen:cmd.burstLen, len:cmd.len-extend(cmd.burstLen), tag:cmd.tag};
	    cmdRegs[loadIdx] <= new_cmd;
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
	     // if(i==2)
	     // 	for(Integer j = 0; j < valueOf(w); j=j+32) begin
	     // 	   Bit#(32) xx = v[j+31:j]; 
	     // 	   $display("%h", xx);
	     // 	end
	  endmethod
       endinterface);
   
   Vector#(numServers, MemWriteEngineServer#(dataWidth)) rs;
   for(Integer i = 0; i < valueOf(numServers); i=i+1)
      rs[i] = (interface MemWriteEngineServer#(dataWidth);
                  interface Put request;
                     method Action put(MemengineCmd cmd);
                        Bit#(32) bsb = fromInteger(bufferSizeBytes);
`ifdef SIMULATION
                        Bit#(32) dw = fromInteger(valueOf(dataWidthBytes));
                        Bit#(32) bl = extend(cmd.burstLen);
                        // this is because bsc lifts the divide operation (below) 
                        // and on startup the simulator gets a floating-point exception
                        if (bl ==0)
                           bl = 1;
                        let mdw0 = ((cmd.len)/bl)*bl != cmd.len;
                        let mdw1 = ((cmd.len)/dw)*dw != cmd.len;
                        let bbl = extend(cmd.burstLen) > bsb;
                        if(bbl || mdw0 || mdw1 || cmd.len == 0) begin
                           if (bbl)
                              $display("XXXXXXXXXX mkMemWriteEngineBuff::unsupported burstLen %d %d", bsb, cmd.burstLen);
                           if (mdw0 || mdw1 || cmd.len == 0)
                              $display("XXXXXXXXXX mkMemWriteEngineBuff::unsupported len %h mdw0=%d mdw1=%d", cmd.len, mdw0, mdw1);
                        end
                        else
`endif
                           begin
                           cmds_in[i].enq(cmd);
                           //$display("(%d) %h %h %h", i, cmd.base, cmd.len, cmd.burstLen);
                           end
                      endmethod
                  endinterface
                  interface Get done;
                     method ActionValue#(Bool) get;
                        let rv <- toGet(outfs[i]).get;
                        return rv;
                     endmethod
                  endinterface
                  interface PipeIn data = check_in(write_data_buffs[i], i);
              endinterface);
   interface MemWriteClient dmaClient;
      interface Get writeReq;
	 method ActionValue#(MemRequest) get();
	    match {.idx, .cmd} <- toGet(loadf_c).get;
	    Bit#(BurstLenSize) bl = cmd.burstLen;
	    Bool last = False;
	    if (cmd.len <= extend(bl)) begin
	       last = True;
	       bl = truncate(cmd.len);
	    end
	    let new_tag = (cmd.tag << valueOf(serverIdxSz)) | extend(idx);
	    workf.enq(tuple3(truncate(bl>>beat_shift), new_tag, last));
	    //$display("writeReq %d, %h %h %h", idx, cmd.base, bl, last);
	    return MemRequest { sglId: cmd.sglId, offset: cmd.base, burstLen:bl, tag: new_tag};
	 endmethod
      endinterface
      interface Get writeData;
	 method ActionValue#(MemData#(dataWidth)) get;
	    match {.rc, .new_tag, .last} = workf.first;
	    Bit#(serverIdxSz) idx = truncate(new_tag);
	    let new_respCnt = respCnt+1;
	    let lastBeat = False;
	    if (new_respCnt == rc) begin
	       respCnt <= 0;
	       workf.deq;
	       donef.enq(tuple2(idx,last));
	       lastBeat = True;
	    end
	    else begin
	       respCnt <= new_respCnt;
	    end
	    let wd <- toGet(write_data_buffs[idx]).get();
	    return MemData{data:wd, tag:new_tag, last:lastBeat};
	 endmethod
      endinterface
      interface Put writeDone;
	 method Action put(Bit#(MemTagSize) tag);
	    match {.idx, .last} <- toGet(donef).get;
	    if (last)
	       outfs[idx].enq(True);
	    //$display("writeDone %d %d", idx, last);
	 endmethod
      endinterface
   endinterface 
   interface writeServers = rs;
endmodule
