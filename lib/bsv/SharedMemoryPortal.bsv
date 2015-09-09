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
   Vector#(2, MemReadEngineServer#(64)) readEngine, Vector#(2, MemWriteEngineServer#(64)) writeEngine)(SharedMemoryPortal#(64));
   SharedMemoryPipeOut#(64,numRequests) pipeOut <- mkSharedMemoryPipeOut(readEngine, writeEngine);
   mapM_(uncurry(mkConnection), zip(pipeOut.data, portal.requests));

   interface SharedMemoryPortalConfig cfg = pipeOut.cfg;
endmodule

module mkSharedMemoryIndicationPortal#(PipePortal#(numRequests, numIndications, 32) portal,
    Vector#(2, MemReadEngineServer#(64)) readEngines, Vector#(2, MemWriteEngineServer#(64)) writeEngines)(SharedMemoryPortal#(64));
   let defaultClock <- exposeCurrentClock;
   let defaultReset <- exposeCurrentReset;
   let readEngine = readEngines[0];
   let writeEngine = writeEngines[0];

   // read the head and tail pointers, if they are different, then read a request
   Reg#(Bit#(16)) limitReg <- mkReg(0);
   Reg#(Bit#(16)) headReg <- mkReg(0);
   Reg#(Bit#(16)) tailReg <- mkReg(0);
   Reg#(Bit#(16)) messageWordsReg <- mkReg(0);
   Reg#(Bit#(16)) methodIdReg <- mkReg(0);
   Reg#(Bool) paddingReg <- mkReg(False);
   Reg#(SharedMemoryPortalState) state <- mkReg(Idle);
   Reg#(Bit#(32)) sglIdReg <- mkReg(0);
   Reg#(Bool)     readyReg   <- mkReg(False);
   Vector#(numIndications, Bool) readyBits = map(pipeOutNotEmpty, portal.indications);
   Bool      interruptStatus = False;
   Bit#(16)  readyChannel = -1;
   function Bool pipeOutNotEmpty(PipeOut#(a) po); return po.notEmpty(); endfunction
   Gearbox#(1,2,Bit#(32)) gb <- mk1toNGearbox(defaultClock, defaultReset, defaultClock, defaultReset);

   let verbose = True;

   for (Integer i = valueOf(numIndications) - 1; i >= 0; i = i - 1) begin
      if (readyBits[i]) begin
         interruptStatus = True;
         readyChannel = fromInteger(i);
      end
   end

   rule updateIndHeadTail if (state == Idle && readyReg);
      readEngine.request.put(
          MemengineCmd {sglId: sglIdReg, base: 0, burstLen: 16, len: 16, tag: 0});
      state <= HeadRequested;
   endrule

   rule receiveIndHeadTail if (state == HeadRequested || state == TailRequested);
      let md <- toGet(readEngine.data).get();
      let data = md.data;
      let w0 = data[31:0];
      let w1 = data[63:32];
      let head = headReg;
      let tail = tailReg;
      if (state == HeadRequested) begin
         limitReg <= truncate(w0);
         headReg <= truncate(w1);
         head = truncate(w1);
         state <= TailRequested;
      end
      else begin
         if (tailReg == 0) begin
            tail = truncate(w0);
            tailReg <= tail;
         end
         //if (tail != headReg)
            state <= SendHeader;
         //else
            //state <= Idle;
      end
      if (verbose)
         $display("receiveIndHeadTail state=%d w0=%x w1=%x head=%d tail=%d limit=%d", state, w0, w1, head, tail, limitReg);
   endrule

   rule send64bits;
      let v = gb.first;
      gb.deq();
      writeEngine.data.enq(pack(v));
   endrule

   rule sendHeader if (state == SendHeader && interruptStatus);
      Bit#(16) messageBits = portal.messageSize.size(readyChannel);
      Bit#(16) roundup = messageBits[4:0] == 0 ? 0 : 1;
      Bit#(16) numWords = (messageBits >> 5) + roundup;
      Bit#(16) totalWords = numWords + 1;
      Bit#(32) hdr = extend(readyChannel) << 16 | extend(numWords + 1);
      if (numWords[0] == 0)
         totalWords = numWords + 2;
      paddingReg <= numWords[0] == 0;
      $display("sendHeader hdr=%h messageBits=%d numWords=%d totalWords=%d paddingReg=%d headReg=%h", hdr, messageBits, numWords, totalWords, paddingReg, headReg);
      headReg <= headReg + totalWords;
      messageWordsReg <= numWords;
      methodIdReg <= readyChannel;
      gb.enq(replicate(hdr));
      writeEngine.request.put( MemengineCmd
          {sglId: sglIdReg, base: extend(headReg) << 2, burstLen: 8, len: extend(totalWords) << 2, tag: 0});
      state <= SendMessage;
   endrule

   rule sendMessage if (state == SendMessage);
      messageWordsReg <= messageWordsReg - 1;
      let v = portal.indications[methodIdReg].first;
      portal.indications[methodIdReg].deq();
      gb.enq(replicate(v));
      $display("sendMessage v=%h messageWords=%d", v, messageWordsReg);
      if (messageWordsReg == 1) begin
         if (paddingReg)
            state <= SendPadding;
         else
            state <= UpdateHead;
      end
   endrule

   rule sendPadding if (state == SendPadding);
      $display("sendPadding");
      gb.enq(replicate(32'hffff0001));
      state <= UpdateHead;
   endrule

   rule updateHead if (state == UpdateHead);
      $display("updateIndHead limit=%d head=%d", limitReg, headReg);
      gb.enq(replicate(extend(limitReg)));
      writeEngine.request.put(
             MemengineCmd {sglId: sglIdReg, base: 0 << 2, burstLen: 8, len: 2 << 2, tag: 0});
      state <= UpdateHead2;
   endrule

   rule updateHead2 if (state == UpdateHead2);
      $display("updateIndHead2");
      gb.enq(replicate(extend(headReg)));
      state <= SendHeader;
   endrule

   rule done;
      let done <- writeEngine.done.get();
   endrule

   interface SharedMemoryPortalConfig cfg;
      method Action setSglId(Bit#(32) id);
         sglIdReg <= id;
         readyReg <= True;
      endmethod
   endinterface
endmodule
