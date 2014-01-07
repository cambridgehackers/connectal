// Copyright (c) 2014 Quanta Research Cambridge, Inc.

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

import Vector            :: *;
import FIFO              :: *;
import SpecialFIFOs      :: *;
import GetPut            :: *;
import Connectable       :: *;
import StmtFSM           :: *;
import Portal            :: *;
import AxiClientServer   :: *;
import Leds              :: *;
import Top               :: *;

import "BDPI" function Action      initPortal(Bit#(32) d);
import "BDPI" function Bool                    writeReq();
import "BDPI" function ActionValue#(Bit#(32)) writeAddr();
import "BDPI" function ActionValue#(Bit#(32)) writeData();
import "BDPI" function Bool                     readReq();
import "BDPI" function ActionValue#(Bit#(32))  readAddr();
import "BDPI" function Action        readData(Bit#(32) d);

		 
		 
module mkBsimTop();
   let top <- mkPortalTop();
   let wf <- mkPipelineFIFO;
   let init_seq = (action 
		      initPortal(0);
		      initPortal(1);
		      initPortal(2);
		      initPortal(3);
		      initPortal(4);
		      initPortal(5);
		      initPortal(6);
		      initPortal(7);
                   endaction);
   let init_fsm <- mkOnce(init_seq);
   
   (* descending_urgency = "rdResp, rdReq" *)
   rule init_rule;
      init_fsm.start;
   endrule
   rule wrReq (writeReq());
      let wa <- writeAddr;
      let wd <- writeData;
      top.ctrl.req_aw.put(Axi3WriteRequest { address: wa, len: 0, size: axiBusSize(32), id: 0, prot: 0, burst: 1, cache: 'b11, qos: 0, lock: 0 });
      wf.enq(wd);
   endrule
   rule wrData;
      wf.deq;
      top.ctrl.resp_write.put(Axi3WriteData { data: wf.first, id: 0, last: 1 });
   endrule
   rule rdReq (readReq());
      let ra <- readAddr;
	 top.ctrl.req_ar.put(Axi3ReadRequest { address: ra, len: 0, size: axiBusSize(32), id: 0, prot: 0, burst: 1, cache: 'b11, qos: 0, lock: 0 });
   endrule
   rule rdResp;
      let rd <- top.ctrl.resp_read.get();
      readData(rd.data);
   endrule
endmodule
