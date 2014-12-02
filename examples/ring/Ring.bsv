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

import FIFO::*;
import FIFOF::*;
import BRAMFIFO::*;
import GetPut::*;
import GetPutF::*;
import StmtFSM::*;
import ClientServer::*;

import ConnectalMemory::*;
import MemTypes::*;
import ConnectalCompletionBuffer::**;

import RingTypes::*;
import RingBuffer::*;
import CopyEngine::*;
import EchoEngine::*;
import NopEngine::*;

interface RingRequest;
   method Action set(Bit#(1) cmd, Bit#(3) regist, Bit#(64) addr);
   method Action setCmdLast(Bit#(64) addr);
   method Action setCmdFirst(Bit#(64) addr);
   method Action setStatusLast(Bit#(64) addr);
   method Action setStatusFirst(Bit#(64) addr);
   method Action get(Bit#(1) cmd, Bit#(3) regist);
   method Action hwenable(Bit#(1) en);
   method Action doCommandIndirect(Bit#(64) pointer, Bit#(64) addr);
   method Action doCommandImmediate(Bit#(64) data);
endinterface

interface RingIndication;
   method Action setResult(Bit#(1) cmd, Bit#(3) regist, Bit#(64) addr);
   method Action getResult(Bit#(1) cmd, Bit#(3) regist, Bit#(64) addr);
endinterface

module mkRingRequest#(RingIndication indication,
		      MemReadServer#(64) dma_read_chan,
		      MemWriteServer#(64) dma_write_chan,
		      MemReadServer#(64) cmd_read_chan,
		      MemWriteServer#(64) status_write_chan )(RingRequest);

   ServerF#(Bit#(64), Bit#(64)) copyEngine <- mkCopyEngine(dma_read_chan, dma_write_chan);   
   ServerF#(Bit#(64), Bit#(64)) nopEngine <- mkNopEngine();
   ServerF#(Bit#(64), Bit#(64)) echoEngine <- mkEchoEngine();
   CompletionBuffer#(4,void) fetchComplete <- mkCompletionBuffer;
   
   RingBuffer cmdRing <- mkRingBuffer;
   RingBuffer statusRing <- mkRingBuffer;
   Reg#(Bool) hwenabled <- mkReg(False);
   Reg#(Bool) cmdBusy <- mkReg(False);
   Reg#(MemData#(64)) cmd <- mkReg(MemData{data:0, tag:0});
   Reg#(Bit#(4)) ii <- mkReg(0);
   Reg#(Bit#(4)) respCtr <- mkReg(0);
   Reg#(Bit#(4)) dispCtr <- mkReg(0);
   Reg#(Bit#(6)) statusTag <- mkReg(0);
   Reg#(Bool) cmdFetchEn <- mkReg(False);

   let engineselect = cmd.data[63:56];
   function ServerF#(Bit#(64), Bit#(64)) cmdifc();
      if (engineselect == zeroExtend(pack(CmdNOP))) 
	 return nopEngine;
      else if (engineselect == zeroExtend(pack(CmdCOPY))) 
	 return copyEngine;
      else if (engineselect == zeroExtend(pack(CmdECHO))) 
	 return echoEngine;
      else 
	 return nopEngine;
   endfunction

   Stmt cmdFetch =   
   seq
//      $display("cmdFetch FSM TOP");
      while (True) 
	 seq
	    if (hwenabled) 
	       seq
	       if (cmdRing.notEmpty()) 
		  action
		     let ct <-  fetchComplete.reserve.get();
//		     $display ("cmdFetch handle=%h address=%h burst=%h tag=%h", 
//		      cmdRing.mempointer, cmdRing.bufferlastfetch, 8, ct );
		     cmd_read_chan.readReq.put(
			MemRequest{sglId: cmdRing.mempointer,
			   offset: cmdRing.bufferlastfetch, burstLen: 8*8, tag: zeroExtend(unpack(ct))});
		     cmdRing.popfetch();
		  endaction
	       endseq
	 endseq
   endseq;
   
   Stmt cmdDispatch = 
   seq
      while (True) seq
//	 $display("cmdDispatch FSM TOP");
	 seq
	    action
	       let rv <- cmd_read_chan.readData.get();
	       cmd <= rv;
	       fetchComplete.complete.put(tuple2(pack(truncate(rv.tag)),?));
	    endaction
	    // wait a cycle so cmd is valid!
//	    $display("cmdDispatch 0 tag=%h %h", cmd.tag, cmd.data);
	    cmdifc.request.put(cmd.data);
	 endseq
	 for (dispCtr <= 1; dispCtr < 8; dispCtr <= dispCtr + 1)
	    action
	       let rv <- cmd_read_chan.readData.get();
//	       $display("  cmdDispatch %h tag=%h %h", dispCtr, rv.tag, rv.data);
	       cmdifc.request.put(rv.data);
	    endaction
      endseq
   endseq;
   
   rule finishCmdReads;
      let v <- fetchComplete.drain.get();
      cmdRing.popack();
//      $display("pop ack");
   endrule
   
   Stmt responseArbiter =
   seq
      while(True) seq
	 if (statusRing.notFull() && copyEngine.response.notEmpty())
	    seq
//	       $display("responseArbiter copyEngine completion");
//	       $display("status write handle=%d address=%h burst=%h tag=%h",
//		  statusRing.mempointer, statusRing.bufferfirst, 8, statusTag);
	       status_write_chan.writeReq.put(
		  MemRequest{sglId: statusRing.mempointer, 
		     offset: statusRing.bufferfirst, burstLen: 8*8, tag: statusTag});
	       for (respCtr <= 0; respCtr < 8; respCtr <= respCtr + 1)
		  action
		     let rv <- copyEngine.response.get();
		     status_write_chan.writeData.put(MemData{data: rv, tag: statusTag});
		  endaction
	       statusRing.push();
	       statusTag <= statusTag + 1;
	    endseq
	 
	 if (statusRing.notFull() && echoEngine.response.notEmpty())
	    seq
//	       $display("responseArbiter echoEngine completion");
//	       $display("status write handle=%d address=%h burst=%h tag=%h",
//		  statusRing.mempointer, statusRing.bufferfirst, 8, statusTag);
	       status_write_chan.writeReq.put(
		  MemRequest{sglId: statusRing.mempointer, 
		     offset: statusRing.bufferfirst, burstLen: 8*8, tag: statusTag});
	       for (respCtr <= 0; respCtr < 8; respCtr <= respCtr + 1)
		  action
		     let rv <- echoEngine.response.get();
		     status_write_chan.writeData.put(MemData{data: rv, tag: statusTag});
		  endaction
	       statusRing.push();
	       statusTag <= statusTag + 1;
	    endseq

      endseq
   endseq;
   
   rule writeAck;
      let tag <- status_write_chan.writeDone.get();
      //$display("status write done tag=%h", tag);
   endrule
   
   mkAutoFSM (cmdFetch);
   mkAutoFSM (cmdDispatch);
   mkAutoFSM (responseArbiter);

      // to start a command, doCommand fires off a memory read to the
      // specified address. when it comes back, the doCommandRule will
      // handle it
      method Action doCommandIndirect(Bit#(64) pointer, Bit#(64) addr);
	 let ct <- fetchComplete.reserve.get();
	 cmd_read_chan.readReq.put(
				   MemRequest{sglId: truncate(pointer),
	 offset: truncate(addr), burstLen: 8*8, tag: zeroExtend(unpack(ct))});
      endmethod
   
      method Action doCommandImmediate(Bit#(64) data);
      	 $display("doCommandImmediate %h", data);
      endmethod

      method Action set(Bit#(1) _cmd, Bit#(3) regist, Bit#(64) addr);
	 if (_cmd == 0)
	    cmdRing.configifc.set(regist, truncate(addr));
	 else
	    statusRing.configifc.set(regist, truncate(addr));
	 indication.setResult(_cmd, regist, addr);
      endmethod
   
      method Action setCmdFirst(Bit#(64) addr);
	    cmdRing.configifc.setFirst(truncate(addr));
      endmethod
   
      method Action setStatusFirst(Bit#(64) addr);
	    statusRing.configifc.setFirst(truncate(addr));
      endmethod
   
      method Action setCmdLast(Bit#(64) addr);
	    cmdRing.configifc.setLast(truncate(addr));
      endmethod
   
      method Action setStatusLast(Bit#(64) addr);
	    statusRing.configifc.setLast(truncate(addr));
      endmethod
   
      method Action get(Bit#(1) _cmd, Bit#(3) regist);
	 if (_cmd == 0)
	    indication.getResult(0, regist, 
	       zeroExtend(cmdRing.configifc.get(regist)));
	 else
	    indication.getResult(1, regist, 
	       zeroExtend(statusRing.configifc.get(regist)));
      endmethod


      method Action hwenable(Bit#(1) en);
	 $display ("hwenable set to %h", en);
	 hwenabled <= en == 1;
      endmethod
   
endmodule