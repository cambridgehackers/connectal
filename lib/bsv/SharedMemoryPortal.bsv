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
import FIFO::*;
import FIFOF::*;
import GetPut::*;
import ClientServer::*;
import CtrlMux::*;

import MIFO::*;
import Pipe::*;
import Portal::*;
import MemTypes::*;
import AddressGenerator::*;
import MemTypes::*;
import MemreadEngine::*;
import MemwriteEngine::*;
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
   Waiting,
   Stop
   } SharedMemoryPortalState deriving (Bits,Eq);

module mkSharedMemoryRequestPortal#(PipePortal#(numRequests, numIndications, 32) portal,
				    MemreadServer#(64) readEngine,
				    MemwriteServer#(64) writeEngine,
				    Reg#(Bit#(32)) sglIdReg,
				    Reg#(Bool)     readyReg)(SharedMemoryPortal#(64));
      // read the head and tail pointers, if they are different, then read a request
      Reg#(Bit#(32)) reqLimitReg <- mkReg(0);
      Reg#(Bit#(32)) reqHeadReg <- mkReg(0);
      Reg#(Bit#(32)) reqTailReg <- mkReg(0);
      Reg#(Bit#(16)) wordCountReg <- mkReg(0);
      Reg#(Bit#(16)) messageWordsReg <- mkReg(0);
      Reg#(Bit#(16)) methodIdReg <- mkReg(0);
      Reg#(SharedMemoryPortalState) reqState <- mkReg(Idle);

   let verbose = False;

      rule updateReqHeadTail if (reqState == Idle && readyReg);
	 readEngine.cmdServer.request.put(MemengineCmd { sglId: sglIdReg,
							base: 0,
							burstLen: 16,
							len: 16
							});
	 reqState <= HeadRequested;
      endrule

      rule receiveReqHeadTail if (reqState == HeadRequested || reqState == TailRequested);
	 let data <- toGet(readEngine.dataPipe).get();
	 let w0 = data[31:0];
	 let w1 = data[63:32];
	 let head = reqHeadReg;
	 let tail = reqTailReg;
	 if (reqState == HeadRequested) begin
	    reqLimitReg <= w0;
	    reqHeadReg <= w1;
	    head = w1;
	    reqState <= TailRequested;
	 end
	 else begin
	    if (reqTailReg == 0) begin
	       tail = w0;
	       reqTailReg <= tail;
	    end
	    if (tail != reqHeadReg)
	       reqState <= RequestMessage;
	    else
	       reqState <= Idle;
	 end
	 if (verbose)
	    $display("receiveReqHeadTail state=%d w0=%x w1=%x head=%d tail=%d limit=%d", reqState, w0, w1, head, tail, reqLimitReg);
      endrule

      rule requestMessage if (reqState == RequestMessage);
	 Bit#(32) wordCount = reqHeadReg - reqTailReg;
	 if ((reqTailReg & 1) == 1) begin
	    $display("WARNING requestMessage: reqTail=%d is odd.", reqTailReg);
	 end
	 let tail = reqTailReg + wordCount;
	 if (reqHeadReg < reqTailReg) begin
	    $display("requestMessage wrapped: head=%d tail=%d", reqHeadReg, reqTailReg);
	    wordCount = reqLimitReg - reqTailReg;
	    tail = 4;
	 end
	 if (verbose) $display("requestMessage id=%d tail=%h head=%h wordCount=%d", sglIdReg, reqTailReg, reqHeadReg, wordCount);

	 reqTailReg <= tail;
	 wordCountReg <= truncate(wordCount);
	 readEngine.cmdServer.request.put(MemengineCmd {sglId: sglIdReg,
							base: extend(reqTailReg << 2),
							burstLen: 16,
							len: wordCount << 2
							});
	 reqState <= MessageHeaderRequested;
      endrule

      MIFO#(4,1,4,Bit#(32)) readMifo <- mkMIFO();
      rule demuxwords if (readMifo.enqReady());
	 let data <- toGet(readEngine.dataPipe).get();
	 Vector#(2,Bit#(32)) dvec = unpack(data);
	 let enqCount = 2;
	 Vector#(4,Bit#(32)) dvec4;
	 dvec4[0] = dvec[0];
	 dvec4[1] = dvec[1];
	 dvec4[2] = 0;
	 dvec4[3] = 0;
	 readMifo.enq(enqCount, dvec4);
      endrule

      rule receiveMessageHeader if (reqState == MessageHeaderRequested);
	 let vec <- toGet(readMifo).get();
	 let hdr = vec[0];
	 let methodId = hdr[31:16];
	 let messageWords = hdr[15:0];
	 methodIdReg <= methodId;
	 if (verbose)
	    $display("receiveMessageHeader hdr=%x methodId=%x messageWords=%d wordCount=%d", hdr, methodId, messageWords, wordCountReg);
	 wordCountReg <= wordCountReg - 1;
	 messageWordsReg <= messageWords - 1;
	 if (hdr == 0) begin
	    if (wordCountReg == 1)
	       reqState <= UpdateTail;
	    else
	       reqState <= Drain;
	 end
	 else if (wordCountReg <= messageWords)
	    reqState <= UpdateTail;
	 else if (messageWords == 1)
	    reqState <= MessageHeaderRequested;
	 else
	    reqState <= MessageRequested;
      endrule

      rule drain if (reqState == Drain);
	 let vec <- toGet(readMifo).get();
	 if (wordCountReg == 1)
	    reqState <= UpdateTail;
	 wordCountReg <= wordCountReg - 1;
      endrule

      rule receiveMessage if (reqState == MessageRequested);
	 let vec <- toGet(readMifo).get();
	 let data = vec[0];
	 if (verbose)
	    $display("receiveMessage data=%x messageWords=%d wordCount=%d", data, messageWordsReg, wordCountReg);
	 if (methodIdReg != 16'hFFFF)
	    portal.requests[methodIdReg].enq(data);

	 messageWordsReg <= messageWordsReg - 1;
	 wordCountReg <= wordCountReg - 1;
	 if (messageWordsReg == 1)
	    reqState <= MessageHeaderRequested;
	 else if (wordCountReg <= 1)
	    reqState <= UpdateTail;
      endrule

      rule updateTail if (reqState == UpdateTail);
	 if (verbose)
	    $display("updateTail: tail=%d", reqTailReg);
	 // update the tail pointer
	 writeEngine.cmdServer.request.put(MemengineCmd {sglId: sglIdReg,
							 base: 8,
							 len: 8,
							 burstLen: 8
							 });
	 writeEngine.dataPipe.enq(extend(reqTailReg));
	 reqState <= Waiting;
      endrule
      rule waiting if (reqState == Waiting);
	 let done <- writeEngine.cmdServer.response.get();
	 reqState <= Idle;
      endrule

      rule consumeResponse;
	 let response <- readEngine.cmdServer.response.get();
      endrule
endmodule

module mkSharedMemoryIndicationPortal#(PipePortal#(numRequests, numIndications, 32) portal,
				    MemreadServer#(64) readEngine,
				    MemwriteServer#(64) writeEngine,
				    Reg#(Bit#(32)) sglIdReg,
				    Reg#(Bool)     readyReg)(SharedMemoryPortal#(64));
      // read the head and tail pointers, if they are different, then read a request
      Reg#(Bit#(32)) indLimitReg <- mkReg(0);
      Reg#(Bit#(32)) indHeadReg <- mkReg(0);
      Reg#(Bit#(32)) indTailReg <- mkReg(0);
      Reg#(Bit#(16)) wordCountReg <- mkReg(0);
      Reg#(Bit#(16)) messageWordsReg <- mkReg(0);
      Reg#(Bit#(16)) methodIdReg <- mkReg(0);
      Reg#(SharedMemoryPortalState) indState <- mkReg(Idle);

   let verbose = True;

      rule updateIndHeadTail if (indState == Idle && readyReg);
	 readEngine.cmdServer.request.put(MemengineCmd { sglId: sglIdReg,
							base: 0,
							burstLen: 16,
							len: 16
							});
	 indState <= HeadRequested;
      endrule

      rule receiveIndHeadTail if (indState == HeadRequested || indState == TailRequested);
	 let data <- toGet(readEngine.dataPipe).get();
	 let w0 = data[31:0];
	 let w1 = data[63:32];
	 let head = indHeadReg;
	 let tail = indTailReg;
	 if (indState == HeadRequested) begin
	    indLimitReg <= w0;
	    indHeadReg <= w1;
	    head = w1;
	    indState <= TailRequested;
	 end
	 else begin
	    if (indTailReg == 0) begin
	       tail = w0;
	       indTailReg <= tail;
	    end
	    if (tail != indHeadReg)
	       indState <= RequestMessage;
	    else
	       indState <= Idle;
	 end
	 if (verbose)
	    $display("receiveIndHeadTail state=%d w0=%x w1=%x head=%d tail=%d limit=%d", indState, w0, w1, head, tail, indLimitReg);
      endrule
endmodule

module mkSharedMemoryPortal#(PipePortal#(numRequests, numIndications, 32) portal)(SharedMemoryPortal#(64));

   MemreadEngineV#(64,2,1) readEngine <- mkMemreadEngine();
   MemwriteEngineV#(64,2,1) writeEngine <- mkMemwriteEngine();

   Bool verbose = False;

   Reg#(Bit#(32)) sglIdReg <- mkReg(0);
   Reg#(Bool)     readyReg   <- mkReg(False);

   if (valueOf(numRequests) > 0) begin
      let readPortal <- mkSharedMemoryRequestPortal(portal, readEngine.read_servers[0], writeEngine.write_servers[0], sglIdReg, readyReg);
   end
   else if (valueOf(numIndications) > 0) begin
      let writePortal <- mkSharedMemoryIndicationPortal(portal, readEngine.read_servers[0], writeEngine.write_servers[0], sglIdReg, readyReg);
   end
   interface SharedMemoryPortalConfig cfg;
      method Action setSglId(Bit#(32) id);
	 sglIdReg <= id;
	 readyReg <= True;
      endmethod
   endinterface
   interface MemReadClient  readClient = readEngine.dmaClient;
   interface MemWriteClient writeClient = writeEngine.dmaClient;
   interface ReadOnly interrupt;
   endinterface
endmodule
