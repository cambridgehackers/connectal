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

import FIFOF::*;
import BRAMFIFO::*;
import GetPut::*;

import AxiClientServer::*;
import AxiRDMA::*;
import BsimRDMA::*;
import PortalMemory::*;
import PortalRMemory::*;
import StmtFSM::*;

import RingTypes::*;

import RingBuffer::*;
import FIFO::*;
import GetPut::*;
import ClientServer::*;
import CopyEngine::*;
import EchoEngine::*;
import NopEngine::*;

interface CoreRequest;
   method Action set(Bit#(1) cmd, Bit#(2) regist, Bit#(40) addr);
   method Action get(Bit#(1) cmd, Bit#(2) regist);
   method Action hwenable(Bit#(1) en);
   method Action doCommandIndirect(Bit#(40) addr);
   method Action doCommandImmediate(CommandStruct cmd);
endinterface

interface CoreIndication;
   method Action setResult(Bit#(1) cmd, Bit#(2) regist, Bit#(40) addr);
   method Action getResult(Bit#(1) cmd, Bit#(2) regist, Bit#(40) addr);
   method Action completion(Bit#(32) command, Bit#(32) tag);
endinterface

interface RingRequest;
   interface Axi3Client#(40,64,8,12) m_axi;
   interface CoreRequest coreRequest;
   interface DMARequest dmaRequest;
endinterface

interface RingIndication;
   interface CoreIndication coreIndication;
   interface DMAIndication dmaIndication;
endinterface

module mkRingRequest#(RingIndication indication)(RingRequest);
   
`ifdef BSIM
   BsimDMA#(Bit#(64))  dma <- mkBsimDMA(indication.dmaIndication);
`else
   AxiDMA#(Bit#(64))   dma <- mkAxiDMA(indication.dmaIndication);
`endif

   Server#(Bit#(64), Bit#(64)) ce <- mkCopyEngine(dma.read.readChannels[2], dma.write.writeChannels[2]);
   Server#(Bit#(64), Bit#(64)) discardServer <- mkNopServer();
   Server#(Bit#(64), Bit#(64)) echoServer <- mkEchoServer();
   
   Server#(Bit#(64), Bit#(64)) cmdServer;
   Server#(Bit#(64), Bit#(64)) responseServer;

   ReadChan#(Bit#(64))   dma_read_chan = dma.read.readChannels[0];
   WriteChan#(Bit#(64)) dma_write_chan = dma.write.writeChannels[0];
   ReadChan#(CommandStruct) cmd_read_chan = dma.read.readChannels[1];
   WriteChan#(Bit#(64)) status_write_chan = dma.write.writeChannels[1];


   RingBuffer cmdRing <- mkRingBuffer;
   RingBuffer statusRing <- mkRingBuffer;
   Reg#(Bool) hwenabled <- mkReg(False);
   Reg#(Bool) cmdBusy <- mkReg(False);
   UInt#(64) cmd;

   // wait for hwenabled
   // wait for not cmdBusy
   // wait for cmdRing not empty
   // then start fetches for the next command
   Stmt CmdFetch = 
   seq
      while (True) seq
	 while(!(hwenabled && cmdRing.notEmpty())) noAction;
	 cmd_read_chan.readReq.put(cmdRing.expBufferLast);
	 cmdRing.expBufferLast <= cmdRing.expBufferLast + 8;
      endseq
   endseq
   
   function UInt#(8) getopcode(UInt#(64) a);
      return a[63:56];
   endfunction

   Stmt CmdDispatch = 
   seq
      while (True) seq
	 cmd = cmd_read_chan.readData.get();
	 let fn = getopcode(cmd);
	 if (fn == cmdNop)
	    cmdServer = nopServer;
	 else if (fn == cmdCOPY)
	    cmdServer = ce;
	 else if (fn == cmdECHO)
	    cmdServer = echoServer;
	 cmdServer.put(cmd);
	 for (ii = 1; ii < 8; ii = ii + 1)
	    cmdServer.put(cmd_read_chan.readData.get());
      endseq
   endseq
   
   
   Stmt CmdCompletion =
   seq
      while(True) seq
	 while(!(hwenabled && statusRing.notFull())) noAction;
      endseq
   endseq

   rule copyCompletion;
      let v <- ce.response.get();
      indication.coreIndication.completion(1, v);
   endrule

//   rule doCommandRule;
      //let v <- cmd_read_chan.readData.get;
      //doCommandImmediate(v);
//   endrule
   
   interface CoreRequest coreRequest;

      // to start a command, doCommand fires off a memory read to the
      // specified address. when it comes back, the doCommandRule will
      // handle it
      method Action doCommandIndirect(Bit#(40) addr);
	 //cmd_read_chan.readReq.put(addr);
      endmethod
   
      method Action doCommandImmediate(CommandStruct cmd);
      	 $display("doCopy %h %h %h", cmd.fromAddress, cmd.toAddress, cmd.count);
	 ce.request.put(cmd);
      endmethod
   

      method Action set(Bit#(1) cmd, Bit#(2) regist, Bit#(40) addr);
	 if (cmd == 1)
	    cmdRing.set(regist, addr);
	 else
	    statusRing.set(regist, addr);
	 indication.coreIndication.setResult(cmd, regist, addr);
      endmethod
   
      method Action get(Bit#(1) cmd, Bit#(2) regist);
	 if (cmd == 1)
	    indication.coreIndication.getResult(1, regist, cmdRing.get(regist));
	 else
	    indication.coreIndication.getResult(0, regist, 
	       statusRing.get(regist));
      endmethod

      method Action hwenable(Bit#(1) en);
	 hwenabled <= en == 1;
      endmethod
   
       
   endinterface

`ifndef BSIM
   interface Axi3Client m_axi = dma.m_axi;
`endif
   interface DMARequest dmaRequest = dma.request;
endmodule