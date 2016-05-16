// Copyright (c) 2016 Connectal Project

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
import Pipe::*;
import GetPut::*;
import MemTypes::*;
import ConnectalMemory::*;

module mkTraceReadClient#(PipeIn#(Tuple3#(dmaChanId,Bool,MemRequest)) tracePipe,
			  PipeIn#(Tuple3#(dmaChanId,Bool,MemData#(dataWidth))) traceDataPipe,
			  dmaChanId chan,
			  MemReadClient#(dataWidth) m)
   (MemReadClient#(dataWidth));

   let reqFifo  <- mkFIFOF();
   let dataFifo <- mkFIFOF();

   rule rl_req;
      let mr <- m.readReq.get();
      tracePipe.enq(tuple3(chan, False, mr));
      reqFifo.enq(mr);
   endrule

   rule rl_data;
      let md <- toGet(dataFifo).get();
      traceDataPipe.enq(tuple3(chan, False, md));
      m.readData.put(md);
   endrule

   interface Get readReq = toGet(reqFifo);
   interface Put readData = toPut(dataFifo);
endmodule

module mkTraceWriteClient#(PipeIn#(Tuple3#(dmaChanId,Bool,MemRequest)) tracePipe,
			   PipeIn#(Tuple3#(dmaChanId,Bool,MemData#(dataWidth))) traceDataPipe,
			   dmaChanId chan, MemWriteClient#(dataWidth) m)
   (MemWriteClient#(dataWidth));

   let reqFifo <- mkFIFOF();
   let dataFifo <- mkFIFOF();

   rule rl_req;
      let mr <- m.writeReq.get();
      tracePipe.enq(tuple3(chan, True, mr));
      reqFifo.enq(mr);
   endrule

   rule rl_data;
      let md <- m.writeData.get();
      traceDataPipe.enq(tuple3(chan, True, md));
      dataFifo.enq(md);
   endrule

   interface Get writeReq = toGet(reqFifo);
   interface Get writeData = toGet(dataFifo);
   interface Put writeDone = m.writeDone;
endmodule
