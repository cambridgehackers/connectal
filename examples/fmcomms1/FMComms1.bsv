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
import ConnectalMemTypes::*;
import MemReadEngine::*;
import MemWriteEngine::*;
import Pipe::*;
import Connectable::*;

interface FMComms1Request;
   method Action startRead(Bit#(32) pointer, Bit#(32) numWords, Bit#(32) burstLen, Bit#(32) run);
   method Action startWrite(Bit#(32) pointer, Bit#(32) numWords, Bit#(32) burstLen, Bit#(32) run);
   method Action getReadStatus();
   method Action getWriteStatus();
endinterface

interface FMComms1;
   interface FMComms1Request request;
   interface MemReadClient#(64) readDmaClient;
   interface MemWriteClient#(64) writeDmaClient;
endinterface

interface FMComms1Indication;
   method Action readStatus(Bit#(32) numIter, Bit#(32) running);
   method Action writeStatus(Bit#(32) numIter, Bit#(32) running);
endinterface

/* This is like a combined memread and memwrite.  
 * The read side is set to repetitively read a buffer, until
 * another portal call is made to startRead with the run bit off.
 * 
 * Writes are the same
 */
module mkFMComms1#(FMComms1Indication indication, PipeIn#(Bit#(64)) dac, PipeOut#(Bit#(64)) adc) (FMComms1);

   Reg#(SGLId)     readPointer <- mkReg(0);
   Reg#(Bit#(32))         readNumWords <- mkReg(0);
   Reg#(Bit#(32))         readIterCount <- mkReg(0);
   Reg#(Bit#(BurstLenSize)) readBurstLen <- mkReg(0);
   Reg#(Bit#(1))          readRun <- mkReg(0);

   MemReadEngine#(64,64,1,1)         re <- mkMemReadEngineBuff(64*16);

   Reg#(SGLId)     writePointer <- mkReg(0);
   Reg#(Bit#(32))         writeNumWords <- mkReg(0);
   Reg#(Bit#(32))         writeIterCount <- mkReg(0);
   Reg#(Bit#(BurstLenSize)) writeBurstLen <- mkReg(0);
   Reg#(Bit#(1))          writeRun <- mkReg(0);
   
   MemWriteEngine#(64,64,1,1)        we <- mkMemWriteEngineBuff(64*16);
   
   mkConnection(adc, we.writeServers[0].data);
   rule readrule;
      let v <- toGet(re.readServers[0].data).get;
      toPut(dac).put(v.data);
      if (v.last && readRun == 0)
	 indication.readStatus(readIterCount, zeroExtend(readRun));
   endrule
   
   rule readStart (readRun == 1);
      readIterCount <= readIterCount + 1;
      re.readServers[0].request.put(MemengineCmd{sglId:readPointer, base:0, len:readNumWords*4, burstLen:readBurstLen*4});
   endrule
   
   rule writeStart (writeRun == 1);
      writeIterCount <= writeIterCount + 1;
      we.writeServers[0].request.put(MemengineCmd{sglId:writePointer, base:0, len:writeNumWords*4, burstLen:writeBurstLen*4});
   endrule
   
   rule writeFinish;
      let rv <- we.writeServers[0].done.get;
      if (writeRun == 0)
	 indication.writeStatus(writeIterCount, zeroExtend(writeRun));
   endrule
   
   interface MemReadClient readDmaClient = re.dmaClient;
   interface ObjectWeadClient writeDmaClient = we.dmaClient;
   interface FMComms1Request request;
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
