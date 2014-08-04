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
import Vector::*;
import ClientServer::*;
import GetPut::*;

import MemTypes::*;
import MemreadEngine::*;
import MemwriteEngine::*;
import Pipe::*;
import Connectable::*;

interface ChannelSelectRequest;
   
   
   
   method Action startRead(Bit#(32) pointer, Bit#(32) numWords, Bit#(32) burstLen, Bit#(32) run);
   method Action startWrite(Bit#(32) pointer, Bit#(32) numWords, Bit#(32) burstLen, Bit#(32) run);
   method Action getReadStatus();
   method Action getWriteStatus();
endinterface


interface ChannelRequestIndication;
   method Action readStatus(Bit#(32) numIter, Bit#(32) running);
   method Action writeStatus(Bit#(32) numIter, Bit#(32) running);
endinterface

module mkChannelSelectRequest#(ChannelRequestIndication indication) (ChannelSelectRequest);

   
   rule writeFinish;
      let rv <- we.writeServers[0].response.get;
      if (writeRun == 0)
	 indication.writeStatus(writeIterCount, zeroExtend(writeRun));
   endrule
   
   interface ChannelRequestRequest request;
      method Action startRead(Bit#(32) pointer, Bit#(32) numWords, Bit#(32) burstLen, Bit#(32) run);
	 $display("startRead rdPointer=%d numWords=%h burstLen=%d run=%d",
	    pointer, numWords, burstLen, run);
	 if (run == 1) indication.readStatus(readIterCount, run);
	 readPointer <= pointer;
	 readNumWords  <= numWords;
	 readBurstLen  <= truncate(burstLen);
	 readRun <= truncate(run);
      endmethod
      method Action startWrite(Bit#(32) pointer, Bit#(32) numWords, Bit#(32) burstLen, Bit#(32) run);
	 $display("startWrite rdPointer=%d numWords=%h burstLen=%d run=%d",
	    pointer, numWords, burstLen, run);
	 if (run == 1) indication.writeStatus(writeIterCount, run);
	 writePointer <= pointer;
	 writeNumWords  <= numWords;
	 writeBurstLen  <= truncate(burstLen);
	 writeRun <= truncate(run);
      endmethod
      method Action getReadStatus();
	 indication.readStatus(readIterCount, zeroExtend(readRun));
      endmethod
      method Action getWriteStatus();
	 indication.writeStatus(writeIterCount, zeroExtend(writeRun));
      endmethod
   endinterface
endmodule


