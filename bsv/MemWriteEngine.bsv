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
import BuildVector::*;
import Cntrs::*;
import FIFOF::*;
import FIFO::*;
import GetPut::*;
import Connectable::*;
import BRAMFIFO::*;
import ConfigCounter::*;
import MemTypes::*;
import Pipe::*;
import ConnectalConfig::*;

`include "ConnectalProjectConfig.bsv"

module mkMemWriteEngine(MemWriteEngine#(busWidth, userWidth, cmdQDepth, numServers))
   provisos( Add#(1, d__, busWidth)
	    ,Add#(1, d__, userWidth)
	    ,Add#(e__, TLog#(numServers), MemTagSize)
	    ,FunnelPipesPipelined#(1, numServers, MemData#(userWidth), 2)
	    ,FunnelPipesPipelined#(1, numServers, MemRequest, 2)
	    ,FunnelPipesPipelined#(1, numServers, Bit#(MemTagSize), 2)
	    );
   let rv <- mkMemWriteEngineBuff(valueOf(TExp#(BurstLenSize)));
   return rv;
endmodule

interface MemWriteChannel#(numeric type busWidth, numeric type userWidth, numeric type cmdQDepth);
   interface PipeIn#(Bit#(MemTagSize))        writeGnt; // grants request
   interface PipeOut#(MemRequest)             writeReq;
   interface PipeOut#(MemData#(userWidth))    writeData;
   interface PipeIn#(Bit#(MemTagSize))        writeDone;
   interface MemWriteEngineServer#(userWidth) writeServer;
endinterface

module mkMemWriteChannel#(Integer bufferSizeBytes, Integer channelNumber,
			  PipeOut#(Bit#(MemTagSize)) writeGntPipe, PipeOut#(Bit#(MemTagSize)) writeDonePipe)
   (MemWriteChannel#(busWidth, userWidth, cmdQDepth))
   provisos ( Div#(busWidth,8,busWidthBytes)
	     ,Log#(busWidthBytes,beatShift)
	     ,Add#(1, d__, userWidth)
	     ,Add#(userWidth, 0, busWidth)
	     );

   Integer bufferSizeBeats = bufferSizeBytes/valueOf(busWidthBytes);
   Reg#(Bool) load_in_progress <- mkReg(False);
   FIFO#(Tuple3#(MemengineCmd,Bool,Bool))       serverCond <- mkFIFO1();
   FIFO#(Tuple2#(Bit#(MemTagSize),MemengineCmd)) serverReq <- mkSizedFIFO(valueOf(cmdQDepth));
   FIFO#(Tuple3#(Bit#(8),Bit#(MemTagSize),Bool))inProgress <- mkSizedFIFO(valueOf(cmdQDepth));
   FIFO#(Tuple3#(Bit#(MemTagSize),Bit#(MemTagSize),Bool)) serverDone <- mkSizedFIFO(valueOf(cmdQDepth));
   FIFOF#(MemRequest)           writeReqFifo <- mkFIFOF();
   FIFOF#(MemData#(userWidth)) writeDataFifo <- mkFIFOF();

   Reg#(Bool)              clientInFlight <- mkReg(False);
   Reg#(Bool)              clientBursts <- mkReg(False);
   ConfigCounter#(16)      clientAvail <- mkConfigCounter(0);
   Reg#(MemengineCmd)      clientStart <- mkReg(unpack(0));
   FIFO#(Bool)             clientFinished <- mkSizedFIFO(1);
   FIFOF#(MemengineCmd)    clientCommand <- mkSizedFIFOF(1);
   Count#(Bit#(32))        clientCycles     <- mkCount(0);
   FIFOF#(MemRequestCycles) clientCyclesFifo <- mkFIFOF();
   FIFOF#(Bit#(userWidth)) dataBuffer <- mkSizedBRAMFIFOF(bufferSizeBeats);
   Reg#(Bit#(32)) cycles <- mkReg(0);
   rule rl_cycles;
      cycles <= cycles + 1;
   endrule
   
   Reg#(Bit#(8))                    respCnt <- mkReg(0);
   let beat_shift = fromInteger(valueOf(beatShift));

   rule store_cmd if (!clientInFlight);
      let cmd <- toGet(clientCommand).get();
      clientInFlight <= True;
      clientBursts <= True;
      clientStart <= cmd;
      $display("cycles %d starting request %d bytes %d", cycles, cmd.tag, cmd.len);
      clientCycles <= 0;
   endrule
   rule rule_request_cycles;
      clientCycles.incr(1);
   endrule

   rule load_ctxt_a if (!load_in_progress);
      if (clientBursts) begin
	 load_in_progress <= True;
	 let cmd = clientStart;
	 let cond0 <- clientAvail.maybeDecrement(unpack(extend(cmd.burstLen>>beat_shift)));
	 let cond1 = cmd.len <= extend(cmd.burstLen);
	 serverCond.enq(tuple3(cmd,cond0,cond1));
      end
   endrule

   rule load_ctxt_b if (load_in_progress);
      load_in_progress <= False;
      match {.cmd,.cond0,.cond1} <- toGet(serverCond).get;
      if  (cond0) begin
	 //$display("load_ctxt_b cycles %d %h", cycles, cmd.base);
	 serverReq.enq(tuple2(0,cmd));
	 if (cond1) begin
	    clientBursts <= False;
	 end
	 else begin
	    clientStart <= MemengineCmd{sglId:cmd.sglId, base:cmd.base+extend(cmd.burstLen),
               burstLen:cmd.burstLen, len:cmd.len-extend(cmd.burstLen), tag:cmd.tag};
	 end
      end
   endrule

   rule rlWriteReq;
      match {.idx, .cmd} <- toGet(serverReq).get;
      Bit#(BurstLenSize) bl = cmd.burstLen;
      Bool last = False;
      if (cmd.len <= extend(bl)) begin
	 last = True;
	 bl = truncate(cmd.len);
      end
      inProgress.enq(tuple3(truncate(bl>>beat_shift), cmd.tag, last));
      //$display("writeReq %d, %h %h %h", channelNumber, cmd.base, bl, last);
      writeReqFifo.enq(MemRequest { sglId: cmd.sglId, offset: extend(cmd.base), burstLen:bl, tag: fromInteger(channelNumber)});
   endrule      

   rule rlWriteData;
      match {.rc, .client_tag, .last} = inProgress.first;
      let gnt = writeGntPipe.first;
      let new_respCnt = respCnt+1;
      let lastBeat = False;
      if (new_respCnt == rc) begin
	 respCnt <= 0;
	 inProgress.deq();
	 writeGntPipe.deq();
	 serverDone.enq(tuple3(0,client_tag,last));
	 lastBeat = True;
      end
      else begin
	 respCnt <= new_respCnt;
      end
      let wd <- toGet(dataBuffer).get();
      writeDataFifo.enq(MemData{data:wd, tag:fromInteger(channelNumber), last:lastBeat});
   endrule      

   rule rlWriteDone;
      let tag <- toGet(writeDonePipe).get();
      match {.idx, .req_tag, .last} <- toGet(serverDone).get;
      if (last) begin
	 clientInFlight <= False;
	 clientFinished.enq(True);
`ifdef MEMENGINE_REQUEST_CYCLES
	 $display("cycles %d req_tag %d clientCycles = %d", cycles, req_tag, clientCycles);
	 clientCyclesFifo.enq(MemRequestCycles { tag: req_tag, cycles: clientCycles });
`endif
      end
      //$display("writeDone %d %d", channelNumber, last);
   endrule

   MemWriteEngineServer#(userWidth) ws = (interface MemWriteEngineServer#(userWidth);
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
		  clientCommand.enq(cmd);
		  $display("(%d) %h %h %h", channelNumber, cmd.base, cmd.len, cmd.burstLen);
	       end
	 endmethod
      endinterface
      interface Get done;
	 method ActionValue#(Bool) get = toGet(clientFinished).get;
      endinterface
      interface PipeIn data = interface PipeIn;
				 method Bool notFull = dataBuffer.notFull;
   				 method Action enq(Bit#(userWidth) v);
				    dataBuffer.enq(v);
				    clientAvail.increment(1);
				 endmethod
			      endinterface;
	 interface PipeOut requestCycles = toPipeOut(clientCyclesFifo);
	 endinterface);
   interface writeServer = ws;
   interface writeReq = toPipeOut(writeReqFifo);
   interface writeData = toPipeOut(writeDataFifo);
endmodule

module mkMemWriteEngineBuff#(Integer bufferSizeBytes)(MemWriteEngine#(busWidth, userWidth, cmdQDepth, numServers))
   provisos ( Div#(busWidth,8,busWidthBytes)
	     ,Log#(busWidthBytes,beatShift)
	     ,Add#(1, a__, userWidth)
	     ,Add#(userWidth, 0, busWidth)
	     ,Add#(b__, TLog#(numServers), MemTagSize)
             ,FunnelPipesPipelined#(1, numServers, MemData#(userWidth), 2)
             ,FunnelPipesPipelined#(1, numServers, MemRequest, 2)
             ,FunnelPipesPipelined#(1, numServers, Bit#(MemTagSize), 2)
	     );

   FIFOF#(Bit#(MemTagSize)) writeDoneFifo <- mkFIFOF();
   function Tuple2#(Bit#(TLog#(numServers)),Bit#(MemTagSize)) tagDone(Bit#(MemTagSize) tag);
      return tuple2(truncate(tag), tag);
   endfunction
`ifdef ARB_FUNNEL
   FIFOF#(Bit#(MemTagSize))       arbFifo <- mkFIFOF1();
   UnFunnelPipe#(1,numServers,Bit#(MemTagSize),2) arbPipes <- mkUnFunnelPipesPipelined(vec(mapPipe(tagDone, toPipeOut(arbFifo))));
   UnFunnelPipe#(1,numServers,Bit#(MemTagSize),2) donePipes <- mkUnFunnelPipesPipelined(vec(mapPipe(tagDone, toPipeOut(writeDoneFifo))));
`else
   Vector#(numServers, FIFOF#(Bit#(MemTagSize)))   arbFifos <- replicateM(mkFIFOF);
   Vector#(numServers, PipeOut#(Bit#(MemTagSize))) arbPipes = map(toPipeOut, arbFifos);
   Vector#(numServers, FIFOF#(Bit#(MemTagSize)))   doneFifos <- replicateM(mkFIFOF);
   Vector#(numServers, PipeOut#(Bit#(MemTagSize))) donePipes = map(toPipeOut, doneFifos);
`endif
   Vector#(numServers, MemWriteChannel#(busWidth,userWidth,cmdQDepth)) writeChannels <- zipWith3M(mkMemWriteChannel(bufferSizeBytes),
												  genVector(),
												  arbPipes,
												  donePipes);
   function PipeOut#(MemRequest) writeChannelDmaWriteReq(Integer i);
      return writeChannels[i].writeReq;
   endfunction
   function PipeOut#(MemData#(userWidth)) writeChannelDmaWriteData(Integer i);
      return writeChannels[i].writeData;
   endfunction
   function MemWriteEngineServer#(userWidth) writeChannelServer(Integer i);
      return writeChannels[i].writeServer;
   endfunction

   Reg#(Bool)         reqInFlight <- mkReg(False);
   FIFOF#(MemRequest)          writeReqFifo <- mkFIFOF();
   FIFOF#(MemData#(userWidth)) writeDataFifo <- mkSizedFIFOF(16);
   FunnelPipe#(1,numServers,MemRequest,2) reqFunnel <- mkFunnelPipesPipelined(genWith(writeChannelDmaWriteReq));
   FunnelPipe#(1,numServers,MemData#(userWidth),2) dataFunnel <- mkFunnelPipesPipelined(genWith(writeChannelDmaWriteData));

   rule rl_arbitration if (!reqInFlight);
      let req <- toGet(reqFunnel[0]).get();
      // tag is channel number
`ifdef ARB_FUNNEL
      arbFifo.enq(req.tag);
`else
      arbFifos[req.tag].enq(req.tag);
`endif
      writeReqFifo.enq(req);
      reqInFlight <= True;
   endrule
   rule rl_writeData if (reqInFlight);
      MemData#(userWidth) md <- toGet(dataFunnel[0]).get();
      if (md.last)
	 reqInFlight <= False;
      writeDataFifo.enq(md);
   endrule

`ifndef ARB_FUNNEL
   rule rl_writeDone;
      let tag <- toGet(writeDoneFifo).get();
      doneFifos[tag].enq(tag);
   endrule
`endif

   interface writeServers = genWith(writeChannelServer);
   interface MemWriteClient dmaClient;
      interface writeReq = toGet(writeReqFifo);
      interface writeData = toGet(writeDataFifo);
      interface writeDone = toPut(writeDoneFifo);
   endinterface: dmaClient

endmodule
