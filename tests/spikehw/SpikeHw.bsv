
import BuildVector::*;
import Clocks::*;
import Connectable::*;
import GetPut::*;
import FIFOF::*;
import BRAM::*;
import BRAMFIFO::*;
import Probe::*;
import StmtFSM::*;
import TriState::*;
import Vector::*;
import XilinxCells::*;
import Probe::*;

import ConnectalXilinxCells::*;
import ConnectalBramFifo::*;
import ConnectalConfig::*;
import GetPutWithClocks::*;
import CtrlMux::*;
import HostInterface::*;
import ConnectalMemTypes::*;
import Pipe::*;
import AxiBits::*;
import PhysMemSlaveFromBram::*;
import TraceMemClient::*;

import BpiFlash::*;
import AxiIntcBvi::*;
import AxiIic::*;
import AxiSpiBvi::*;
import AxiUart::*;
`ifdef EthernetSgmii
import AxiEthBvi::*;
`else
//import AxiEth1000BaseX::*;
import AxiEthSubsystem::*;
import TriModeMacBvi::*;
import GigEthPcsPmaBvi::*;
import AxiEthBufferBvi::*;
import AxiEth1000BaseX::*; // for interfaces
`endif
import AxiDmaBvi::*;
import SpikeHwPins::*;
import SpikeHwIfc::*;

`include "ConnectalProjectConfig.bsv"

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

   let newReset <- mkReset(10, True, clock);

   BUFRParams bufrParams = defaultValue;
`ifndef BOARD_miniitx100
   bufrParams.bufr_divide = "2";
   Clock clk_125mhz <- mkClockBUFR(bufrParams, clocked_by clock);
`endif
   bufrParams.bufr_divide = "4";
   Clock uartClk <- mkClockBUFR(bufrParams, clocked_by host.derivedClock);

   let bootRom    <- mkBramBootRom();
`ifdef IncludeFlash
   let bpiFlash   <- mkBpiFlash();
`endif
   let axiIntcBvi <- mkAxiIntcBvi(clock, newReset.new_rst);
   let axiIicBvi  <- mkAxiIicBvi(clock, newReset.new_rst);
//   let axiSpiBvi  <- mkAxiSpiBvi(clock, clock, newReset.new_rst);
   let axiUartBvi <- mkAxiUartBvi(clock, newReset.new_rst, uartClk);
`ifdef IncludeEthernet
//   let axiEthBvi <- mkAxiEthBvi(clock, host.tsys_clk_200mhz_buf, clock,
//				newReset.new_rst, newReset.new_rst, newReset.new_rst, newReset.new_rst, newReset.new_rst);
   let axiEthBvi <- AxiEthSubsystem::mkAxiEthBvi(clock, host.tsys_clk_200mhz_buf, reset_by newReset.new_rst);

`endif

   Reg#(Bit#(32)) objId <- mkReg(0);
   Reg#(Bit#(1))  iicResetReg <- mkReg(0);
   Reg#(Bit#(1))  eth_los <- mkReg(0);

   let irqLevel <- mkReg(0);
   let intrLevel <- mkReg(0);

   function Bit#(16) intr();
      Bit#(16) _intr = 0;
      _intr[0] = axiUartBvi.ip2intc_irpt();
      _intr[1] = axiEthBvi.s2mm_dma.introut(); // rx
      _intr[2] = axiEthBvi.mm2s_dma.introut(); // tx
`ifdef IncludeEthernet
      _intr[3] = axiEthBvi.mac.irq();
//      _intr[4] = axiEthBvi.interrupt();
`endif
      _intr[5] = axiIicBvi.iic2intc_irpt();
//      _intr[6] = axiSpiBvi.ip2intc_irpt();
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

   FIFOF#(BRAMRequest#(Bit#(32),Bit#(32))) reqFifo <- mkSizedFIFOF(4);
   FIFOF#(Bit#(32))                       dataFifo <- mkSizedFIFOF(16);

   Axi4MasterBits#(32,DataBusWidth,MemTagSize,Empty) m_axi_mm2s = toAxi4MasterBits(axiEthBvi.m_axi_mm2s);
   Axi4MasterBits#(32,DataBusWidth,MemTagSize,Empty) m_axi_s2mm = toAxi4MasterBits(axiEthBvi.m_axi_s2mm);
   Axi4MasterBits#(32,DataBusWidth,MemTagSize,Empty) m_axi_sg = toAxi4MasterBits(axiEthBvi.m_axi_sg);

   Axi4SlaveLiteBits#(12,32) axiUartSlaveLite = toAxi4SlaveBits(axiUartBvi.s_axi);
   PhysMemSlave#(12,32) axiUartMemSlave      <- mkPhysMemSlave(axiUartSlaveLite);

   Axi4SlaveLiteBits#(9,32) axiIntcSlaveLite = toAxi4SlaveBits(axiIntcBvi.s_axi);
   PhysMemSlave#(12,32) axiIntcMemSlave      <- mkPhysMemSlave(axiIntcSlaveLite);

   Axi4SlaveLiteBits#(9,32) axiIicSlaveLite  = toAxi4SlaveBits(axiIicBvi.s_axi);
   PhysMemSlave#(12,32) axiIicMemSlave       <- mkPhysMemSlave(axiIicSlaveLite);

//   Axi4SlaveLiteBits#(7,32) axiSpiSlaveLite  = toAxi4SlaveBits(axiSpiBvi.s_axi);
//   PhysMemSlave#(12,32) axiSpiMemSlave       <- mkPhysMemSlave(axiSpiSlaveLite);

`ifdef IncludeEthernet
   PhysMemSlave#(12,32) axiDmaMemSlave       <- mkPhysMemSlave(axiEthBvi.s_axi_dma);

   Axi4SlaveLiteBits#(12,32) axiEthSlaveLite = toAxi4SlaveBits(axiEthBvi.s_axi_mac);
   PhysMemSlave#(12,32) axiEthMemSlave       <- mkPhysMemSlave(axiEthSlaveLite);
   PhysMemSlave#(20,32) deviceSlaveMux       <- mkPhysMemSlaveMux(vec(axiUartMemSlave, axiIntcMemSlave, axiIicMemSlave,
								      axiDmaMemSlave, axiEthMemSlave)); // , axiSpiMemSlave
`else
   PhysMemSlave#(20,32) deviceSlaveMux       <- mkPhysMemSlaveMux(vec(axiUartMemSlave, axiIntcMemSlave, axiIicMemSlave));
`endif

   PhysMemSlave#(20,32) bootRomMemSlave      <- mkPhysMemSlaveFromBram(bootRom);
   PhysMemSlave#(21,32) memSlaveMux          <- mkPhysMemSlaveMux(vec(bootRomMemSlave, deviceSlaveMux));

   let memReadClients  <- mapM(mkMemReadClient(objId), vec(m_axi_mm2s, m_axi_sg));
   let memWriteClients <- mapM(mkMemWriteClient(objId), vec(m_axi_s2mm, m_axi_sg));

`ifdef IncludeFlash
   PhysMemSlave#(26,16) bpiFlashSlave <- mkPhysMemSlaveFromBram(bpiFlash.server);
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

`ifndef BOARD_miniitx100
   DiffClock sfp_rec_clk_buf <- mkClockOBUFDS(defaultValue, clocked_by clk_125mhz);
`endif
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

   // IOBUF spiSckIOBuf  <- mkIOBUF(axiSpiBvi.sck.t, axiSpiBvi.sck.o);
   // IOBUF spiSsIOBuf   <- mkIOBUF(axiSpiBvi.ss.t, axiSpiBvi.ss.o);
   // IOBUF spiMosiIOBuf <- mkIOBUF(axiSpiBvi.io0.t, axiSpiBvi.io0.o);
   // IOBUF spiMisoIOBuf <- mkIOBUF(axiSpiBvi.io1.t, axiSpiBvi.io1.o);
   // rule spi_o;
   //    axiSpiBvi.sck.i(spiSckIOBuf.o);
   //    axiSpiBvi.ss.i(spiSsIOBuf.o);
   //    axiSpiBvi.io0.i(spiMosiIOBuf.o);
   //    axiSpiBvi.io1.i(spiMisoIOBuf.o);
   // endrule

   // Probe#(Bit#(1)) spi_sck_i_probe <- mkProbe();
   // Probe#(Bit#(1)) spi_sck_o_probe <- mkProbe();
   // Probe#(Bit#(1)) spi_sck_t_probe <- mkProbe();
   // Probe#(Bit#(1)) spi_ss_i_probe <- mkProbe();
   // Probe#(Bit#(1)) spi_ss_o_probe <- mkProbe();
   // Probe#(Bit#(1)) spi_ss_t_probe <- mkProbe();
   // Probe#(Bit#(1)) spi_miso_i_probe <- mkProbe();
   // Probe#(Bit#(1)) spi_miso_o_probe <- mkProbe();
   // Probe#(Bit#(1)) spi_miso_t_probe <- mkProbe();
   // Probe#(Bit#(1)) spi_mosi_i_probe <- mkProbe();
   // Probe#(Bit#(1)) spi_mosi_o_probe <- mkProbe();
   // Probe#(Bit#(1)) spi_mosi_t_probe <- mkProbe();
   // rule rl_spi_trace;
   //    spi_sck_i_probe <= spiSckIOBuf.o;
   //    spi_sck_o_probe <= axiSpiBvi.sck.o;
   //    spi_sck_t_probe <= axiSpiBvi.sck.t;
   //    spi_ss_i_probe <= spiSsIOBuf.o;
   //    spi_ss_o_probe <= axiSpiBvi.ss.o;
   //    spi_ss_t_probe <= axiSpiBvi.ss.t;
   //    spi_miso_i_probe <= spiMisoIOBuf.o;
   //    spi_miso_o_probe <= axiSpiBvi.io1.o;
   //    spi_miso_t_probe <= axiSpiBvi.io1.t;
   //    spi_mosi_i_probe <= spiMosiIOBuf.o;
   //    spi_mosi_o_probe <= axiSpiBvi.io0.o;
   //    spi_mosi_t_probe <= axiSpiBvi.io0.t;
   // endrule


   FIFOF#(Tuple3#(DmaChannel,Bool,MemRequest)) traceFifo <- mkDualClockBramFIFOF(clock, reset, clock, reset);
   FIFOF#(Tuple3#(DmaChannel,Bool,MemRequest)) traceFifo0 <- mkFIFOF();
   FIFOF#(Tuple3#(DmaChannel,Bool,MemRequest)) traceFifo1 <- mkFIFOF();
   PipeIn#(Tuple3#(DmaChannel,Bool,MemRequest)) tracePipe = toPipeIn(traceFifo0);
   FIFOF#(Tuple3#(DmaChannel,Bool,MemData#(DataBusWidth))) traceDataFifo <- mkDualClockBramFIFOF(clock, reset, clock, reset);
   FIFOF#(Tuple3#(DmaChannel,Bool,MemData#(DataBusWidth))) traceDataFifo0 <- mkFIFOF();
   FIFOF#(Tuple3#(DmaChannel,Bool,MemData#(DataBusWidth))) traceDataFifo1 <- mkFIFOF();
   PipeIn#(Tuple3#(DmaChannel,Bool,MemData#(DataBusWidth))) traceDataPipe = toPipeIn(traceDataFifo0);
   let trace0Cnx <- mkConnection(toGet(traceFifo0), toPut(traceFifo));
   let trace1Cnx <- mkConnection(toGet(traceFifo), toPut(traceFifo1));
   rule rl_trace1;
      match { .chan, .write, .req } <- toGet(traceFifo1).get();
      ind.traceDmaRequest(chan, write, truncate(req.sglId), truncate(req.offset), extend(req.burstLen));
   endrule
   let traceData0Cnx <- mkConnection(toGet(traceDataFifo0), toPut(traceDataFifo));
   let traceData1Cnx <- mkConnection(toGet(traceDataFifo), toPut(traceDataFifo1));
   rule rl_trace_data;
      match { .chan, .write, .md } <- toGet(traceDataFifo1).get();
      ind.traceDmaData(chan, write, md.data, md.last);
   endrule

   let traceReadClients <- mapM(uncurry(mkTraceReadClient(tracePipe,traceDataPipe)),
				zip(vec(DMA_TX, DMA_SG),
				    memReadClients));
   let traceWriteClients <- mapM(uncurry(mkTraceWriteClient(tracePipe,traceDataPipe)),
				 zip(vec(DMA_RX, DMA_SG),
				     memWriteClients));

   interface SpikeHwRequest request;
      method Action reset();
	 newReset.assertReset();
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
		    pack(newReset.isAsserted),
`ifdef IncludeEthernet
		    axiEthBvi.mmcm.locked_out(), eth_los,
`else
		    0, eth_los,
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
`ifdef EthernetSgmii
	 interface AxiethbviSgmii sgmii = axiEthBvi.sgmii;
`else
	 interface AxiethbviSfp sfp = axiEthBvi.sfp;
`endif
         method Bit#(1) tx_disable();
	    return 0;
	 endmethod
         method Action rx_los(Bit#(1) v);
            eth_los <= v;
	 endmethod
      endinterface
`else
      interface EthPins eth;
         method Bit#(1) tx_disable();
	    return 0;
	 endmethod
         method Action rx_los(Bit#(1) v);
            eth_los <= v;
	 endmethod
      endinterface
`endif
`ifdef IncludeFlash
      interface flash = bpiFlash.flash;
`endif
      interface SpikeUartPins uart;
`ifndef BOARD_miniitx100
	 method tx  = axiUartBvi.sout;
	 method rx  = axiUartBvi.sin;
`endif
`ifdef UART_HAX_RTS_CTS
	 method rts = axiUartBvi.rtsn;
	 method cts = axiUartBvi.ctsn;
`endif
      endinterface   
      interface SpikeIicPins iic;
         interface scl = sclIOBuf.io;
         interface sda = sdaIOBuf.io;
	 method mux_reset = iicResetReg;
      endinterface
      // interface SpikeSpiPins spi;
      //    interface sck  = spiSckIOBuf.io;
      //    interface ss   = spiSsIOBuf.io;
      //    interface miso = spiMisoIOBuf.io;
      //    interface mosi = spiMosiIOBuf.io;
      // endinterface
      interface Clock deleteme_unused_clock = clock;
      interface Reset deleteme_unused_reset = reset;
`ifndef BOARD_miniitx100
      interface Clock sfp_rec_clk_p = sfp_rec_clk_buf.p;
      interface Clock sfp_rec_clk_n = sfp_rec_clk_buf.n;
`endif
   endinterface

   interface Vector dmaReadClient = traceReadClients;
   interface Vector dmaWriteClient = traceWriteClients;
endmodule
