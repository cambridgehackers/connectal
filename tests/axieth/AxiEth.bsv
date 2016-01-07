
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
import MemTypes::*;
import AxiBits::*;

import AxiEthBvi::*;
import AxiDmaBvi::*;
import EthPins::*;

interface AxiEthTestRequest;
   method Action reset();
   method Action read(Bit#(25) addr);
   method Action write(Bit#(25) addr, Bit#(16) data);
   method Action setParameters(Bit#(16) cycles, Bool stallOnWaitIn);
endinterface

interface AxiEthTestIndication;
   method Action resetDone();
endinterface

interface AxiEth;
   interface AxiEthTestRequest request;
   interface Vector#(2, MemReadClient#(DataBusWidth)) dmaReadClient;
   interface Vector#(2, MemWriteClient#(DataBusWidth)) dmaWriteClient;
   interface AxiEthPins pins;
endinterface

module mkAxiEth#(AxiEthTestIndication ind)(AxiEth);

   let clock <- exposeCurrentClock();
   let reset <- exposeCurrentReset();

   let axiDmaBvi <- mkAxiDmaBvi(clock,clock,clock,clock);
   let axiEthBvi <- mkAxiEthBvi();

   // packet data and status from the ethernet
   mkConnection(axiEthBvi.m_axis_rxd, axiDmaBvi.s_axis_s2mm);
   mkConnection(axiEthBvi.m_axis_rxs, axiDmaBvi.s_axis_s2mm_sts);

   // packet data and control to the ethernet
   mkConnection(axiDmaBvi.m_axis_mm2s,       axiEthBvi.s_axis_txd);
   mkConnection(axiDmaBvi.m_axis_mm2s_cntrl, axiEthBvi.s_axis_txc);

   let m_axi_mm2s = toAxi4MasterBits(axiDmaBvi.m_axi_mm2s);
   let m_axi_s2mm = toAxi4MasterBits(axiDmaBvi.m_axi_s2mm);
   let m_axi_sg = toAxi4MasterBits(axiDmaBvi.m_axi_sg);

   interface AxiEthTestRequest request;
      method Action reset();
      endmethod
   endinterface
   interface AxiEthPins pins;
       interface EthPins eth;
	  interface AxiethbviMdio mdio = axiEthBvi.mdio;
	  interface AxiethbviMgt mgt   = axiEthBvi.mgt;
       endinterface
   endinterface
//   interface Vector dmaReadClient = vec(axiDmaBvi.;
//   interface Vector dmaWriteClient;
endmodule
