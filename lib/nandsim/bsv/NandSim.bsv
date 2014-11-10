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

import FIFO::*;
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

interface NandSim#(numeric type numSlaves);
   interface NandSimRequest request;
   interface Vector#(numSlaves,PhysMemSlave#(PhysAddrWidth,64)) memSlaves;
   interface MemReadClient#(64) readClient;
   interface MemWriteClient#(64) writeClient;
endinterface

interface NandSimControl;
   interface NandSimRequest request;   
   interface ReadOnly#(Bit#(32)) nandPtr;
endinterface

module mkNandSim#(NandSimIndication indication) (NandSim#(numSlaves))
   provisos(
      Add#(a__, TLog#(TAdd#(numSlaves, 3)), TAdd#(1, TLog#(TMul#(1,TAdd#(numSlaves, 3)))))
      ,Pipe::FunnelPipesPipelined#(1, TAdd#(numSlaves, 3),Tuple2#(Bit#(TLog#(TAdd#(numSlaves, 3))), MemTypes::MemengineCmd),TMin#(2, TLog#(TAdd#(numSlaves, 3))))
      ,Pipe::FunnelPipesPipelined#(1, TAdd#(numSlaves, 3), Tuple2#(Bit#(64),Bool), TMin#(2, TLog#(TAdd#(numSlaves, 3))))
      ,Add#(b__, TLog#(TAdd#(numSlaves, 3)), TLog#(TMul#(1, TAdd#(numSlaves,3))))
      ,Pipe::FunnelPipesPipelined#(1, TAdd#(numSlaves, 3), Tuple3#(Bit#(2),Bit#(64), Bool), TMin#(2, TLog#(TAdd#(numSlaves, 3))))
      ,Pipe::FunnelPipesPipelined#(1, TAdd#(numSlaves, 3),Tuple3#(Bit#(TLog#(TAdd#(numSlaves, 3))), Bit#(64), Bool), TMin#(2,TLog#(TAdd#(numSlaves, 3))))
      ,Add#(c__, TLog#(TAdd#(numSlaves, 2)), TAdd#(1, TLog#(TMul#(1,TAdd#(numSlaves, 2)))))
      ,Pipe::FunnelPipesPipelined#(1, TAdd#(numSlaves, 2),Tuple2#(Bit#(TLog#(TAdd#(numSlaves, 2))), MemTypes::MemengineCmd),TMin#(2, TLog#(TAdd#(numSlaves, 2))))
      ,Pipe::FunnelPipesPipelined#(1, TAdd#(numSlaves, 2), Tuple2#(Bit#(64),Bool), TMin#(2, TLog#(TAdd#(numSlaves, 2))))
      ,Add#(d__, TLog#(TAdd#(numSlaves, 2)), TLog#(TMul#(1, TAdd#(numSlaves,2))))
      );

   
   let verbose = False;
   
   MemreadEngineV#(64, 1,  TAdd#(numSlaves,2))  re <- mkMemreadEngine();
   MemwriteEngineV#(64, 1, TAdd#(numSlaves,3))  we <- mkMemwriteEngine();
   NandSimControl ns <- mkNandSimControl(take(re.readServers), take(re.dataPipes), take(we.writeServers), take(we.dataPipes), indication);
   
   Vector#(numSlaves,Server#(MemengineCmd,Bool)) slave_read_servers  = takeTail(re.readServers);
   Vector#(numSlaves,PipeOut#(Bit#(64)))         slave_read_pipes    = takeTail(re.dataPipes);
   Vector#(numSlaves,Server#(MemengineCmd,Bool)) slave_write_servers = takeTail(we.writeServers);
   Vector#(numSlaves,PipeIn#(Bit#(64)))          slave_write_pipes   = takeTail(we.dataPipes);
   Vector#(numSlaves,FIFO#(Bit#(MemTagSize)))    slaveWriteTags <- replicateM(mkSizedFIFO(1));
   Vector#(numSlaves,FIFO#(Bit#(MemTagSize)))    slaveReadTags <- replicateM(mkSizedFIFO(1));
   Vector#(numSlaves,Reg#(Bit#(BurstLenSize)))   slaveReadCnts <- replicateM(mkReg(0));
   
   for(Integer i = 0; i < valueOf(numSlaves); i=i+1)
      rule completeSlaveReadReq;
	 slaveReadTags[i].deq;
	 let rv <- slave_read_servers[i].response.get;
	 if (verbose) $display("mkNandSim::completeSlaveReadReq (%d)", i);
      endrule

   function PhysMemSlave#(PhysAddrWidth,64) mms(Integer i);
      return (
   interface PhysMemSlave;
      interface PhysMemWriteServer write_server; 
	 interface Put writeReq;
	    method Action put(PhysMemRequest#(PhysAddrWidth) req);
	       slave_write_servers[i].request.put(MemengineCmd{sglId:ns.nandPtr, base:extend(req.addr), burstLen:req.burstLen, len:extend(req.burstLen)});
	       slaveWriteTags[i].enq(req.tag);
            endmethod
	 endinterface
	 interface Put writeData;
	    method Action put(MemData#(64) wdata);
	       slave_write_pipes[i].enq(wdata.data);
            endmethod
	 endinterface
	 interface Get writeDone;
	    method ActionValue#(Bit#(MemTagSize)) get();
	       let rv <- slave_write_servers[i].response.get;
	       slaveWriteTags[i].deq;
	       return slaveWriteTags[i].first;
            endmethod
	 endinterface
      endinterface
      interface PhysMemReadServer read_server;
	 interface Put readReq;
	    method Action put(PhysMemRequest#(PhysAddrWidth) req);
	       if (verbose) $display("mkNandSim.memSlave::readReq %d %d %d (%d)", req.addr, req.burstLen, req.tag, i);
	       slave_read_servers[i].request.put(MemengineCmd{sglId:ns.nandPtr, base:extend(req.addr), burstLen:req.burstLen, len:extend(req.burstLen)});
	       slaveReadTags[i].enq(req.tag);
	       slaveReadCnts[i] <= req.burstLen;
	    endmethod
	 endinterface
	 interface Get  readData;
	    method ActionValue#(MemData#(64)) get();
	       let rv <- toGet(slave_read_pipes[i]).get;
	       let new_slaveReadCnt = slaveReadCnts[i]-8;
	       let last = new_slaveReadCnt==0;
	       slaveReadCnts[i] <= new_slaveReadCnt;
	       if (verbose) $display("mkNandSim.memSlave::readData %d %d %d %d (%d)", slaveReadTags[i].first, last, rv, slaveReadCnts[i], i);
	       return MemData{data:rv, tag:slaveReadTags[i].first,last:last};
            endmethod
	 endinterface
      endinterface
   endinterface
	      );
   endfunction
   interface memSlaves = map(mms,genVector);
   interface request = ns.request;
   interface MemReadClient readClient = re.dmaClient;
   interface MemWriteClient writeClient = we.dmaClient;
   
endmodule

module mkNandSimControl#(Vector#(2, Server#(MemengineCmd,Bool)) readServers,
			  Vector#(2, PipeOut#(Bit#(64))) readPipes,
			  Vector#(3, Server#(MemengineCmd,Bool)) writeServers,
			  Vector#(3, PipeIn#(Bit#(64))) writePipes,
			  NandSimIndication indication) (NandSimControl);

   Server#(MemengineCmd,Bool)  dramReadServer = readServers[0];
   Server#(MemengineCmd,Bool)  nandReadServer = readServers[1];

   Server#(MemengineCmd,Bool) dramWriteServer = writeServers[0];
   Server#(MemengineCmd,Bool) nandWriteServer = writeServers[1];
   Server#(MemengineCmd,Bool) nandEraseServer = writeServers[2];

   Reg#(Maybe#(Bit#(32)))  nandPointer <- mkReg(tagged Invalid);
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
	 nandReadServer.request.put(MemengineCmd {sglId: fromMaybe(0,nandPointer), base: extend(nandAddr), burstLen: truncate(burstLen), len: extend(numBytes)});
	 dramWriteServer.request.put(MemengineCmd {sglId: pointer, base: extend(dramOffset), burstLen: truncate(burstLen), len: extend(numBytes)});
      endmethod

      /*!
      * Reads from DRAM and writes to NAND
      */
      method Action startWrite(Bit#(32) pointer, Bit#(32) dramOffset, Bit#(32) nandAddr,Bit#(32) numBytes, Bit#(32) burstLen);
	 $display("startWrite numBytes=%d burstLen=%d", numBytes, burstLen);
	 writeReqFifo.enq(numBytes);
	 nandWriteServer.request.put(MemengineCmd {sglId: fromMaybe(0,nandPointer), base: extend(nandAddr), burstLen: truncate(burstLen), len: extend(numBytes)});
	 dramReadServer.request.put(MemengineCmd {sglId: pointer, base: extend(dramOffset), burstLen: truncate(burstLen), len: extend(numBytes)});
      endmethod

      method Action startErase(Bit#(32) nandAddr, Bit#(32) numBytes);
	 $display("startErase numBytes=%d burstLen=%d", numBytes, 16);
	 nandEraseServer.request.put(MemengineCmd {sglId: fromMaybe(0,nandPointer), base: extend(nandAddr), burstLen: 16, len: extend(numBytes)});
      endmethod

      method Action configureNand(Bit#(32) ptr, Bit#(32) numBytes);
	 nandPointer <= tagged Valid ptr;
	 nandLen <= numBytes;
	 indication.configureNandDone();
	 $display("configureNand ptr=%d", ptr);
      endmethod
   endinterface
   interface ReadOnly nandPtr;
      method Bit#(32) _read if (isValid(nandPointer));
	 return fromMaybe(0,nandPointer);
      endmethod
   endinterface
endmodule

