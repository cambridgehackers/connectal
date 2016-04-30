open_hw
connect_hw_server
open_hw_target
current_hw_device [lindex [get_hw_devices] 0]
set_property PROBES.FILE {/home/jamey/connectal.clean/tests/spikehw/debug.ltx} [lindex [get_hw_devices] 0]
set_property PROGRAM.FILE {/home/jamey/connectal.clean/tests/spikehw/debug.bit} [lindex [get_hw_devices] 0]
program_hw_devices [lindex [get_hw_devices] 0]
quit
