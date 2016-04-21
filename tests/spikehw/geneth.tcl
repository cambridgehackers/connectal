
set ipdir {cores}

set boardname {nfsume}
#set boardname {miniitx100}

if {$boardname == {nfsume}} {
    set partname {xc7vx690tffg1761-2}
    set databuswidth 32
}
if {$boardname == {miniitx100}} {
    set partname {xc7z100ffg900-2}
    set databuswidth 64
}

file mkdir $ipdir/$boardname

create_project -name local_synthesized_ip -in_memory -part $partname
set_property board_part xilinx.com:vc709:part0:1.0 [current_project]

################################################################
# This is a generated script based on design: bd_0
#
# Though there are limitations about the generated script,
# the main purpose of this utility is to make learning
# IP Integrator Tcl commands easier.
################################################################


################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source bd_0_script.tcl

# If you do not already have a project created,
# you can create a project using the following command:
#    create_project project_1 myproj -part xc7vx690tffg1761-2
#    set_property BOARD_PART xilinx.com:vc709:part0:1.0 [current_project]

# CHECKING IF PROJECT EXISTS
if { [get_projects -quiet] eq "" } {
   puts "ERROR: Please open or create a project!"
   return 1
}



# CHANGE DESIGN NAME HERE
set design_name bd_0

# This script was generated for a remote BD.
set str_bd_folder /home/jamey/connectal.clean/tests/spikehw/cores/nfsume/foo_eth
set str_bd_filepath ${str_bd_folder}/${design_name}/${design_name}.bd

# Check if remote design exists on disk
if { [file exists $str_bd_filepath ] == 1 } {
   puts "ERROR: The remote BD file path <$str_bd_filepath> already exists!\n"

   puts "INFO: Please modify the variable <str_bd_folder> to another path or modify the variable <design_name>."

   return 1
}

# Check if design exists in memory
set list_existing_designs [get_bd_designs -quiet $design_name]
if { $list_existing_designs ne "" } {
   puts "ERROR: The design <$design_name> already exists in this project!"
   puts "ERROR: Will not create the remote BD <$design_name> at the folder <$str_bd_folder>.\n"

   puts "INFO: Please modify the variable <design_name>."

   return 1
}

# Check if design exists on disk within project
set list_existing_designs [get_files */${design_name}.bd]
if { $list_existing_designs ne "" } {
   puts "ERROR: The design <$design_name> already exists in this project at location:"
   puts "   $list_existing_designs"
   puts "ERROR: Will not create the remote BD <$design_name> at the folder <$str_bd_folder>.\n"

   puts "INFO: Please modify the variable <design_name>."

   return 1
}

# Now can create the remote BD
create_bd_design -dir $str_bd_folder $design_name
current_bd_design $design_name

##################################################################
# DESIGN PROCs
##################################################################



# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     puts "ERROR: Unable to find parent cell <$parentCell>!"
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     puts "ERROR: Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports
  set m_axis_rxd [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 m_axis_rxd ]
  set m_axis_rxs [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 m_axis_rxs ]
  set mgt_clk [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 mgt_clk ]
  set_property -dict [ list \
CONFIG.BOARD.ASSOCIATED_PARAM {DIFFCLK_BOARD_INTERFACE} \
 ] $mgt_clk
  set s_axi [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi ]
  set_property -dict [ list \
CONFIG.PROTOCOL {AXI4LITE} \
 ] $s_axi
  set s_axis_txc [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 s_axis_txc ]
  set s_axis_txd [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 s_axis_txd ]
  set sfp [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:sfp_rtl:1.0 sfp ]
  set_property -dict [ list \
CONFIG.BOARD.ASSOCIATED_PARAM {ETHERNET_BOARD_INTERFACE} \
 ] $sfp

  # Create ports
  set axi_rxd_arstn [ create_bd_port -dir I -type rst axi_rxd_arstn ]
  set_property -dict [ list \
CONFIG.POLARITY {ACTIVE_LOW} \
 ] $axi_rxd_arstn
  set axi_rxs_arstn [ create_bd_port -dir I -type rst axi_rxs_arstn ]
  set_property -dict [ list \
CONFIG.POLARITY {ACTIVE_LOW} \
 ] $axi_rxs_arstn
  set axi_txc_arstn [ create_bd_port -dir I -type rst axi_txc_arstn ]
  set_property -dict [ list \
CONFIG.POLARITY {ACTIVE_LOW} \
 ] $axi_txc_arstn
  set axi_txd_arstn [ create_bd_port -dir I -type rst axi_txd_arstn ]
  set_property -dict [ list \
CONFIG.POLARITY {ACTIVE_LOW} \
 ] $axi_txd_arstn
  set axis_clk [ create_bd_port -dir I -type clk axis_clk ]
  set gt0_qplloutclk_out [ create_bd_port -dir O -type clk gt0_qplloutclk_out ]
  set gt0_qplloutrefclk_out [ create_bd_port -dir O -type clk gt0_qplloutrefclk_out ]
  set gtref_clk_buf_out [ create_bd_port -dir O -type clk gtref_clk_buf_out ]
  set_property -dict [ list \
CONFIG.FREQ_HZ {125000000} \
 ] $gtref_clk_buf_out
  set gtref_clk_out [ create_bd_port -dir O -type clk gtref_clk_out ]
  set_property -dict [ list \
CONFIG.FREQ_HZ {125000000} \
 ] $gtref_clk_out
  set interrupt [ create_bd_port -dir O -type intr interrupt ]
  set_property -dict [ list \
CONFIG.SENSITIVITY {LEVEL_HIGH} \
 ] $interrupt
  set mac_irq [ create_bd_port -dir O -type intr mac_irq ]
  set_property -dict [ list \
CONFIG.SENSITIVITY {EDGE_RISING} \
 ] $mac_irq
  set mmcm_locked_out [ create_bd_port -dir O mmcm_locked_out ]
  set pma_reset_out [ create_bd_port -dir O -type rst pma_reset_out ]
  set_property -dict [ list \
CONFIG.POLARITY {ACTIVE_HIGH} \
 ] $pma_reset_out
  set ref_clk [ create_bd_port -dir I -type clk ref_clk ]
  set rxuserclk2_out [ create_bd_port -dir O -type clk rxuserclk2_out ]
  set_property -dict [ list \
CONFIG.FREQ_HZ {62500000} \
 ] $rxuserclk2_out
  set rxuserclk_out [ create_bd_port -dir O -type clk rxuserclk_out ]
  set_property -dict [ list \
CONFIG.FREQ_HZ {62500000} \
 ] $rxuserclk_out
  set s_axi_lite_clk [ create_bd_port -dir I -type clk s_axi_lite_clk ]
  set s_axi_lite_resetn [ create_bd_port -dir I -type rst s_axi_lite_resetn ]
  set_property -dict [ list \
CONFIG.POLARITY {ACTIVE_LOW} \
 ] $s_axi_lite_resetn
  set signal_detect [ create_bd_port -dir I signal_detect ]
  set userclk2_out [ create_bd_port -dir O -type clk userclk2_out ]
  set_property -dict [ list \
CONFIG.FREQ_HZ {125000000} \
 ] $userclk2_out
  set userclk_out [ create_bd_port -dir O -type clk userclk_out ]
  set_property -dict [ list \
CONFIG.FREQ_HZ {62500000} \
 ] $userclk_out

  # Create instance: eth_buf, and set properties
  set eth_buf [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_ethernet_buffer:2.0 eth_buf ]
  set_property -dict [ list \
CONFIG.C_AVB {0} \
CONFIG.C_PHYADDR {1} \
CONFIG.C_PHY_TYPE {5} \
CONFIG.C_STATS {1} \
CONFIG.C_TYPE {1} \
CONFIG.ENABLE_LVDS {0} \
CONFIG.HAS_SGMII {true} \
CONFIG.MCAST_EXTEND {false} \
CONFIG.RXCSUM {None} \
CONFIG.RXMEM {4k} \
CONFIG.RXVLAN_STRP {false} \
CONFIG.RXVLAN_TAG {false} \
CONFIG.RXVLAN_TRAN {false} \
CONFIG.SIMULATION_MODE {false} \
CONFIG.TXCSUM {None} \
CONFIG.TXMEM {4k} \
CONFIG.TXVLAN_STRP {false} \
CONFIG.TXVLAN_TAG {false} \
CONFIG.TXVLAN_TRAN {false} \
CONFIG.USE_BOARD_FLOW {true} \
CONFIG.enable_1588 {0} \
 ] $eth_buf

  # Create instance: eth_mac, and set properties
  set eth_mac [ create_bd_cell -type ip -vlnv xilinx.com:ip:tri_mode_ethernet_mac:9.0 eth_mac ]
  set_property -dict [ list \
CONFIG.Data_Rate {1_Gbps} \
CONFIG.ETHERNET_BOARD_INTERFACE {Custom} \
CONFIG.Enable_1588 {false} \
CONFIG.Enable_1588_1step {false} \
CONFIG.Enable_AVB {false} \
CONFIG.Enable_MDIO {true} \
CONFIG.Enable_Priority_Flow_Control {false} \
CONFIG.Frame_Filter {true} \
CONFIG.Half_Duplex {false} \
CONFIG.MAC_Speed {1000_Mbps} \
CONFIG.MDIO_BOARD_INTERFACE {Custom} \
CONFIG.Make_MDIO_External {false} \
CONFIG.Management_Interface {true} \
CONFIG.Number_of_Table_Entries {4} \
CONFIG.Physical_Interface {Internal} \
CONFIG.RX_Inband_TS_Enable {false} \
CONFIG.Statistics_Counters {true} \
CONFIG.Statistics_Reset {false} \
CONFIG.Statistics_Width {64bit} \
CONFIG.SupportLevel {0} \
CONFIG.TX_Inband_CF_Enable {false} \
CONFIG.Timer_Format {Time_of_day} \
CONFIG.USE_BOARD_FLOW {false} \
 ] $eth_mac

  # Create instance: pcs_pma, and set properties
  set pcs_pma [ create_bd_cell -type ip -vlnv xilinx.com:ip:gig_ethernet_pcs_pma:15.1 pcs_pma ]
  set_property -dict [ list \
CONFIG.Auto_Negotiation {true} \
CONFIG.C_PHYADDR {1} \
CONFIG.DIFFCLK_BOARD_INTERFACE {sfp_mgt_clk} \
CONFIG.DrpClkRate {50.0} \
CONFIG.ETHERNET_BOARD_INTERFACE {sfp1} \
CONFIG.EXAMPLE_SIMULATION {0} \
CONFIG.Enable_1588 {false} \
CONFIG.Ext_Management_Interface {false} \
CONFIG.LvdsRefClk {125} \
CONFIG.MDIO_BOARD_INTERFACE {Custom} \
CONFIG.Management_Interface {true} \
CONFIG.MaxDataRate {1G} \
CONFIG.Physical_Interface {Transceiver} \
CONFIG.RefClkRate {125} \
CONFIG.SGMII_Mode {10_100_1000} \
CONFIG.SGMII_PHY_Mode {false} \
CONFIG.Standard {1000BASEX} \
CONFIG.SupportLevel {Include_Shared_Logic_in_Core} \
CONFIG.Timer_Format {Time_of_day} \
CONFIG.TransceiverControl {false} \
CONFIG.USE_BOARD_FLOW {true} \
 ] $pcs_pma

  # Create interface connections
  connect_bd_intf_net -intf_net eth_buf_AXI_STR_RXD [get_bd_intf_ports m_axis_rxd] [get_bd_intf_pins eth_buf/AXI_STR_RXD]
  connect_bd_intf_net -intf_net eth_buf_AXI_STR_RXS [get_bd_intf_ports m_axis_rxs] [get_bd_intf_pins eth_buf/AXI_STR_RXS]
  connect_bd_intf_net -intf_net eth_buf_S_AXI_2TEMAC [get_bd_intf_pins eth_buf/S_AXI_2TEMAC] [get_bd_intf_pins eth_mac/s_axi]
  connect_bd_intf_net -intf_net eth_buf_TX_AXIS_MAC [get_bd_intf_pins eth_buf/TX_AXIS_MAC] [get_bd_intf_pins eth_mac/s_axis_tx]
  connect_bd_intf_net -intf_net eth_mac_gmii [get_bd_intf_pins eth_mac/gmii] [get_bd_intf_pins pcs_pma/gmii_pcs_pma]
  connect_bd_intf_net -intf_net eth_mac_m_axis_rx [get_bd_intf_pins eth_buf/RX_AXIS_MAC] [get_bd_intf_pins eth_mac/m_axis_rx]
  connect_bd_intf_net -intf_net mgt_clk_1 [get_bd_intf_ports mgt_clk] [get_bd_intf_pins pcs_pma/gtrefclk_in]
  connect_bd_intf_net -intf_net pcs_pma_sfp [get_bd_intf_ports sfp] [get_bd_intf_pins pcs_pma/sfp]
  connect_bd_intf_net -intf_net s_axi_1 [get_bd_intf_ports s_axi] [get_bd_intf_pins eth_buf/S_AXI]
  connect_bd_intf_net -intf_net s_axis_txc_1 [get_bd_intf_ports s_axis_txc] [get_bd_intf_pins eth_buf/AXI_STR_TXC]
  connect_bd_intf_net -intf_net s_axis_txd_1 [get_bd_intf_ports s_axis_txd] [get_bd_intf_pins eth_buf/AXI_STR_TXD]

  # Create port connections
  connect_bd_net -net axi_rxd_arstn_1 [get_bd_ports axi_rxd_arstn] [get_bd_pins eth_buf/AXI_STR_RXD_ARESETN]
  connect_bd_net -net axi_rxs_arstn_1 [get_bd_ports axi_rxs_arstn] [get_bd_pins eth_buf/AXI_STR_RXS_ARESETN]
  connect_bd_net -net axi_txc_arstn_1 [get_bd_ports axi_txc_arstn] [get_bd_pins eth_buf/AXI_STR_TXC_ARESETN]
  connect_bd_net -net axi_txd_arstn_1 [get_bd_ports axi_txd_arstn] [get_bd_pins eth_buf/AXI_STR_TXD_ARESETN]
  connect_bd_net -net axis_clk_1 [get_bd_ports axis_clk] [get_bd_pins eth_buf/AXI_STR_RXD_ACLK] [get_bd_pins eth_buf/AXI_STR_RXS_ACLK] [get_bd_pins eth_buf/AXI_STR_TXC_ACLK] [get_bd_pins eth_buf/AXI_STR_TXD_ACLK]
  connect_bd_net -net eth_buf_INTERRUPT [get_bd_ports interrupt] [get_bd_pins eth_buf/INTERRUPT]
  connect_bd_net -net eth_buf_RESET2PCSPMA [get_bd_pins eth_buf/RESET2PCSPMA] [get_bd_pins pcs_pma/reset]
  connect_bd_net -net eth_buf_RESET2TEMACn [get_bd_pins eth_buf/RESET2TEMACn] [get_bd_pins eth_mac/glbl_rstn] [get_bd_pins eth_mac/rx_axi_rstn] [get_bd_pins eth_mac/tx_axi_rstn]
  connect_bd_net -net eth_buf_pause_req [get_bd_pins eth_buf/pause_req] [get_bd_pins eth_mac/pause_req]
  connect_bd_net -net eth_buf_pause_val [get_bd_pins eth_buf/pause_val] [get_bd_pins eth_mac/pause_val]
  connect_bd_net -net eth_buf_tx_ifg_delay [get_bd_pins eth_buf/tx_ifg_delay] [get_bd_pins eth_mac/tx_ifg_delay]
  connect_bd_net -net eth_mac_mac_irq [get_bd_ports mac_irq] [get_bd_pins eth_mac/mac_irq]
  connect_bd_net -net eth_mac_mdc [get_bd_pins eth_mac/mdc] [get_bd_pins pcs_pma/mdc]
  connect_bd_net -net eth_mac_mdio_o [get_bd_pins eth_mac/mdio_o] [get_bd_pins pcs_pma/mdio_i]
  connect_bd_net -net eth_mac_rx_mac_aclk [get_bd_pins eth_buf/rx_mac_aclk] [get_bd_pins eth_mac/rx_mac_aclk]
  connect_bd_net -net eth_mac_rx_reset [get_bd_pins eth_buf/rx_reset] [get_bd_pins eth_mac/rx_reset]
  connect_bd_net -net eth_mac_rx_statistics_valid [get_bd_pins eth_buf/rx_statistics_valid] [get_bd_pins eth_mac/rx_statistics_valid]
  connect_bd_net -net eth_mac_rx_statistics_vector [get_bd_pins eth_buf/rx_statistics_vector] [get_bd_pins eth_mac/rx_statistics_vector]
  connect_bd_net -net eth_mac_speedis10100 [get_bd_pins eth_buf/speed_is_10_100] [get_bd_pins eth_mac/speedis10100]
  connect_bd_net -net eth_mac_tx_mac_aclk [get_bd_pins eth_buf/tx_mac_aclk] [get_bd_pins eth_mac/tx_mac_aclk]
  connect_bd_net -net eth_mac_tx_reset [get_bd_pins eth_buf/tx_reset] [get_bd_pins eth_mac/tx_reset]
  connect_bd_net -net pcs_pma_an_interrupt [get_bd_pins eth_buf/EMAC_CLIENT_AUTONEG_INT] [get_bd_pins pcs_pma/an_interrupt]
  connect_bd_net -net pcs_pma_gt0_qplloutclk_out [get_bd_ports gt0_qplloutclk_out] [get_bd_pins pcs_pma/gt0_qplloutclk_out]
  connect_bd_net -net pcs_pma_gt0_qplloutrefclk_out [get_bd_ports gt0_qplloutrefclk_out] [get_bd_pins pcs_pma/gt0_qplloutrefclk_out]
  connect_bd_net -net pcs_pma_gtrefclk_bufg_out [get_bd_ports gtref_clk_buf_out] [get_bd_pins pcs_pma/gtrefclk_bufg_out]
  connect_bd_net -net pcs_pma_gtrefclk_out [get_bd_ports gtref_clk_out] [get_bd_pins pcs_pma/gtrefclk_out]
  connect_bd_net -net pcs_pma_mdio_o [get_bd_pins eth_mac/mdio_i] [get_bd_pins pcs_pma/mdio_o]
  connect_bd_net -net pcs_pma_mmcm_locked_out [get_bd_ports mmcm_locked_out] [get_bd_pins eth_buf/EMAC_RX_DCM_LOCKED_INT] [get_bd_pins pcs_pma/mmcm_locked_out]
  connect_bd_net -net pcs_pma_pma_reset_out [get_bd_ports pma_reset_out] [get_bd_pins pcs_pma/pma_reset_out]
  connect_bd_net -net pcs_pma_resetdone [get_bd_pins eth_buf/EMAC_RESET_DONE_INT] [get_bd_pins pcs_pma/resetdone]
  connect_bd_net -net pcs_pma_rxuserclk2_out [get_bd_ports rxuserclk2_out] [get_bd_pins pcs_pma/rxuserclk2_out]
  connect_bd_net -net pcs_pma_rxuserclk_out [get_bd_ports rxuserclk_out] [get_bd_pins pcs_pma/rxuserclk_out]
  connect_bd_net -net pcs_pma_status_vector [get_bd_pins eth_buf/PCSPMA_STATUS_VECTOR] [get_bd_pins pcs_pma/status_vector]
  connect_bd_net -net pcs_pma_userclk2_out [get_bd_ports userclk2_out] [get_bd_pins eth_buf/GTX_CLK] [get_bd_pins eth_mac/gtx_clk] [get_bd_pins pcs_pma/userclk2_out]
  connect_bd_net -net pcs_pma_userclk_out [get_bd_ports userclk_out] [get_bd_pins pcs_pma/userclk_out]
  connect_bd_net -net ref_clk_1 [get_bd_ports ref_clk] [get_bd_pins pcs_pma/independent_clock_bufg]
  connect_bd_net -net s_axi_lite_clk_1 [get_bd_ports s_axi_lite_clk] [get_bd_pins eth_buf/S_AXI_ACLK] [get_bd_pins eth_mac/s_axi_aclk]
  connect_bd_net -net s_axi_lite_resetn_1 [get_bd_ports s_axi_lite_resetn] [get_bd_pins eth_buf/S_AXI_ARESETN] [get_bd_pins eth_mac/s_axi_resetn]
  connect_bd_net -net signal_detect_1 [get_bd_ports signal_detect] [get_bd_pins pcs_pma/signal_detect]

  # Create address segments
  create_bd_addr_seg -range 0x20000 -offset 0x0 [get_bd_addr_spaces eth_buf/S_AXI_2TEMAC] [get_bd_addr_segs eth_mac/s_axi/Reg] SEG_eth_mac_Reg
  create_bd_addr_seg -range 0x40000 -offset 0x0 [get_bd_addr_spaces s_axi] [get_bd_addr_segs eth_buf/S_AXI/Reg] SEG_eth_buf_REG


  # Restore current instance
  current_bd_instance $oldCurInst

  save_bd_design

#  generate_target -force synthesis [get_ips]

}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""
make_wrapper -import -top [get_files $str_bd_filepath]


