source "board.tcl"
source "$connectaldir/scripts/connectal-synth-ip.tcl"

puts $boardname
set prj_boardname $boardname
if [string match "*g2" $boardname] {set prj_boardname [string trimright $boardname "g2"]}

connectal_synth_ip axi_protocol_checker 2.0 axi_protocol_checker_0 [list \
    CONFIG.ADDR_WIDTH 64 \
    CONFIG.DATA_WIDTH 512 \
    CONFIG.HAS_WSTRB 1 \
    CONFIG.ID_WIDTH 6 \
    CONFIG.ARUSER_WIDTH 0 \
    CONFIG.AWUSER_WIDTH 0 \
    CONFIG.BUSER_WIDTH 0 \
    CONFIG.RUSER_WIDTH 0 \
    CONFIG.WUSER_WIDTH 0 \
    CONFIG.MAX_AR_WAITS 500 \
    CONFIG.MAX_AW_WAITS 500 \
    CONFIG.MAX_B_WAITS 500 \
    CONFIG.MAX_R_WAITS 500 \
    CONFIG.MAX_W_WAITS 500 \
    ]

# create_project -name local_synthesized_ip -in_memory
# set_property PART {xcvu9p-flgb2104-2-i} [current_project]
# create_ip -name axi_protocol_checker -version 2.0 -vendor xilinx.com -library ip -module_name axi_protocol_checker_0 -dir /home/ubuntu/connectal/out/awsf1/axi_protocol_checker_0
# report_property -file /home/ubuntu/connectal/out/awsf1/axi_protocol_checker_0.properties.log [get_ips axi_protocol_checker_0]
