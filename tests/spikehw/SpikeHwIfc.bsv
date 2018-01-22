
import BuildVector::*;
import Clocks::*;
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
import ConnectalMemTypes::*;
import Pipe::*;
import AxiBits::*;
import PhysMemSlaveFromBram::*;

import BpiFlash::*;
import AxiIntcBvi::*;
import AxiIic::*;
import AxiUart::*;
`ifdef EthernetSgmii
import AxiEthBvi::*;
`else
import AxiEth1000BaseX::*;
`endif
import AxiDmaBvi::*;
import SpikeHwPins::*;

`include "ConnectalProjectConfig.bsv"

typedef enum { DMA_RX, DMA_TX, DMA_SG } DmaChannel deriving (Bits,Eq);

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
   method Action status(Bit#(1) reset_asserted, Bit#(1) mmcm_locked, Bit#(1) rx_los, Bit#(1) irq, Bit#(16) intrSources);
   method Action traceDmaRequest(DmaChannel channel, Bool write, Bit#(16) objId, Bit#(32) offset, Bit#(16) burstLen);
   method Action traceDmaData(DmaChannel channel, Bool write, Bit#(32) data, Bool last);
endinterface
