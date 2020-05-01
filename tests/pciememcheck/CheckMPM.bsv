
import BRAM         :: *;
import Connectable  :: *;
import DefaultValue :: *;
import FIFO         :: *;
import GetPut       :: *;
import PCIE         :: *;
import StmtFSM      :: *;
import Vector       :: *;

import BlueCheck         :: *;
import ConnectalMemTypes :: *;
import PcieToMem         :: *;
import PcieTracer        :: *;
import PhysMemSlaveFromBram :: *;
import MemToPcie         :: *;

module mkRefMem(PhysMemSlave#(32, 32));
   BRAM_Configure cfg = defaultValue;
   cfg.memorySize = 32*1024;
   BRAM1Port#(Bit#(32), Bit#(32)) bramPort <- mkBRAM1Server(cfg);
   BRAMServer#(Bit#(32), Bit#(32)) br = bramPort.portA;
   PhysMemSlave#(32, 32) bramPhysMem <- mkPhysMemSlaveFromBram(br);
   return bramPhysMem;
endmodule

module mkMemToPcieToMem(PhysMemSlave#(40, 32));
   PciId my_id = defaultValue;
   MemToPcie#(32) memToPcie <- mkMemToPcie(my_id);
   PcieToMem pcieToMem <- mkPcieToMem(my_id);
   BRAM_Configure cfg = defaultValue;
   cfg.memorySize = 32*1024;
   BRAM1Port#(Bit#(32), Bit#(32)) bramPort <- mkBRAM1Server(cfg);
   BRAMServer#(Bit#(32), Bit#(32)) br = bramPort.portA;
   PhysMemSlave#(32, 32) bramPhysMem <- mkPhysMemSlaveFromBram(br);
   //mkConnection(memToPcie.tlp.request, pcieToMem.tlp.response);
   //mkConnection(memToPcie.tlp.response, pcieToMem.tlp.request);
   //mkConnection(pcieToMem.master, bramPhysMem);

   let fhandle <- mkReg(InvalidFile);
   let didOnce <- mkReg(False);
   rule once if (!didOnce);
      //let mcd <- $fopen("pcielog.txt", "w");
      //fhandle <= mcd;
      didOnce <= True;
   endrule

   Reg#(Bit#(32)) cycles <- mkReg(0);
   rule rl_cycles;
      cycles <= cycles + 1;
   endrule
   rule rl_to_bram;
      let tlp <- memToPcie.tlp.request.get();
      pcieToMem.tlp.response.put(tlp);
      TimestampedTlpData ttd = TimestampedTlpData { tlp: tlp, source: 4, timestamp: cycles };
      //$fwriteh(fhandle, ttd);
      $display("tracetb %h", ttd);
   endrule
   rule rl_from_bram;
      let tlp <- pcieToMem.tlp.request.get();
      memToPcie.tlp.response.put(tlp);
      TimestampedTlpData ttd = TimestampedTlpData { tlp: tlp, source: 8, timestamp: cycles };
      //$fwriteh(fhandle, ttd);
      $display("tracefb %h", ttd);
   endrule

   rule rl_rd_addr;
      let req <- pcieToMem.master.read_client.readReq.get();
      bramPhysMem.read_server.readReq.put(req);
      $display("impl read %x tag %x", req.addr[5:2], req.tag);
   endrule
   rule rl_wr_addr;
      let req <- pcieToMem.master.write_client.writeReq.get();
      bramPhysMem.write_server.writeReq.put(req);
      $display("impl write %x tag %x", req.addr[5:2], req.tag);
   endrule
   rule rl_rd_data;
      let md <- bramPhysMem.read_server.readData.get();
      pcieToMem.master.read_client.readData.put(md);
      $display("impl read data %x tag %x", md.data, md.tag);
   endrule
   rule rl_wr_data;
      let md <- pcieToMem.master.write_client.writeData.get();
      bramPhysMem.write_server.writeData.put(md);
      $display("impl write data %x tag %x", md.data, md.tag);
   endrule
   rule rl_wr_done;
      let tag <- bramPhysMem.write_server.writeDone.get();
      pcieToMem.master.write_client.writeDone.put(tag);
      $display("impl write done tag %x", tag);
   endrule
   return memToPcie.slave;
endmodule

typedef struct {
   Bool write;
   Bit#(12) address;
   Bit#(32) data;
   Bit#(MemTagSize) tag;
   } Req deriving (Bits, Eq, FShow);

module [BlueCheck] checkMPM(Empty);
   let verbose = True;
   PhysMemSlave#(32, 32) refmem  <- mkRefMem();
   PhysMemSlave#(40, 32) pciemem <- mkMemToPcieToMem();
   FIFO#(Bool) isWriteFifo <- mkSizedFIFO(128);
   FIFO#(Bit#(4)) doneFifo <- mkSizedFIFO(128);
   FIFO#(Bit#(4)) addrFifo <- mkSizedFIFO(128);
   Vector#(16, FIFO#(Bool)) scoreboard <- replicateM(mkFIFO1);
   Vector#(16, FIFO#(Bool)) tagscoreboard <- replicateM(mkFIFO1);

   let writeDataFifo <- mkSizedFIFO(128);
   rule rl_write_data;
      let writeData <- toGet(writeDataFifo).get();
      refmem.write_server.writeData.put(writeData);
      pciemem.write_server.writeData.put(writeData);
      if (verbose) $display("rl_write_data %h tag %h", writeData.data, writeData.tag);
   endrule

   rule rl_write_done;
      let address <- toGet(doneFifo).get();
      let reftag <- refmem.write_server.writeDone.get();
      let pcietag <- pciemem.write_server.writeDone.get();
      scoreboard[address].deq();
      tagscoreboard[reftag].deq();
      if (verbose) $display("reftag %x", reftag);
   endrule

   function Action sendPhysMemReq(Bool write, Bit#(4) address, Bit#(32) data, Bit#(4) tag);
      return (action
	 PhysMemRequest#(32, 32) refreq = PhysMemRequest { addr: zeroExtend(address) << 2, burstLen: 4, tag: zeroExtend(tag) };
	 PhysMemRequest#(40, 32) pciereq = PhysMemRequest { addr: zeroExtend(address) << 2, burstLen: 4, tag: zeroExtend(tag) };

	 $display((write ? "write " : "read "), address, " data ", data, " tag ", tag);

         isWriteFifo.enq(write);

	scoreboard[address].enq(True);
	tagscoreboard[tag].enq(True);
	if (write) begin
	   MemData#(32) writeData = MemData {data: data, tag: zeroExtend(tag), last: True };
	   refmem.write_server.writeReq.put(refreq);
	   pciemem.write_server.writeReq.put(pciereq);
	   writeDataFifo.enq(writeData);
	   doneFifo.enq(address);
	end
	else begin
	   refmem.read_server.readReq.put(refreq);
	   pciemem.read_server.readReq.put(pciereq);
           addrFifo.enq(address);
	end
   endaction);
   endfunction

   ActionValue#(Bool) checkPhysMemResp = (actionvalue
      let isWrite <- toGet(isWriteFifo).get();
      if (isWrite) begin
         return True;
      end
      else begin
         let address <- toGet(addrFifo).get();
         let refresp <- refmem.read_server.readData.get();
         let pcieresp <- pciemem.read_server.readData.get();
         if (verbose) $display("refresp ", address, " data ", refresp.data, " tag ", refresp.tag, " pcieresp ", pcieresp.data, " tag ", pcieresp.tag);
	 scoreboard[address].deq();
         tagscoreboard[refresp.tag].deq();
         return refresp == pcieresp;
      end
      endactionvalue);

   prop("read", sendPhysMemReq(False));
   prop("write", sendPhysMemReq(True));
   prop("check", checkPhysMemResp);

endmodule

interface PcieMemChecker;
   interface FSM fsm;
   method Action start(Bit#(32) numIterations, Bool verbose);
   method ActionValue#(Bool) done();
endinterface 

(* synthesize *)
module [Module] mkPcieMemChecker(PcieMemChecker);
   BlueCheck_Params params = bcParams;
   Reg#(Bit#(32)) numIterations <- mkReg(100000);
   params.numIterations = numIterations;
   params.verbose = True;
   let test <- mkModelChecker(checkMPM, params);

   Reg#(Bool) started <- mkReg(False);
   let _fsm <- mkFSM(test);
   interface fsm = _fsm;
   method Action start(Bit#(32) numiters, Bool v) if (!started);
      numIterations <= numiters;
      _fsm.start();
      started <= True;
   endmethod
   method ActionValue#(Bool) done() if (started && _fsm.done);
      started <= False;
      return True;
   endmethod
endmodule
