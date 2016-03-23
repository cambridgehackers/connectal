
import GetPut::*;
import Clocks::*;
import Connectable::*;
import AxiBits::*;
import AxiStream::*;
import AxiEthBufferBvi::*;
import TriModeEthMacBvi::*;
import GigEthPcsPmaBvi::*;
import AxiEth1000BaseX::*;

interface AxiEthSubsystem;
   interface AxiStreamMaster#(32) m_axis_rxd;
   interface AxiStreamMaster#(32) m_axis_rxs;
   interface AxiStreamSlave#(32)  s_axis_txd;
   interface AxiStreamSlave#(32)  s_axis_txc;
   interface TrimodeethbviS_axi s_axi;
   interface TrimodeethbviMac mac;
   interface AxiethbviSfp sfp;
   interface AxiethbviMgt mgt;
   interface GigethpcspmabviSignal signal;
   interface GigethpcspmabviMmcm mmcm;
endinterface

module mkAxiEthBvi#(Clock axis_clk, Clock ref_clk)(AxiEthSubsystem);
   let reset <- exposeCurrentReset;

  // connect_bd_net -net eth_buf_RESET2PCSPMA [get_bd_pins eth_buf/RESET2PCSPMA] [get_bd_pins pcs_pma/reset] //FIXME
//   let resetToPcsPma <- mkReset(10, True, ref_clk);

   let pcs <- mkGigEthPcsPmaBvi(ref_clk, reset);
  // connect_bd_net -net pcs_pma_userclk2_out [get_bd_ports userclk2_out] [get_bd_pins eth_buf/GTX_CLK] [get_bd_pins eth_mac/gtx_clk] [get_bd_pins pcs_pma/userclk2_out]
   Clock gtx_clk = pcs.userclk2.out;

   let trimodemac <- mkTriModeMacBvi(gtx_clk, axis_clk, reset, reset, reset);

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


   interface m_axis_rxd = buffer.axi_str_rxd;
   //interface m_axis_rxs = buffer.axi_str_rxs;
   interface s_axis_txd = buffer.axi_str_txd;
   //interface s_axis_txc = buffer.axi_str_txc;
   interface s_axi = trimodemac.s_axi;
   interface mac   = trimodemac.mac;

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
