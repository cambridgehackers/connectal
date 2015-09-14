// Copyright (c) 2015 Connectal Project

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
import BuildVector::*;
import FIFO::*;
import FIFOF::*;
import GetPut::*;
import Connectable::*;
import Pipe::*;
import MemTypes::*;
import MemReadEngine::*;
import MemWriteEngine::*;
import HostInterface::*;

interface DmaRequest;
   method Action burstLen(Bit#(8) burstLenBytes);
   method Action read(Bit#(32) sglId, Bit#(32) base, Bit#(32) bytes, Bit#(8) tag);
   method Action write(Bit#(32) sglId, Bit#(32) base, Bit#(32) bytes, Bit#(8) tag);
endinterface

interface DmaIndication;
   method Action readDone(Bit#(8) tag);
   method Action writeDone(Bit#(8) tag);
endinterface

interface Dma#(numeric type numChannels);
   // request from software
   interface Vector#(numChannels,DmaRequest) request;
   // data out to application logic
   interface Vector#(numChannels,PipeOut#(MemDataF#(DataBusWidth))) readData;
   // data in from application logic
   interface Vector#(numChannels,PipeIn#(MemDataF#(DataBusWidth)))  writeData;
   // DMA interfaces connected to MemServer
   interface Vector#(1,MemReadClient#(DataBusWidth))      readClient;
   interface Vector#(1,MemWriteClient#(DataBusWidth))     writeClient;
endinterface

typedef 14 NumOutstandingRequests;
typedef TMul#(NumOutstandingRequests,TMul#(32,4)) BufferSizeBytes;

function Bit#(dsz) memdatafToData(MemDataF#(dsz) mdf); return mdf.data; endfunction

module mkDma#(DmaIndication indication)(Dma#(numChannels))
   provisos (Add#(1, a__, numChannels),
	     Add#(b__, TLog#(numChannels), TAdd#(1, TLog#(TMul#(NumOutstandingRequests, numChannels)))),
	     Add#(c__, TLog#(numChannels), 6), // why is this?
	     Add#(d__, TLog#(numChannels), TLog#(TMul#(NumOutstandingRequests, numChannels)))
	     );
   MemReadEngine#(DataBusWidth,DataBusWidth,NumOutstandingRequests,numChannels)  re <- mkMemReadEngineBuff(valueOf(BufferSizeBytes));
   MemWriteEngine#(DataBusWidth,DataBusWidth,NumOutstandingRequests,numChannels) we <- mkMemWriteEngineBuff(valueOf(BufferSizeBytes));

   Vector#(numChannels, FIFOF#(MemDataF#(DataBusWidth))) readFifo <- replicateM(mkFIFOF());
   Vector#(numChannels, FIFO#(Bit#(8))) writeTags <- replicateM(mkSizedFIFO(valueOf(NumOutstandingRequests)));
   Reg#(Bit#(BurstLenSize)) burstLenReg <- mkReg(64);

   for (Integer channel = 0; channel < valueOf(numChannels); channel = channel + 1) begin
       FIFO#(Bit#(8)) readTags <- mkSizedFIFO(valueOf(NumOutstandingRequests));

       rule readDataRule;
	  let mdf <- toGet(re.readServers[channel].data).get();
	  if (mdf.last)
	     readTags.enq(extend(mdf.tag));
	  readFifo[channel].enq(mdf);
       endrule
       rule readDoneRule;
	  let tag <- toGet(readTags).get();
	  indication.readDone(tag);
       endrule
       rule writeDoneRule;
	  let done <- we.writeServers[channel].done.get();
	  let tag <- toGet(writeTags[channel]).get();
	  indication.writeDone(tag);
       endrule
   end

   function DmaRequest dmaRequestInterface(Integer channel);
      return (interface DmaRequest;
	 method Action burstLen(Bit#(8) burstLenBytes);
	      burstLenReg <= burstLenBytes;
	 endmethod
	 method Action read(Bit#(32) sglId, Bit#(32) base, Bit#(32) bytes, Bit#(8) tag);
	      re.readServers[channel].request.put(MemengineCmd {sglId: truncate(sglId),
								base: extend(base),
								burstLen: extend(burstLenReg),
								len: bytes,
								tag: truncate(tag)
								});
	 endmethod
	 method Action write(Bit#(32) sglId, Bit#(32) base, Bit#(32) bytes, Bit#(8) tag);
	      we.writeServers[channel].request.put(MemengineCmd {sglId: truncate(sglId),
								 base: extend(base),
								 burstLen: extend(burstLenReg),
								 len: bytes,
								 tag: truncate(tag)
								 });
	      writeTags[channel].enq(tag);
	 endmethod
	 endinterface);
   endfunction
   function PipeIn#(Bit#(dsz)) writeServerData(MemWriteEngineServer#(dsz) s); return s.data; endfunction

   interface Vector request = genWith(dmaRequestInterface);
   interface readData = map(toPipeOut,readFifo);
   interface writeData = map(mapPipeIn(memdatafToData), map(writeServerData, we.writeServers));
   interface readClient = vec(re.dmaClient);
   interface writeClient = vec(we.dmaClient);
endmodule
