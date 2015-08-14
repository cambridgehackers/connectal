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
import HostInterface::*;
import MemreadEngine::*;
import MemwriteEngine::*;

interface NandCfgRequest;
   method Action startRead(Bit#(32) drampointer, Bit#(32) dramOffset, Bit#(32) nandAddr, Bit#(32) numBytes, Bit#(32) burstLen);
   method Action startWrite(Bit#(32) drampointer, Bit#(32) dramOffset, Bit#(32) nandAddr, Bit#(32) numBytes, Bit#(32) burstLen);
   method Action startErase(Bit#(32) nandAddr, Bit#(32) numBytes);
   method Action configureNand(Bit#(32) ptr, Bit#(32) numBytes);
endinterface

interface NandCfgIndication;
   method Action readDone(Bit#(32) tag);
   method Action writeDone(Bit#(32) tag);
   method Action eraseDone(Bit#(32) tag);
   method Action configureNandDone();
endinterface

interface NandSim;
   interface NandCfgRequest request;
   interface PhysMemSlave#(PhysAddrWidth,64) memSlave;
   interface Vector#(1, MemReadClient#(64)) readClient;
   interface Vector#(1, MemWriteClient#(64)) writeClient;
endinterface

interface NandSimControl;
   interface NandCfgRequest request;
   interface ReadOnly#(Bit#(32)) nandPtr;
endinterface

module mkNandSim#(NandCfgIndication indication) (NandSim);
   let verbose = False;

   MemreadEngine#(64, 1,  3)  re <- mkMemreadEngine();
   MemwriteEngine#(64, 1, 4)  we <- mkMemwriteEngine();
   NandSimControl ns <- mkNandSimControl(take(re.read_servers), take(we.write_servers), indication);

   Server#(MemengineCmd,Bool) slave_read_server  = re.read_servers[2].cmdServer;
   PipeOut#(MemDataF#(64))    slave_read_pipe    = re.read_servers[2].memDataPipe;
   Server#(MemengineCmd,Bool) slave_write_server = we.write_servers[3].cmdServer;
   PipeIn#(Bit#(64))          slave_write_pipe   = we.write_servers[3].dataPipe;
   FIFO#(Bit#(MemTagSize))    slaveWriteTag <- mkSizedFIFO(1);
   FIFO#(Bit#(MemTagSize))    slaveReadTag <- mkSizedFIFO(1);
   Reg#(Bit#(BurstLenSize))   slaveReadCnt <- mkReg(0);

   rule completeSlaveReadReq;
      slaveReadTag.deq;
      let rv <- slave_read_server.response.get;
      if (verbose) $display("mkNandSim::completeSlaveReadReq");
   endrule

   interface PhysMemSlave memSlave;
      interface PhysMemWriteServer write_server;
	 interface Put writeReq;
	    method Action put(PhysMemRequest#(PhysAddrWidth) req);
	       slave_write_server.request.put(MemengineCmd{sglId:ns.nandPtr, base:extend(req.addr), burstLen:req.burstLen, len:extend(req.burstLen), tag: 0});
	       slaveWriteTag.enq(req.tag);
            endmethod
	 endinterface
	 interface Put writeData;
	    method Action put(MemData#(64) wdata);
	       slave_write_pipe.enq(wdata.data);
            endmethod
	 endinterface
	 interface Get writeDone;
	    method ActionValue#(Bit#(MemTagSize)) get();
	       let rv <- slave_write_server.response.get;
	       slaveWriteTag.deq;
	       return slaveWriteTag.first;
            endmethod
	 endinterface
      endinterface
      interface PhysMemReadServer read_server;
	 interface Put readReq;
	    method Action put(PhysMemRequest#(PhysAddrWidth) req);
	       if (verbose) $display("mkNandSim.memSlave::readReq %d %d %d", req.addr, req.burstLen, req.tag);
	       slave_read_server.request.put(MemengineCmd{sglId:ns.nandPtr, base:extend(req.addr), burstLen:req.burstLen, len:extend(req.burstLen), tag: 0});
	       slaveReadTag.enq(req.tag);
	       slaveReadCnt <= req.burstLen;
	    endmethod
	 endinterface
	 interface Get  readData;
	    method ActionValue#(MemData#(64)) get();
	       let rv <- toGet(slave_read_pipe).get;
	       let new_slaveReadCnt = slaveReadCnt-8;
	       let last = new_slaveReadCnt==0;
	       slaveReadCnt <= new_slaveReadCnt;
	       if (verbose) $display("mkNandSim.memSlave::readData %d %d %d %d", slaveReadTag.first, last, rv.data, slaveReadCnt);
	       return MemData{data:rv.data, tag:slaveReadTag.first,last:last};
            endmethod
	 endinterface
      endinterface
   endinterface
   interface request = ns.request;
   interface MemReadClient readClient = cons(re.dmaClient, nil);
   interface MemWriteClient writeClient = cons(we.dmaClient, nil);

endmodule

module mkNandSimControl#(Vector#(2, MemreadServer#(64)) readSrvs, Vector#(3, MemwriteServer#(64)) writeSrvs,
			  NandCfgIndication indication) (NandSimControl);
   let dramReadServer = readSrvs[0];
   let nandReadServer = readSrvs[1];
   let dramWriteServer = writeSrvs[0];
   let nandWriteServer = writeSrvs[1];
   let nandEraseServer = writeSrvs[2];

   Reg#(Maybe#(Bit#(32)))  nandPointer <- mkReg(tagged Invalid);
   Reg#(Bit#(32))  nandLen       <- mkReg(0);

   FIFOF#(Bit#(32))  readReqFifo <- mkFIFOF();
   FIFOF#(Bit#(32)) writeReqFifo <- mkFIFOF();
   Reg#(Bit#(32))   readCountReg <- mkReg(0);
   Reg#(Bit#(32))  writeCountReg <- mkReg(0);
   FIFOF#(Bool)     readDoneFifo <- mkFIFOF();
   FIFOF#(Bool)    writeDoneFifo <- mkFIFOF();

   rule countNandWrite;
      let v <- toGet(readSrvs[0].memDataPipe).get();
      let count = writeCountReg;
      if (count == 0)
	 count = writeReqFifo.first();
      //$display("write v=%h count=%d", v, count);
      writeSrvs[1].dataPipe.enq(v.data);
      if (count == 8) begin
	 writeReqFifo.deq();
	 writeDoneFifo.enq(True);
      end
      writeCountReg <= count-8;
   endrule

   rule countNandRead;
      let v <- toGet(readSrvs[1].memDataPipe).get();
      let count = readCountReg;
      if (count == 0)
	 count = readReqFifo.first();
      //$display("read v=%h count=%d", v, count);
      writeSrvs[0].dataPipe.enq(v.data);
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
   mkConnection(erasePipe, writeSrvs[2].dataPipe);

   rule eraseDone;
      let done <- nandEraseServer.cmdServer.response.get();
      $display("eraseDone");
      indication.eraseDone(0);
   endrule

   rule writeDone;
      let nandWriteDone <- nandWriteServer.cmdServer.response.get();
      let dramReadDone <- dramReadServer.cmdServer.response.get();
      let v <- toGet(writeDoneFifo).get();
      $display("writeDone");
      indication.writeDone(0);
   endrule

   rule readDone;
      let nandReadDone <- nandReadServer.cmdServer.response.get();
      let dramWriteDone <- dramWriteServer.cmdServer.response.get();
      let v <- toGet(readDoneFifo).get();
      $display("readDone");
      indication.readDone(0);
   endrule

   interface NandCfgRequest request;
      /*!
      * Reads from NAND and writes to DRAM
      */
      method Action startRead(Bit#(32) pointer, Bit#(32) dramOffset, Bit#(32) nandAddr,Bit#(32) numBytes, Bit#(32) burstLen);
	 $display("startRead numBytes=%d burstLen=%d", numBytes, burstLen);
	 readReqFifo.enq(numBytes);
	 nandReadServer.cmdServer.request.put(MemengineCmd {sglId: fromMaybe(0,nandPointer), base: extend(nandAddr), burstLen: truncate(burstLen), len: extend(numBytes), tag: 0});
	 dramWriteServer.cmdServer.request.put(MemengineCmd {sglId: pointer, base: extend(dramOffset), burstLen: truncate(burstLen), len: extend(numBytes), tag: 0});
      endmethod

      /*!
      * Reads from DRAM and writes to NAND
      */
      method Action startWrite(Bit#(32) pointer, Bit#(32) dramOffset, Bit#(32) nandAddr,Bit#(32) numBytes, Bit#(32) burstLen);
	 $display("startWrite numBytes=%d burstLen=%d", numBytes, burstLen);
	 writeReqFifo.enq(numBytes);
	 nandWriteServer.cmdServer.request.put(MemengineCmd {sglId: fromMaybe(0,nandPointer), base: extend(nandAddr), burstLen: truncate(burstLen), len: extend(numBytes), tag: 0});
	 dramReadServer.cmdServer.request.put(MemengineCmd {sglId: pointer, base: extend(dramOffset), burstLen: truncate(burstLen), len: extend(numBytes), tag: 0});
      endmethod

      method Action startErase(Bit#(32) nandAddr, Bit#(32) numBytes);
	 $display("startErase numBytes=%d burstLen=%d", numBytes, 16);
	 nandEraseServer.cmdServer.request.put(MemengineCmd {sglId: fromMaybe(0,nandPointer), base: extend(nandAddr), burstLen: 16, len: extend(numBytes), tag: 0});
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

