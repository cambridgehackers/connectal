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

interface MemreadEngine#(numeric type dataWidth);
   method Action start(ObjectPointer pointer, Bit#(ObjectOffsetSize) base, Bit#(32) readLen, Bit#(32) burstLen);
   method ActionValue#(Bool) finish();
   interface ObjectReadClient#(dataWidth) dmaClient;
endinterface

module mkMemreadEngine#(Integer cmdQDepth, FIFOF#(Bit#(dataWidth)) f) (MemreadEngine#(dataWidth))
   provisos (Div#(dataWidth,8,dataWidthBytes),
	     Mul#(dataWidthBytes,8,dataWidth),
	     Log#(dataWidthBytes,beatShift));
   
   Reg#(Bit#(32))             reqLen <- mkReg(0);
   Reg#(Bit#(32))            respCnt <- mkReg(0);
   
   Reg#(Bit#(32))                off <- mkReg(0);
   Reg#(Bit#(ObjectOffsetSize)) base <- mkReg(0);

   Reg#(ObjectPointer)       pointer <- mkReg(0);
   Reg#(Bit#(8))            burstLen <- mkReg(0);
   
   FIFOF#(Bool)                   ff <- mkSizedFIFOF(1);
   FIFO#(Bit#(32))                wf <- mkSizedFIFO(cmdQDepth);
   
   let beat_shift = fromInteger(valueOf(beatShift));

   method Action start(ObjectPointer p, Bit#(ObjectOffsetSize) b, Bit#(32) rl, Bit#(32) bl) if (off >= reqLen);
      dynamicAssert(bl[31:8]==0, "mkMemreadEngine::start");
      dynamicAssert(bl[7:0]!=0, "mkMemreadEngine::start");
      if (bl[31:8] != 0 || bl[7:0] == 0)
	 $display("MemreadEngine.start burstLen %d out of range [0-255]", bl);
      reqLen   <= rl;
      off      <= 0;
      pointer  <= p;
      burstLen <= truncate(bl);
      base     <= b;
      //$display("mkMemreadEngine.start p=%d b=%d rl=%d beat_shift=%d bl=%d", p, b, rl, beat_shift, bl);
      wf.enq(rl >> beat_shift);
   endmethod
   
   method ActionValue#(Bool) finish;
      ff.deq;
      return ff.first;
   endmethod
   
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
endmodule


typedef struct {ObjectPointer pointer;
		Bit#(ObjectOffsetSize) base;
		Bit#(32) burstLen;
		Bit#(32) readLen;
		} MemengineCmd deriving (Eq,Bits);

interface MemreadEngineV#(numeric type dataWidth, numeric type cmdQDepth, numeric type numServers);
   interface Vector#(numServers, Server#(MemengineCmd,Bool)) readServers;
   interface ObjectReadClient#(dataWidth) dmaClient;
endinterface

module mkMemreadEngineV#(Vector#(numServers, FIFOF#(Bit#(dataWidth))) fs) (MemreadEngineV#(dataWidth, cmdQDepth, numServers))
   provisos (Div#(dataWidth,8,dataWidthBytes),
	     Mul#(dataWidthBytes,8,dataWidth),
	     Log#(dataWidthBytes,beatShift),
	     Mul#(cmdQDepth,numServers,cmdBuffSz),
	     Log#(cmdBuffSz, cmdBuffAddrSz),
	     Log#(numServers, serverIdxSz),
	     Add#(a__, serverIdxSz, cmdBuffAddrSz));
   
   function Bit#(cmdBuffAddrSz) hf(Integer i) = fromInteger(i*valueOf(cmdQDepth));
   Vector#(numServers, Reg#(Bit#(TAdd#(1,TLog#(cmdQDepth))))) outs1 <- replicateM(mkReg(0));
   Vector#(numServers, Reg#(Bit#(TAdd#(1,TLog#(cmdQDepth))))) outs0 <- replicateM(mkReg(0));
   Vector#(numServers, Reg#(Bit#(cmdBuffAddrSz))) head <- mapM(mkReg, genWith(hf));
   Vector#(numServers, Reg#(Bit#(cmdBuffAddrSz))) tail <- mapM(mkReg, genWith(hf));
   Vector#(numServers, FIFO#(MemengineCmd))       infs <- replicateM(mkSizedFIFO(1));

   BRAM1Port#(Bit#(cmdBuffAddrSz),MemengineCmd) cmdBuf <- mkBRAM1Server(defaultValue);
   FIFO#(Bit#(serverIdxSz))                       outf <- mkSizedFIFO(1);   
   FIFO#(Bit#(serverIdxSz))                      loadf <- mkSizedFIFO(1);
   FIFO#(Tuple3#(Bit#(8),Bit#(serverIdxSz),Bool)) workf <- mkSizedFIFO(32); // isthis the right size?
   
   Reg#(Bit#(8))                               respCnt <- mkReg(0);
   Reg#(Bit#(serverIdxSz))                     loadIdx <- mkReg(0);
   let beat_shift = fromInteger(valueOf(beatShift));
   let cmd_q_depth = fromInteger(valueOf(cmdQDepth));

   for(Integer i = 0; i < valueOf(numServers); i=i+1)
    rule store_cmd;
       let cmd <- toGet(infs[i]).get;
       let new_tail = tail[i]+1;
       if (new_tail >= (fromInteger(i)+1)*cmd_q_depth)
	  new_tail = fromInteger(i)*cmd_q_depth;
       tail[i] <= new_tail;
       outs1[i] <= outs1[i]+1;
       cmdBuf.portA.request.put(BRAMRequest{write:True, responseOnWrite:False, address:tail[i], datain:cmd});
       //$display("store_cmd: %d %h", i, tail[i]);
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
			 infs[i].enq(c);
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
	    Bit#(32) bl = cmd.burstLen;
	    let last = False;
	    if (cmd.readLen <= bl) begin
	       last = True;
	       bl = cmd.readLen;
	       outs1[idx] <= outs1[idx]-1;
	       let new_head = head[idx]+1;
	       if (new_head >= extend(idx+1)*cmd_q_depth)
		  new_head = extend(idx)*cmd_q_depth;
	       head[idx] <= new_head;
	       //$display("new_head %d %d", idx, new_head);
	    end
	    let new_cmd = MemengineCmd{pointer:cmd.pointer, base:cmd.base+extend(bl), burstLen:cmd.burstLen, readLen:cmd.readLen-bl};
	    cmdBuf.portA.request.put(BRAMRequest{write:True, responseOnWrite:False, address:head[idx], datain:new_cmd});
	    workf.enq(tuple3(truncate(bl>>beat_shift), idx, last));
	    //$display("readReq %d, %h %h %h", idx, cmd.base, bl, last);
	    return ObjectRequest { pointer: cmd.pointer, offset: cmd.base, burstLen:truncate(bl), tag: 0 };
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

