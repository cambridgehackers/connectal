#
set -e
set -x
scripts/importbvi.py -o PPS7.bsv -I PPS7 -P PPS7 \
    -p c_emio_gpio_width:gpio_width \
    -p c_m_axi_gp0_thread_id_width:id_width \
    -p c_m_axi_gp1_thread_id_width:id_width \
    -p c_s_axi_gp0_id_width:id_width \
    -p c_s_axi_gp1_id_width:id_width \
    -p c_s_axi_acp_id_width:id_width \
    -p c_s_axi_hp0_id_width:id_width \
    -p c_s_axi_hp0_data_width:data_width \
    -p c_s_axi_hp1_id_width:id_width \
    -p c_s_axi_hp1_data_width:data_width \
    -p c_s_axi_hp2_id_width:id_width \
    -p c_s_axi_hp2_data_width:data_width \
    -p c_s_axi_hp3_id_width:id_width \
    -p c_s_axi_hp3_data_width:data_width \
    -p c_mio_primitive:mio_width -p c_dm_width -p c_dq_width -p c_dqs_width \
    -c M_AXI_GP1_ACLK \
    -c M_AXI_GP0_ACLK -c FCLK_CLK0 \
    -c S_AXI_GP0_ACLK -c S_AXI_GP1_ACLK \
    -c S_AXI_ACP_ACLK \
    -c S_AXI_HP0_ACLK -c S_AXI_HP1_ACLK -c S_AXI_HP2_ACLK -c S_AXI_HP3_ACLK \
    -d DDR_ARB \
    -e C_NUM_F2P_INTR_INPUTS:16 \
    -i PS7EXTENDED:Pps7Can:Pps7Core:Pps7Dma:Pps7Enet:Pps7Event:Pps7Fclk_clktrig:Pps7Fpga:Pps7Ftmd:Pps7Ftmt:Pps7Pjtag:Pps7Sdio:Pps7Spi:Pps7Sram:Pps7Trace:Pps7Ttc:Pps7Uart:Pps7Usb:Pps7Wdt \
    xilinx.unused/sources/processing_system7/processing_system7.v

#    -m DDR_DQS:DDR_DQS_p -m DDR_Clk:DDR_Clk_p \
#    -c ENET0_GMII_RX_CLK -c ENET0_GMII_TX_CLK \
#    -c ENET1_GMII_RX_CLK -c ENET1_GMII_TX_CLK \
#    -c SDIO0_CLK -c SDIO0_CLK_FB \
#    -c SDIO1_CLK -c SDIO1_CLK_FB \
#    -c TTC0_CLK0_IN -c TTC0_CLK1_IN -c TTC0_CLK2_IN \
#    -c TTC1_CLK0_IN -c TTC1_CLK1_IN -c TTC1_CLK2_IN \
#    -c WDT_CLK_IN \
#    -c TRACE_CLK \
#    -c DMA0_ACLK -c DMA1_ACLK -c DMA2_ACLK -c DMA3_ACLK \
#    -c FCLK_CLK3 -c FCLK_CLK2 -c FCLK_CLK1 \
#    -c FTMD_TRACEIN_CLK \
#    -c PS_CLK \


