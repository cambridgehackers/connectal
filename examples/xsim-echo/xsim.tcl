open_vcd foo.vcd
log_vcd xsim_state_mkFSMstate
log_vcd xsim_echoReg xsim_vecho_heard
start_vcd
run -all
stop_vcd
close_vcd
