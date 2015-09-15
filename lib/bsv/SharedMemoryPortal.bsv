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
import Vector::*;
import GetPut::*;
import Connectable::*;
import ClientServer::*;
import Gearbox::*;
import MIFO::*;
import DefaultValue::*;
import MIMO::*;
import Pipe::*;
import Portal::*;
import MemTypes::*;
import ConnectalMemory::*;
import SharedMemoryFifo::*;

typedef enum {
   Idle,
   HeadRequested,
   TailRequested,
   RequestMessage,
   MessageHeaderRequested,
   MessageRequested,
   Drain,
   UpdateTail,
   UpdateHead,
   UpdateHead2,
   Waiting,
   SendHeader,
   SendMessage,
   SendPadding,
   Stop
   } SharedMemoryPortalState deriving (Bits,Eq);

module mkSharedMemoryRequestPortal#(PipePortal#(numRequests, numIndications, 32) portal,
   function Bit#(16) messageSize(Bit#(16) methodNumber),
   Vector#(2, MemReadEngineServer#(64)) readEngine, Vector#(2, MemWriteEngineServer#(64)) writeEngine)(SharedMemoryPortal#(64));
   SharedMemoryPipeOut#(64,numRequests) pipeOut <- mkSharedMemoryPipeOut(readEngine, writeEngine);
   mapM_(uncurry(mkConnection), zip(pipeOut.data, portal.requests));

   interface SharedMemoryPortalConfig cfg = pipeOut.cfg;
endmodule

// adds a header word to each message out of an indication pipe
module mkFramedIndicationPipe#(PipePortal#(numRequests,numIndications,32) pipePortal,
			       function Bit#(16) messageSize(Bit#(16) methodNumber),
			       Integer i)(PipeOut#(Bit#(32)));

   let pipeOut = pipePortal.indications[i];
   Bit#(16) messageBits = messageSize(fromInteger(i));
   Bit#(16) roundup = messageBits[4:0] == 0 ? 0 : 1;
   Bit#(16) numWords = (messageBits >> 5) + roundup;
   Bit#(16) totalWords = numWords + 1;
   Bit#(32) hdr = fromInteger(i) << 16 | extend(numWords + 1);
   let sendHeader <- mkReg(True);
   Reg#(Bit#(16)) burstLenReg <- mkReg(0);
   return (interface PipeOut;
	      method Bit#(32) first() if (pipeOut.notEmpty());
	         if (sendHeader)
		    return hdr;
		 else
		    return pipeOut.first();
	      endmethod
	      method Action deq() if (pipeOut.notEmpty());
	         if (sendHeader) begin
		    sendHeader <= False;
		    burstLenReg <= numWords;
		 end
		 else begin
		    pipeOut.deq();
		    burstLenReg <= burstLenReg - 1;
		    if (burstLenReg == 1)
		       sendHeader <= True;
		 end
	      endmethod
	      method Bool notEmpty(); return pipeOut.notEmpty(); endmethod
	   endinterface);
endmodule

module mkSharedMemoryIndicationPortal#(PipePortal#(numRequests,numIndications,32) pipePortal,
				       function Bit#(16) messageSize(Bit#(16) methodNumber),
				       Vector#(2, MemReadEngineServer#(64)) readEngines, Vector#(2, MemWriteEngineServer#(64)) writeEngines)
   (SharedMemoryPortal#(64));

   Vector#(numIndications, PipeOut#(Bit#(32))) indicationPipes <- genWithM(mkFramedIndicationPipe(pipePortal,messageSize));

   SharedMemoryPipeIn#(64) pipeIn <- mkSharedMemoryPipeIn(indicationPipes, readEngines, writeEngines);
   interface SharedMemoryPortalConfig cfg = pipeIn.cfg;
endmodule
