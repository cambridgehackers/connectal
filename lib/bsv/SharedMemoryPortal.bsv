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
import ClientServer::*;
import Gearbox::*;
import MIFO::*;
import Pipe::*;
import Portal::*;
import MemTypes::*;
import ConnectalMemory::*;

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
    MemreadServer#(64) readEngine, MemwriteServer#(64) writeEngine)(SharedMemoryPortal#(64));
   // read the head and tail pointers, if they are different, then read a request
   Reg#(Bit#(32)) limitReg <- mkReg(0);
   Reg#(Bit#(32)) headReg <- mkReg(0);
   Reg#(Bit#(32)) tailReg <- mkReg(0);
   Reg#(Bit#(16)) countReg <- mkReg(0);
   Reg#(Bit#(16)) messageWordsReg <- mkReg(0);
   Reg#(Bit#(16)) methodIdReg <- mkReg(0);
   Reg#(SharedMemoryPortalState) state <- mkReg(Idle);
   Reg#(Bit#(32)) sglIdReg <- mkReg(0);
   Reg#(Bool)     readyReg   <- mkReg(False);
   MIFO#(4,1,4,Bit#(32)) readMifo <- mkMIFO();

   let verbose = False;

   rule updateReqHeadTail if (state == Idle && readyReg);
      readEngine.cmdServer.request.put(
          MemengineCmd {sglId: sglIdReg, base: 0, burstLen: 16, len: 16, tag: 0});
      state <= HeadRequested;
   endrule

   rule receiveReqHeadTail if (state == HeadRequested || state == TailRequested);
      let v <- toGet(readEngine.memDataPipe).get();
      let w0 = v.data[31:0];
      let w1 = v.data[63:32];
      let head = headReg;
      let tail = tailReg;
      if (state == HeadRequested) begin
         limitReg <= w0;
         headReg <= w1;
         head = w1;
         state <= TailRequested;
      end
      else begin
         if (tailReg == 0) begin
            tail = w0;
            tailReg <= tail;
         end
         if (tail != headReg)
            state <= RequestMessage;
         else
            state <= Idle;
      end
      if (verbose)
         $display("receiveReqHeadTail state=%d w0=%x w1=%x head=%d tail=%d limit=%d", state, w0, w1, head, tail, limitReg);
   endrule

   rule requestMessage if (state == RequestMessage);
      Bit#(32) wordCount = headReg - tailReg;
      if ((tailReg & 1) == 1) begin
         $display("WARNING requestMessage: reqTail=%d is odd.", tailReg);
      end
      let tail = tailReg + wordCount;
      if (headReg < tailReg) begin
         $display("requestMessage wrapped: head=%d tail=%d", headReg, tailReg);
         wordCount = limitReg - tailReg;
         tail = 4;
      end
      if (verbose) $display("requestMessage id=%d tail=%h head=%h wordCount=%d", sglIdReg, tailReg, headReg, wordCount);
      tailReg <= tail;
      countReg <= truncate(wordCount);
      readEngine.cmdServer.request.put( MemengineCmd
          {sglId: sglIdReg, base: extend(tailReg << 2), burstLen: 16, len: wordCount << 2, tag: 0});
      state <= MessageHeaderRequested;
   endrule

   rule demuxwords if (readMifo.enqReady());
      let v <- toGet(readEngine.memDataPipe).get();
      Vector#(2,Bit#(32)) dvec = unpack(v.data);
      let enqCount = 2;
      Vector#(4,Bit#(32)) dvec4;
      dvec4[0] = dvec[0];
      dvec4[1] = dvec[1];
      dvec4[2] = 0;
      dvec4[3] = 0;
      readMifo.enq(enqCount, dvec4);
   endrule

   rule receiveMessageHeader if (state == MessageHeaderRequested);
      let vec <- toGet(readMifo).get();
      let hdr = vec[0];
      let methodId = hdr[31:16];
      let messageWords = hdr[15:0];
      methodIdReg <= methodId;
      if (verbose)
         $display("receiveMessageHeader hdr=%x methodId=%x messageWords=%d wordCount=%d", hdr, methodId, messageWords, countReg);
      countReg <= countReg - 1;
      messageWordsReg <= messageWords - 1;
      if (hdr == 0) begin
         if (countReg == 1)
            state <= UpdateTail;
         else
            state <= Drain;
      end
      else if (countReg == 1)
         state <= UpdateTail;
      else if (messageWords == 1)
         state <= MessageHeaderRequested;
      else
         state <= MessageRequested;
   endrule

   rule drain if (state == Drain);
      let vec <- toGet(readMifo).get();
      if (countReg == 1)
         state <= UpdateTail;
      countReg <= countReg - 1;
   endrule

   rule receiveMessage if (state == MessageRequested);
      let vec <- toGet(readMifo).get();
      let data = vec[0];
      if (verbose)
         $display("receiveMessage data=%x messageWords=%d wordCount=%d", data, messageWordsReg, countReg);
      if (methodIdReg != 16'hFFFF)
         portal.requests[methodIdReg].enq(data);
      messageWordsReg <= messageWordsReg - 1;
      countReg <= countReg - 1;
      if (messageWordsReg == 1)
         state <= MessageHeaderRequested;
      else if (countReg <= 1)
         state <= UpdateTail;
   endrule

   rule updateTail if (state == UpdateTail);
      if (verbose)
         $display("updateTail: tail=%d", tailReg);
      // update the tail pointer
      writeEngine.cmdServer.request.put(
          MemengineCmd {sglId: sglIdReg, base: 8, len: 8, burstLen: 8, tag: 0});
      writeEngine.dataPipe.enq(extend(tailReg));
      state <= Waiting;
   endrule

   rule waiting if (state == Waiting);
      let done <- writeEngine.cmdServer.response.get();
      state <= Idle;
   endrule

   rule consumeResponse;
      let response <- readEngine.cmdServer.response.get();
   endrule

   interface SharedMemoryPortalConfig cfg;
      method Action setSglId(Bit#(32) id);
         sglIdReg <= id;
         readyReg <= True;
      endmethod
   endinterface
endmodule

module mkSharedMemoryIndicationPortal#(PipePortal#(numRequests, numIndications, 32) portal,
    MemreadServer#(64) readEngine, MemwriteServer#(64) writeEngine)(SharedMemoryPortal#(64));
   let defaultClock <- exposeCurrentClock;
   let defaultReset <- exposeCurrentReset;
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
      readEngine.cmdServer.request.put(
          MemengineCmd {sglId: sglIdReg, base: 0, burstLen: 16, len: 16, tag: 0});
      state <= HeadRequested;
   endrule

   rule receiveIndHeadTail if (state == HeadRequested || state == TailRequested);
      let data <- toGet(readEngine.dataPipe).get();
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
      writeEngine.dataPipe.enq(pack(v));
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
      writeEngine.cmdServer.request.put( MemengineCmd
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
      writeEngine.cmdServer.request.put(
             MemengineCmd {sglId: sglIdReg, base: 0 << 2, burstLen: 8, len: 2 << 2, tag: 0});
      state <= UpdateHead2;
   endrule

   rule updateHead2 if (state == UpdateHead2);
      $display("updateIndHead2");
      gb.enq(replicate(extend(headReg)));
      state <= SendHeader;
   endrule

   rule done;
      let done <- writeEngine.cmdServer.response.get();
   endrule

   interface SharedMemoryPortalConfig cfg;
      method Action setSglId(Bit#(32) id);
         sglIdReg <= id;
         readyReg <= True;
      endmethod
   endinterface
endmodule
