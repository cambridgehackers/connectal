
import BuildVector::*;
import Connectable::*;
import GetPut::*;
import FIFOF::*;
import BRAM::*;
import Probe::*;
import StmtFSM::*;
import TriState::*;
import Vector::*;
import XilinxCells::*;
import Probe::*;

import ConnectalXilinxCells::*;
import ConnectalConfig::*;
import CtrlMux::*;
import HostInterface::*;
import MemTypes::*;
import AxiBits::*;
import PhysMemToBram::*;

import BpiFlash::*;
import AxiIntcBvi::*;
import AxiIic::*;
import AxiUart::*;
import AxiEthBvi::*;
import AxiDmaBvi::*;
import SpikeHwPins::*;

`ifndef BOARD_nfsume
`define IncludeFlash
`endif

interface SpikeHwRequest;
   method Action reset();
   method Action setupDma(Bit#(32) memref);
   method Action status();
   method Action read(Bit#(32) addr);
   method Action write(Bit#(32) addr, Bit#(32) value);
   method Action setFlashParameters(Bit#(16) cycles);
   method Action readFlash(Bit#(32) addr);
   method Action writeFlash(Bit#(32) addr, Bit#(32) value);
   method Action iicReset(Bit#(1) rst);
endinterface

interface SpikeHwIndication;
   method Action irqChanged(Bit#(1) newIrq, Bit#(16) intrSources);
   method Action readDone(Bit#(32) value); 
   method Action writeDone(); 
   method Action readFlashDone(Bit#(32) value); 
   method Action writeFlashDone(); 
   method Action resetDone();
   method Action status(Bit#(1) mmcm_locked, Bit#(1) irq, Bit#(16) intrSources);
endinterface

interface SpikeHw;
   interface SpikeHwRequest request;
   interface Vector#(2, MemReadClient#(DataBusWidth)) dmaReadClient;
   interface Vector#(2, MemWriteClient#(DataBusWidth)) dmaWriteClient;
   interface SpikeHwPins pins;
endinterface

typedef 65536 BootRomBytes;
typedef TDiv#(BootRomBytes,4) BootRomEntries;

module mkBramBootRom(Server#(BRAMRequest#(Bit#(TLog#(BootRomEntries)),Bit#(32)),Bit#(32)));
   BRAM_Configure cfg = defaultValue;
   cfg.memorySize = valueOf(BootRomEntries); // 128KB (32K x 4bytes)
   cfg.latency = 2;
   cfg.loadFormat = tagged Hex "bootromx4.hex";

   BRAM1Port#(Bit#(TLog#(BootRomEntries)), Bit#(32)) bram <- mkBRAM1Server(cfg);
   return bram.portA;
endmodule

module mkSpikeHw#(HostInterface host, SpikeHwIndication ind)(SpikeHw);

   let clock <- exposeCurrentClock();
   let reset <- exposeCurrentReset();

   BUFRParams bufrParams = defaultValue;
   bufrParams.bufr_divide = "4";
   Clock uartClk <- mkClockBUFR(bufrParams, clocked_by host.derivedClock);

   let bootRom    <- mkBramBootRom();
`ifdef IncludeFlash
   let bpiFlash   <- mkBpiFlash();
`endif
   let axiIntcBvi <- mkAxiIntcBvi(clock, reset);
   let axiIicBvi  <- mkAxiIicBvi(clock, reset);
   let axiUartBvi <- mkAxiUartBvi(clock, reset, uartClk);
   let axiDmaBvi <- mkAxiDmaBvi(clock,clock,clock,clock,reset);
`ifdef IncludeEthernet
   let axiEthBvi <- mkAxiEthBvi(host.tsys_clk_200mhz_buf,
				clock, reset, clock,
				reset, reset, reset, reset);
`endif

   

   Reg#(Bit#(32)) objId <- mkReg(0);
   Reg#(Bit#(1))  iicResetReg <- mkReg(0);

   let irqLevel <- mkReg(0);
   let intrLevel <- mkReg(0);

   function Bit#(16) intr();
      Bit#(16) _intr = 0;
      _intr[0] = axiUartBvi.ip2intc_irpt();
      //_intr[1] = axiDma tx
      //_intr[2] = axiDma rx
      //_intr[3] = axiEth rx
      //_intr[4] = Phy 
      _intr[5] = axiIicBvi.iic2intc_irpt();
      return _intr;
   endfunction

   rule rl_intr;

      axiIntcBvi.intr(intr());
   endrule

   FIFOF#(Tuple2#(Bit#(1),Bit#(16))) irqChangeFifo <- mkSizedFIFOF(8);
   rule rl_irq_levels_changed;
      let irq = axiIntcBvi.irq;
      let levels = intr();

      if (irq != irqLevel) begin
	 $display("irq changed irq=%h intr sources %h", irq, levels);
	 irqLevel <= irq;
	 intrLevel <= levels;
	 irqChangeFifo.enq(tuple2(irq, levels));
      end
   endrule

   rule rl_intr_indication;
      match { .irq, .levels } <- toGet(irqChangeFifo).get();
      ind.irqChanged(irq, levels);
   endrule

   Reg#(Bit#(32)) cycles <- mkReg(0);
   Reg#(Bool)     mmcm_lock <- mkReg(False);
   rule rl_cycles;
      cycles <= cycles+1;
   endrule

   FIFOF#(BRAMRequest#(Bit#(32),Bit#(32))) reqFifo <- mkFIFOF();
   FIFOF#(Bit#(32))                       dataFifo <- mkFIFOF();

`ifdef IncludeEthernet
   // packet data and status from the ethernet
   mkConnection(axiEthBvi.m_axis_rxd, axiDmaBvi.s_axis_s2mm);
   mkConnection(axiEthBvi.m_axis_rxs, axiDmaBvi.s_axis_s2mm_sts);

   // packet data and control to the ethernet
   mkConnection(axiDmaBvi.m_axis_mm2s,       axiEthBvi.s_axis_txd);
   mkConnection(axiDmaBvi.m_axis_mm2s_cntrl, axiEthBvi.s_axis_txc);
`endif

   Axi4MasterBits#(32,32,MemTagSize,Empty) m_axi_mm2s = toAxi4MasterBits(axiDmaBvi.m_axi_mm2s);
   Axi4MasterBits#(32,32,MemTagSize,Empty) m_axi_s2mm = toAxi4MasterBits(axiDmaBvi.m_axi_s2mm);
   Axi4MasterBits#(32,32,MemTagSize,Empty) m_axi_sg = toAxi4MasterBits(axiDmaBvi.m_axi_sg);

   Axi4SlaveLiteBits#(12,32) axiUartSlaveLite = toAxi4SlaveBits(axiUartBvi.s_axi);
   PhysMemSlave#(12,32) axiUartMemSlave      <- mkPhysMemSlave(axiUartSlaveLite);

   Axi4SlaveLiteBits#(9,32) axiIntcSlaveLite = toAxi4SlaveBits(axiIntcBvi.s_axi);
   PhysMemSlave#(12,32) axiIntcMemSlave      <- mkPhysMemSlave(axiIntcSlaveLite);

   Axi4SlaveLiteBits#(9,32) axiIicSlaveLite  = toAxi4SlaveBits(axiIicBvi.s_axi);
   PhysMemSlave#(12,32) axiIicMemSlave       <- mkPhysMemSlave(axiIicSlaveLite);

   PhysMemSlave#(12,32) axiDmaMemSlave       <- mkPhysMemSlave(axiDmaBvi.s_axi_lite);

`ifdef IncludeEthernet
   Axi4SlaveLiteBits#(18,32) axiEthSlaveLite = toAxi4SlaveBits(axiEthBvi.s_axi);
   PhysMemSlave#(18,32) axiEthMemSlave       <- mkPhysMemSlave(axiEthSlaveLite);
   PhysMemSlave#(20,32) deviceSlaveMux       <- mkPhysMemSlaveMux(vec(axiIntcMemSlave, axiDmaMemSlave, axiEthMemSlave));
`else
   PhysMemSlave#(20,32) deviceSlaveMux       <- mkPhysMemSlaveMux(vec(axiUartMemSlave, axiIntcMemSlave, axiDmaMemSlave, axiIicMemSlave));
`endif

   PhysMemSlave#(20,32) bootRomMemSlave      <- mkPhysMemToBram(bootRom);
   PhysMemSlave#(21,32) memSlaveMux          <- mkPhysMemSlaveMux(vec(bootRomMemSlave, deviceSlaveMux));

`ifdef IncludeFlash
   PhysMemSlave#(26,16) bpiFlashSlave <- mkPhysMemToBram(bpiFlash.server);
`endif

   FIFOF#(Bit#(32)) dfifo <- mkFIFOF();
   FIFOF#(Bit#(32)) flashdfifo <- mkFIFOF();

`ifdef IncludeEthernet
   rule rl_axieth;
      axiEthBvi.signal.detect(1); // drive to 1 if not using optical transceiver, else use signal from transceiver
   endrule
`endif

   rule rl_rdata;
      let rdata <- memSlaveMux.read_server.readData.get();
      ind.readDone(rdata.data);
   endrule

   rule rl_wdata;
      let wdata <- toGet(dfifo).get();
       memSlaveMux.write_server.writeData.put(MemData {data: wdata, tag: 0, last: True});
   endrule

   rule rl_writeDone;
      let tag <- memSlaveMux.write_server.writeDone.get();
      ind.writeDone();
   endrule

   rule rl_bpiflash_rdata;
`ifdef IncludeFlash
      let rdata <- bpiFlashSlave.read_server.readData.get();
      ind.readFlashDone(extend(rdata.data));
`endif
   endrule

   rule rl_bpiflash_wdata;
`ifdef IncludeFlash
      let wdata <- toGet(flashdfifo).get();
       bpiFlashSlave.write_server.writeData.put(MemData {data: truncate(wdata), tag: 0, last: True});
`endif
   endrule

   rule rl_bpiflash_writeDone;
`ifdef IncludeFlash
      let tag <- bpiFlashSlave.write_server.writeDone.get();
      ind.writeFlashDone();
`endif
   endrule

   IOBUF sdaIOBuf <- mkIOBUF(axiIicBvi.sda.t, axiIicBvi.sda.o);
   IOBUF sclIOBuf <- mkIOBUF(axiIicBvi.scl.t, axiIicBvi.scl.o);
   // No probe for .o because they are tied to ground -- I2C operates open collector
   Probe#(Bit#(1)) sda_i_probe <- mkProbe();
   Probe#(Bit#(1)) sda_t_probe <- mkProbe();
   Probe#(Bit#(1)) scl_i_probe <- mkProbe();
   Probe#(Bit#(1)) scl_t_probe <- mkProbe();

   rule iic_o;
      sda_i_probe <= sdaIOBuf.o;
      sda_t_probe <= axiIicBvi.sda.t;
      scl_i_probe <= sclIOBuf.o;
      scl_t_probe <= axiIicBvi.scl.t;

      axiIicBvi.sda.i(sdaIOBuf.o);
      axiIicBvi.scl.i(sclIOBuf.o);
   endrule

   interface SpikeHwRequest request;
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
      method Action setFlashParameters(Bit#(16) cycles);
`ifdef IncludeFlash
	 bpiFlash.setParameters(cycles, False);
`endif
      endmethod
      method Action readFlash(Bit#(32) addr);
`ifdef IncludeFlash
	 bpiFlashSlave.read_server.readReq.put(PhysMemRequest { addr: truncate(addr), burstLen: 2, tag: 0 });
`endif
      endmethod
      method Action writeFlash(Bit#(32) addr, Bit#(32) value);
`ifdef IncludeFlash
	 bpiFlashSlave.write_server.writeReq.put(PhysMemRequest { addr: truncate(addr), burstLen: 2, tag: 0 });
	 flashdfifo.enq(value);
`endif
      endmethod
      method Action status();
	 ind.status(
`ifdef IncludeEthernet
	    axiEthBvi.mmcm.locked_out(),
`else
		    0,
`endif

	    axiIntcBvi.irq, intr());
      endmethod
      method Action iicReset(Bit#(1) rst);
	 iicResetReg <= rst;
      endmethod
   endinterface
   interface SpikeHwPins pins;
`ifdef IncludeEthernet
      interface EthPins eth;
	 interface AxiethbviMgt mgt   = axiEthBvi.mgt;
	 interface AxiethbviMdio sfp = axiEthBvi.sfp;
      endinterface
`endif
`ifdef IncludeFlash
      interface flash = bpiFlash.flash;
`endif
      interface SpikeUartPins uart;
	 method tx  = axiUartBvi.sout;
	 method rts = axiUartBvi.rtsn;
	 method rx  = axiUartBvi.sin;
	 method cts = axiUartBvi.ctsn;
      endinterface   
      interface SpikeIicPins iic;
         interface scl = sclIOBuf.io;
         interface sda = sdaIOBuf.io;
`ifndef BOARD_nfsume
	 method gpo = axiIicBvi.gpo()[0];
`else
	 method mux_reset = iicResetReg;
`endif
      endinterface
      interface Clock deleteme_unused_clock = clock;
      interface Reset deleteme_unused_reset = reset;
   endinterface

   interface Vector dmaReadClient = map(toMemReadClient(objId), vec(m_axi_mm2s, m_axi_sg));
   interface Vector dmaWriteClient = map(toMemWriteClient(objId), vec(m_axi_s2mm, m_axi_sg));
endmodule
