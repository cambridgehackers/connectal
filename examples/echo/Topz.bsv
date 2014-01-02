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

import SpecialFIFOs::*;
import StmtFSM::*;
import FIFO::*;

import AxiMasterSlave::*;
import Directory::*;
import CtrlMux::*;
import Portal::*;
import Leds::*;

import Top::*;

module mkZynqTop(AxiTop);
   let axiTop <- mkPortalTop();
   return axiTop;
endmodule : mkZynqTop

import "BDPI" function Action      initPortal(Bit#(32) d);
import "BDPI" function Bool                    writeReq();
import "BDPI" function ActionValue#(Bit#(32)) writeAddr();
import "BDPI" function ActionValue#(Bit#(32)) writeData();
import "BDPI" function Bool                     readReq();
import "BDPI" function ActionValue#(Bit#(32))  readAddr();
import "BDPI" function Action        readData(Bit#(32) d);

module mkBsimTop();
   AxiTop top <- mkPortalTop;
   let wf <- mkPipelineFIFO;
   let init_seq = (action 
		      initPortal(0);
		      initPortal(1);
		      initPortal(2);
      		      initPortal(3);
                   endaction);
   let init_fsm <- mkOnce(init_seq);
   rule init_rule;
      init_fsm.start;
   endrule
   rule wrReq (writeReq());
      let wa <- writeAddr;
      let wd <- writeData;
      top.ctrl.write.writeAddr(wa,0,0,0,0,0,0);
      wf.enq(wd);
   endrule
   rule wrData;
      wf.deq;
      top.ctrl.write.writeData(wf.first,0,0,0);
   endrule
   rule rdReq (readReq());
      let ra <- readAddr;
      top.ctrl.read.readAddr(ra,0,0,0,0,0,0);
   endrule
   rule rdResp;
      let rd <- top.ctrl.read.readData;
      readData(rd);
   endrule
endmodule
