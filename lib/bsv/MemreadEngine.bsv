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
import Connectable::*;

import PortalMemory::*;
import MemTypes::*;
import Pipe::*;


module mkMemreadEngine(MemreadEngine#(dataWidth, cmdQDepth))
   provisos (Div#(dataWidth,8,dataWidthBytes),
	     Mul#(dataWidthBytes,8,dataWidth),
	     Log#(dataWidthBytes,beatShift));
   
   FIFOF#(Bit#(dataWidth))         f <- mkFIFOF;
   
   Reg#(Bit#(32))             reqLen <- mkReg(0);
   Reg#(Bit#(32))            respCnt <- mkReg(0);
   
   Reg#(Bit#(32))                off <- mkReg(0);
   Reg#(Bit#(ObjectOffsetSize)) base <- mkReg(0);

   Reg#(ObjectPointer)       pointer <- mkReg(0);
   Reg#(Bit#(8))            burstLen <- mkReg(0);
   
   FIFOF#(Bool)                   ff <- mkSizedFIFOF(1);
   FIFO#(Bit#(32))                wf <- mkSizedFIFO(valueOf(cmdQDepth));
   
   let beat_shift = fromInteger(valueOf(beatShift));

   Vector#(1, Server#(MemengineCmd,Bool)) rs;
   rs[0] =  (interface Server#(MemengineCmd,Bool)
		interface Put request;
		   method Action put(MemengineCmd c) if (off >= reqLen);
		      reqLen   <= c.len;
		      off      <= 0;
		      pointer  <= c.pointer;
		      burstLen <= c.burstLen;
		      base     <= c.base;
		      //$display("mkMemreadEngine.start p=%d b=%d rl=%d beat_shift=%d bl=%d", p, b, rl, beat_shift, bl);
		      wf.enq(c.len >> beat_shift);
		   endmethod
		endinterface
		interface Get response;
		   method ActionValue#(Bool) get;
		      ff.deq;
		      return ff.first;
		   endmethod
		endinterface
	     endinterface);
   interface readServers = rs;
   interface ObjectReadClient dmaClient;
      interface Get readReq;
	 method ActionValue#(ObjectRequest) get() if (off < reqLen);
	    //$display("mkMemreadEngine.dmaClient.readReq: ptr=%d off=%d reqLen=%d burstLen=%d", pointer, off, reqLen, burstLen);
	    off <= off + extend(burstLen);
	    let bl = burstLen;
	    if (off + extend(burstLen) > reqLen)
	       bl = truncate(reqLen - off);
	    return ObjectRequest { pointer: pointer, offset: extend(off)+base, burstLen: bl, tag: 0 };
	 endmethod
      endinterface
      interface Put readData;
	 method Action put(ObjectData#(dataWidth) d);
	    let new_respCnt = respCnt+1;
	    //$display("mkMemreadEngine.dmaClient.readData new_respCnt=%d wf.first=%d", new_respCnt, wf.first);
	    if (new_respCnt == wf.first) begin
	       ff.enq(True);
	       respCnt <= 0;
	       wf.deq;
	       //$display("mkMemreadEngine.dmaClient.readData: %h", new_respCnt);
	    end
	    else begin
	       respCnt <= new_respCnt;
	    end
	    f.enq(d.data);
	 endmethod
      endinterface
   endinterface   
   interface dataPipes = cons(toPipeOut(f),nil);
endmodule


module mkMemreadEngineV(MemreadEngineV#(dataWidth, cmdQDepth, numServers))
   provisos (Div#(dataWidth,8,dataWidthBytes),
	     Mul#(dataWidthBytes,8,dataWidth),
	     Log#(dataWidthBytes,beatShift),
	     Log#(cmdQDepth,logCmdQDepth),
	     Mul#(cmdQDepth,numServers,cmdBuffSz),
	     Log#(cmdBuffSz, cmdBuffAddrSz),
	     Log#(numServers, serverIdxSz),
	     Add#(1,cmdQDepth, outCntSz),
	     Add#(1, c__, numServers),
	     Add#(b__, TLog#(numServers), cmdBuffAddrSz),
	     Add#(d__, serverIdxSz, TAdd#(1, cmdBuffAddrSz)),
	     Add#(a__, serverIdxSz, cmdBuffAddrSz),
	     Min#(2,TLog#(numServers),bpc),
	     FunnelPipesPipelined#(1,numServers,Tuple2#(Bit#(serverIdxSz),MemengineCmd),bpc),
	     FunnelPipesPipelined#(1,numServers,Tuple2#(Bit#(dataWidth),Bool),bpc));
   
   let maxBurstBeats = 16;
   let maxBufferedBursts = 2;
   
   function Bit#(cmdBuffAddrSz) hf(Integer i) = fromInteger(i*valueOf(cmdQDepth));
   Vector#(numServers, Reg#(Bit#(outCntSz)))     outs1 <- replicateM(mkReg(0));
   Vector#(numServers, Reg#(Bit#(outCntSz)))     outs0 <- replicateM(mkReg(0));
   Vector#(numServers, Reg#(Bit#(16)))         buffCap <- replicateM(mkReg(maxBurstBeats*maxBufferedBursts));
   Vector#(numServers, Reg#(Bit#(cmdBuffAddrSz))) head <- mapM(mkReg, genWith(hf));
   Vector#(numServers, Reg#(Bit#(cmdBuffAddrSz))) tail <- mapM(mkReg, genWith(hf));

   BRAM2Port#(Bit#(cmdBuffAddrSz),MemengineCmd)    cmdBuf <- mkBRAM2Server(defaultValue);
   FIFO#(Bit#(serverIdxSz))                       loadf_a <- mkSizedFIFO(1);
   FIFO#(Tuple2#(Bit#(serverIdxSz),MemengineCmd)) loadf_b <- mkSizedFIFO(1);
   FIFO#(Tuple3#(Bit#(8),Bit#(serverIdxSz),Bool))   workf <- mkSizedFIFO(32); // isthis the right size?

   Vector#(numServers, FIFO#(void))              outfs <- replicateM(mkSizedFIFO(1));
   Vector#(numServers, FIFOF#(Tuple2#(Bit#(serverIdxSz), MemengineCmd))) cmds_in <- replicateM(mkSizedFIFOF(1));
   FunnelPipe#(1, numServers, Tuple2#(Bit#(serverIdxSz), MemengineCmd),bpc) cmds_in_funnel <- mkFunnelPipesPipelined(map(toPipeOut,cmds_in));

   FIFOF#(Tuple2#(Bit#(TLog#(numServers)), Tuple2#(Bit#(dataWidth),Bool))) read_data <- mkFIFOF;
   UnFunnelPipe#(1, numServers, Tuple2#(Bit#(dataWidth),Bool),bpc) read_data_unfunnel <- mkUnFunnelPipesPipelined(cons(toPipeOut(read_data),nil));
   Vector#(numServers, FIFOF#(Tuple2#(Bit#(dataWidth),Bool)))  read_data_unfunnel_buffs <- replicateM(mkSizedBRAMFIFOF(maxBufferedBursts*maxBurstBeats));
   Vector#(numServers, PipeIn#(Tuple2#(Bit#(dataWidth),Bool))) foo = map(toPipeIn, read_data_unfunnel_buffs); 
   zipWithM(mkConnection, read_data_unfunnel, foo);
   function PipeOut#(Bit#(dataWidth)) check_out(PipeOut#(Tuple2#(Bit#(dataWidth),Bool)) x, Integer i) = 
      (interface PipeOut;
	  method Bit#(dataWidth) first;
	     return tpl_1(x.first);
	  endmethod
	  method Action deq;
	     x.deq;
	     buffCap[i] <= buffCap[i]+1;
	     if (tpl_2(x.first)) 
		outfs[i].enq(?);
	  endmethod
	  method Bool notEmpty = x.notEmpty;
       endinterface);
   Vector#(numServers, PipeOut#(Bit#(dataWidth))) read_data_pipes = zipWith(check_out, map(toPipeOut,read_data_unfunnel_buffs), genVector);
   
   Reg#(Bit#(8))                               respCnt <- mkReg(0);
   Reg#(Bit#(serverIdxSz))                     loadIdx <- mkReg(0);
   let beat_shift = fromInteger(valueOf(beatShift));
   let cmd_q_depth = fromInteger(valueOf(cmdQDepth));

   rule store_cmd;
      match {.idx, .cmd} <- toGet(cmds_in_funnel[0]).get;
      outs1[idx] <= outs1[idx]+1;
      cmdBuf.portB.request.put(BRAMRequest{write:True, responseOnWrite:False, address:tail[idx], datain:cmd});
      dynamicAssert(cmd.burstLen>>beat_shift <= maxBurstBeats,  "mkMemreadEngineV.store_cmd::unsupportedBurstLen");
      //$display("MemreadEngineV.store_cmd: %d %d", idx, tail[idx]);

      Bit#(TAdd#(1,cmdBuffAddrSz)) nt = extend(tail[idx])+1;
      Bit#(TAdd#(1,cmdBuffAddrSz)) li = (extend(idx)+1)*cmd_q_depth;
      Bit#(TAdd#(1,cmdBuffAddrSz)) rs = (extend(idx)+0)*cmd_q_depth;
      if (nt >= li) 
	 nt = rs;
      tail[idx] <= truncate(nt);
   endrule
   
   rule load_ctxt_a;
      loadIdx <= loadIdx+1;
      if (outs1[loadIdx] > 0) begin
	 cmdBuf.portA.request.put(BRAMRequest{write:False, responseOnWrite:False, address:head[loadIdx], datain:?});
	 loadf_a.enq(loadIdx);
      end
   endrule

   rule load_ctxt_b;
      let idx <- toGet(loadf_a).get;
      let cmd <- cmdBuf.portA.response.get;
      if (outs1[idx] > 0 && buffCap[idx] > extend(cmd.burstLen>>beat_shift)) begin
	 //$display("load_ctxt %h %d", cmd.base, idx);
	 buffCap[idx] <= buffCap[idx]-extend(cmd.burstLen>>beat_shift);
	 loadf_b.enq(tuple2(idx,cmd));
	 if (cmd.len <= extend(cmd.burstLen)) begin
	    outs1[idx] <= outs1[idx]-1;

	    Bit#(TAdd#(1,cmdBuffAddrSz)) nt = extend(head[idx])+1;
	    Bit#(TAdd#(1,cmdBuffAddrSz)) li = (extend(idx)+1)*cmd_q_depth;
	    Bit#(TAdd#(1,cmdBuffAddrSz)) rs = (extend(idx)+0)*cmd_q_depth;
	    if (nt >= li) 
	       nt = rs;
	    head[idx] <= truncate(nt);
	    //$display("new_head %d %d", idx, new_head);	 
	 end
	 let new_cmd = MemengineCmd{pointer:cmd.pointer, base:cmd.base+extend(cmd.burstLen), burstLen:cmd.burstLen, len:cmd.len-extend(cmd.burstLen)};
	 cmdBuf.portA.request.put(BRAMRequest{write:True, responseOnWrite:False, address:head[idx], datain:new_cmd});
      end
   endrule
   
   Vector#(numServers, Server#(MemengineCmd,Bool)) rs;
   for(Integer i = 0; i < valueOf(numServers); i=i+1)
      rs[i] = (interface Server#(MemengineCmd,Bool);
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
	    match {.idx, .cmd} <- toGet(loadf_b).get;
	    Bit#(8) bl = cmd.burstLen;
	    let last = False;
	    if (cmd.len <= extend(bl)) begin
	       last = True;
	       bl = truncate(cmd.len);
	    end
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




