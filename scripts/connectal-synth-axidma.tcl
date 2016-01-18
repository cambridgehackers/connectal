source "board.tcl"
source "$connectaldir/scripts/connectal-synth-ip.tcl"

set prj_boardname $boardname
if [string match "*g2" $boardname] {set prj_boardname [string trimright $boardname "g2"]}

connectal_synth_ip axi_dma 7.1 axi_dma_0 [list CONFIG.c_sg_include_stscntrl_strm {1} CONFIG.c_m_axi_mm2s_data_width {32} CONFIG.c_m_axi_s2mm_data_width {32} CONFIG.c_mm2s_burst_size {8} CONFIG.c_s2mm_burst_size {8}]

