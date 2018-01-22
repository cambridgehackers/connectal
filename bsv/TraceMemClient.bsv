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
import ConnectalMemTypes::*;
import ConnectalMemory::*;

module mkTraceReadClient#(PipeIn#(Tuple4#(dmaChanId,Bool,MemRequest,Bit#(timeStampWidth))) tracePipe,
			  PipeIn#(Tuple4#(dmaChanId,Bool,MemData#(dataWidth),Bit#(timeStampWidth))) traceDataPipe,
			  dmaChanId chan,
			  MemReadClient#(dataWidth) m)
   (MemReadClient#(dataWidth));

   Reg#(Bit#(timeStampWidth)) cycles <- mkReg(0);
   rule rl_cycles;
      cycles <= cycles + 1;
   endrule

   let reqFifo  <- mkFIFOF();
   let dataFifo <- mkFIFOF();

   rule rl_rd_req;
      let mr <- m.readReq.get();
      if (tracePipe.notFull())
	 tracePipe.enq(tuple4(chan, False, mr, cycles));
      reqFifo.enq(mr);
   endrule

   rule rl_rd_data;
      let md <- toGet(dataFifo).get();
      if (traceDataPipe.notFull())
	 traceDataPipe.enq(tuple4(chan, False, md, cycles));
      m.readData.put(md);
   endrule

   interface Get readReq = toGet(reqFifo);
   interface Put readData = toPut(dataFifo);
endmodule

module mkTraceWriteClient#(PipeIn#(Tuple4#(dmaChanId,Bool,MemRequest,Bit#(timeStampWidth))) tracePipe,
			   PipeIn#(Tuple4#(dmaChanId,Bool,MemData#(dataWidth),Bit#(timeStampWidth))) traceDataPipe,
			   PipeIn#(Tuple2#(dmaChanId,Bit#(timeStampWidth))) traceDonePipe,
			   dmaChanId chan, MemWriteClient#(dataWidth) m)
   (MemWriteClient#(dataWidth));

   Reg#(Bit#(timeStampWidth)) cycles <- mkReg(0);
   rule rl_cycles;
      cycles <= cycles + 1;
   endrule

   let reqFifo <- mkFIFOF();
   let dataFifo <- mkFIFOF();
   let doneFifo <- mkFIFOF();

   rule rl_wr_req;
      let mr <- m.writeReq.get();
      if (tracePipe.notFull())
	 tracePipe.enq(tuple4(chan, True, mr, cycles));
      reqFifo.enq(mr);
   endrule

   rule rl_wr_data;
      let md <- m.writeData.get();
      if (traceDataPipe.notFull())
	 traceDataPipe.enq(tuple4(chan, True, md, cycles));
      dataFifo.enq(md);
   endrule

   rule rl_wr_done;
      let tag <- toGet(doneFifo).get();
      if (traceDonePipe.notFull())
	 traceDonePipe.enq(tuple2(chan, cycles));
      m.writeDone.put(tag);
   endrule

   interface Get writeReq = toGet(reqFifo);
   interface Get writeData = toGet(dataFifo);
   interface Put writeDone = toPut(doneFifo);
endmodule
