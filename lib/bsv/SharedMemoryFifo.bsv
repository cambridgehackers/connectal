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
import BuildVector::*;
import GetPut::*;
import ClientServer::*;
import Gearbox::*;
import DefaultValue::*;
import FIFO::*;
import FIFOF::*;
import MIMO::*;
import Pipe::*;
import Portal::*;
import MemTypes::*;
import ConnectalMemory::*;

interface SharedMemoryPipeOut#(numeric type dataBusWidth, numeric type pipeCount);
   interface SharedMemoryPortalConfig cfg;
   interface Vector#(pipeCount, PipeOut#(Bit#(32))) data;
endinterface
interface SharedMemoryPipeIn#(numeric type dataBusWidth);
   interface SharedMemoryPortalConfig cfg;
   interface PipeIn#(Bit#(32)) data;
endinterface


typedef enum {
   Idle,
   WrPtrRequested, // 1
   RdPtrRequested, // 2
   RequestMessage, // 3
   MessageHeaderRequested, // 4
   MessageRequested, // 5
   Drain,
   UpdateRdPtr,
   UpdateWrPtr,
   UpdateWrPtr2,
   Waiting,
   SendHeader,
   SendMessage,
   SendPadding,
   Stop
   } SharedMemoryPortalState deriving (Bits,Eq);

module mkSharedMemoryRequestPipeOut#(Vector#(2, MemreadServer#(64)) readEngine, Vector#(2, MemwriteServer#(64)) writeEngine)(SharedMemoryPipeOut#(64,pipeCount));
   // read the wrPtr and rdPtr pointers, if they are different, then read a request
   Reg#(Bit#(32)) limitReg <- mkReg(0);
   Reg#(Bit#(32)) wrPtrReg <- mkReg(0);
   Reg#(Bit#(32)) rdPtrReg <- mkReg(0);
   Reg#(Bit#(16)) countReg <- mkReg(0);
   Reg#(Bit#(16)) messageWordsReg <- mkReg(0);
   Reg#(Bit#(16)) methodIdReg <- mkReg(0);
   Reg#(SharedMemoryPortalState) state <- mkReg(Idle);
   Reg#(Bit#(32)) sglIdReg <- mkReg(0);
   Reg#(Bool)     readyReg   <- mkReg(False);
   MIMOConfiguration mimoConfig = defaultValue;
   MIMO#(2,1,2,Bit#(32)) readMimo <- mkMIMO(mimoConfig);
   Vector#(pipeCount, FIFOF#(Bit#(32))) dataFifo <- replicateM(mkFIFOF);

   let verbose = True;

   rule updateReqWrPtrRdPtr if (state == Idle && readyReg);
      if (verbose) $display("updateReqWrPtrRdPtr");
      readEngine[0].request.put(
          MemengineCmd {sglId: sglIdReg, base: 0, burstLen: 16, len: 16, tag: 0});
      state <= WrPtrRequested;
   endrule

   rule receiveReqWrPtrRdPtr if (state == WrPtrRequested || state == RdPtrRequested);
      let v <- toGet(readEngine[0].data).get();
      let w0 = v.data[31:0];
      let w1 = v.data[63:32];
      let wrPtr = wrPtrReg;
      let rdPtr = rdPtrReg;
      let limit = limitReg;
      if (state == WrPtrRequested) begin
	 limit = w0;
         limitReg <= w0;
         wrPtrReg <= w1;
         wrPtr = w1;
         state <= RdPtrRequested;
      end
      else begin
         if (rdPtrReg == 0) begin
            rdPtr = w0;
            rdPtrReg <= rdPtr;
         end
         if (rdPtr != wrPtrReg)
            state <= RequestMessage;
         else
            state <= Idle;
      end
      if (verbose)
         $display("receiveReqWrPtrRdPtr state=%d w0=%x w1=%x wrPtr=%d rdPtr=%d limit=%d", state, w0, w1, wrPtr, rdPtr, limit);
   endrule

   rule requestMessage if (state == RequestMessage);
      Bit#(32) wordCount = wrPtrReg - rdPtrReg;
      if ((rdPtrReg & 1) == 1) begin
         $display("WARNING requestMessage: reqRdPtr=%d is odd.", rdPtrReg);
      end
      let rdPtr = rdPtrReg + wordCount;
      if (wrPtrReg < rdPtrReg) begin
         $display("requestMessage wrapped: wrPtr=%d rdPtr=%d", wrPtrReg, rdPtrReg);
         wordCount = limitReg - rdPtrReg;
         rdPtr = 4;
      end
      if (verbose) $display("requestMessage id=%d rdPtr=%d wrPtr=%d wordCount=%d", sglIdReg, rdPtrReg, wrPtrReg, wordCount);
      rdPtrReg <= rdPtr;
      countReg <= truncate(wordCount);
      readEngine[1].request.put( MemengineCmd
          {sglId: sglIdReg, base: extend(rdPtrReg << 2), burstLen: 16, len: wordCount << 2, tag: 0});
      state <= MessageHeaderRequested;
   endrule

   let enqCount = 2;
   rule demuxwords if (readMimo.enqReadyN(enqCount));
      let v <- toGet(readEngine[1].data).get();
      Vector#(2,Bit#(32)) dvec = unpack(v.data);
      readMimo.enq(enqCount, dvec);
   endrule

   rule receiveMessageHeader if (state == MessageHeaderRequested);
      let vec <- toGet(toPipeOut(readMimo)).get();
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
            state <= UpdateRdPtr;
         else
            state <= Drain;
      end
      else if (countReg == 1)
         state <= UpdateRdPtr;
      else if (messageWords == 1)
         state <= MessageHeaderRequested;
      else
         state <= MessageRequested;
   endrule

   rule drain if (state == Drain);
      let vec <- toGet(readMimo).get();
      if (countReg == 1)
         state <= UpdateRdPtr;
      countReg <= countReg - 1;
   endrule

   rule receiveMessage if (state == MessageRequested);
      let vec <- toGet(toPipeOut(readMimo)).get();
      let data = vec[0];
      if (verbose)
         $display("receiveMessage data=%x messageWords=%d wordCount=%d", data, messageWordsReg, countReg);
      if (methodIdReg != 16'hFFFF)
         dataFifo[methodIdReg].enq(data);
      messageWordsReg <= messageWordsReg - 1;
      countReg <= countReg - 1;
      if (countReg <= 1)
         state <= UpdateRdPtr;
      else if (messageWordsReg == 1)
         state <= MessageHeaderRequested;
   endrule

   rule updateRdPtr if (state == UpdateRdPtr);
      if (verbose)
         $display("updateRdPtr: rdPtr=%d", rdPtrReg);
      // update the rdPtr pointer
      writeEngine[0].request.put(
          MemengineCmd {sglId: sglIdReg, base: 8, len: 8, burstLen: 8, tag: 0});
      writeEngine[0].data.enq(extend(rdPtrReg));
      state <= Waiting;
   endrule

   rule waiting if (state == Waiting);
      let done <- writeEngine[0].done.get();
      state <= Idle;
   endrule

   interface SharedMemoryPortalConfig cfg;
      method Action setSglId(Bit#(32) id);
	 if (verbose) $display("setSglId id=%d", id);
         sglIdReg <= id;
         readyReg <= True;
      endmethod
   endinterface
   interface data = map(toPipeOut, dataFifo);
endmodule

module mkSharedMemoryIndicationPortal#(PipePortal#(numRequests, numIndications, 32) portal,
    Vector#(2,MemReadServer#(64)) readEngine, Vector#(2, MemWriteServer#(64)) writeEngine)(SharedMemoryPortal#(64));
   let defaultClock <- exposeCurrentClock;
   let defaultReset <- exposeCurrentReset;
   // read the wrPtr and rdPtr pointers, if they are different, then read a request
   Reg#(Bit#(16)) limitReg <- mkReg(0);
   Reg#(Bit#(16)) wrPtrReg <- mkReg(0);
   Reg#(Bit#(16)) rdPtrReg <- mkReg(0);
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

   rule updateIndWrPtrRdPtr if (state == Idle && readyReg);
      readEngine[0].request.put(
          MemengineCmd {sglId: sglIdReg, base: 0, burstLen: 16, len: 16, tag: 0});
      state <= WrPtrRequested;
   endrule

   rule receiveIndWrPtrRdPtr if (state == WrPtrRequested || state == RdPtrRequested);
      let md <- toGet(readEngine[0].data).get();
      let data = md.data;
      let w0 = data[31:0];
      let w1 = data[63:32];
      let wrPtr = wrPtrReg;
      let rdPtr = rdPtrReg;
      if (state == WrPtrRequested) begin
         limitReg <= truncate(w0);
         wrPtrReg <= truncate(w1);
         wrPtr = truncate(w1);
         state <= RdPtrRequested;
      end
      else begin
         if (rdPtrReg == 0) begin
            rdPtr = truncate(w0);
            rdPtrReg <= rdPtr;
         end
         //if (rdPtr != wrPtrReg)
            state <= SendHeader;
         //else
            //state <= Idle;
      end
      if (verbose)
         $display("receiveIndWrPtrRdPtr state=%d w0=%x w1=%x wrPtr=%d rdPtr=%d limit=%d", state, w0, w1, wrPtr, rdPtr, limitReg);
   endrule

   rule send64bits;
      let v = gb.first;
      gb.deq();
      writeEngine[0].data.enq(pack(v));
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
      $display("sendHeader hdr=%h messageBits=%d numWords=%d totalWords=%d paddingReg=%d wrPtrReg=%h", hdr, messageBits, numWords, totalWords, paddingReg, wrPtrReg);
      wrPtrReg <= wrPtrReg + totalWords;
      messageWordsReg <= numWords;
      methodIdReg <= readyChannel;
      gb.enq(vec(hdr));
      writeEngine[0].request.put( MemengineCmd
          {sglId: sglIdReg, base: extend(wrPtrReg) << 2, burstLen: 8, len: extend(totalWords) << 2, tag: 0});
      state <= SendMessage;
   endrule

   rule sendMessage if (state == SendMessage);
      messageWordsReg <= messageWordsReg - 1;
      let v = portal.indications[methodIdReg].first;
      portal.indications[methodIdReg].deq();
      gb.enq(vec(v));
      $display("sendMessage v=%h messageWords=%d", v, messageWordsReg);
      if (messageWordsReg == 1) begin
         if (paddingReg)
            state <= SendPadding;
         else
            state <= UpdateWrPtr;
      end
   endrule

   rule sendPadding if (state == SendPadding);
      $display("sendPadding");
      gb.enq(vec(32'hffff0001));
      state <= UpdateWrPtr;
   endrule

   rule updateWrPtr if (state == UpdateWrPtr);
      $display("updateIndWrPtr limit=%d wrPtr=%d", limitReg, wrPtrReg);
      gb.enq(vec(extend(limitReg)));
      writeEngine[0].request.put(
             MemengineCmd {sglId: sglIdReg, base: 0 << 2, burstLen: 8, len: 2 << 2, tag: 0});
      state <= UpdateWrPtr2;
   endrule

   rule updateWrPtr2 if (state == UpdateWrPtr2);
      $display("updateIndWrPtr2");
      gb.enq(vec(extend(wrPtrReg)));
      state <= SendHeader;
   endrule

   rule done;
      let done <- writeEngine[0].done.get();
   endrule
   rule done2;
      let done <- writeEngine[1].done.get();
   endrule

   interface SharedMemoryPortalConfig cfg;
      method Action setSglId(Bit#(32) id);
         sglIdReg <= id;
         readyReg <= True;
      endmethod
   endinterface
endmodule
