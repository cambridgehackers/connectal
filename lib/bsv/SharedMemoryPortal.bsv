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
import BuildVector::*;
import ClientServer::*;
import Connectable::*;
import DefaultValue::*;
import FIFOF::*;
import Gearbox::*;
import GetPut::*;
import MIMO::*;
import Probe::*;
import Vector::*;

import Pipe::*;
import Portal::*;
import ConnectalMemTypes::*;
import ConnectalMemory::*;
import SharedMemoryFifo::*;

module mkSharedMemoryRequestPortal#(PipePortal#(numRequests, numIndications, 32) portal,
   function Bit#(16) messageSize(Bit#(16) methodNumber),
   Vector#(2, MemReadEngineServer#(64)) readEngine, Vector#(2, MemWriteEngineServer#(64)) writeEngine)(SharedMemoryPortal#(64));
   SharedMemoryPipeOut#(64,numRequests) pipeOut <- mkSharedMemoryPipeOut(readEngine, writeEngine);
   SerialPortalDemux#(numRequests) demux <- mkSerialPortalDemux(Method);
   mkConnection(pipeOut.data, demux.inputPipe);
   mapM_(uncurry(mkConnection), zip(demux.data, portal.requests));

   interface SharedMemoryPortalConfig cfg = pipeOut.cfg;
endmodule

// adds a header word to each message out of an indication pipe
module mkFramedMessagePipe#(Integer portalNumber,
			    PipePortal#(numRequests,numIndications,32) pipePortal,
			    function Bit#(16) messageSize(Bit#(16) methodNumber),
			    Integer i)(PipeOut#(Bit#(32)));

   let pipeOut = pipePortal.indications[i];
   Bit#(16) messageBits = messageSize(fromInteger(i));
   Bit#(16) roundup = messageBits[4:0] == 0 ? 0 : 1;
   Bit#(16) numWords = (messageBits >> 5) + roundup;
   Bit#(16) totalWords = numWords + 1;
   Bit#(32) hdr = (fromInteger(portalNumber) << 24) | (fromInteger(i) << 16) | extend(numWords + 1);
   let sendHeader <- mkReg(True);
   Reg#(Bit#(16)) burstLenReg <- mkReg(0);
   PipeOut#(Bit#(32)) framedPipe = (interface PipeOut;
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
   if (False) begin // optional pipeline stage
      FIFOF#(Bit#(32)) framedFifo <- mkFIFOF();
      mkConnection(framedPipe, toPipeIn(framedFifo));
      return toPipeOut(framedFifo);
   end
   else begin
      return framedPipe;
   end
endmodule

module mkSharedMemoryIndicationPortal#(PipePortal#(numRequests,numIndications,32) pipePortal,
				       function Bit#(16) messageSize(Bit#(16) methodNumber),
				       Vector#(2, MemReadEngineServer#(64)) readEngines, Vector#(2, MemWriteEngineServer#(64)) writeEngines)
   (SharedMemoryPortal#(64));

   Vector#(numIndications, PipeOut#(Bit#(32))) indicationPipes <- genWithM(mkFramedMessagePipe(0,pipePortal,messageSize));

   SerialPortalMux#(numIndications) serialPortalMux <- mkSerialPortalMux();
   mkConnection(indicationPipes, serialPortalMux.data);
   SharedMemoryPipeIn#(64) pipeIn <- mkSharedMemoryPipeIn(serialPortalMux.outputPipe, readEngines, writeEngines);
   interface SharedMemoryPortalConfig cfg = pipeIn.cfg;
endmodule

interface SerialPortalDemux#(numeric type pipeCount);
   interface Vector#(pipeCount, PipeOut#(Bit#(32))) data;
   interface PipeIn#(Bit#(32))                      inputPipe;
endinterface
interface SerialPortalMux#(numeric type pipeCount);
   interface Vector#(pipeCount, PipeIn#(Bit#(32))) data;
   interface PipeOut#(Bit#(32))                    outputPipe;
endinterface

typedef enum {
   Idle,
   MessageHeader,
   MessageBody,
   Stop
   } SerialPortalState deriving (Bits,Eq);

typedef enum {
   Portal,
   Method
   } SerialPortalDemuxLevel deriving (Bits,Eq);

module mkSerialPortalDemux#(SerialPortalDemuxLevel portalDemux)(SerialPortalDemux#(pipeCount));
   let clock <- exposeCurrentClock();
   let reset <- exposeCurrentReset();
   Reg#(Bit#(16)) messageWordsReg <- mkReg(0);
   Reg#(Bit#(8))  selectorReg <- mkReg(0);
   Reg#(SerialPortalState) state <- mkReg(Idle);
   FIFOF#(Bit#(32)) inputFifo <- mkFIFOF();
   Vector#(pipeCount, FIFOF#(Bit#(32))) dataFifo <- replicateM(mkFIFOF);

   let verbose = False;

   rule idle if (state == Idle);
      state <= MessageHeader;
   endrule

   rule receiveMessageHeader if (state == MessageHeader);
      let hdr <- toGet(inputFifo).get();
      let selector = (portalDemux == Portal) ? hdr[31:24] : hdr[23:16];
      let messageWords = hdr[15:0];
      selectorReg <= selector;
      if (verbose)
         $display("receiveMessageHeader hdr=%x selector=%x messageWords=%d", hdr, selector, messageWords);
      if (portalDemux == Portal) // methodDemux need the header
         dataFifo[selector].enq(hdr);
      messageWordsReg <= messageWords - 1;
      if (messageWords == 1)
         state <= MessageHeader;
      else
         state <= MessageBody;
   endrule

   rule receiveMessage if (state == MessageBody);
      let data <- toGet(inputFifo).get();
      if (verbose)
         $display("receiveMessage data=%x messageWords=%d", data, messageWordsReg);
      if (selectorReg != 8'hFF)
         dataFifo[selectorReg].enq(data);
      messageWordsReg <= messageWordsReg - 1;
      if (messageWordsReg == 1)
         state <= MessageHeader;
   endrule

   interface data      = map(toPipeOut, dataFifo);
   interface inputPipe = toPipeIn(inputFifo);
endmodule

module mkSerialPortalMux(SerialPortalMux#(pipeCount));
   let clock <- exposeCurrentClock;
   let reset <- exposeCurrentReset;
   Reg#(Bit#(16)) messageWordsReg <- mkReg(0);
   Reg#(Bit#(16)) readyChannelReg <- mkReg(0);
   Reg#(Bool)     interruptStatusReg <- mkReg(False);
   Reg#(Bool) paddingReg <- mkReg(False);
   Reg#(SerialPortalState) state <- mkReg(Idle);
   Reg#(Bit#(32)) sglIdReg <- mkReg(0);

   function Bool fifoNotEmpty(FIFOF#(a) fifo); return fifo.notEmpty(); endfunction

   Vector#(pipeCount, FIFOF#(Bit#(32)))   inputFifos <- replicateM(mkFIFOF());
   Vector#(pipeCount, PipeOut#(Bit#(32))) pipes      = map(toPipeOut, inputFifos);
   Vector#(pipeCount, Bool)               readyBits  = map(fifoNotEmpty, inputFifos);
   Bool      interruptStatus = False;
   Bit#(16)  readyChannel = -1;
   FIFOF#(Bit#(32)) outputFifo <- mkFIFOF();

   let verbose = True;
   let stateProbe <- mkProbe();
   let messageWordsProbe <- mkProbe();
   let messageDataProbe <- mkProbe();

   for (Integer i = valueOf(pipeCount) - 1; i >= 0; i = i - 1) begin
      if (readyBits[i]) begin
         interruptStatus = True;
         readyChannel = fromInteger(i);
      end
   end

   rule idle if (state == Idle);
      readyChannelReg <= readyChannel;
      interruptStatusReg <= interruptStatus;
      SerialPortalState nextState = Idle;
      if (interruptStatus)
	 nextState = MessageHeader;

      state <= nextState;
      stateProbe <= nextState;
   endrule

   rule sendHeader if (state == MessageHeader && interruptStatusReg);
      Bit#(32) hdr <- toGet(inputFifos[readyChannelReg]).get();
      Bit#(16) totalWords = hdr[15:0];
      let messageWords = totalWords-1;
      messageWordsProbe <= messageWords;

      messageWordsReg <= messageWords;
      outputFifo.enq(hdr);
      state <= MessageBody;
      stateProbe <= MessageBody;
      messageDataProbe <= hdr;
   endrule

   rule sendMessage if (state == MessageBody);
      messageWordsReg <= messageWordsReg - 1;
      let v <- toGet(inputFifos[readyChannelReg]).get();
      outputFifo.enq(v);
      $display("sendMessage v=%h messageWords=%d paddingReg=%d", v, messageWordsReg, paddingReg);
      if (messageWordsReg == 1) begin
         state <= Idle;
	 stateProbe <= Idle;
      end
      messageDataProbe <= v;
   endrule

   interface data       = map(toPipeIn, inputFifos);
   interface outputPipe = toPipeOut(outputFifo);
endmodule
