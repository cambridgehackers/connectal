// Copyright (c) 2016 Connectal Project

// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use, copy,
// modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
// BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
// ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

`include "ConnectalProjectConfig.bsv"
import FIFOF::*;
import BRAMFIFO::*;
import GetPut::*;
import Clocks::*;
import Connectable::*;
import StmtFSM::*;
`define PROBE_ME
`ifdef PROBE_ME
import Probe::*;
`else
interface Probe#(type a);
   method Action _write(a v);
endinterface   
module mkProbe(Probe#(a));
   method Action _write(a v);
   endmethod
endmodule
`endif
import Vector::*;

import AxiBits::*;
import AxiStream::*;
import AxiEthBufferBvi::*;
import TriModeMacBvi::*;
import GigEthPcsPmaBvi::*;
import AxiEth1000BaseX::*;
import SyncAxisFifo32x1024::*;
import AxiDmaBvi::*;

interface AxiEthSubsystem;
   interface AxidmabviMm2s     mm2s_dma;
   interface AxidmabviS2mm     s2mm_dma;
   interface AxidmabviM_axi_mm2s     m_axi_mm2s;
   interface AxidmabviM_axi_s2mm     m_axi_s2mm;
   interface AxidmabviM_axi_sg       m_axi_sg;

   interface Axi4SlaveLiteBits#(10,32) s_axi_dma;

   interface TrimodemacS_axi s_axi_mac;
   interface TrimodemacMac mac;
   interface AxiethbviSfp sfp;
   interface AxiethbviMgt mgt;
   interface GigethpcspmabviSignal signal;
   interface GigethpcspmabviMmcm mmcm;
endinterface

instance Connectable#(TrimodemacGmii,GigethpcspmabviGmii);
   module mkConnection#(TrimodemacGmii mac, GigethpcspmabviGmii phy)(Empty);
      rule rx;
	 mac.rx_dv(phy.rx_dv());
	 mac.rx_er(phy.rx_er());
	 mac.rxd(phy.rxd());
      endrule
      rule tx;
	 phy.tx_en(mac.tx_en());
	 phy.tx_er(mac.tx_er());
	 phy.txd(mac.txd());
      endrule
   endmodule
endinstance

instance Connectable#(TrimodemacMdio,GigethpcspmabviMdio);
   module mkConnection#(TrimodemacMdio macMdio, GigethpcspmabviMdio phyMdio)(Empty);
      rule rl_mdio;
	 macMdio.i(phyMdio.o());
	 phyMdio.i(macMdio.o());
      endrule
   endmodule
endinstance

instance Connectable#(TriModeMac,GigEthPcsPma);
   module mkConnection#(TriModeMac mac, GigEthPcsPma phy)(Empty);
      let mdcCnx  <- mkConnection(phy.mdc,  mac.mdc); // should be a clock, but PHY is providing a clock to MAC and this would make a cycle
      let mdioCnx <- mkConnection(mac.mdio, phy.mdio);
      let gmiiCnx <- mkConnection(mac.gmii, phy.gmii);
   endmodule
endinstance

module mkStreamControlConnection#(AxiStreamMaster#(32) from, AxiStreamMaster#(32) cntrl,
				  TrimodemacTx_axis_mac to,
				  Clock fromClock, Reset fromReset, Clock toClock, Reset toReset)(Empty);
   let sfifo <- mkSyncAxisFifo32x1024(fromClock, fromReset, toClock, toReset);

   Reg#(Bit#(2)) phaseReg <- mkReg(0, clocked_by toClock, reset_by toReset);

   Probe#(Bit#(32)) fromControlDataProbe <- mkProbe(clocked_by fromClock, reset_by fromReset);
   Probe#(Bit#(1)) fromControlValidProbe <- mkProbe(clocked_by fromClock, reset_by fromReset);

   Probe#(Bit#(32)) fromDataProbe <- mkProbe(clocked_by toClock, reset_by toReset);
   Probe#(Bit#(4)) fromKeepProbe <- mkProbe(clocked_by toClock, reset_by toReset);
   Probe#(Bit#(1)) fromLastProbe <- mkProbe(clocked_by toClock, reset_by toReset);

   Probe#(Bit#(8)) toDataProbe <- mkProbe(clocked_by toClock, reset_by toReset);
   Probe#(Bit#(4)) toKeepProbe <- mkProbe(clocked_by toClock, reset_by toReset);
   Probe#(Bit#(1)) toLastProbe <- mkProbe(clocked_by toClock, reset_by toReset);
   Probe#(Bit#(1)) toValidProbe <- mkProbe(clocked_by toClock, reset_by toReset);

   Probe#(Bit#(2)) phaseProbe    <- mkProbe(clocked_by toClock, reset_by toReset);
   Probe#(Bit#(4)) moreDataProbe <- mkProbe(clocked_by toClock, reset_by toReset);

   rule rl_control if (cntrl.tvalid() == 1);
      fromControlDataProbe <= cntrl.tdata();
      fromControlValidProbe <= cntrl.tvalid();
   endrule

   let fromCnx <- mkConnection(from, sfifo.s_axis);

   Wire#(Bool) doDeq <- mkDWire(False, clocked_by toClock, reset_by toReset);
   rule rl_expand if (to.tready() == 1 && sfifo.m_axis.tvalid() == 1);

      fromDataProbe <= sfifo.m_axis.tdata();
      fromKeepProbe <= sfifo.m_axis.tkeep();
      fromLastProbe <= sfifo.m_axis.tlast();

      Vector#(4,Bit#(8)) data = unpack(sfifo.m_axis.tdata());
      let keep = sfifo.m_axis.tkeep();
      let last = sfifo.m_axis.tlast();
      //match { .data, .keep, .last } = sfifo.first();
      let phase = phaseReg;
      Bool lastPhase = (phaseReg == 3);
      Bit#(4) moreData = keep[3:phase+1];
      if (!lastPhase)
	 lastPhase = (moreData == 0);

      to.tdata(data[phase]);
      //to.tkeep(keep[phase]);
      to.tlast(pack(last == 1 && lastPhase));

      toDataProbe <= data[phase];
      toLastProbe <= pack(last == 1 && lastPhase);

      if (lastPhase) begin
	 //sfifo.deq();
	 doDeq <= True;
	 phase = 0;
      end
      else begin
	 phase = phase + 1;
      end
      phaseReg <= phase;

      phaseProbe <= phase;
      moreDataProbe <= moreData;
   endrule

   rule rl_to_handshake;
      to.tvalid(sfifo.m_axis.tvalid());
      toValidProbe <= sfifo.m_axis.tvalid();
      sfifo.m_axis.tready(pack(doDeq));
   endrule
endmodule

module mkStreamStatusConnection#(TrimodemacRx_axis_mac from,
				 AxiStreamSlave#(32) to, AxiStreamSlave#(32) status,
				 Clock fromClock, Reset fromReset, Clock toClock, Reset toReset)(Empty);

   Reg#(Bit#(16)) byteCountReg <- mkReg(0, clocked_by fromClock, reset_by fromReset);
   Reg#(Bit#(2)) phaseReg <- mkReg(0, clocked_by fromClock, reset_by fromReset);
   Vector#(4,Reg#(Bit#(8))) dataReg <- replicateM(mkReg(0), clocked_by fromClock, reset_by fromReset);
   Reg#(Bit#(4)) keepReg <- mkReg(0, clocked_by fromClock, reset_by fromReset);
   let sfifo <- mkSyncAxisFifo32x1024(fromClock, fromReset, toClock, toReset);
   let stsfifo <- mkSyncAxisFifo32x1024(fromClock, fromReset, toClock, toReset);

   Wire#(Bool) doEnq <- mkDWire(False, clocked_by fromClock, reset_by fromReset);

   Probe#(Bool) probeOverrun <- mkProbe(clocked_by fromClock, reset_by fromReset);
   Probe#(Bit#(1)) fromValidProbe <- mkProbe(clocked_by fromClock, reset_by fromReset);
   Probe#(Bit#(8)) fromDataProbe <- mkProbe(clocked_by fromClock, reset_by fromReset);
   Probe#(Bit#(1)) fromLastProbe <- mkProbe(clocked_by fromClock, reset_by fromReset);
   Probe#(Bit#(32)) toDataProbe <- mkProbe(clocked_by fromClock, reset_by fromReset);
   Probe#(Bit#(4)) toKeepProbe <- mkProbe(clocked_by fromClock, reset_by fromReset);
   Probe#(Bit#(2)) phaseProbe    <- mkProbe(clocked_by fromClock, reset_by fromReset);
   Probe#(Bit#(1)) toReadyProbe <- mkProbe(clocked_by toClock, reset_by toReset);
   Probe#(Bit#(16)) byteCountProbe    <- mkProbe(clocked_by fromClock, reset_by fromReset);

   FIFOF#(Bit#(16)) lengthFifo <- mkFIFOF(clocked_by fromClock, reset_by fromReset);
   Wire#(Bit#(32)) statusDataWire <- mkDWire(0, clocked_by fromClock, reset_by fromReset);
   Wire#(Bit#(1))  statusLastWire <- mkDWire(0, clocked_by fromClock, reset_by fromReset);
   Wire#(Bit#(1))  statusValidWire <- mkDWire(0, clocked_by fromClock, reset_by fromReset);

   Probe#(Bit#(32)) statusDataProbe <- mkProbe(clocked_by fromClock, reset_by fromReset);
   Probe#(Bit#(1))  statusLastProbe <- mkProbe(clocked_by fromClock, reset_by fromReset);
   Probe#(Bit#(1))  statusValidProbe <- mkProbe(clocked_by fromClock, reset_by fromReset);
   let stsFsm <- mkAutoFSM((seq
			    while (True) seq
			      await (lengthFifo.notEmpty && stsfifo.s_axis.tready==1);
			      action // status word
				 statusDataWire <= 32'h80000000 | extend(lengthFifo.first);
				 statusLastWire <= 0;
				 statusValidWire <= 1;
			      endaction
			      await (stsfifo.s_axis.tready==1);
			      action // app0
				 statusDataWire <= 0;
				 statusLastWire <= 0;
				 statusValidWire <= 1;
			      endaction
			      await (stsfifo.s_axis.tready==1);
			      action // app1
				 statusDataWire <= 1;
				 statusLastWire <= 0;
				 statusValidWire <= 1;
			      endaction
			      await (stsfifo.s_axis.tready==1);
			      action // app2
				 statusDataWire <= 2;
				 statusLastWire <= 0;
				 statusValidWire <= 1;
			      endaction
			      await (stsfifo.s_axis.tready==1);
			      action // app3
				 statusDataWire <= 3;
				 statusLastWire <= 0;
				 statusValidWire <= 1;
			      endaction
			      await (stsfifo.s_axis.tready==1);
			      action // app4
				 statusDataWire <= extend(lengthFifo.first);
				 statusLastWire <= 0;
				 statusValidWire <= 1;
				 lengthFifo.deq();
			      endaction
			    endseq // while
			   endseq),
			   clocked_by fromClock, reset_by fromReset);
   rule rl_status_handshake;

      if (statusValidWire == 1) begin
	 statusValidProbe <= 1;
	 statusDataProbe <= statusDataWire;
	 statusLastProbe <= statusLastWire;
      end

      stsfifo.s_axis.tvalid(statusValidWire);
      stsfifo.s_axis.tdata(statusDataWire);
      stsfifo.s_axis.tlast(statusLastWire);
      stsfifo.s_axis.tkeep(maxBound);
   endrule

   rule rl_overrun if (from.tvalid() == 1 && sfifo.s_axis.tready() == 0);
      probeOverrun <= True;
   endrule

   rule rl_from_valid;
      fromValidProbe <= from.tvalid();
   endrule

   rule rl_combine if (unpack(from.tvalid()));
      phaseProbe <= phaseReg;

      Bool last = unpack(from.tlast());
      let byteCount = byteCountReg + 1;
      let phase = phaseReg;
      Vector#(4,Bit#(8)) data = readVReg(dataReg);
      let keep = keepReg;
      keep[phase] = 1; //from.tkeep();
      data[phase] = from.tdata();

      sfifo.s_axis.tdata(pack(data));
      sfifo.s_axis.tkeep(keep);
      sfifo.s_axis.tlast(pack(last));

      byteCountProbe <= byteCount;

      if (last || (phaseReg == 3)) begin

	 toKeepProbe <= keep;
	 toDataProbe <= pack(data);
	 fromLastProbe <= pack(last); //from.tlast();

	 phase = 0;
	 data  = unpack(0);
	 keep  = 0;
	 doEnq <= True;
	 //sfifo.enq(tuple3(pack(data), keep, pack(last)));
      end
      else begin
	 phase = phase + 1;
      end

      if (last) begin
	 byteCount = 0;
	 lengthFifo.enq(byteCount);
      end

      byteCountReg <= byteCount;
      phaseReg <= phase;
      writeVReg(dataReg, data);
      keepReg  <= keep;

      fromDataProbe <= from.tdata();

   endrule

   rule rl_from_handshake;
      //from.tready(pack(sfifo.s_axis.tready())); // scary -- no backpressure
      sfifo.s_axis.tvalid(pack(doEnq));
   endrule

   rule rl_to_ready_probe;
      toReadyProbe <= to.tready();
   endrule	 

   let toCnx <- mkConnection(sfifo.m_axis, to);
   let stsCnx <- mkConnection(stsfifo.m_axis, status);
endmodule

(* synthesize *)
module mkAxiEthBvi#(Clock axis_clk, Clock ref_clk)(AxiEthSubsystem);
   let clock <- exposeCurrentClock;
   let reset <- exposeCurrentReset;

  // connect_bd_net -net eth_buf_RESET2PCSPMA [get_bd_pins eth_buf/RESET2PCSPMA] [get_bd_pins pcs_pma/reset] //FIXME
//   let resetToPcsPma <- mkReset(10, True, ref_clk);

   let pcs <- mkGigEthPcsPmaBvi(ref_clk, reset);
  // connect_bd_net -net pcs_pma_userclk2_out [get_bd_ports userclk2_out] [get_bd_pins eth_buf/GTX_CLK] [get_bd_pins eth_mac/gtx_clk] [get_bd_pins pcs_pma/userclk2_out]
   Clock gtx_clk = pcs.userclk2.out;

   let trimodemac <- mkTriModeMacBvi(gtx_clk, axis_clk, reset, reset, reset, reset);

  // connect_bd_intf_net -intf_net eth_mac_gmii [get_bd_intf_pins eth_mac/gmii] [get_bd_intf_pins pcs_pma/gmii_pcs_pma]
   let gmiiConnection <- mkConnection(trimodemac.gmii, pcs.gmii);

  // connect_bd_net -net eth_mac_mdc [get_bd_pins eth_mac/mdc] [get_bd_pins pcs_pma/mdc]
   rule rl_misc;
      pcs.mdc(trimodemac.mdc()); // actually a clock
   endrule
  // connect_bd_net -net eth_mac_mdio_o [get_bd_pins eth_mac/mdio_o] [get_bd_pins pcs_pma/mdio_i]
  // connect_bd_net -net pcs_pma_mdio_o [get_bd_pins eth_mac/mdio_i] [get_bd_pins pcs_pma/mdio_o]
  let mdioConnection <- mkConnection(trimodemac.mdio, pcs.mdio);

  // connect_bd_net -net reset_inv_Res [get_bd_pins eth_mac/glbl_rstn] [get_bd_pins eth_mac/rx_axi_rstn] [get_bd_pins eth_mac/tx_axi_rstn] [get_bd_pins reset_inv/Res]


   // ports:
   // connect_bd_intf_net -intf_net eth_mac_rx_statistics [get_bd_intf_ports rx_statistics] [get_bd_intf_pins eth_mac/rx_statistics]
   // connect_bd_intf_net -intf_net eth_mac_tx_statistics [get_bd_intf_ports tx_statistics] [get_bd_intf_pins eth_mac/tx_statistics]
   // connect_bd_intf_net -intf_net mgt_clk_1 [get_bd_intf_ports mgt_clk] [get_bd_intf_pins pcs_pma/gtrefclk_in]
   // connect_bd_intf_net -intf_net pcs_pma_sfp [get_bd_intf_ports sfp] [get_bd_intf_pins pcs_pma/sfp]
   // connect_bd_intf_net -intf_net s_axi_1 [get_bd_intf_ports s_axi] [get_bd_intf_pins eth_mac/s_axi]
   // connect_bd_intf_net -intf_net s_axis_pause_1 [get_bd_intf_ports s_axis_pause] [get_bd_intf_pins eth_mac/s_axis_pause]
   // connect_bd_intf_net -intf_net s_axis_tx_1 [get_bd_intf_ports s_axis_tx] [get_bd_intf_pins eth_mac/s_axis_tx]
   // connect_bd_net -net eth_mac_mac_irq [get_bd_ports mac_irq] [get_bd_pins eth_mac/mac_irq]
   // connect_bd_net -net eth_mac_rx_axis_filter_tuser [get_bd_ports rx_axis_filter_tuser] [get_bd_pins eth_mac/rx_axis_filter_tuser]
   // connect_bd_net -net eth_mac_rx_mac_aclk [get_bd_ports rx_mac_aclk] [get_bd_pins eth_mac/rx_mac_aclk]
   // connect_bd_net -net eth_mac_rx_reset [get_bd_ports rx_reset] [get_bd_pins eth_mac/rx_reset]
   // connect_bd_net -net eth_mac_tx_mac_aclk [get_bd_ports tx_mac_aclk] [get_bd_pins eth_mac/tx_mac_aclk]
   // connect_bd_net -net eth_mac_tx_reset [get_bd_ports tx_reset] [get_bd_pins eth_mac/tx_reset]
   // connect_bd_net -net glbl_rst_1 [get_bd_ports glbl_rst] [get_bd_pins pcs_pma/reset] [get_bd_pins reset_inv/Op1]
   // connect_bd_net -net pcs_pma_gt0_qplloutclk_out [get_bd_ports gt0_qplloutclk_out] [get_bd_pins pcs_pma/gt0_qplloutclk_out]
   // connect_bd_net -net pcs_pma_gt0_qplloutrefclk_out [get_bd_ports gt0_qplloutrefclk_out] [get_bd_pins pcs_pma/gt0_qplloutrefclk_out]
   // connect_bd_net -net pcs_pma_gtrefclk_bufg_out [get_bd_ports gtref_clk_buf_out] [get_bd_pins pcs_pma/gtrefclk_bufg_out]
   // connect_bd_net -net pcs_pma_gtrefclk_out [get_bd_ports gtref_clk_out] [get_bd_pins pcs_pma/gtrefclk_out]
   // connect_bd_net -net pcs_pma_mmcm_locked_out [get_bd_ports mmcm_locked_out] [get_bd_pins pcs_pma/mmcm_locked_out]
   // connect_bd_net -net pcs_pma_pma_reset_out [get_bd_ports pma_reset_out] [get_bd_pins pcs_pma/pma_reset_out]
   // connect_bd_net -net pcs_pma_rxuserclk2_out [get_bd_ports rxuserclk2_out] [get_bd_pins pcs_pma/rxuserclk2_out]
   // connect_bd_net -net pcs_pma_rxuserclk_out [get_bd_ports rxuserclk_out] [get_bd_pins pcs_pma/rxuserclk_out]
   // connect_bd_net -net pcs_pma_status_vector [get_bd_ports status_vector] [get_bd_pins pcs_pma/status_vector]
   // connect_bd_net -net pcs_pma_userclk2_out [get_bd_ports userclk2_out] [get_bd_pins eth_mac/gtx_clk] [get_bd_pins pcs_pma/userclk2_out]
   // connect_bd_net -net pcs_pma_userclk_out [get_bd_ports userclk_out] [get_bd_pins pcs_pma/userclk_out]
   // connect_bd_net -net ref_clk_1 [get_bd_ports ref_clk] [get_bd_pins pcs_pma/independent_clock_bufg]
   // connect_bd_intf_net -intf_net eth_mac_m_axis_rx [get_bd_intf_ports m_axis_rx] [get_bd_intf_pins eth_mac/m_axis_rx]
   // connect_bd_net -net s_axi_lite_clk_1 [get_bd_ports s_axi_lite_clk] [get_bd_pins eth_mac/s_axi_aclk]
   // connect_bd_net -net s_axi_lite_resetn_1 [get_bd_ports s_axi_lite_resetn] [get_bd_pins eth_mac/s_axi_resetn]
   // connect_bd_net -net signal_detect_1 [get_bd_ports signal_detect] [get_bd_pins pcs_pma/signal_detect]
   // connect_bd_net -net tx_ifg_delay_1 [get_bd_ports tx_ifg_delay] [get_bd_pins eth_mac/tx_ifg_delay]

   let axiDmaBvi <- mkAxiDmaBvi(clock,clock,clock,clock,reset);

   // packet data and status from the ethernet
   let rxResetInverted <- mkResetInverter(trimodemac.rx.reset, clocked_by trimodemac.rx.mac_aclk);
   let rxCnx <- mkStreamStatusConnection(trimodemac.rx_axis_mac, axiDmaBvi.s_axis_s2mm, axiDmaBvi.s_axis_s2mm_sts,
					 trimodemac.rx.mac_aclk, rxResetInverted, clock, reset);
   //mkConnection(axiEthBvi.m_axis_rxs, axiDmaBvi.s_axis_s2mm_sts);

   // packet data and control to the ethernet
   let txResetInverted <- mkResetInverter(trimodemac.tx.reset, clocked_by trimodemac.tx.mac_aclk);
   let txCnx <- mkStreamControlConnection(axiDmaBvi.m_axis_mm2s, axiDmaBvi.m_axis_mm2s_cntrl,
					  trimodemac.tx_axis_mac,
					  clock, reset, trimodemac.tx.mac_aclk, txResetInverted);
   //mkConnection(axiDmaBvi.m_axis_mm2s_cntrl, axiEthBvi.s_axis_txc);
   interface   mm2s_dma = axiDmaBvi.mm2s;
   interface   s2mm_dma = axiDmaBvi.s2mm;
   interface m_axi_mm2s = axiDmaBvi.m_axi_mm2s;
   interface m_axi_s2mm = axiDmaBvi.m_axi_s2mm;
   interface m_axi_sg   = axiDmaBvi.m_axi_sg;

   interface  s_axi_dma = axiDmaBvi.s_axi_lite;

   interface  s_axi_mac = trimodemac.s_axi;
   interface        mac = trimodemac.mac;

   interface signal = pcs.signal;
   interface mmcm = pcs.mmcm;
   interface AxiethbviMgt mgt;
      method clk_clk_p = pcs.gtrefclk.p;
      method clk_clk_n = pcs.gtrefclk.n;
   endinterface
   interface AxiethbviSfp sfp;
      method txp = pcs.txp;
      method txn = pcs.txn;
      method rxp = pcs.rxp;
      method rxn = pcs.rxn;
   endinterface
endmodule
