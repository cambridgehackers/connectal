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
import BRAMFIFO::*;
import ConfigCounter::*;
import MemTypes::*;
import Pipe::*;
import ConnectalConfig::*;

`include "ConnectalProjectConfig.bsv"

module mkMemWriteEngine(MemWriteEngine#(busWidth, userWidth, cmdQDepth, numServers))
   provisos( Add#(1, d__, busWidth)
	    ,Add#(1, d__, userWidth)
	    ,Add#(e__, TLog#(numServers), 6)
	    );
   let rv <- mkMemWriteEngineBuff(valueOf(TExp#(BurstLenSize)));
   return rv;
endmodule

module mkMemWriteEngineBuff#(Integer bufferSizeBytes)(MemWriteEngine#(busWidth, userWidth, cmdQDepth, numServers))
   provisos ( Div#(busWidth,8,busWidthBytes)
	     ,Log#(busWidthBytes,beatShift)
	     ,Log#(numServers, serverIdxSz)
	     ,Add#(1, d__, userWidth)
	     ,Add#(userWidth, 0, busWidth)
	     ,Add#(g__, serverIdxSz, 6)
	     );

   Integer bufferSizeBeats = bufferSizeBytes/valueOf(busWidthBytes);
   Reg#(Bool) load_in_progress <- mkReg(False);
   FIFO#(Tuple3#(MemengineCmd,Bool,Bool))       serverCond <- mkFIFO1();
   FIFO#(Tuple2#(Bit#(serverIdxSz),MemengineCmd)) serverReq <- mkSizedFIFO(valueOf(cmdQDepth));
   FIFO#(Tuple3#(Bit#(8),Bit#(MemTagSize),Bool))inProgress <- mkSizedFIFO(valueOf(cmdQDepth));
   FIFO#(Tuple2#(Bit#(serverIdxSz),Bool))       serverDone <- mkSizedFIFO(valueOf(cmdQDepth));

   Vector#(numServers, Reg#(Bool))              clientInFlight <- replicateM(mkReg(False));
   Vector#(numServers, ConfigCounter#(16))      clientAvail <- replicateM(mkConfigCounter(0));
   Vector#(numServers, Reg#(MemengineCmd))      clientStart <- replicateM(mkReg(unpack(0)));
   Vector#(numServers, FIFO#(Bool))             clientFinished <- replicateM(mkSizedFIFO(1));
   Vector#(numServers, FIFOF#(MemengineCmd))    clientCommand <- replicateM(mkSizedFIFOF(1));
   Vector#(numServers, FIFOF#(Bit#(userWidth))) dataBuffer <- replicateM(mkSizedBRAMFIFOF(bufferSizeBeats));

   Reg#(Bit#(8))                    respCnt <- mkReg(0);
   Reg#(Bit#(TAdd#(1,serverIdxSz))) loadIdx <- mkReg(0);
   let beat_shift = fromInteger(valueOf(beatShift));

   function Action incr_loadIdx =
      (action
       if(loadIdx+1 >= fromInteger(valueOf(numServers)))
	  loadIdx <= 0;
       else
	  loadIdx <= loadIdx+1;
       endaction);

   for (Integer idx = 0; idx < valueOf(numServers); idx = idx + 1)
      rule store_cmd if (!clientInFlight[idx]);
	 let cmd <- toGet(clientCommand[idx]).get();
	 clientInFlight[idx] <= True;
	 clientStart[idx] <= cmd;
      endrule

   rule load_ctxt_a if (!load_in_progress);
      if (clientInFlight[loadIdx]) begin
	 load_in_progress <= True;
	 let cmd = clientStart[loadIdx];
	 let cond0 <- clientAvail[loadIdx].maybeDecrement(unpack(extend(cmd.burstLen>>beat_shift)));
	 let cond1 = cmd.len <= extend(cmd.burstLen);
	 serverCond.enq(tuple3(cmd,cond0,cond1));
      end
      else begin
	 incr_loadIdx;
      end
   endrule

   rule load_ctxt_b if (load_in_progress);
      load_in_progress <= False;
      incr_loadIdx;
      match {.cmd,.cond0,.cond1} <- toGet(serverCond).get;
      if  (cond0) begin
	 //$display("load_ctxt_b %h %d", cmd.base, idx);
	 serverReq.enq(tuple2(truncate(loadIdx),cmd));
	 if (cond1) begin
	    clientInFlight[loadIdx] <= False;
	 end
	 else begin
	    clientStart[loadIdx] <= MemengineCmd{sglId:cmd.sglId, base:cmd.base+extend(cmd.burstLen),
               burstLen:cmd.burstLen, len:cmd.len-extend(cmd.burstLen), tag:cmd.tag};
	 end
      end
   endrule

   Vector#(numServers, MemWriteEngineServer#(userWidth)) rs;
   for(Integer i = 0; i < valueOf(numServers); i=i+1)
      rs[i] = (interface MemWriteEngineServer#(userWidth);
                  interface Put request;
                     method Action put(MemengineCmd cmd);
                        Bit#(32) bsb = fromInteger(bufferSizeBytes);
`ifdef SIMULATION
                        Bit#(32) dw = fromInteger(valueOf(busWidthBytes));
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
                           clientCommand[i].enq(cmd);
                           //$display("(%d) %h %h %h", i, cmd.base, cmd.len, cmd.burstLen);
                           end
                      endmethod
                  endinterface
                  interface Get done;
                     method ActionValue#(Bool) get = toGet(clientFinished[i]).get;
                  endinterface
                  interface PipeIn data = interface PipeIn;
   	                  method Bool notFull = dataBuffer[i].notFull;
   	                  method Action enq(Bit#(userWidth) v);
	                     dataBuffer[i].enq(v);
	                     clientAvail[i].increment(1);
	                  endmethod
                       endinterface;
              endinterface);
   interface writeServers = rs;
   interface MemWriteClient dmaClient;
      interface Get writeReq;
	 method ActionValue#(MemRequest) get();
	    match {.idx, .cmd} <- toGet(serverReq).get;
	    Bit#(BurstLenSize) bl = cmd.burstLen;
	    Bool last = False;
	    if (cmd.len <= extend(bl)) begin
	       last = True;
	       bl = truncate(cmd.len);
	    end
	    let new_tag = (cmd.tag << valueOf(serverIdxSz)) | extend(idx);
	    inProgress.enq(tuple3(truncate(bl>>beat_shift), new_tag, last));
	    //$display("writeReq %d, %h %h %h", idx, cmd.base, bl, last);
	    return MemRequest { sglId: cmd.sglId, offset: extend(cmd.base), burstLen:bl, tag: new_tag};
	 endmethod
      endinterface
      interface Get writeData;
	 method ActionValue#(MemData#(busWidth)) get;
	    match {.rc, .new_tag, .last} = inProgress.first;
	    Bit#(serverIdxSz) idx = truncate(new_tag);
	    let new_respCnt = respCnt+1;
	    let lastBeat = False;
	    if (new_respCnt == rc) begin
	       respCnt <= 0;
	       inProgress.deq;
	       serverDone.enq(tuple2(idx,last));
	       lastBeat = True;
	    end
	    else begin
	       respCnt <= new_respCnt;
	    end
	    let wd <- toGet(dataBuffer[idx]).get();
	    return MemData{data:wd, tag:new_tag, last:lastBeat};
	 endmethod
      endinterface
      interface Put writeDone;
	 method Action put(Bit#(MemTagSize) tag);
	    match {.idx, .last} <- toGet(serverDone).get;
	    if (last)
	       clientFinished[idx].enq(True);
	    //$display("writeDone %d %d", idx, last);
	 endmethod
      endinterface
   endinterface
endmodule

