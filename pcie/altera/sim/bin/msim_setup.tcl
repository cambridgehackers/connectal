
# (C) 2001-2014 Altera Corporation. All rights reserved.
# Your use of Altera Corporation's design tools, logic functions and 
# other software and tools, and its AMPP partner logic functions, and 
# any output files any of the foregoing (including device programming 
# or simulation files), and any associated documentation or information 
# are expressly subject to the terms and conditions of the Altera 
# Program License Subscription Agreement, Altera MegaCore Function 
# License Agreement, or other applicable license agreement, including, 
# without limitation, that your use is for the sole purpose of 
# programming logic devices manufactured by Altera and sold by Altera 
# or its authorized distributors. Please refer to the applicable 
# agreement for further details.

# ACDS 14.0 200 linux 2014.12.28.02:13:14

# ----------------------------------------
# Auto-generated simulation script

# ----------------------------------------
# Initialize variables
if ![info exists SYSTEM_INSTANCE_NAME] { 
  set SYSTEM_INSTANCE_NAME ""
} elseif { ![ string match "" $SYSTEM_INSTANCE_NAME ] } { 
  set SYSTEM_INSTANCE_NAME "/$SYSTEM_INSTANCE_NAME"
}

if ![info exists TOP_LEVEL_NAME] { 
  set TOP_LEVEL_NAME "mkPcieS5Top_tb"
}

if ![info exists QSYS_SIMDIR] { 
  set QSYS_SIMDIR "./../"
}

if ![info exists QUARTUS_INSTALL_DIR] { 
  set QUARTUS_INSTALL_DIR "/home/hwang/altera/14.0/quartus/"
}

# ----------------------------------------
# Initialize simulation properties - DO NOT MODIFY!
set ELAB_OPTIONS ""
set SIM_OPTIONS ""
if ![ string match "*-64 vsim*" [ vsim -version ] ] {
} else {
}

# ----------------------------------------
# Copy ROM/RAM files to simulation directory
alias file_copy {
  echo "\[exec\] file_copy"
}

# ----------------------------------------
# Create compilation libraries
proc ensure_lib { lib } { if ![file isdirectory $lib] { vlib $lib } }
ensure_lib          ./libraries/     
ensure_lib          ./libraries/work/
vmap       work     ./libraries/work/
vmap       work_lib ./libraries/work/
if ![ string match "*ModelSim ALTERA*" [ vsim -version ] ] {
  ensure_lib                        ./libraries/altera_ver/            
  vmap       altera_ver             ./libraries/altera_ver/            
  ensure_lib                        ./libraries/lpm_ver/               
  vmap       lpm_ver                ./libraries/lpm_ver/               
  ensure_lib                        ./libraries/sgate_ver/             
  vmap       sgate_ver              ./libraries/sgate_ver/             
  ensure_lib                        ./libraries/altera_mf_ver/         
  vmap       altera_mf_ver          ./libraries/altera_mf_ver/         
  ensure_lib                        ./libraries/altera_lnsim_ver/      
  vmap       altera_lnsim_ver       ./libraries/altera_lnsim_ver/      
  ensure_lib                        ./libraries/stratixiv_hssi_ver/    
  vmap       stratixiv_hssi_ver     ./libraries/stratixiv_hssi_ver/    
  ensure_lib                        ./libraries/stratixiv_pcie_hip_ver/
  vmap       stratixiv_pcie_hip_ver ./libraries/stratixiv_pcie_hip_ver/
  ensure_lib                        ./libraries/stratixiv_ver/         
  vmap       stratixiv_ver          ./libraries/stratixiv_ver/         
  ensure_lib                        ./libraries/stratixv_ver/          
  vmap       stratixv_ver           ./libraries/stratixv_ver/          
  ensure_lib                        ./libraries/stratixv_hssi_ver/     
  vmap       stratixv_hssi_ver      ./libraries/stratixv_hssi_ver/     
  ensure_lib                        ./libraries/stratixv_pcie_hip_ver/ 
  vmap       stratixv_pcie_hip_ver  ./libraries/stratixv_pcie_hip_ver/ 
}
ensure_lib                                 ./libraries/altera_common_sv_packages/      
vmap       altera_common_sv_packages       ./libraries/altera_common_sv_packages/      
ensure_lib                                 ./libraries/rst_controller/                 
vmap       rst_controller                  ./libraries/rst_controller/                 
ensure_lib                                 ./libraries/alt_xcvr_reconfig_0/            
vmap       alt_xcvr_reconfig_0             ./libraries/alt_xcvr_reconfig_0/            
ensure_lib                                 ./libraries/pcie_reconfig_driver_0/         
vmap       pcie_reconfig_driver_0          ./libraries/pcie_reconfig_driver_0/         
ensure_lib                                 ./libraries/APPS/                           
vmap       APPS                            ./libraries/APPS/                           
ensure_lib                                 ./libraries/DUT/                            
vmap       DUT                             ./libraries/DUT/                            
ensure_lib                                 ./libraries/DUT_pcie_tb/                    
vmap       DUT_pcie_tb                     ./libraries/DUT_pcie_tb/                    
ensure_lib                                 ./libraries/mkPcieS5Top_inst_clk_50_rst_bfm/
vmap       mkPcieS5Top_inst_clk_50_rst_bfm ./libraries/mkPcieS5Top_inst_clk_50_rst_bfm/
ensure_lib                                 ./libraries/mkPcieS5Top_inst_clk_50_bfm/    
vmap       mkPcieS5Top_inst_clk_50_bfm     ./libraries/mkPcieS5Top_inst_clk_50_bfm/    
ensure_lib                                 ./libraries/mkPcieS5Top_inst/               
vmap       mkPcieS5Top_inst                ./libraries/mkPcieS5Top_inst/               

# ----------------------------------------
# Compile device library files
alias dev_com {
  echo "\[exec\] dev_com"
  if ![ string match "*ModelSim ALTERA*" [ vsim -version ] ] {
    vlog     "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_primitives.v"                     -work altera_ver            
    vlog     "$QUARTUS_INSTALL_DIR/eda/sim_lib/220model.v"                              -work lpm_ver               
    vlog     "$QUARTUS_INSTALL_DIR/eda/sim_lib/sgate.v"                                 -work sgate_ver             
    vlog     "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_mf.v"                             -work altera_mf_ver         
    vlog -sv "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_lnsim.sv"                         -work altera_lnsim_ver      
    vlog     "$QUARTUS_INSTALL_DIR/eda/sim_lib/stratixiv_hssi_atoms.v"                  -work stratixiv_hssi_ver    
    vlog     "$QUARTUS_INSTALL_DIR/eda/sim_lib/stratixiv_pcie_hip_atoms.v"              -work stratixiv_pcie_hip_ver
    vlog     "$QUARTUS_INSTALL_DIR/eda/sim_lib/stratixiv_atoms.v"                       -work stratixiv_ver         
    vlog     "$QUARTUS_INSTALL_DIR/eda/sim_lib/mentor/stratixv_atoms_ncrypt.v"          -work stratixv_ver          
    vlog     "$QUARTUS_INSTALL_DIR/eda/sim_lib/stratixv_atoms.v"                        -work stratixv_ver          
    vlog     "$QUARTUS_INSTALL_DIR/eda/sim_lib/mentor/stratixv_hssi_atoms_ncrypt.v"     -work stratixv_hssi_ver     
    vlog     "$QUARTUS_INSTALL_DIR/eda/sim_lib/stratixv_hssi_atoms.v"                   -work stratixv_hssi_ver     
    vlog     "$QUARTUS_INSTALL_DIR/eda/sim_lib/mentor/stratixv_pcie_hip_atoms_ncrypt.v" -work stratixv_pcie_hip_ver 
    vlog     "$QUARTUS_INSTALL_DIR/eda/sim_lib/stratixv_pcie_hip_atoms.v"               -work stratixv_pcie_hip_ver 
  }
}

# ----------------------------------------
# Compile the design files in correct order
alias com {
  echo "\[exec\] com"
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/verbosity_pkg.sv"                                                                      -work altera_common_sv_packages      
  vlog                                                                  "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/altera_reset_controller.v"                                                             -work rst_controller                 
  vlog                                                                  "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/altera_reset_synchronizer.v"                                                           -work rst_controller                 
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/altera_xcvr_functions.sv"                                 -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/mentor/altera_xcvr_functions.sv"                          -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/sv_xcvr_h.sv"                                             -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/mentor/sv_xcvr_h.sv"                                      -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/alt_xcvr_resync.sv"                                       -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/mentor/alt_xcvr_resync.sv"                                -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/alt_xcvr_reconfig_h.sv"                                   -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/mentor/alt_xcvr_reconfig_h.sv"                            -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/sv_xcvr_dfe_cal_sweep_h.sv"                               -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/mentor/sv_xcvr_dfe_cal_sweep_h.sv"                        -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/alt_xcvr_reconfig.sv"                                     -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/mentor/alt_xcvr_reconfig.sv"                              -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/alt_xcvr_reconfig_sv.sv"                                  -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/mentor/alt_xcvr_reconfig_sv.sv"                           -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/alt_xcvr_reconfig_cal_seq.sv"                             -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/mentor/alt_xcvr_reconfig_cal_seq.sv"                      -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/alt_xreconf_cif.sv"                                       -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/mentor/alt_xreconf_cif.sv"                                -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/alt_xreconf_uif.sv"                                       -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/mentor/alt_xreconf_uif.sv"                                -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/alt_xreconf_basic_acq.sv"                                 -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/mentor/alt_xreconf_basic_acq.sv"                          -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/alt_xcvr_reconfig_analog.sv"                              -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/mentor/alt_xcvr_reconfig_analog.sv"                       -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/alt_xcvr_reconfig_analog_sv.sv"                           -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/mentor/alt_xcvr_reconfig_analog_sv.sv"                    -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/alt_xreconf_analog_datactrl.sv"                           -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/mentor/alt_xreconf_analog_datactrl.sv"                    -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/alt_xreconf_analog_rmw.sv"                                -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/mentor/alt_xreconf_analog_rmw.sv"                         -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/alt_xreconf_analog_ctrlsm.sv"                             -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/mentor/alt_xreconf_analog_ctrlsm.sv"                      -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/alt_xcvr_reconfig_offset_cancellation.sv"                 -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/mentor/alt_xcvr_reconfig_offset_cancellation.sv"          -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/alt_xcvr_reconfig_offset_cancellation_sv.sv"              -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/mentor/alt_xcvr_reconfig_offset_cancellation_sv.sv"       -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/alt_xcvr_reconfig_eyemon.sv"                              -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/mentor/alt_xcvr_reconfig_eyemon.sv"                       -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/alt_xcvr_reconfig_eyemon_sv.sv"                           -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/alt_xcvr_reconfig_eyemon_ctrl_sv.sv"                      -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/alt_xcvr_reconfig_eyemon_ber_sv.sv"                       -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog                                                                  "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/ber_reader_dcfifo.v"                                                                   -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/step_to_mon_sv.sv"                                        -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/mon_to_step_sv.sv"                                        -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/mentor/alt_xcvr_reconfig_eyemon_sv.sv"                    -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/mentor/alt_xcvr_reconfig_eyemon_ctrl_sv.sv"               -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/mentor/alt_xcvr_reconfig_eyemon_ber_sv.sv"                -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog                                                                  "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/mentor/ber_reader_dcfifo.v"                                                            -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/mentor/step_to_mon_sv.sv"                                 -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/mentor/mon_to_step_sv.sv"                                 -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/alt_xcvr_reconfig_dfe.sv"                                 -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/mentor/alt_xcvr_reconfig_dfe.sv"                          -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/alt_xcvr_reconfig_dfe_sv.sv"                              -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/alt_xcvr_reconfig_dfe_reg_sv.sv"                          -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/alt_xcvr_reconfig_dfe_cal_sv.sv"                          -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/alt_xcvr_reconfig_dfe_cal_sweep_sv.sv"                    -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/alt_xcvr_reconfig_dfe_cal_sweep_datapath_sv.sv"           -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/alt_xcvr_reconfig_dfe_oc_cal_sv.sv"                       -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/alt_xcvr_reconfig_dfe_pi_phase_sv.sv"                     -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/alt_xcvr_reconfig_dfe_step_to_mon_en_sv.sv"               -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/alt_xcvr_reconfig_dfe_adapt_tap_sv.sv"                    -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/alt_xcvr_reconfig_dfe_ctrl_mux_sv.sv"                     -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/alt_xcvr_reconfig_dfe_local_reset_sv.sv"                  -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/alt_xcvr_reconfig_dfe_cal_sim_sv.sv"                      -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/alt_xcvr_reconfig_dfe_adapt_tap_sim_sv.sv"                -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/mentor/alt_xcvr_reconfig_dfe_sv.sv"                       -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/mentor/alt_xcvr_reconfig_dfe_reg_sv.sv"                   -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/mentor/alt_xcvr_reconfig_dfe_cal_sv.sv"                   -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/mentor/alt_xcvr_reconfig_dfe_cal_sweep_sv.sv"             -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/mentor/alt_xcvr_reconfig_dfe_cal_sweep_datapath_sv.sv"    -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/mentor/alt_xcvr_reconfig_dfe_oc_cal_sv.sv"                -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/mentor/alt_xcvr_reconfig_dfe_pi_phase_sv.sv"              -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/mentor/alt_xcvr_reconfig_dfe_step_to_mon_en_sv.sv"        -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/mentor/alt_xcvr_reconfig_dfe_adapt_tap_sv.sv"             -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/mentor/alt_xcvr_reconfig_dfe_ctrl_mux_sv.sv"              -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/mentor/alt_xcvr_reconfig_dfe_local_reset_sv.sv"           -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/mentor/alt_xcvr_reconfig_dfe_cal_sim_sv.sv"               -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/mentor/alt_xcvr_reconfig_dfe_adapt_tap_sim_sv.sv"         -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/alt_xcvr_reconfig_adce.sv"                                -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/mentor/alt_xcvr_reconfig_adce.sv"                         -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/alt_xcvr_reconfig_adce_sv.sv"                             -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/alt_xcvr_reconfig_adce_datactrl_sv.sv"                    -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/mentor/alt_xcvr_reconfig_adce_sv.sv"                      -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/mentor/alt_xcvr_reconfig_adce_datactrl_sv.sv"             -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/alt_xcvr_reconfig_dcd.sv"                                 -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/mentor/alt_xcvr_reconfig_dcd.sv"                          -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/alt_xcvr_reconfig_dcd_sv.sv"                              -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/alt_xcvr_reconfig_dcd_cal.sv"                             -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/alt_xcvr_reconfig_dcd_control.sv"                         -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/alt_xcvr_reconfig_dcd_datapath.sv"                        -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/alt_xcvr_reconfig_dcd_pll_reset.sv"                       -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/alt_xcvr_reconfig_dcd_eye_width.sv"                       -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/alt_xcvr_reconfig_dcd_align_clk.sv"                       -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/alt_xcvr_reconfig_dcd_get_sum.sv"                         -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/alt_xcvr_reconfig_dcd_cal_sim_model.sv"                   -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/mentor/alt_xcvr_reconfig_dcd_sv.sv"                       -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/mentor/alt_xcvr_reconfig_dcd_cal.sv"                      -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/mentor/alt_xcvr_reconfig_dcd_control.sv"                  -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/mentor/alt_xcvr_reconfig_dcd_datapath.sv"                 -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/mentor/alt_xcvr_reconfig_dcd_pll_reset.sv"                -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/mentor/alt_xcvr_reconfig_dcd_eye_width.sv"                -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/mentor/alt_xcvr_reconfig_dcd_align_clk.sv"                -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/mentor/alt_xcvr_reconfig_dcd_get_sum.sv"                  -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/mentor/alt_xcvr_reconfig_dcd_cal_sim_model.sv"            -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/alt_xcvr_reconfig_mif.sv"                                 -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/mentor/alt_xcvr_reconfig_mif.sv"                          -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/sv_xcvr_reconfig_mif.sv"                                  -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/sv_xcvr_reconfig_mif_ctrl.sv"                             -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/sv_xcvr_reconfig_mif_avmm.sv"                             -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/mentor/sv_xcvr_reconfig_mif.sv"                           -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/mentor/sv_xcvr_reconfig_mif_ctrl.sv"                      -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/mentor/sv_xcvr_reconfig_mif_avmm.sv"                      -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/alt_xcvr_reconfig_pll.sv"                                 -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/mentor/alt_xcvr_reconfig_pll.sv"                          -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/sv_xcvr_reconfig_pll.sv"                                  -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/sv_xcvr_reconfig_pll_ctrl.sv"                             -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/mentor/sv_xcvr_reconfig_pll.sv"                           -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/mentor/sv_xcvr_reconfig_pll_ctrl.sv"                      -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/alt_xcvr_reconfig_soc.sv"                                 -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/alt_xcvr_reconfig_cpu_ram.sv"                             -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/alt_xcvr_reconfig_direct.sv"                              -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/sv_xrbasic_l2p_addr.sv"                                   -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/sv_xrbasic_l2p_ch.sv"                                     -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/sv_xrbasic_l2p_rom.sv"                                    -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/sv_xrbasic_lif_csr.sv"                                    -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/sv_xrbasic_lif.sv"                                        -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/sv_xcvr_reconfig_basic.sv"                                -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/alt_arbiter_acq.sv"                                       -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/alt_xcvr_reconfig_basic.sv"                               -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/mentor/sv_xrbasic_l2p_addr.sv"                            -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/mentor/sv_xrbasic_l2p_ch.sv"                              -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/mentor/sv_xrbasic_l2p_rom.sv"                             -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/mentor/sv_xrbasic_lif_csr.sv"                             -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/mentor/sv_xrbasic_lif.sv"                                 -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/mentor/sv_xcvr_reconfig_basic.sv"                         -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/mentor/alt_arbiter_acq.sv"                                -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/mentor/alt_xcvr_reconfig_basic.sv"                        -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/alt_xcvr_arbiter.sv"                                      -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/alt_xcvr_m2s.sv"                                          -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog                                                                  "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/altera_wait_generate.v"                                                                -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/alt_xcvr_csr_selector.sv"                                 -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/mentor/alt_xcvr_arbiter.sv"                               -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/mentor/alt_xcvr_m2s.sv"                                   -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog                                                                  "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/mentor/altera_wait_generate.v"                                                         -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/mentor/alt_xcvr_csr_selector.sv"                          -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/sv_reconfig_bundle_to_basic.sv"                           -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/mentor/sv_reconfig_bundle_to_basic.sv"                    -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog                                                                  "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/alt_xcvr_reconfig_cpu.v"                                                               -work alt_xcvr_reconfig_0            
  vlog                                                                  "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/alt_xcvr_reconfig_cpu_reconfig_cpu.v"                                                  -work alt_xcvr_reconfig_0            
  vlog                                                                  "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/alt_xcvr_reconfig_cpu_reconfig_cpu_test_bench.v"                                       -work alt_xcvr_reconfig_0            
  vlog                                                                  "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/alt_xcvr_reconfig_cpu_mm_interconnect_0.v"                                             -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/alt_xcvr_reconfig_cpu_irq_mapper.sv"                      -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog                                                                  "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/altera_reset_controller.v"                                                             -work alt_xcvr_reconfig_0            
  vlog                                                                  "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/altera_reset_synchronizer.v"                                                           -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/altera_merlin_master_translator.sv"                       -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/altera_merlin_slave_translator.sv"                        -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/altera_merlin_master_agent.sv"                            -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/altera_merlin_slave_agent.sv"                             -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/altera_merlin_burst_uncompressor.sv"                      -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog                                                                  "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/altera_avalon_sc_fifo.v"                                                               -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/alt_xcvr_reconfig_cpu_mm_interconnect_0_router.sv"        -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/alt_xcvr_reconfig_cpu_mm_interconnect_0_router_001.sv"    -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/alt_xcvr_reconfig_cpu_mm_interconnect_0_router_002.sv"    -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/alt_xcvr_reconfig_cpu_mm_interconnect_0_router_003.sv"    -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/alt_xcvr_reconfig_cpu_mm_interconnect_0_cmd_demux.sv"     -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/alt_xcvr_reconfig_cpu_mm_interconnect_0_cmd_demux_001.sv" -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/altera_merlin_arbitrator.sv"                              -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/alt_xcvr_reconfig_cpu_mm_interconnect_0_cmd_mux.sv"       -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/alt_xcvr_reconfig_cpu_mm_interconnect_0_cmd_mux_001.sv"   -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/alt_xcvr_reconfig_cpu_mm_interconnect_0_rsp_mux.sv"       -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/alt_xcvr_reconfig_cpu_mm_interconnect_0_rsp_mux_001.sv"   -L altera_common_sv_packages -work alt_xcvr_reconfig_0            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/alt_xcvr_reconfig_h.sv"                                   -L altera_common_sv_packages -work pcie_reconfig_driver_0         
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/altpcie_reconfig_driver.sv"                               -L altera_common_sv_packages -work pcie_reconfig_driver_0         
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/altpcied_sv_hwtcl.sv"                                     -L altera_common_sv_packages -work APPS                           
  vlog                                                                  "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/altpcierd_hip_rs.v"                                                                    -work APPS                           
  vlog                                                                  "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/altpcierd_tl_cfg_sample.v"                                                             -work APPS                           
  vlog                                                                  "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/altpcierd_rx_ecrc_128_sim.v"                                                           -work APPS                           
  vlog                                                                  "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/altpcierd_rx_ecrc_64_sim.v"                                                            -work APPS                           
  vlog                                                                  "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/altpcierd_tx_ecrc_128_sim.v"                                                           -work APPS                           
  vlog                                                                  "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/altpcierd_tx_ecrc_64_sim.v"                                                            -work APPS                           
  vlog                                                                  "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/altpcierd_ast256_downstream.v"                                                         -work APPS                           
  vlog                                                                  "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/altpcierd_cdma_app_icm.v"                                                              -work APPS                           
  vlog                                                                  "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/altpcierd_cdma_ast_msi.v"                                                              -work APPS                           
  vlog                                                                  "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/altpcierd_cdma_ast_rx.v"                                                               -work APPS                           
  vlog                                                                  "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/altpcierd_cdma_ast_rx_128.v"                                                           -work APPS                           
  vlog                                                                  "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/altpcierd_cdma_ast_rx_64.v"                                                            -work APPS                           
  vlog                                                                  "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/altpcierd_cdma_ast_tx.v"                                                               -work APPS                           
  vlog                                                                  "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/altpcierd_cdma_ast_tx_128.v"                                                           -work APPS                           
  vlog                                                                  "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/altpcierd_cdma_ast_tx_64.v"                                                            -work APPS                           
  vlog                                                                  "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/altpcierd_cdma_ecrc_check_128.v"                                                       -work APPS                           
  vlog                                                                  "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/altpcierd_cdma_ecrc_check_64.v"                                                        -work APPS                           
  vlog                                                                  "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/altpcierd_cdma_ecrc_gen.v"                                                             -work APPS                           
  vlog                                                                  "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/altpcierd_cdma_ecrc_gen_calc.v"                                                        -work APPS                           
  vlog                                                                  "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/altpcierd_cdma_ecrc_gen_ctl_128.v"                                                     -work APPS                           
  vlog                                                                  "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/altpcierd_cdma_ecrc_gen_ctl_64.v"                                                      -work APPS                           
  vlog                                                                  "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/altpcierd_cdma_ecrc_gen_datapath.v"                                                    -work APPS                           
  vlog                                                                  "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/altpcierd_compliance_test.v"                                                           -work APPS                           
  vlog                                                                  "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/altpcierd_cpld_rx_buffer.v"                                                            -work APPS                           
  vlog                                                                  "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/altpcierd_cplerr_lmi.v"                                                                -work APPS                           
  vlog                                                                  "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/altpcierd_dma_descriptor.v"                                                            -work APPS                           
  vlog                                                                  "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/altpcierd_dma_dt.v"                                                                    -work APPS                           
  vlog                                                                  "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/altpcierd_dma_prg_reg.v"                                                               -work APPS                           
  vlog                                                                  "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/altpcierd_example_app_chaining.v"                                                      -work APPS                           
  vlog                                                                  "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/altpcierd_npcred_monitor.v"                                                            -work APPS                           
  vlog                                                                  "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/altpcierd_pcie_reconfig_initiator.v"                                                   -work APPS                           
  vlog                                                                  "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/altpcierd_rc_slave.v"                                                                  -work APPS                           
  vlog                                                                  "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/altpcierd_read_dma_requester.v"                                                        -work APPS                           
  vlog                                                                  "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/altpcierd_read_dma_requester_128.v"                                                    -work APPS                           
  vlog                                                                  "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/altpcierd_reconfig_clk_pll.v"                                                          -work APPS                           
  vlog                                                                  "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/altpcierd_reg_access.v"                                                                -work APPS                           
  vlog                                                                  "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/altpcierd_rxtx_downstream_intf.v"                                                      -work APPS                           
  vlog                                                                  "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/altpcierd_tx_ecrc_ctl_fifo.v"                                                          -work APPS                           
  vlog                                                                  "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/altpcierd_tx_ecrc_data_fifo.v"                                                         -work APPS                           
  vlog                                                                  "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/altpcierd_tx_ecrc_fifo.v"                                                              -work APPS                           
  vlog                                                                  "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/altpcierd_write_dma_requester.v"                                                       -work APPS                           
  vlog                                                                  "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/altpcierd_write_dma_requester_128.v"                                                   -work APPS                           
  vlog                                                                  "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/altpcie_sv_hip_ast_hwtcl.v"                                                            -work DUT                            
  vlog                                                                  "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/altpcie_hip_256_pipen1b.v"                                                             -work DUT                            
  vlog                                                                  "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/altpcie_rs_serdes.v"                                                                   -work DUT                            
  vlog                                                                  "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/altpcie_rs_hip.v"                                                                      -work DUT                            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/altpcie_ptk.sv"                                           -L altera_common_sv_packages -work DUT                            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/altpcie_monitor_sv_dlhip_sim.sv"                          -L altera_common_sv_packages -work DUT                            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/altera_xcvr_functions.sv"                                 -L altera_common_sv_packages -work DUT                            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/sv_pcs.sv"                                                -L altera_common_sv_packages -work DUT                            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/sv_pcs_ch.sv"                                             -L altera_common_sv_packages -work DUT                            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/sv_pma.sv"                                                -L altera_common_sv_packages -work DUT                            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/sv_reconfig_bundle_to_xcvr.sv"                            -L altera_common_sv_packages -work DUT                            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/sv_reconfig_bundle_to_ip.sv"                              -L altera_common_sv_packages -work DUT                            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/sv_reconfig_bundle_merger.sv"                             -L altera_common_sv_packages -work DUT                            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/sv_rx_pma.sv"                                             -L altera_common_sv_packages -work DUT                            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/sv_tx_pma.sv"                                             -L altera_common_sv_packages -work DUT                            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/sv_tx_pma_ch.sv"                                          -L altera_common_sv_packages -work DUT                            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/sv_xcvr_h.sv"                                             -L altera_common_sv_packages -work DUT                            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/sv_xcvr_avmm_csr.sv"                                      -L altera_common_sv_packages -work DUT                            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/sv_xcvr_avmm_dcd.sv"                                      -L altera_common_sv_packages -work DUT                            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/sv_xcvr_avmm.sv"                                          -L altera_common_sv_packages -work DUT                            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/sv_xcvr_data_adapter.sv"                                  -L altera_common_sv_packages -work DUT                            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/sv_xcvr_native.sv"                                        -L altera_common_sv_packages -work DUT                            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/sv_xcvr_plls.sv"                                          -L altera_common_sv_packages -work DUT                            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/alt_xcvr_resync.sv"                                       -L altera_common_sv_packages -work DUT                            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/sv_hssi_10g_rx_pcs_rbc.sv"                                -L altera_common_sv_packages -work DUT                            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/sv_hssi_10g_tx_pcs_rbc.sv"                                -L altera_common_sv_packages -work DUT                            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/sv_hssi_8g_rx_pcs_rbc.sv"                                 -L altera_common_sv_packages -work DUT                            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/sv_hssi_8g_tx_pcs_rbc.sv"                                 -L altera_common_sv_packages -work DUT                            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/sv_hssi_8g_pcs_aggregate_rbc.sv"                          -L altera_common_sv_packages -work DUT                            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/sv_hssi_common_pcs_pma_interface_rbc.sv"                  -L altera_common_sv_packages -work DUT                            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/sv_hssi_common_pld_pcs_interface_rbc.sv"                  -L altera_common_sv_packages -work DUT                            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/sv_hssi_pipe_gen1_2_rbc.sv"                               -L altera_common_sv_packages -work DUT                            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/sv_hssi_pipe_gen3_rbc.sv"                                 -L altera_common_sv_packages -work DUT                            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/sv_hssi_rx_pcs_pma_interface_rbc.sv"                      -L altera_common_sv_packages -work DUT                            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/sv_hssi_rx_pld_pcs_interface_rbc.sv"                      -L altera_common_sv_packages -work DUT                            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/sv_hssi_tx_pcs_pma_interface_rbc.sv"                      -L altera_common_sv_packages -work DUT                            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/sv_hssi_tx_pld_pcs_interface_rbc.sv"                      -L altera_common_sv_packages -work DUT                            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/sv_xcvr_emsip_adapter.sv"                                 -L altera_common_sv_packages -work DUT                            
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/sv_xcvr_pipe_native.sv"                                   -L altera_common_sv_packages -work DUT                            
  vlog     "+incdir+$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/" "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/altpcietb_ltssm_mon.v"                                                                 -work DUT_pcie_tb                    
  vlog     "+incdir+$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/" "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/altpcietb_pipe_phy.v"                                                                  -work DUT_pcie_tb                    
  vlog     "+incdir+$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/" "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/altpcietb_pipe32_hip_interface.v"                                                      -work DUT_pcie_tb                    
  vlog     "+incdir+$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/" "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/altpcietb_pipe32_driver.v"                                                             -work DUT_pcie_tb                    
  vlog     "+incdir+$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/" "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/altpcie_tbed_sv_hwtcl.v"                                                               -work DUT_pcie_tb                    
  vlog     "+incdir+$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/" "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/altpcietb_bfm_top_rp.v"                                                                -work DUT_pcie_tb                    
  vlog     "+incdir+$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/" "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/altpcietb_bfm_rp_gen2_x8.v"                                                            -work DUT_pcie_tb                    
  vlog     "+incdir+$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/" "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/altpcietb_bfm_driver_chaining.v"                                                       -work DUT_pcie_tb                    
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/altera_avalon_reset_source.sv"                            -L altera_common_sv_packages -work mkPcieS5Top_inst_clk_50_rst_bfm
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/altera_avalon_clock_source.sv"                            -L altera_common_sv_packages -work mkPcieS5Top_inst_clk_50_bfm    
  vlog -sv                                                              "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/altera_avalon_clock_source.sv"                            -L altera_common_sv_packages -work mkPcieS5Top_inst_clk_50_bfm    
  vlog                                                                  "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/altera_pcie_sv_hip_ast_wrapper.v"                                                                         -work APPS 
  vlog                                                                  "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/altera_pcie_reconfig_driver_wrapper.v"                                                                         -work APPS 
  vlog                                                                  "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/alt_xcvr_reconfig_wrapper.v"                                                                         -work APPS 
  vlog                                                                  "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/altera_pcie_hip_ast_ed.v"                                                                         -work APPS 
  vlog                                                                  "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/CONNECTNET.v"                                                                         -work APPS 
  vlog                                                                  "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/mkPcieS5Wrap.v"                                                                         -work APPS 
  vlog                                                                  "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/submodules/mkPcieS5Top.v"                                                                         -work APPS 
  vlog                                                                  "$QSYS_SIMDIR/mkPcieS5Top_tb/simulation/mkPcieS5Top_tb.v"                                                                                                                      
}

# ----------------------------------------
# Elaborate top level design
alias elab {
  echo "\[exec\] elab"
  eval vsim -t ps $ELAB_OPTIONS -L work -L work_lib -L altera_common_sv_packages -L rst_controller -L alt_xcvr_reconfig_0 -L pcie_reconfig_driver_0 -L APPS -L DUT -L DUT_pcie_tb -L mkPcieS5Top_inst_clk_50_rst_bfm -L mkPcieS5Top_inst_clk_50_bfm -L mkPcieS5Top_inst -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L stratixiv_hssi_ver -L stratixiv_pcie_hip_ver -L stratixiv_ver -L stratixv_ver -L stratixv_hssi_ver -L stratixv_pcie_hip_ver $TOP_LEVEL_NAME
}

# ----------------------------------------
# Elaborate the top level design with novopt option
alias elab_debug {
  echo "\[exec\] elab_debug"
  eval vsim -novopt -t ps $ELAB_OPTIONS -L work -L work_lib -L altera_common_sv_packages -L rst_controller -L alt_xcvr_reconfig_0 -L pcie_reconfig_driver_0 -L APPS -L DUT -L DUT_pcie_tb -L mkPcieS5Top_inst_clk_50_rst_bfm -L mkPcieS5Top_inst_clk_50_bfm -L mkPcieS5Top_inst -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L stratixiv_hssi_ver -L stratixiv_pcie_hip_ver -L stratixiv_ver -L stratixv_ver -L stratixv_hssi_ver -L stratixv_pcie_hip_ver $TOP_LEVEL_NAME
}

# ----------------------------------------
# Compile all the design files and elaborate the top level design
alias ld "
  dev_com
  com
  elab
"

# ----------------------------------------
# Compile all the design files and elaborate the top level design with -novopt
alias ld_debug "
  dev_com
  com
  elab_debug
"

# ----------------------------------------
# Print out user commmand line aliases
alias h {
  echo "List Of Command Line Aliases"
  echo
  echo "file_copy                     -- Copy ROM/RAM files to simulation directory"
  echo
  echo "dev_com                       -- Compile device library files"
  echo
  echo "com                           -- Compile the design files in correct order"
  echo
  echo "elab                          -- Elaborate top level design"
  echo
  echo "elab_debug                    -- Elaborate the top level design with novopt option"
  echo
  echo "ld                            -- Compile all the design files and elaborate the top level design"
  echo
  echo "ld_debug                      -- Compile all the design files and elaborate the top level design with -novopt"
  echo
  echo 
  echo
  echo "List Of Variables"
  echo
  echo "TOP_LEVEL_NAME                -- Top level module name."
  echo
  echo "SYSTEM_INSTANCE_NAME          -- Instantiated system module name inside top level module."
  echo
  echo "QSYS_SIMDIR                   -- Qsys base simulation directory."
  echo
  echo "QUARTUS_INSTALL_DIR           -- Quartus installation directory."
}
file_copy
h
