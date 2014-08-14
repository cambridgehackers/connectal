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

interface NandSim#(numeric type i);
   interface Vector#(i,NandSimRequest) requests;
   interface ObjectReadClient#(64) readClient;
   interface ObjectWriteClient#(64) writeClient;
endinterface

interface NandSimInternal;
   interface NandSimRequest request;   
endinterface

module mkNandSim#(Vector#(i,NandSimIndication) indications) (NandSim#(i))
   provisos( Add#(1, a__, TMul#(i, 3))
	    ,Add#(b__, TLog#(TMul#(i, 3)), TAdd#(1, TLog#(TMul#(1, TMul#(i, 3)))))
	    ,FunnelPipesPipelined#(1, TMul#(i, 3), Tuple2#(Bit#(TLog#(TMul#(i,3))), MemengineCmd), TMin#(2, TLog#(TMul#(i, 3))))
	    ,FunnelPipesPipelined#(1, TMul#(i, 3), Tuple2#(Bit#(64), Bool),TMin#(2, TLog#(TMul#(i, 3))))
	    ,Add#(c__, TLog#(TMul#(i, 3)), TLog#(TMul#(1, TMul#(i, 3))))
	    ,FunnelPipesPipelined#(1, TMul#(i, 3), Tuple3#(Bit#(2), Bit#(64),Bool), TMin#(2, TLog#(TMul#(i, 3))))
	    ,FunnelPipesPipelined#(1, TMul#(i, 3), Tuple3#(Bit#(TLog#(TMul#(i,3))), Bit#(64), Bool), TMin#(2, TLog#(TMul#(i, 3))))
	    ,Add#(1, d__, TMul#(i, 2))
	    ,Add#(e__, TLog#(TMul#(i, 2)), TAdd#(1, TLog#(TMul#(1, TMul#(i, 2)))))
	    ,FunnelPipesPipelined#(1, TMul#(i, 2), Tuple2#(Bit#(TLog#(TMul#(i,2))), MemengineCmd), TMin#(2, TLog#(TMul#(i, 2))))
	    ,FunnelPipesPipelined#(1, TMul#(i, 2), Tuple2#(Bit#(64), Bool),TMin#(2, TLog#(TMul#(i, 2))))
	    ,Add#(f__, TLog#(TMul#(i, 2)), TLog#(TMul#(1, TMul#(i, 2))))
	    ,Add#(3, g__, TMul#(i, 3))
	    ,Add#(2, h__, TMul#(i, 2))
	    );

   MemreadEngineV#(64, 1, TMul#(i,2))   re <- mkMemreadEngine();
   MemwriteEngineV#(64, 1, TMul#(i,3))  we <- mkMemwriteEngine();
   
   Vector#(i, NandSimInternal) nss;
   Vector#(i, NandSimRequest)  nsr;
   for(Integer j = 0; j < valueOf(i); j=j+1) begin
      nss[j] <- mkNandSimInternal(takeAt(j*2,re.readServers), takeAt(j*2,re.dataPipes), takeAt(j*3,we.writeServers), takeAt(j*3,we.dataPipes), indications[j]);
      nsr[j] = nss[j].request;
   end
      
   interface requests = nsr;
   interface ObjectReadClient readClient = re.dmaClient;
   interface ObjectWriteClient writeClient = we.dmaClient;
   
endmodule

module mkNandSimInternal#(Vector#(2, Server#(MemengineCmd,Bool)) readServers,
			  Vector#(2, PipeOut#(Bit#(64))) readPipes,
			  Vector#(3, Server#(MemengineCmd,Bool)) writeServers,
			  Vector#(3, PipeIn#(Bit#(64))) writePipes,
			  NandSimIndication indication) (NandSimInternal);

   Server#(MemengineCmd,Bool)  dramReadServer = readServers[0];
   Server#(MemengineCmd,Bool)  nandReadServer = readServers[1];

   Server#(MemengineCmd,Bool) dramWriteServer = writeServers[0];
   Server#(MemengineCmd,Bool) nandWriteServer = writeServers[1];
   Server#(MemengineCmd,Bool) nandEraseServer = writeServers[2];

   Reg#(Bit#(32))  nandPointer   <- mkReg(0);
   Reg#(Bit#(32))  nandLen       <- mkReg(0);

   FIFOF#(Bit#(32))  readReqFifo <- mkFIFOF();
   FIFOF#(Bit#(32)) writeReqFifo <- mkFIFOF();
   Reg#(Bit#(32))   readCountReg <- mkReg(0);
   Reg#(Bit#(32))  writeCountReg <- mkReg(0);
   FIFOF#(Bool)     readDoneFifo <- mkFIFOF();
   FIFOF#(Bool)    writeDoneFifo <- mkFIFOF();
   rule countNandWrite;
      let v <- toGet(readPipes[0]).get();

      let count = writeCountReg;
      if (count == 0)
	 count = writeReqFifo.first();

      //$display("write v=%h count=%d", v, count);
      writePipes[1].enq(v);

      if (count == 8) begin
	 writeReqFifo.deq();
	 writeDoneFifo.enq(True);
      end
      writeCountReg <= count-8;
   endrule
   rule countNandRead;
      let v <- toGet(readPipes[1]).get();

      let count = readCountReg;
      if (count == 0)
	 count = readReqFifo.first();

      //$display("read v=%h count=%d", v, count);
      writePipes[0].enq(v);

      if (count == 8) begin
	 readReqFifo.deq();
	 readDoneFifo.enq(True);
      end
      readCountReg <= count-8;
   endrule

   PipeOut#(Bit#(64)) erasePipe = (interface PipeOut#(Bit#(64));
				       method Bit#(64) first(); return fromInteger(-1); endmethod
				       method Action deq(); endmethod
				       method Bool notEmpty(); return True; endmethod
				   endinterface);
   mkConnection(erasePipe, writePipes[2]);

   rule eraseDone;
      let done <- nandEraseServer.response.get();
      $display("eraseDone");
      indication.eraseDone(0);
   endrule
   
   rule writeDone;
      let nandWriteDone <- nandWriteServer.response.get();
      let dramReadDone <- dramReadServer.response.get();
      let v <- toGet(writeDoneFifo).get();
      $display("writeDone");
      indication.writeDone(0);
   endrule

   rule readDone;
      let nandReadDone <- nandReadServer.response.get();
      let dramWriteDone <- dramWriteServer.response.get();
      let v <- toGet(readDoneFifo).get();
      $display("readDone");
      indication.readDone(0);
   endrule
   
   interface NandSimRequest request;
      /*!
      * Reads from NAND and writes to DRAM
      */
      method Action startRead(Bit#(32) pointer, Bit#(32) dramOffset, Bit#(32) nandAddr,Bit#(32) numBytes, Bit#(32) burstLen);
	 $display("startRead numBytes=%d burstLen=%d", numBytes, burstLen);
	 readReqFifo.enq(numBytes);
	 nandReadServer.request.put(MemengineCmd {pointer: nandPointer, base: extend(nandAddr), burstLen: truncate(burstLen), len: extend(numBytes)});
	 dramWriteServer.request.put(MemengineCmd {pointer: pointer, base: extend(dramOffset), burstLen: truncate(burstLen), len: extend(numBytes)});
      endmethod

      /*!
      * Reads from DRAM and writes to NAND
      */
      method Action startWrite(Bit#(32) pointer, Bit#(32) dramOffset, Bit#(32) nandAddr,Bit#(32) numBytes, Bit#(32) burstLen);
	 $display("startWrite numBytes=%d burstLen=%d", numBytes, burstLen);
	 writeReqFifo.enq(numBytes);
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

endmodule


