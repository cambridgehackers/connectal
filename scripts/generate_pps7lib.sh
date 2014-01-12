#
set -x
set -e
scripts/importbvi.py \
    -r EMIOCAN:CAN \
    -r EMIOCORE:CORE \
    -r EMIODMA:DMA \
    -r EMIOENET:ENET \
    -r EMIOGPIO:GPIO \
    -r EMIOI2C:I2C \
    -r EMIOPJTAG:PJTAG \
    -r EMIOPS:PS \
    -r EMIOSDIO:SDIO \
    -r EMIOSPI:SPI \
    -r EMIOSRAM:SRAM \
    -r EMIOTRACE:TRACE \
    -r EMIOTTC:TTC \
    -r EMIOUART:UART \
    -r EMIOUSB:USB \
    -r EMIOWDT:WDT \
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
    ../import_components/Xilinx/Vivado/2013.2/data/parts/xilinx/zynq/zynq.lib >PPS7.bsv

#    -r PS:PS_ \
