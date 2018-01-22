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
import BRAMFIFO::*;
import FIFO::*;
import FIFOF::*;
import GetPut::*;
import Vector::*;
import BRAM::*;
import GetPut::*;
import Connectable::*;
import Pipe::*;
import ConnectalMemTypes::*;
import MemReadEngine::*;
import MemWriteEngine::*;
import FlashCtrlModel::*;

interface NandCfgRequest;
   method Action startRead(Bit#(32) drampointer, Bit#(32) dramOffset, Bit#(32) nandAddr, Bit#(32) numBytes, Bit#(32) burstLen);
   method Action startWrite(Bit#(32) drampointer, Bit#(32) dramOffset, Bit#(32) nandAddr, Bit#(32) numBytes, Bit#(32) burstLen);
   method Action startErase(Bit#(32) nandAddr, Bit#(32) numBytes);
endinterface

interface NandCfgIndication;
   method Action readDone(Bit#(32) tag);
   method Action writeDone(Bit#(32) tag);
   method Action eraseDone(Bit#(32) tag);
endinterface

interface NandSimMod#(numeric type numSlaves, numeric type memengineOuts);
   interface NandCfgRequest request;
   interface Vector#(numSlaves,PhysMemSlave#(PhysAddrWidth,64)) memSlaves;
endinterface

interface NandSimControl;
   interface NandCfgRequest request;   
endinterface


module mkNandSimMod#(NandCfgIndication indication,
		     MemReadServer#(64) nand_ctrl_host_rs,
		     MemWriteServer#(64) nand_ctrl_host_ws) (NandSimMod#(numSlaves,memengineOuts))
   provisos(

    Add#(a__, TLog#(TAdd#(numSlaves, 1)), 6)
,    Add#(b__, TLog#(TAdd#(numSlaves, 1)), TLog#(TMul#(4, TAdd#(numSlaves,
    1))))
,    Pipe::FunnelPipesPipelined#(1, TAdd#(numSlaves, 1), Tuple2#(Bit#(64),
    Bool), TMin#(2, TLog#(TAdd#(numSlaves, 1))))
,    Pipe::FunnelPipesPipelined#(1, TAdd#(numSlaves, 1),
    Tuple2#(Bit#(TLog#(TAdd#(numSlaves, 1))), MemTypes::MemengineCmd),
    TMin#(2, TLog#(TAdd#(numSlaves, 1))))
,    Add#(c__, TLog#(TAdd#(numSlaves, 1)), TAdd#(1, TLog#(TMul#(4,
    TAdd#(numSlaves, 1)))))
,    Add#(d__, TLog#(TAdd#(numSlaves, 2)), 6)
,    Pipe::FunnelPipesPipelined#(1, TAdd#(numSlaves, 2),
    Tuple3#(Bit#(TLog#(TAdd#(numSlaves, 2))), Bit#(64), Bool), TMin#(2,
    TLog#(TAdd#(numSlaves, 2))))
,    Pipe::FunnelPipesPipelined#(1, TAdd#(numSlaves, 2), Tuple3#(Bit#(2),
    Bit#(64), Bool), TMin#(2, TLog#(TAdd#(numSlaves, 2))))
,    Add#(e__, TLog#(TAdd#(numSlaves, 2)), TLog#(TMul#(4, TAdd#(numSlaves,
    2))))
,    Pipe::FunnelPipesPipelined#(1, TAdd#(numSlaves, 2), Tuple2#(Bit#(64),
    Bool), TMin#(2, TLog#(TAdd#(numSlaves, 2))))
,    Pipe::FunnelPipesPipelined#(1, TAdd#(numSlaves, 2),
    Tuple2#(Bit#(TLog#(TAdd#(numSlaves, 2))), MemTypes::MemengineCmd),
    TMin#(2, TLog#(TAdd#(numSlaves, 2))))
,    Add#(f__, TLog#(TAdd#(numSlaves, 2)), TAdd#(1, TLog#(TMul#(4,
    TAdd#(numSlaves, 2)))))
,   Add#(g__, TLog#(TAdd#(numSlaves, 1)), TLog#(TMul#(memengineOuts,
						  TAdd#(numSlaves, 1))))
,   Add#(h__, TLog#(TAdd#(numSlaves, 1)), TAdd#(1, TLog#(TMul#(memengineOuts,
							   TAdd#(numSlaves, 1)))))
,   Add#(i__, TLog#(TAdd#(numSlaves, 2)), TLog#(TMul#(memengineOuts,
						  TAdd#(numSlaves, 2))))
,   Add#(j__, TLog#(TAdd#(numSlaves, 2)), TAdd#(1, TLog#(TMul#(memengineOuts,
							   TAdd#(numSlaves, 2)))))
      );
   
   let verbose = False;
   
   MemReadEngine#(64,64,memengineOuts,  TAdd#(numSlaves,1))  re <- mkMemReadEngine();
   MemWriteEngine#(64,64,memengineOuts, TAdd#(numSlaves,2))  we <- mkMemWriteEngine();
   NandSimControl ns <- mkNandSimControl(nand_ctrl_host_rs, re.readServers[0],
	 nand_ctrl_host_ws, we.writeServers[0], we.writeServers[1], indication);
   
   Vector#(numSlaves,MemReadServer#(64)) slave_read_servers  = takeTail(re.readServers);
   Vector#(numSlaves,MemWriteServer#(MemengineCmd,Bool)) slave_write_servers = takeTail(we.writeServers);
   Vector#(numSlaves,FIFO#(Bit#(MemTagSize)))    slaveWriteTags <- replicateM(mkSizedBRAMFIFO(valueOf(memengineOuts)));
   Vector#(numSlaves,FIFO#(Bit#(MemTagSize)))    slaveReadTags <- replicateM(mkSizedBRAMFIFO(valueOf(memengineOuts)));
   Vector#(numSlaves,Reg#(Bit#(BurstLenSize)))   slaveReadCnts <- replicateM(mkReg(0));

   connectToFlashModel(re.dmaClient,we.dmaClient);
   
   function PhysMemSlave#(PhysAddrWidth,64) mms(Integer i);
      return (
   interface PhysMemSlave;
      interface PhysMemWriteServer write_server; 
	 interface Put writeReq;
	    method Action put(PhysMemRequest#(PhysAddrWidth) req);
	       slave_write_servers[i].request.put(MemengineCmd{sglId:0, base:extend(req.addr), burstLen:req.burstLen, len:extend(req.burstLen), tag:req.tag});
	       slaveWriteTags[i].enq(req.tag);
            endmethod
	 endinterface
	 interface Put writeData;
	    method Action put(MemData#(64) wdata);
	       slave_write_servers[i].data.enq(wdata.data);
            endmethod
	 endinterface
	 interface Get writeDone;
	    method ActionValue#(Bit#(MemTagSize)) get();
	       let rv <- slave_write_servers[i].done.get;
	       slaveWriteTags[i].deq;
	       return slaveWriteTags[i].first;
            endmethod
	 endinterface
      endinterface
      interface PhysMemReadServer read_server;
	 interface Put readReq;
	    method Action put(PhysMemRequest#(PhysAddrWidth) req);
	       if (verbose) $display("mkNandSim.memSlave::readReq %d %d %d (%d)", req.addr, req.burstLen, req.tag, i);
	       slave_read_servers[i].request.put(MemengineCmd{sglId:0, base:extend(req.addr), burstLen:req.burstLen, len:extend(req.burstLen), tag:req.tag});
	       slaveReadTags[i].enq(req.tag);
	       slaveReadCnts[i] <= req.burstLen;
	    endmethod
	 endinterface
	 interface Get  readData;
	    method ActionValue#(MemData#(64)) get();
	       let rv <- toGet(slave_read_servers[i].data).get;
	       let new_slaveReadCnt = slaveReadCnts[i]-8;
	       let last = new_slaveReadCnt==0;
	       slaveReadCnts[i] <= new_slaveReadCnt;
	       if (verbose) $display("mkNandSim.memSlave::readData %d %d %d %d (%d)", slaveReadTags[i].first, last, rv.data, slaveReadCnts[i], i);
               if (rv.last)
	          slaveReadTags[i].deq;
	       return MemData{data:rv.data, tag:slaveReadTags[i].first,last:last};
            endmethod
	 endinterface
      endinterface
   endinterface
	      );
   endfunction
   interface memSlaves = map(mms,genVector);
   interface request = ns.request;
endmodule

module mkNandSimControl#(MemReadServer#(64) dram_read_server, MemReadServer#(64) nand_read_server,
    MemWriteServer#(64) dram_write_server, MemWriteServer#(64) nand_write_server,
    MemWriteServer#(64) nand_erase_server, NandCfgIndication indication) (NandSimControl);
   FIFOF#(Bit#(32))  readReqFifo <- mkFIFOF();
   FIFOF#(Bit#(32)) writeReqFifo <- mkFIFOF();
   Reg#(Bit#(32))   readCountReg <- mkReg(0);
   Reg#(Bit#(32))  writeCountReg <- mkReg(0);
   FIFOF#(Bool)     readDoneFifo <- mkFIFOF();
   FIFOF#(Bool)    writeDoneFifo <- mkFIFOF();
   FIFO#(void)     dram_read_done <- mkFIFO;
   FIFO#(void)     nand_read_done <- mkFIFO;

   rule countNandWrite;
      let v <- toGet(dram_read_server.data).get();
      let count = writeCountReg;
      if (count == 0)
	 count = writeReqFifo.first();
      //$display("write v=%h count=%d", v.data, count);
      nand_write_server.data.enq(v.data);
      if (count == 8) begin
	 writeReqFifo.deq();
	 writeDoneFifo.enq(True);
      end
      writeCountReg <= count-8;
      if (v.last)
         dram_read_done.enq(?);
   endrule

   rule countNandRead;
      let v <- toGet(nand_read_server.data).get();
      let count = readCountReg;
      if (count == 0)
	 count = readReqFifo.first();
      //$display("read v=%h count=%d", v.data, count);
      dram_write_server.data.enq(v.data);
      if (count == 8) begin
	 readReqFifo.deq();
	 readDoneFifo.enq(True);
      end
      readCountReg <= count-8;
      if (v.last)
         nand_read_done.enq(?);
   endrule

   PipeOut#(Bit#(64)) erasePipe = (interface PipeOut#(Bit#(64));
				       method Bit#(64) first(); return fromInteger(-1); endmethod
				       method Action deq(); endmethod
				       method Bool notEmpty(); return True; endmethod
				   endinterface);
   rule eraseRule;
      let v <- toGet(nand_erase_server.data).get;
      toPut(erasePipe).put(v.data);
   endrule

   rule eraseDone;
      let done <- nand_erase_server.done.get();
      $display("eraseDone");
      indication.eraseDone(0);
   endrule
   
   rule writeDone;
      let nandWriteDone <-  nand_write_server.done.get();
      dram_read_done.deq;
      let v <- toGet(writeDoneFifo).get();
      $display("writeDone");
      indication.writeDone(0);
   endrule

   rule readDone;
      nand_read_done.deq;
      let dramWriteDone <- dram_write_server.done.get();
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
	  nand_read_server.request.put(MemengineCmd {sglId: 0, base: extend(nandAddr), burstLen: truncate(burstLen), len: extend(numBytes), tag:0});
	 dram_write_server.request.put(MemengineCmd {sglId: pointer, base: extend(dramOffset), burstLen: truncate(burstLen), len: extend(numBytes), tag:0});
      endmethod

      /*!
      * Reads from DRAM and writes to NAND
      */
      method Action startWrite(Bit#(32) pointer, Bit#(32) dramOffset, Bit#(32) nandAddr,Bit#(32) numBytes, Bit#(32) burstLen);
	 $display("startWrite numBytes=%d burstLen=%d", numBytes, burstLen);
	 writeReqFifo.enq(numBytes);
	  nand_write_server.request.put(MemengineCmd {sglId: 0, base: extend(nandAddr), burstLen: truncate(burstLen), len: extend(numBytes), tag:0});
	  dram_read_server.request.put(MemengineCmd {sglId: pointer, base: extend(dramOffset), burstLen: truncate(burstLen), len: extend(numBytes), tag:0});
      endmethod

      method Action startErase(Bit#(32) nandAddr, Bit#(32) numBytes);
	 $display("startErase numBytes=%d burstLen=%d", numBytes, 16);
	 nand_erase_server.request.put(MemengineCmd {sglId: 0, base: extend(nandAddr), burstLen: 16, len: extend(numBytes), tag:0});
      endmethod
   endinterface
endmodule
