
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
import CtrlMux::*;
import HostInterface::*;
import ConnectalMemTypes::*;
import AxiBits::*;

import AxiIntcBvi::*;
import AxiEthBvi::*;
import AxiDmaBvi::*;
import EthPins::*;

interface AxiEthTestRequest;
   method Action reset();
   method Action setupDma(Bit#(32) memref);
   method Action status();
   method Action read(Bit#(32) addr);
   method Action write(Bit#(32) addr, Bit#(32) value);
endinterface

interface AxiEthTestIndication;
   method Action irqChanged(Bit#(1) newIrq, Bit#(4) intrSources);
   method Action readDone(Bit#(32) value); 
   method Action writeDone(); 
   method Action resetDone();
   method Action status(Bit#(1) mmcm_locked, Bit#(1) irq, Bit#(4) intrSources);
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

   let axiIntcBvi <- mkAxiIntcBvi(clock, reset);
   let axiDmaBvi <- mkAxiDmaBvi(clock,clock,clock,clock,reset);
   let axiEthBvi <- mkAxiEthBvi(host.tsys_clk_200mhz_buf,
				clock, reset, clock,
				reset, reset, reset, reset);

   Reg#(Bit#(32)) objId <- mkReg(0);

   let irqLevel <- mkReg(0);
   let intrLevel <- mkReg(0);
   Bit#(4) intr = {
      axiDmaBvi.s2mm.introut(),
      axiDmaBvi.mm2s.introut(),
      axiEthBvi.mac.irq(),
      axiEthBvi.interrupt()
      };

   rule rl_intr;
      axiIntcBvi.intr(intr);
   endrule

   rule rl_intr_indication;
      let irq = axiIntcBvi.irq;
      irqLevel <= irq;
      intrLevel <= intr;

      if (irq != irqLevel || intr != intrLevel) begin
	 ind.irqChanged(irq, intr);
	 $display("irq changed irq=%h intr sources %h", irq, intr);
      end
   endrule
   Reg#(Bit#(32)) cycles <- mkReg(0);
   Reg#(Bool)     mmcm_lock <- mkReg(False);
   rule rl_cycles;
      cycles <= cycles+1;
   endrule
   rule rl_mmcm_lock if (!mmcm_lock);
      if (axiEthBvi.mmcm.locked_out() == 1) begin
	 mmcm_lock <= True;
	 $display("%d mmcm locked", cycles);
      end
   endrule

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

   Axi4SlaveLiteBits#(9,32) axiIntcSlaveLite = toAxi4SlaveBits(axiIntcBvi.s_axi);
   PhysMemSlave#(18,32) axiIntcMemSlave <- mkPhysMemSlave(axiIntcSlaveLite);
   PhysMemSlave#(18,32) axiDmaMemSlave <- mkPhysMemSlave(axiDmaBvi.s_axi_lite);
   Axi4SlaveLiteBits#(18,32) axiEthSlaveLite = toAxi4SlaveBits(axiEthBvi.s_axi);
   PhysMemSlave#(18,32) axiEthMemSlave <- mkPhysMemSlave(axiEthSlaveLite);
   PhysMemSlave#(20,32) memSlaveMux    <- mkPhysMemSlaveMux(vec(axiIntcMemSlave, axiDmaMemSlave, axiEthMemSlave));

   FIFOF#(Bit#(32)) dfifo <- mkFIFOF();

   rule rl_axieth;
      axiEthBvi.signal.detect(1); // drive to 1 if not using optical transceiver, else use signal from transceiver
   endrule

   rule rl_rdata;
      let rdata <- memSlaveMux.read_server.readData.get();
      ind.readDone(rdata.data);
   endrule

   rule rl_wdata;
      let wdata <- toGet(dfifo).get();
       memSlaveMux.write_server.writeData.put(MemData {data: wdata, tag: 0});
   endrule

   rule rl_writeDone;
      let tag <- memSlaveMux.write_server.writeDone.get();
      ind.writeDone();
   endrule

   interface AxiEthTestRequest request;
      method Action reset();
      endmethod
      method Action setupDma(Bit#(32) memref);
	 objId <= memref;
      endmethod
      method Action read(Bit#(32) addr);
	 memSlaveMux.read_server.readReq.put(PhysMemRequest { addr: truncate(addr), burstLen: 4, tag: 0 });
      endmethod
      method Action write(Bit#(32) addr, Bit#(32) value);
	 memSlaveMux.write_server.writeReq.put(PhysMemRequest { addr: truncate(addr), burstLen: 4, tag: 0 });
	 dfifo.enq(value);
      endmethod
      method Action status();
	 ind.status(axiEthBvi.mmcm.locked_out(), axiIntcBvi.irq, intr);
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
   interface Vector dmaReadClient = map(toMemReadClient(objId), vec(m_axi_mm2s, m_axi_sg));
   interface Vector dmaWriteClient = map(toMemWriteClient(objId), vec(m_axi_s2mm, m_axi_sg));
endmodule
