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


import BRAMFIFO::*;
import GetPut::*;
import ClientServer::*;
import RingBuffer::*;

interface RingSWtoHW;
   interface RingBuffer ring;
   interface GetF#(Bit#(64));
   method Action hwenable(Bit#(1) en);
endinterface: RingSwtoHW

module mkRingSWtoHW#(RingBuffer ring, ReadChan#(Bit#(64)) copy_read_chan, UInt itemSize)(RingSwToHW);

   FIFOF#(Bit#(64)) out <- mkSizedBRAMFIFOF#(itemSize * 4);

   Stmt fetchMachine = 
   seq
   while(hwenabled) seq
      if (ring.notEmpty())
	 seq
	    cmd_read_chan.readReq.put(ring.get(2));
	    ring.pop(8);
	 endseq
     endseq
   endrule

   rule ramDataReady 
      UInt#(64) d = cmd_read_chan.readData.get;
      out.put(d);
   endrule
      


endmodule
