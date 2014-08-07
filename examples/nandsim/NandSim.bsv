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

import FIFOF::*;
import GetPut::*;
import Vector::*;
import BRAM::*;
import GetPut::*;
import Connectable::*;
import Pipe::*;
import MemTypes::*;
import MemreadEngine::*;
import MemwriteEngine::*;

interface NandSimRequest;
   method Action startRead(Bit#(32) drampointer, Bit#(32) dramOffset, Bit#(32) nandAddr, Bit#(32) numBytes, Bit#(32) burstLen);
   method Action startWrite(Bit#(32) drampointer, Bit#(32) dramOffset, Bit#(32) nandAddr, Bit#(32) numBytes, Bit#(32) burstLen);
   method Action startErase(Bit#(32) nandAddr, Bit#(32) numBytes);
   method Action configureNand(Bit#(32) ptr, Bit#(32) numBytes);
endinterface

interface NandSimIndication;
   method Action readDone(Bit#(32) tag);
   method Action writeDone(Bit#(32) tag);
   method Action eraseDone(Bit#(32) tag);
   method Action configureNandDone();
endinterface

interface NandSim;
   interface NandSimRequest request;
   interface ObjectReadClient#(64) readClient;
   interface ObjectWriteClient#(64) writeClient;
endinterface

module mkNandSim#(NandSimIndication indication) (NandSim);

   MemreadEngineV#(64, 1, 2)     re <- mkMemreadEngine();
   MemwriteEngineV#(64, 1, 3)    we <- mkMemwriteEngine();
   
   Server#(MemengineCmd,Bool)  dramReadServer = re.readServers[0];
   Server#(MemengineCmd,Bool)  nandReadServer = re.readServers[1];

   Server#(MemengineCmd,Bool) dramWriteServer = we.writeServers[0];
   Server#(MemengineCmd,Bool) nandWriteServer = we.writeServers[1];
   Server#(MemengineCmd,Bool) nandEraseServer = we.writeServers[2];

   Reg#(Bit#(32))  nandPointer   <- mkReg(0);
   Reg#(Bit#(32))  nandLen       <- mkReg(0);

   Reg#(Bit#(32)) nandWriteCount <- mkReg(0);
   // rule traceNandWrite;
   //    let v <- toGet(re.dataPipes[0]).get();
   //    $display("count=%d v=%h", nandWriteCount, v);
   //    we.dataPipes[1].enq(v);
   //    nandWriteCount <= nandWriteCount + 8;
   // endrule
   mkConnection(re.dataPipes[0], we.dataPipes[1]);
   mkConnection(re.dataPipes[1], we.dataPipes[0]);

   PipeOut#(Bit#(64)) erasePipe = (interface PipeOut#(Bit#(64));
				       method Bit#(64) first(); return fromInteger(-1); endmethod
				       method Action deq(); endmethod
				       method Bool notEmpty(); return True; endmethod
				   endinterface);
   mkConnection(erasePipe, we.dataPipes[2]);

   rule eraseDone;
      let done <- nandEraseServer.response.get();
      $display("eraseDone");
      indication.eraseDone(0);
   endrule
   
   rule writeDone;
      let nandWriteDone <- nandWriteServer.response.get();
      let dramReadDone <- dramReadServer.response.get();
      $display("writeDone");
      indication.writeDone(0);
   endrule

   rule readDone;
      let nandReadDone <- nandReadServer.response.get();
      let dramWriteDone <- dramWriteServer.response.get();
      $display("readDone");
      indication.readDone(0);
   endrule
   
   interface NandSimRequest request;
      /*!
      * Reads from NAND and writes to DRAM
      */
      method Action startRead(Bit#(32) pointer, Bit#(32) dramOffset, Bit#(32) nandAddr,Bit#(32) numBytes, Bit#(32) burstLen);
	 $display("startRead numBytes=%d burstLen=%d", numBytes, burstLen);
	 nandReadServer.request.put(MemengineCmd {pointer: nandPointer, base: extend(nandAddr), burstLen: truncate(burstLen), len: extend(numBytes)});
	 dramWriteServer.request.put(MemengineCmd {pointer: pointer, base: extend(dramOffset), burstLen: truncate(burstLen), len: extend(numBytes)});
      endmethod

      /*!
      * Reads from DRAM and writes to NAND
      */
      method Action startWrite(Bit#(32) pointer, Bit#(32) dramOffset, Bit#(32) nandAddr,Bit#(32) numBytes, Bit#(32) burstLen);
	 nandWriteCount <= 0;
	 $display("startWrite numBytes=%d burstLen=%d", numBytes, burstLen);
	 nandWriteServer.request.put(MemengineCmd {pointer: nandPointer, base: extend(nandAddr), burstLen: truncate(burstLen), len: extend(numBytes)});
	 dramReadServer.request.put(MemengineCmd {pointer: pointer, base: extend(dramOffset), burstLen: truncate(burstLen), len: extend(numBytes)});
      endmethod

      method Action startErase(Bit#(32) nandAddr, Bit#(32) numBytes);
	 $display("startErase numBytes=%d burstLen=%d", numBytes, 16);
	 nandEraseServer.request.put(MemengineCmd {pointer: nandPointer, base: extend(nandAddr), burstLen: 16, len: extend(numBytes)});
      endmethod

      method Action configureNand(Bit#(32) ptr, Bit#(32) numBytes);
	 nandPointer <= ptr;
	 nandLen <= numBytes;
	 indication.configureNandDone();
	 $display("configureNand ptr=%d", ptr);
      endmethod

   endinterface

   interface ObjectReadClient readClient = re.dmaClient;
   interface ObjectWriteClient writeClient = we.dmaClient;

endmodule
