#
set -x
set -e
scripts/importbvi.py \
    -f DDR -f FTMT -f FTMD \
    -f EMIOGPIO -f EMIOPJTAG -f EMIOTRACE -f EMIOWDT -f EVENT -f PS -f SAXIACP \
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
    -i PS7EXTENDED:Pps7Emiocan:Pps7Emioenet:Pps7Emiopjtag:Pps7Emiosdio:Pps7Emiospi:Pps7Emiotrace:Pps7Emiottc:Pps7Emiouart:Pps7Emiousb:Pps7Emiowdt:Pps7Dma \
    ../import_components/Xilinx/Vivado/2013.2/data/parts/xilinx/zynq/zynq.lib >PPS7.bsv
#Pps7Core:Pps7Dma:Pps7Event:Pps7Fclk_clktrig:Pps7Fpga:Pps7Ftmd:Pps7Ftmt:Pps7Sram \

#    -r PS:PS_ \
