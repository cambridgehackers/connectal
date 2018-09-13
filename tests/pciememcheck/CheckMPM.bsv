
import BRAM         :: *;
import Connectable  :: *;
import FIFO         :: *;
import GetPut       :: *;
import DefaultValue :: *;
import PCIE         :: *;
import StmtFSM      :: *;

import BlueCheck         :: *;
import ConnectalMemTypes :: *;
import PcieToMem         :: *;
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
   mkConnection(memToPcie.tlp.request, pcieToMem.tlp.response);
   mkConnection(memToPcie.tlp.response, pcieToMem.tlp.request);
   mkConnection(pcieToMem.master, bramPhysMem);
   return memToPcie.slave;
endmodule

typedef struct {
   Bool write;
   Bit#(12) address;
   Bit#(32) data;
   Bit#(MemTagSize) tag;
   } Req deriving (Bits, Eq, FShow);

module [BlueCheck] checkMPM(Empty);
   PhysMemSlave#(32, 32) refmem  <- mkRefMem();
   PhysMemSlave#(40, 32) pciemem <- mkMemToPcieToMem();
   FIFO#(Bool) isWriteFifo <- mkSizedFIFO(128);
   function Action sendPhysMemReq(Req req);
      return (action
	PhysMemRequest#(32, 32) refreq = PhysMemRequest { addr: zeroExtend(req.address), burstLen: 4, tag: req.tag };
	PhysMemRequest#(40, 32) pciereq = PhysMemRequest { addr: zeroExtend(req.address), burstLen: 4, tag: req.tag };

	isWriteFifo.enq(req.write);
	if (req.write) begin
	   MemData#(32) writeData = MemData {};
	   refmem.write_server.writeReq.put(refreq);
	   pciemem.write_server.writeReq.put(pciereq);
	   refmem.write_server.writeData.put(writeData);
	   pciemem.write_server.writeData.put(writeData);
	end
	else begin
	   refmem.read_server.readReq.put(refreq);
	   pciemem.read_server.readReq.put(pciereq);
	end
   endaction);
   endfunction

   ActionValue#(Bool) checkPhysMemResp = (actionvalue
      let isWrite <- toGet(isWriteFifo).get();
      if (isWrite) begin
	 let refdone <- refmem.write_server.writeDone.get();
	 let pciedone <- pciemem.write_server.writeDone.get();
         return refdone == pciedone;
      end
      else begin
         let refresp <- refmem.read_server.readData.get();
         let pcieresp <- pciemem.read_server.readData.get();
         return refresp == pcieresp;
      end
      endactionvalue);

   prop("sendPhysMemReq", sendPhysMemReq);
   prop("checkPhysMemResp", checkPhysMemResp);

endmodule

interface PcieMemChecker;
   interface FSM fsm;
   method Action start(Bit#(32) numIterations);
endinterface 

(* synthesize *)
module [Module] mkPcieMemChecker(PcieMemChecker);
   BlueCheck_Params params = bcParams;
   Reg#(Bit#(32)) numIterations <- mkReg(100000);
   params.numIterations = numIterations;
   let test <- mkModelChecker(checkMPM, params);

   let _fsm <- mkFSM(test);
   interface fsm = _fsm;
   method Action start(Bit#(32) numiters);
      numIterations <= numiters;
      _fsm.start();
   endmethod
endmodule
