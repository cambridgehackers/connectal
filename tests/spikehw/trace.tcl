open_hw
connect_hw_server
open_hw_target
current_hw_device [lindex [get_hw_devices] 0]
set_property PROBES.FILE {/home/jamey/connectal.clean/tests/spikehw/debug.ltx} [lindex [get_hw_devices] 0]
set_property PROGRAM.FILE {/home/jamey/connectal.clean/tests/spikehw/debug.bit} [lindex [get_hw_devices] 0]
refresh_hw_device [lindex [get_hw_devices] 0]


set_property TRIGGER_COMPARE_VALUE eq1'h0 [get_hw_probes tile_0_lSpikeHw_sda_t_probe_PROBE -of_objects [get_hw_ilas -of_objects [get_hw_devices xc7vx690t_0] -filter {CELL_NAME=~"u_ila_0"}]]
set_property CONTROL.TRIGGER_MODE BASIC_ONLY [get_hw_ilas -of_objects [get_hw_devices xc7vx690t_0] -filter {CELL_NAME=~"u_ila_0"}]
set_property CONTROL.TRIGGER_POSITION 1000 [get_hw_ilas -of_objects [get_hw_devices xc7vx690t_0] -filter {CELL_NAME=~"u_ila_0"}]
#set_property CONTROL.DATA_DEPTH 131072 [get_hw_ilas -of_objects [get_hw_devices xc7vx690t_0] -filter {CELL_NAME=~"u_ila_0"}]
run_hw_ila [get_hw_ilas -of_objects [get_hw_devices xc7vx690t_0] -filter {CELL_NAME=~"u_ila_0"}]
wait_on_hw_ila [get_hw_ilas -of_objects [get_hw_devices xc7vx690t_0] -filter {CELL_NAME=~"u_ila_0"}]
upload_hw_ila_data [get_hw_ilas -of_objects [get_hw_devices xc7vx690t_0] -filter {CELL_NAME=~"u_ila_0"}]
write_hw_ila_data -force debug.vcd -vcd_file [current_hw_ila_data]
