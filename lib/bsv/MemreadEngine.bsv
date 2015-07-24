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


module mkMemreadEngine(MemreadEngine#(dataWidth, cmdQDepth, numServers))
   provisos( Mul#(TDiv#(dataWidth, 8), 8, dataWidth)
	    ,Add#(1, a__, numServers)
	    ,Add#(b__, TLog#(numServers), TAdd#(1, TLog#(TMul#(cmdQDepth,numServers))))
	    ,Add#(c__, TLog#(numServers), TLog#(TMul#(cmdQDepth, numServers)))
	    ,Add#(d__, TLog#(numServers), 6)
	    );
   let rv <- mkMemreadEngineBuff(valueOf(TExp#(BurstLenSize)));
   return rv;
endmodule

module mkMemreadEngineBuff#(Integer bufferSizeBytes) (MemreadEngine#(dataWidth, cmdQDepth, numServers))
   provisos (Div#(dataWidth,8,dataWidthBytes),
	     Mul#(dataWidthBytes,8,dataWidth),
	     Log#(dataWidthBytes,beatShift),
	     Log#(cmdQDepth,logCmdQDepth),
	     Mul#(cmdQDepth,numServers,cmdBuffSz),
	     Log#(cmdBuffSz, cmdBuffAddrSz),
	     Log#(numServers, serverIdxSz),
	     Add#(1,logCmdQDepth, outCntSz),
	     Add#(1, c__, numServers),
	     Add#(b__, TLog#(numServers), cmdBuffAddrSz),
	     Add#(e__, TLog#(numServers), TAdd#(1, cmdBuffAddrSz)),
	     Add#(a__, serverIdxSz, cmdBuffAddrSz),
	     Min#(2,TLog#(numServers),bpc),
	     Add#(d__, TLog#(numServers), TAdd#(1, serverIdxSz)),
	     Add#(f__, serverIdxSz, 6));
   

   let verbose = False;

   Integer bufferSizeBeats = bufferSizeBytes/valueOf(dataWidthBytes);
   Vector#(numServers, Reg#(Bool))               outs1 <- replicateM(mkReg(False));
   Vector#(numServers, ConfigCounter#(16))     buffCap <- replicateM(mkConfigCounter(fromInteger(bufferSizeBeats)));
   Vector#(numServers, Reg#(MemengineCmd))     cmdRegs <- replicateM(mkReg(unpack(0)));
   
   Reg#(Bool) load_in_progress <- mkReg(False);
   FIFO#(Tuple4#(MemengineCmd,Bool,Bool,Bit#(BurstLenSize)))              loadf_b <- mkSizedFIFO(1);
   FIFO#(Tuple4#(Bit#(serverIdxSz),MemengineCmd,Bool,Bit#(BurstLenSize))) loadf_c <- mkSizedFIFO(valueOf(cmdQDepth));
   FIFO#(Tuple3#(Bit#(8),Bit#(serverIdxSz),Bool))        workf <- mkSizedFIFO(valueOf(cmdQDepth));
   

   Vector#(numServers, FIFO#(void))              outfs <- replicateM(mkSizedFIFO(valueOf(cmdQDepth)));
   Vector#(numServers, FIFO#(MemengineCmd))    cmds_in <- replicateM(mkFIFO());

   FIFOF#(MemData#(dataWidth))                             read_data <- mkFIFOF;
   Vector#(numServers, FIFOF#(MemData#(dataWidth)))  read_data_buffs <- replicateM(mkSizedBRAMFIFOF(bufferSizeBeats));
   function PipeOut#(Bit#(dataWidth)) check_out(PipeOut#(MemData#(dataWidth)) inpipe, Integer i) = 
      (interface PipeOut;
	  method Bit#(dataWidth) first;
	     return inpipe.first.data;
	  endmethod
	  method Action deq;
	     if (verbose) $display("mkMemreadEngineBuff::check_out: idx %d data %h buffCap %d eob %d", i, inpipe.first.data, buffCap[i].read(), inpipe.first.last);
	     inpipe.deq;
	     buffCap[i].increment(1);
	  endmethod
	  method Bool notEmpty = inpipe.notEmpty;
       endinterface);
   Vector#(numServers, PipeOut#(Bit#(dataWidth))) read_data_pipes = zipWith(check_out, map(toPipeOut,read_data_buffs), genVector);
   
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
	 if (verbose) $display("mkMemreadEngineBuff::store_cmd %d %d", idx, buffCap[idx].read);
      endrule
   
   rule load_ctxt_a (!load_in_progress);
      if (outs1[loadIdx]) begin
	 load_in_progress <= True;
	 let cmd = cmdRegs[loadIdx];
         let last_burst = cmd.len <= extend(cmd.burstLen);
         Bit#(BurstLenSize) cmd_len = cmd.burstLen;
	 if (last_burst)
             cmd_len = truncate(cmd.len);
	 let cond0 <- buffCap[loadIdx].maybeDecrement(unpack(extend(cmd_len>>beat_shift)));
	 loadf_b.enq(tuple4(cmd,cond0,last_burst,cmd_len));
	 if (verbose) $display("mkMemreadEngineBuff::load_ctxt_b buffCap %d burstLen %d cond0 %d last_burst %d", buffCap[loadIdx].read(), cmd_len>>beat_shift, cond0, last_burst);
      end
      else begin
	 incr_loadIdx;
      end
   endrule

   // should use an EHR for outs1 to avoid the need for this pragma
   (* descending_urgency = "load_ctxt_c, store_cmd" *)
   rule load_ctxt_c if (load_in_progress);
      load_in_progress <= False;
      incr_loadIdx;
      match {.cmd,.cond0,.last_burst,.cmd_len} <- toGet(loadf_b).get;
      if  (cond0) begin
	 if (verbose) $display("mkMemreadEngineBuff::load_ctxt_c cmd.len %d idx %d cond0 %d last_burst %d", cmd.len, loadIdx, cond0, last_burst);
	 loadf_c.enq(tuple4(truncate(loadIdx),cmd,last_burst,cmd_len));
	 if (last_burst) begin
	    if (verbose) $display("mkMemreadEngineBuff::load_ctxt_b last_burst %d", last_burst);
	    outfs[loadIdx].enq(?);
	    outs1[loadIdx] <= False;
	 end
	 else begin
	    let new_cmd = MemengineCmd{sglId:cmd.sglId, base:cmd.base+extend(cmd.burstLen), 
				       burstLen:cmd.burstLen, len:cmd.len-extend(cmd.burstLen), tag:cmd.tag};
	    cmdRegs[loadIdx] <= new_cmd;
	 end
      end
   endrule
   
   rule read_data_rule;
      let d <- toGet(read_data).get();
      match {.rc, .idx, .last_burst} = workf.first;
      let new_respCnt = respCnt+1;
      let l = False;
      if (verbose) $display("mkMemreadEngineBuff::%h new_respCnt %d rc %d last_burst %d idx %d outs1 %d eob %d", d.data, new_respCnt, rc, last_burst, idx, outs1[idx], d.last);
      if (new_respCnt == rc) begin
	 respCnt <= 0;
	 workf.deq;
	 //$display("eob %d", idx);
	 l = last_burst;
      end
      else begin
	 respCnt <= new_respCnt;
      end
      d.last = l;
      read_data_buffs[idx].enq(d);
   endrule

   function MemreadServer#(dataWidth) toMemreadServer(Server#(MemengineCmd,Bool) cs, PipeOut#(Bit#(dataWidth)) p) =
      (interface MemreadServer;
	  interface cmdServer = cs;
	  interface dataPipe  = p;
       endinterface);

      
   Vector#(numServers, Server#(MemengineCmd,Bool)) rs;
   for(Integer i = 0; i < valueOf(numServers); i=i+1)
      rs[i] = (interface Server#(MemengineCmd,Bool);
		  interface Put request;
		     method Action put(MemengineCmd cmd);
			Bit#(32) bsb = fromInteger(bufferSizeBytes);
`ifdef BSIM	 
			Bit#(32) dw = fromInteger(valueOf(dataWidthBytes));
			let mdw = ((cmd.len)/dw)*dw != cmd.len;
			let bbl = extend(cmd.burstLen) > bsb;
			if(bbl || mdw) begin
			   if (bbl)
			      $display("XXXXXXXXXX mkMemreadEngineBuff::unsupported burstLen %d %d", bsb, cmd.burstLen);
			   if (mdw)
			      $display("XXXXXXXXXX mkMemreadEngineBuff::unsupported len %d", cmd.len);
			end
			else begin
`endif
			   cmds_in[i].enq(cmd);
`ifdef BSIM
			end
`endif
 		     endmethod
		  endinterface
		  interface Get response;
		     method ActionValue#(Bool) get;
			outfs[i].deq;
			return True;
		     endmethod
		  endinterface
	       endinterface);
   interface readServers = rs;
   interface MemReadClient dmaClient;
      interface Get readReq;
	 method ActionValue#(MemRequest) get();
	    match {.idx, .cmd, .last_burst, .bl} <- toGet(loadf_c).get;
	    workf.enq(tuple3(truncate(bl>>beat_shift), idx, last_burst));
	    if (verbose) $display("MemreadEngine::readReq idx %d offset %h burstLenBytes %h last_burst %d", idx, cmd.base, bl, last_burst);
	    return MemRequest { sglId: cmd.sglId, offset: cmd.base, burstLen:bl, tag: (cmd.tag << valueOf(serverIdxSz)) | extend(idx)};
	 endmethod
      endinterface
      interface Put readData = toPut(read_data);
   endinterface 
   interface dataPipes = read_data_pipes;
   interface read_servers = zipWith(toMemreadServer, rs, read_data_pipes);
endmodule


