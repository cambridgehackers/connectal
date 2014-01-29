import StmtFSM           :: *;
import Portal            :: *;
import Connectable       :: *;
import Xilinx            :: *;
import XilinxPCIE        :: *;
import PcieToAxiBridge   :: *;

// bsv libraries
import SpecialFIFOs::*;
import Vector::*;
import StmtFSM::*;
import FIFO::*;
import PCIE::*;
import GetPut::*;

// portz libraries
import PcieToAxiBridge::*;
import AxiMasterSlave::*;
import Directory::*;
import CtrlMux::*;
import Portal::*;
import Leds::*;
import PortalMemory::*;
import AxiDMA::*;
import PortalMemory::*;
import DMA::*;

// defined by user
import Memwrite::*;

module mkTbPcie(Empty);

   DMAIndication dmaIndication = (interface DMAIndication;
      method Action reportStateDbg(DmaDbgRec rec);
	 $display("reportStateDbg rec=%h %x %h %x", rec.x, rec.y, rec.z, rec.w);
      endmethod
      method Action sglistResp(Bit#(32) pref, Bit#(32) idx, Bit#(32) pa);
	 $display("sglistResp pref=%d idx=%d pa=%h", pref, idx, pa);
      endmethod
      method Action parefResp(Bit#(32) v);
      endmethod
      method Action sglistEntry(Bit#(64) physAddr);
	 $display("sglistEntry physAddr=%h", physAddr);
      endmethod
      method Action badAddr(Bit#(32) handle, Bit#(32) address, Bit#(64) pa);
	 $display("badAddr handle=%d address=%h physAddr=%h", handle, address, pa);
      endmethod
      endinterface);

    MemwriteIndication memwriteIndication = (interface MemwriteIndication;
      method Action started(Bit#(32) numWords);
	 $display("started numWords=%d", numWords);
      endmethod
      method Action reportStateDbg(Bit#(32) streamRdCnt, Bit#(32) srcGen);
	 $display("memwrite.reportStateDbg rdcnt=%d srcGen=%h", streamRdCnt, srcGen);
      endmethod
      method Action writeReq(Bit#(32) v);
	 $display("writeReq v=%h", v);
      endmethod
      method Action writeDone(Bit#(32) v);
	 $display("writeDone v=%h", v);
      endmethod
      endinterface);
   Memwrite memwrite <- mkMemwrite(memwriteIndication);
   let memwriteRequest = memwrite.request;

   Vector#(0,  DMAReadClient#(64))   readClients = newVector();
   Vector#(1, DMAWriteClient#(64)) writeClients = newVector();
   writeClients[0] = memwrite.dmaClient;
   Integer               numRequests = 8;

   AxiDMAServer#(addrWidth,64)   dma <- mkAxiDMAServer(dmaIndication, numRequests, readClients, writeClients);

   PciId myId = PciId { bus: 1, dev: 1, func: 0 };
   AxiSlaveEngine#(64) axiSlaveEngine <- mkAxiSlaveEngine(myId);

   let axi_master = dma.m_axi;
   mkConnection(axi_master, axiSlaveEngine.slave3);

      rule tlpsout;
	 let tlp <- tpl_1(axiSlaveEngine.tlps).get();
	 $display($format(fshow("tlp out: ") + fshow(pack(tlp))));
      endrule

   let fsm <- mkFSM(
      seq
	 dma.request.sglist(1, 40'hadd0000, 'h1000);
	 dma.request.sglist(1, 40'hade0000, 'h1000);
	 dma.request.sglist(1, 40'hadf0000, 'h1000);
	 dma.request.sglist(1, 0, 0);
	 $display("starting write");
	 dma.request.readSglist(Read, 1, 0);
	 delay(10);
	 memwriteRequest.startWrite(1, 128, 8);
         delay(100000);
	 $display("done");
	 $finish();
      endseq
      );
   Reg#(Bool) started <- mkReg(False);
   rule start if (!started);
      fsm.start();
      started <= True;
   endrule

endmodule
