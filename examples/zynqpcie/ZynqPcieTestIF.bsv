
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

import FIFO::*;
import Vector::*;
import Clocks::*;
import BRAM::*;
import PCIE::*;
import PcieTracer::*;

interface ZynqPcieTestRequest;
   method Action getStatus(Bit#(32) v);
   method Action getTrace(Bit#(32) offset);
endinterface
interface ZynqPcieTestIndication;
    method Action status(Bit#(32) v);
    method Action trace(Vector#(6, Bit#(32)) offset);
endinterface

interface ZynqPcieTest;
   interface ZynqPcieTestRequest request;
   interface BRAMClient#(Bit#(TAdd#(TlpTraceAddrSize,1)), TimestampedTlpData) traceBramClient;
endinterface

module mkZynqPcieTest#(SyncBitIfc#(Bit#(1)) lnk_up, SyncBitIfc#(Bit#(1)) resetBit, SyncBitIfc#(Bit#(1)) resetSeenBit, ZynqPcieTestIndication indication)(ZynqPcieTest);

   FIFO#(BRAMRequest#(Bit#(TAdd#(TlpTraceAddrSize,1)), TimestampedTlpData)) requestFifo <- mkFIFO();
   FIFO#(TimestampedTlpData) responseFifo <- mkFIFO();

   rule respond;
      let v <- toGet(responseFifo).get();
      indication.trace(unpack(pack(v)));
   endrule

   interface ZynqPcieTestRequest request;
      method Action getStatus(Bit#(32) v);
	 indication.status(extend({lnk_up.read(), resetBit.read(), resetSeenBit.read()}));
      endmethod
      method Action getTrace(Bit#(32) v);
	 requestFifo.enq(BRAMRequest {
	    write: False,
	    responseOnWrite: False,
	    address: truncate(v),
	    datain: unpack(0)
	 });
      endmethod
   endinterface
   interface BRAMClient traceBramClient;
      interface Get request = fifoToGet(requestFifo);
      interface Put response = fifoToPut(responseFifo);
   endinterface
endmodule
