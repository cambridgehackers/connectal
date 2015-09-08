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
   method Action read(Bit#(32) sglId, Bit#(32) base, Bit#(8) burstLen, Bit#(32) bytes, Bit#(8) tag);
   method Action write(Bit#(32) sglId, Bit#(32) base, Bit#(8) burstLen, Bit#(32) bytes, Bit#(8) tag);
endinterface

interface DmaIndication;
   method Action readDone(Bit#(8) tag);
   method Action writeDone(Bit#(8) tag);
endinterface

interface Dma;
   // request from software
   interface DmaRequest request;
   // data out to application logic
   interface Vector#(1,PipeOut#(MemDataF#(DataBusWidth))) readData;
   // data in from application logic
   interface Vector#(1,PipeIn#(MemDataF#(DataBusWidth)))  writeData;
   // DMA interfaces connected to MemServer
   interface Vector#(1,MemReadClient#(DataBusWidth))      readClient;
   interface Vector#(1,MemWriteClient#(DataBusWidth))     writeClient;
endinterface

typedef 14 NumOutstandingRequests;
typedef TMul#(NumOutstandingRequests,TMul#(32,4)) BufferSizeBytes;

function Bit#(dsz) memdatafToData(MemDataF#(dsz) mdf); return mdf.data; endfunction

module mkDma#(DmaIndication indication)(Dma);
   MemReadEngine#(DataBusWidth,DataBusWidth,NumOutstandingRequests,1)  re <- mkMemReadEngineBuff(valueOf(BufferSizeBytes));
   MemWriteEngine#(DataBusWidth,DataBusWidth,NumOutstandingRequests,1) we <- mkMemWriteEngineBuff(valueOf(BufferSizeBytes));

   FIFOF#(MemDataF#(DataBusWidth)) readFifo <- mkFIFOF();
   FIFO#(Bit#(8)) readTags <- mkSizedFIFO(valueOf(NumOutstandingRequests));
   FIFO#(Bit#(8)) writeTags <- mkSizedFIFO(valueOf(NumOutstandingRequests));

   rule readDataRule;
      let mdf <- toGet(re.readServers[0].data).get();
      if (mdf.last)
	 readTags.enq(extend(mdf.tag));
      readFifo.enq(mdf);
   endrule
   rule readDoneRule;
      let tag <- toGet(readTags).get();
      indication.readDone(tag);
   endrule
   rule writeDoneRule;
      let done <- we.writeServers[0].done.get();
      let tag <- toGet(writeTags).get();
      indication.writeDone(tag);
   endrule

   interface DmaRequest request;
      method Action read(Bit#(32) sglId, Bit#(32) base, Bit#(8) burstLen, Bit#(32) bytes, Bit#(8) tag);
         re.readServers[0].request.put(MemengineCmd {sglId: truncate(sglId),
						     base: extend(base),
						     burstLen: extend(burstLen),
						     len: bytes,
						     tag: truncate(tag)
						     });
      endmethod
      method Action write(Bit#(32) sglId, Bit#(32) base, Bit#(8) burstLen, Bit#(32) bytes, Bit#(8) tag);
         we.writeServers[0].request.put(MemengineCmd {sglId: truncate(sglId),
						      base: extend(base),
						      burstLen: extend(burstLen),
						      len: bytes,
						      tag: truncate(tag)
						      });
	 writeTags.enq(tag);
      endmethod
   endinterface
   interface readData = vec(toPipeOut(readFifo));
   interface writeData = vec(mapPipeIn(memdatafToData, we.writeServers[0].data));
   interface readClient = vec(re.dmaClient);
   interface writeClient = vec(we.dmaClient);
endmodule
