import StmtFSM           :: *;
import Portal            :: *;
import Connectable       :: *;
import Xilinx            :: *;
import XilinxPCIE        :: *;
import PcieToAxiBridge   :: *;
import DefaultValue      :: *;
import MIMO              :: *;

// bsv libraries
import SpecialFIFOs::*;
import Vector::*;
import StmtFSM::*;
import FIFOF::*;
import PCIE::*;
import GetPut::*;

// portz libraries
import PcieToAxiBridge::*;
import AxiMasterSlave::*;
import AxiClientServer::*;
import Directory::*;
import CtrlMux::*;
import Portal::*;
import Leds::*;
import PortalMemory::*;
import AxiRDMA::*;
import PortalMemory::*;
import PortalRMemory::*;

// defined by user
import Memread::*;

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
      method Action badAddr(Bit#(32) handle, Bit#(32) address);
	 $display("badAddr handle=%d address=%h", handle, address);
      endmethod
      endinterface);

    MemreadIndication memreadIndication = (interface MemreadIndication;
      method Action started(Bit#(32) numWords);
	 $display("started numWords=%d", numWords);
      endmethod
      method Action reportStateDbg(Bit#(32) streamRdCnt, Bit#(32) srcGen);
	 $display("memread.reportStateDbg rdcnt=%d srcGen=%h", streamRdCnt, srcGen);
      endmethod
      method Action readReq(Bit#(32) v);
	 $display("readReq v=%h", v);
      endmethod
      method Action readDone(Bit#(32) v);
	 $display("readDone v=%h", v);
      endmethod
      endinterface);
   Memread memread <- mkMemread(memreadIndication);
   let memreadRequest = memread.request;

   Vector#(1,  DMAReadClient#(64))   readClients = newVector();
   readClients[0] = memread.dmaClient;
   Vector#(0, DMAWriteClient#(64)) writeClients = newVector();
   Integer               numRequests = 8;

   AxiDMAServer#(64,8)   dma <- mkAxiDMAServer(dmaIndication, numRequests, readClients, writeClients);

   PciId myId = PciId { bus: 1, dev: 1, func: 0 };
   AxiSlaveEngine#(64) axiSlaveEngine <- mkAxiSlaveEngine(myId);

   let axi_master = dma.m_axi;
   mkConnection(axi_master, axiSlaveEngine.slave3);

   MIMO#(4, 1, 4, TLPData#(16)) tlpMimo <- mkMIMO(defaultValue);

   rule tlpsout if (tlpMimo.enqReadyN(4));
      TLPData#(16) tlp <- tpl_1(axiSlaveEngine.tlps).get();
      TLPMemory4DWHeader hdr_4dw = unpack(tlp.data);
      TLPCompletionHeader rc_hdr = defaultValue();
      rc_hdr.tclass = hdr_4dw.tclass;
      rc_hdr.relaxed = hdr_4dw.relaxed;
      rc_hdr.nosnoop = hdr_4dw.nosnoop;
      rc_hdr.length = hdr_4dw.length;
      rc_hdr.tag = hdr_4dw.tag;
      rc_hdr.reqid = hdr_4dw.reqid;
      
      Vector#(4, TLPData#(16)) tlps = unpack(0);

      tlps[0].be = 16'hffff;
      tlps[1].be = 16'hffff;
      tlps[2].be = 16'hffff;
      tlps[3].be = 16'hfff0;
      tlps[0].data = pack(rc_hdr);
      Vector#(4, Bit#(32)) words1 = replicate(32'h5a5a5a5a);
      tlps[1].data = pack(words1);
      Vector#(4, Bit#(32)) words2 = replicate(32'hd00df00d);
      tlps[2].data = pack(words2);
      Vector#(4, Bit#(32)) words3 = replicate(32'hdeadbeef);
      tlps[3].data = pack(words3);
      
      tlps[0].sof = True;
      tlps[3].eof = True;

      tlpMimo.enq(4, tlps);
      $display($format(fshow("tlp out: ") + fshow(pack(tlp)) + fshow(" length=") + fshow(hdr_4dw.length)));
      for (Integer i = 0; i < 4; i = i+1)
	 $display($format(fshow("tlps: ") + fshow(pack(tlps[i]))));
      $display("  ");
   endrule

   rule tlpsin if (tlpMimo.deqReady());
      Vector#(1, TLPData#(16)) tlpv = tlpMimo.first();
      tlpMimo.deq(1);
      //$display("tlpsin tlp=%h\n", pack(tlpv[0]));
      tpl_2(axiSlaveEngine.tlps).put(tlpv[0]);
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
	 memreadRequest.startRead(1, 128, 8);
         delay(100);
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
