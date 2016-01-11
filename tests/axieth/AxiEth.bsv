
import BuildVector::*;
import Connectable::*;
import GetPut::*;
import FIFOF::*;
import BRAM::*;
import Probe::*;
import StmtFSM::*;
import TriState::*;
import Vector::*;

import ConnectalXilinxCells::*;
import ConnectalConfig::*;
import HostInterface::*;
import MemTypes::*;
import AxiBits::*;

import AxiEthBvi::*;
import AxiDmaBvi::*;
import EthPins::*;

interface AxiEthTestRequest;
   method Action reset();
   method Action read(Bit#(10) addr);
   method Action write(Bit#(10) addr, Bit#(32) value);
endinterface

interface AxiEthTestIndication;
   method Action readDone(Bit#(32) value); 
   method Action writeDone(); 
   method Action resetDone();
endinterface

interface AxiEth;
   interface AxiEthTestRequest request;
   interface Vector#(2, MemReadClient#(DataBusWidth)) dmaReadClient;
   interface Vector#(2, MemWriteClient#(DataBusWidth)) dmaWriteClient;
   interface AxiEthPins pins;
endinterface

module mkAxiEth#(HostInterface host, AxiEthTestIndication ind)(AxiEth);

   let clock <- exposeCurrentClock();
   let reset <- exposeCurrentReset();

   let axiDmaBvi <- mkAxiDmaBvi(clock,clock,clock,clock);
   let axiEthBvi <- mkAxiEthBvi(host.tsys_clk_200mhz_buf,
				clock, reset, clock,
				reset, reset, reset, reset);

   FIFOF#(BRAMRequest#(Bit#(32),Bit#(32))) reqFifo <- mkFIFOF();
   FIFOF#(Bit#(32))                       dataFifo <- mkFIFOF();
   // packet data and status from the ethernet
   mkConnection(axiEthBvi.m_axis_rxd, axiDmaBvi.s_axis_s2mm);
   mkConnection(axiEthBvi.m_axis_rxs, axiDmaBvi.s_axis_s2mm_sts);

   // packet data and control to the ethernet
   mkConnection(axiDmaBvi.m_axis_mm2s,       axiEthBvi.s_axis_txd);
   mkConnection(axiDmaBvi.m_axis_mm2s_cntrl, axiEthBvi.s_axis_txc);

   Axi4MasterBits#(32,32,MemTagSize,Empty) m_axi_mm2s = toAxi4MasterBits(axiDmaBvi.m_axi_mm2s);
   Axi4MasterBits#(32,32,MemTagSize,Empty) m_axi_s2mm = toAxi4MasterBits(axiDmaBvi.m_axi_s2mm);
   Axi4MasterBits#(32,32,MemTagSize,Empty) m_axi_sg = toAxi4MasterBits(axiDmaBvi.m_axi_sg);

   PhysMemSlave#(10,32) axiDmaMemSlave <- mkPhysMemSlave(axiDmaBvi.s_axi_lite);
   //PhysMemSlave#(18,32) axiEthMemSlave <- mkPhysMemSlave(axiEthBvi.s_axi);

   rule rl_req;
      let req <- toGet(reqFifo).get();
      if (req.write) begin
	 axiDmaMemSlave.write_server.writeReq.put(PhysMemRequest { addr: truncate(req.address), burstLen: 4, tag: 0 });
	 axiDmaMemSlave.write_server.writeData.put(MemData {data: req.datain, tag: 0});
      end
      else begin
	 axiDmaMemSlave.read_server.readReq.put(PhysMemRequest { addr: truncate(req.address), burstLen: 4, tag: 0 });
      end
   endrule

   rule rl_rdata;
      let rdata <- axiDmaMemSlave.read_server.readData.get();
      ind.readDone(rdata.data);
   endrule

   rule rl_writeDone;
      let tag <- axiDmaMemSlave.write_server.writeDone.get();
      ind.writeDone();
   endrule

   interface AxiEthTestRequest request;
      method Action reset();
      endmethod
   endinterface
   interface AxiEthPins pins;
      interface EthPins eth;
	 interface AxiethbviMgt mgt   = axiEthBvi.mgt;
	 interface AxiethbviMdio sfp = axiEthBvi.sfp;
	 interface Clock deleteme_unused_clock = clock;
	 interface Reset deleteme_unused_reset = reset;
      endinterface
   endinterface
   interface Vector dmaReadClient = map(toMemReadClient, vec(m_axi_mm2s, m_axi_sg));
   //interface Vector dmaWriteClient = map(toMemWriteClient, vec(m_axi_s2mm, m_axi_sg));
endmodule
