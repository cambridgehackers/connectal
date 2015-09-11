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
import BRAMFIFO::*;
import ConfigCounter::*;
import Connectable::*;
import ConnectalMemory::*;
import MemTypes::*;
import Pipe::*;
import MemUtils::*;

module mkMemReadEngine(MemReadEngine#(busWidth, userWidth, cmdQDepth, numServers))
   provisos( Mul#(TDiv#(busWidth, 8), 8, busWidth)
	    ,Add#(1, a__, numServers)
	    ,Add#(busWidth, 0, userWidth)
	    ,Add#(b__, TLog#(numServers), TAdd#(1, TLog#(TMul#(cmdQDepth,numServers))))
	    ,Add#(c__, TLog#(numServers), TLog#(TMul#(cmdQDepth, numServers)))
	    ,Add#(d__, TLog#(numServers), 6)
	    );
   let rv <- mkMemReadEngineBuff(valueOf(cmdQDepth) * valueOf(TExp#(BurstLenSize)));
   return rv;
endmodule

module mkMemReadEngineBuff#(Integer bufferSizeBytes) (MemReadEngine#(busWidth, userWidth, cmdQDepth, numServers))
   provisos (Div#(busWidth,8,busWidthBytes),
	     Mul#(busWidthBytes,8,busWidth),
	     Log#(busWidthBytes,beatShift),
	     Log#(cmdQDepth,logCmdQDepth),
	     Mul#(cmdQDepth,numServers,cmdBuffSz),
	     Log#(cmdBuffSz, cmdBuffAddrSz),
	     Log#(numServers, serverIdxSz),
	     Add#(busWidth, 0, userWidth),
	     Add#(1,logCmdQDepth, outCntSz),
	     Add#(1, c__, numServers),
	     Add#(b__, TLog#(numServers), cmdBuffAddrSz),
	     Add#(e__, TLog#(numServers), TAdd#(1, cmdBuffAddrSz)),
	     Add#(a__, serverIdxSz, cmdBuffAddrSz),
	     Min#(2,TLog#(numServers),bpc),
	     Add#(d__, TLog#(numServers), TAdd#(1, serverIdxSz)),
	     Add#(f__, serverIdxSz, 6));

   let verbose = False;

   Integer bufferSizeBeats = bufferSizeBytes/valueOf(busWidthBytes);
   Vector#(numServers, Reg#(Bool))          clientInFlight <- replicateM(mkReg(False));
   Vector#(numServers, ConfigCounter#(16))  clientAvail <- replicateM(mkConfigCounter(fromInteger(bufferSizeBeats)));
   Vector#(numServers, Reg#(MemengineCmd))  clientCommand <- replicateM(mkReg(unpack(0)));
   Vector#(numServers, Reg#(Bool))          clientFirstBurst <- replicateM(mkReg(False));
   
   Reg#(Bool) load_in_progress <- mkReg(False);
   FIFO#(Tuple5#(MemengineCmd,Bool,Bool,Bool,Bit#(BurstLenSize)))              serverCheckAvail <- mkSizedFIFO(1);
   FIFO#(Tuple5#(Bit#(serverIdxSz),MemengineCmd,Bool,Bool,Bit#(BurstLenSize))) serverRequest <- mkSizedFIFO(valueOf(cmdQDepth));
   FIFO#(Tuple4#(Bit#(8),Bit#(serverIdxSz),Bool,Bool)) serverProcessing <- mkSizedFIFO(valueOf(cmdQDepth));

   Vector#(numServers, FIFO#(MemengineCmd)) clientRequest <- replicateM(mkFIFO());

   FIFOF#(MemData#(busWidth))                       serverDataFifo <- mkFIFOF;
   Vector#(numServers, FIFOF#(MemDataF#(userWidth))) clientDataFifo <- replicateM(mkSizedBRAMFIFOF(bufferSizeBeats));
   function PipeOut#(MemDataF#(userWidth)) mem_data_out(PipeOut#(MemDataF#(userWidth)) inpipe, Integer i) = 
      (interface PipeOut;
	  method MemDataF#(userWidth) first;
	     return inpipe.first;
	  endmethod
	  method Action deq;
	     if (verbose) $display("mkMemReadEngineBuff::check_out: idx %d data %h clientAvail %d eob %d", i, inpipe.first.data, clientAvail[i].read(), inpipe.first.last);
	     inpipe.deq;
	     clientAvail[i].increment(1);
	  endmethod
	  method Bool notEmpty = inpipe.notEmpty;
       endinterface);
   Vector#(numServers, PipeOut#(MemDataF#(userWidth))) memDataPipes = zipWith(mem_data_out, map(toPipeOut,clientDataFifo), genVector);

   Reg#(Bit#(8))                    respCnt <- mkReg(0);
   Reg#(Bit#(TAdd#(1,serverIdxSz))) loadIdx <- mkReg(0);
   let beat_shift = fromInteger(valueOf(beatShift));
   let cmd_q_depth = fromInteger(valueOf(cmdQDepth));
   Reg#(Bit#(32)) counter <- mkReg(0);

   rule incCounter;
      counter <= counter + 1;
   endrule
   
   function Action incr_loadIdx =
      (action
       if(loadIdx+1 >= fromInteger(valueOf(numServers)))
	  loadIdx <= 0;
       else
	  loadIdx <= loadIdx+1;
       endaction);
         
   for (Integer idx = 0; idx < valueOf(numServers); idx = idx + 1)
      rule store_cmd if (!clientInFlight[idx]);
	 let cmd <- toGet(clientRequest[idx]).get();
	 clientInFlight[idx] <= True;
	 clientCommand[idx] <= cmd;
	 clientFirstBurst[idx] <= True;
	 if (verbose) $display("mkMemReadEngineBuff::%d store_cmd %d %d", counter, idx, clientAvail[idx].read);
      endrule
   
   rule load_ctxt_a (!load_in_progress);
      if (clientInFlight[loadIdx]) begin
	 load_in_progress <= True;
	 let cmd = clientCommand[loadIdx];
	 let first_burst = clientFirstBurst[loadIdx];
         let last_burst = cmd.len <= extend(cmd.burstLen);
         Bit#(BurstLenSize) cmd_len = cmd.burstLen;
	 if (last_burst)
             cmd_len = truncate(cmd.len);
	 let cond0 <- clientAvail[loadIdx].maybeDecrement(unpack(extend(cmd_len>>beat_shift)));
	 serverCheckAvail.enq(tuple5(cmd,cond0,first_burst,last_burst,cmd_len));
	 if (verbose) $display("mkMemReadEngineBuff::%d load_ctxt_b clientAvail[%d] %d burstLen %d cond0 %d last_burst %d", counter, loadIdx, clientAvail[loadIdx].read(), cmd_len>>beat_shift, cond0, last_burst);
      end
      else begin
	 incr_loadIdx;
      end
   endrule

   // should use an EHR for clientInFlight to avoid the need for this pragma
   (* descending_urgency = "load_ctxt_c, store_cmd" *)
   rule load_ctxt_c if (load_in_progress);
      load_in_progress <= False;
      incr_loadIdx;
      match {.cmd,.cond0,.first_burst,.last_burst,.cmd_len} <- toGet(serverCheckAvail).get;
      if  (cond0) begin
	 if (verbose) $display("mkMemReadEngineBuff::%d load_ctxt_c cmd.len %d idx %d cond0 %d last_burst %d", counter, cmd.len, loadIdx, cond0, last_burst);
	 serverRequest.enq(tuple5(truncate(loadIdx),cmd,first_burst,last_burst,cmd_len));
	 clientFirstBurst[loadIdx] <= False;
	 if (last_burst) begin
	    if (verbose) $display("mkMemReadEngineBuff::%d load_ctxt_b last_burst %d", counter, last_burst);
	    clientInFlight[loadIdx] <= False;
	 end
	 else begin
	    clientCommand[loadIdx] <= MemengineCmd{sglId:cmd.sglId, base:cmd.base+extend(cmd.burstLen), 
	       burstLen:cmd.burstLen, len:cmd.len-extend(cmd.burstLen), tag:cmd.tag};
	 end
      end
   endrule
   
   rule read_data_rule;
      let d <- toGet(serverDataFifo).get();
      match {.rc, .idx, .first_burst, .last_burst} = serverProcessing.first;
      let new_respCnt = respCnt+1;
      let l = False;
      if (verbose) $display("mkMemReadEngineBuff::%d data %h new_respCnt %d rc %d last_burst %d idx %d clientInFlight %d eob %d", counter, d.data, new_respCnt, rc, last_burst, idx, clientInFlight[idx], d.last);
      if (new_respCnt == rc) begin
	 respCnt <= 0;
	 serverProcessing.deq;
	 //$display("eob %d", idx);
	 l = last_burst;
      end
      else begin
	 respCnt <= new_respCnt;
      end
      clientDataFifo[idx].enq(MemDataF { data: d.data, tag: d.tag,
         first: //first_burst && 
(respCnt == 0), last: l});
   endrule

   Vector#(numServers, MemReadEngineServer#(userWidth)) rs;
   for(Integer i = 0; i < valueOf(numServers); i=i+1)
      rs[i] = (interface MemReadEngineServer#(userWidth);
		  interface Put request;
		     method Action put(MemengineCmd cmd);
			Bit#(32) bsb = fromInteger(bufferSizeBytes);
`ifdef SIMULATION
			Bit#(32) dw = fromInteger(valueOf(busWidthBytes));
			let mdw = ((cmd.len)/dw)*dw != cmd.len;
			let bbl = extend(cmd.burstLen) > bsb;
			if(bbl || mdw) begin
			   if (bbl)
			      $display("XXXXXXXXXX mkMemReadEngineBuff::unsupported burstLen %d %d", bsb, cmd.burstLen);
			   if (mdw)
			      $display("XXXXXXXXXX mkMemReadEngineBuff::unsupported len %d", cmd.len);
			end
			else
`endif
                           begin
			   clientRequest[i].enq(cmd);
			   end
 		     endmethod
		  endinterface
                  interface data = memDataPipes[i];
               endinterface);
   interface readServers = rs;
   interface MemReadClient dmaClient;
      interface Get readReq;
	 method ActionValue#(MemRequest) get();
	    match {.idx, .cmd, .first_burst, .last_burst, .bl} <- toGet(serverRequest).get;
	    serverProcessing.enq(tuple4(truncate(bl>>beat_shift), idx, first_burst, last_burst));
	    if (verbose) $display("MemReadEngine::%d readReq idx %d offset %h burstLenBytes %h last_burst %d", counter, idx, cmd.base, bl, last_burst);
	    return MemRequest { sglId: cmd.sglId, offset: cmd.base, burstLen:bl, tag: (cmd.tag << valueOf(serverIdxSz)) | extend(idx)
`ifdef BYTE_ENABLES
			       , firstbe: maxBound, lastbe: maxBound
`endif
};
	 endmethod
      endinterface
      interface Put readData = toPut(serverDataFifo);
   endinterface 
endmodule
