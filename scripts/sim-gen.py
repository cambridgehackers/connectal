#!/usr/bin/python
## Copyright (c) 2015 Cornell University

## Permission is hereby granted, free of charge, to any person
## obtaining a copy of this software and associated documentation
## files (the "Software"), to deal in the Software without
## restriction, including without limitation the rights to use, copy,
## modify, merge, publish, distribute, sublicense, and/or sell copies
## of the Software, and to permit persons to whom the Software is
## furnished to do so, subject to the following conditions:

## The above copyright notice and this permission notice shall be
## included in all copies or substantial portions of the Software.

## THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
## EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
## MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
## NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
## BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
## ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
## CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
## SOFTWARE.

## Generate Makefile for Modelsim Simulation of Altera PCIE hard IP
import os, sys, shutil, string
import argparse
import subprocess
import glob
import time
import pprint
import json

argparser = argparse.ArgumentParser("Generate Simulation Makefile for Modelsim.")
argparser.add_argument('-o', '--output', help="output file name")
argparser.add_argument('-s', '--simlibs', help="path to simulation library")
argparser.add_argument('-d', '--simdir', help="directory to generate compiled simulation files")
argparser.add_argument('-p', '--projdir', help="directory to project files")
argparser.add_argument('-c', '--connectaldir', help="directory to connectal")
argparser.add_argument('-g', '--generated', help="directory to generated verilog files")
argparser.add_argument('-t', '--testbench', help="directory to generated testbench files")
argparser.add_argument('-T', '--topmodule', help="top testbench module")

# Must be set to avoid error in encrypted RTL
# E.g.: stratixv_hssi_gen3_pcie_hip/<protected>/<protected>/<protected> File: nofile
timescale="-timescale \"1ns / 1ps\""

makeCompileTemplate='''
#
# Auto-generated Makefile for Modelsim PCIe Simulation.
# Do Not Modify.
#
.PHONY: all

prepare_lib:
	vlib %(sim_dir_path)s/work
	vlib %(sim_dir_path)s/altera_ver
	vlib %(sim_dir_path)s/lpm_ver
	vlib %(sim_dir_path)s/sgate_ver
	vlib %(sim_dir_path)s/altera_mf_ver
	vlib %(sim_dir_path)s/altera_lnsim_ver
	vlib %(sim_dir_path)s/stratixiv_hssi_ver
	vlib %(sim_dir_path)s/stratixiv_pcie_hip_ver
	vlib %(sim_dir_path)s/stratixiv_ver
	vlib %(sim_dir_path)s/stratixv_ver
	vlib %(sim_dir_path)s/stratixv_hssi_ver
	vlib %(sim_dir_path)s/stratixv_pcie_hip_ver
	vlib %(sim_dir_path)s/rst_controller
	vlib %(sim_dir_path)s/alt_xcvr_reconfig
	vlib %(sim_dir_path)s/pcie_reconfig_driver
	vlib %(sim_dir_path)s/pcie_hip
	vlib %(sim_dir_path)s/pcie_hip_pcie_tb

create_dir:
	mkdir -p %(sim_dir_path)s

compile-libraries: create_dir prepare_lib
	echo "\[exec\] dev_com"
	vlog %(timescale)s     %(quartus_install_path)s/eda/sim_lib/altera_primitives.v                     -work %(sim_dir_path)s/altera_ver
	vlog %(timescale)s     %(quartus_install_path)s/eda/sim_lib/220model.v                              -work %(sim_dir_path)s/lpm_ver
	vlog %(timescale)s     %(quartus_install_path)s/eda/sim_lib/sgate.v                                 -work %(sim_dir_path)s/sgate_ver
	vlog %(timescale)s     %(quartus_install_path)s/eda/sim_lib/altera_mf.v                             -work %(sim_dir_path)s/altera_mf_ver
	vlog %(timescale)s -sv %(quartus_install_path)s/eda/sim_lib/altera_lnsim.sv                         -work %(sim_dir_path)s/altera_lnsim_ver
	vlog %(timescale)s     %(quartus_install_path)s/eda/sim_lib/stratixiv_hssi_atoms.v                  -work %(sim_dir_path)s/stratixiv_hssi_ver
	vlog %(timescale)s     %(quartus_install_path)s/eda/sim_lib/stratixiv_pcie_hip_atoms.v              -work %(sim_dir_path)s/stratixiv_pcie_hip_ver
	vlog %(timescale)s     %(quartus_install_path)s/eda/sim_lib/stratixiv_atoms.v                       -work %(sim_dir_path)s/stratixiv_ver
	vlog %(timescale)s     %(quartus_install_path)s/eda/sim_lib/mentor/stratixv_atoms_ncrypt.v          -work %(sim_dir_path)s/stratixv_ver
	vlog %(timescale)s     %(quartus_install_path)s/eda/sim_lib/stratixv_atoms.v                        -work %(sim_dir_path)s/stratixv_ver
	vlog %(timescale)s     %(quartus_install_path)s/eda/sim_lib/mentor/stratixv_hssi_atoms_ncrypt.v     -work %(sim_dir_path)s/stratixv_hssi_ver
	vlog %(timescale)s     %(quartus_install_path)s/eda/sim_lib/stratixv_hssi_atoms.v                   -work %(sim_dir_path)s/stratixv_hssi_ver
	vlog %(timescale)s     %(quartus_install_path)s/eda/sim_lib/mentor/stratixv_pcie_hip_atoms_ncrypt.v -work %(sim_dir_path)s/stratixv_pcie_hip_ver
	vlog %(timescale)s     %(quartus_install_path)s/eda/sim_lib/stratixv_pcie_hip_atoms.v               -work %(sim_dir_path)s/stratixv_pcie_hip_ver
	echo "\[exec\] com"
	vlog %(timescale)s      %(sim_file_path)s/submodules/altera_reset_controller.v                                -work %(sim_dir_path)s/rst_controller
	vlog %(timescale)s      %(sim_file_path)s/submodules/altera_reset_synchronizer.v                              -work %(sim_dir_path)s/rst_controller
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/altera_xcvr_functions.sv                                 -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/mentor/altera_xcvr_functions.sv                          -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/sv_xcvr_h.sv                                             -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/mentor/sv_xcvr_h.sv                                      -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/alt_xcvr_resync.sv                                       -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/mentor/alt_xcvr_resync.sv                                -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/alt_xcvr_reconfig_h.sv                                   -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/mentor/alt_xcvr_reconfig_h.sv                            -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/sv_xcvr_dfe_cal_sweep_h.sv                               -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/mentor/sv_xcvr_dfe_cal_sweep_h.sv                        -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/alt_xcvr_reconfig.sv                                     -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/mentor/alt_xcvr_reconfig.sv                              -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/alt_xcvr_reconfig_sv.sv                                  -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/mentor/alt_xcvr_reconfig_sv.sv                           -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/alt_xcvr_reconfig_cal_seq.sv                             -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/mentor/alt_xcvr_reconfig_cal_seq.sv                      -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/alt_xreconf_cif.sv                                       -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/mentor/alt_xreconf_cif.sv                                -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/alt_xreconf_uif.sv                                       -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/mentor/alt_xreconf_uif.sv                                -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/alt_xreconf_basic_acq.sv                                 -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/mentor/alt_xreconf_basic_acq.sv                          -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/alt_xcvr_reconfig_analog.sv                              -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/mentor/alt_xcvr_reconfig_analog.sv                       -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/alt_xcvr_reconfig_analog_sv.sv                           -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/mentor/alt_xcvr_reconfig_analog_sv.sv                    -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/alt_xreconf_analog_datactrl.sv                           -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/mentor/alt_xreconf_analog_datactrl.sv                    -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/alt_xreconf_analog_rmw.sv                                -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/mentor/alt_xreconf_analog_rmw.sv                         -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/alt_xreconf_analog_ctrlsm.sv                             -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/mentor/alt_xreconf_analog_ctrlsm.sv                      -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/alt_xcvr_reconfig_offset_cancellation.sv                 -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/mentor/alt_xcvr_reconfig_offset_cancellation.sv          -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/alt_xcvr_reconfig_offset_cancellation_sv.sv              -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/mentor/alt_xcvr_reconfig_offset_cancellation_sv.sv       -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/alt_xcvr_reconfig_eyemon.sv                              -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/mentor/alt_xcvr_reconfig_eyemon.sv                       -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/alt_xcvr_reconfig_eyemon_sv.sv                           -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/alt_xcvr_reconfig_eyemon_ctrl_sv.sv                      -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/alt_xcvr_reconfig_eyemon_ber_sv.sv                       -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s      %(sim_file_path)s/submodules/ber_reader_dcfifo.v                                      -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/step_to_mon_sv.sv                                        -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/mon_to_step_sv.sv                                        -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/mentor/alt_xcvr_reconfig_eyemon_sv.sv                    -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/mentor/alt_xcvr_reconfig_eyemon_ctrl_sv.sv               -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/mentor/alt_xcvr_reconfig_eyemon_ber_sv.sv                -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s      %(sim_file_path)s/submodules/mentor/ber_reader_dcfifo.v                               -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/mentor/step_to_mon_sv.sv                                 -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/mentor/mon_to_step_sv.sv                                 -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/alt_xcvr_reconfig_dfe.sv                                 -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/mentor/alt_xcvr_reconfig_dfe.sv                          -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/alt_xcvr_reconfig_dfe_sv.sv                              -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/alt_xcvr_reconfig_dfe_reg_sv.sv                          -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/alt_xcvr_reconfig_dfe_cal_sv.sv                          -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/alt_xcvr_reconfig_dfe_cal_sweep_sv.sv                    -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/alt_xcvr_reconfig_dfe_cal_sweep_datapath_sv.sv           -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/alt_xcvr_reconfig_dfe_oc_cal_sv.sv                       -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/alt_xcvr_reconfig_dfe_pi_phase_sv.sv                     -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/alt_xcvr_reconfig_dfe_step_to_mon_en_sv.sv               -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/alt_xcvr_reconfig_dfe_adapt_tap_sv.sv                    -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/alt_xcvr_reconfig_dfe_ctrl_mux_sv.sv                     -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/alt_xcvr_reconfig_dfe_local_reset_sv.sv                  -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/alt_xcvr_reconfig_dfe_cal_sim_sv.sv                      -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/alt_xcvr_reconfig_dfe_adapt_tap_sim_sv.sv                -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/mentor/alt_xcvr_reconfig_dfe_sv.sv                       -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/mentor/alt_xcvr_reconfig_dfe_reg_sv.sv                   -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/mentor/alt_xcvr_reconfig_dfe_cal_sv.sv                   -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/mentor/alt_xcvr_reconfig_dfe_cal_sweep_sv.sv             -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/mentor/alt_xcvr_reconfig_dfe_cal_sweep_datapath_sv.sv    -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/mentor/alt_xcvr_reconfig_dfe_oc_cal_sv.sv                -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/mentor/alt_xcvr_reconfig_dfe_pi_phase_sv.sv              -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/mentor/alt_xcvr_reconfig_dfe_step_to_mon_en_sv.sv        -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/mentor/alt_xcvr_reconfig_dfe_adapt_tap_sv.sv             -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/mentor/alt_xcvr_reconfig_dfe_ctrl_mux_sv.sv              -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/mentor/alt_xcvr_reconfig_dfe_local_reset_sv.sv           -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/mentor/alt_xcvr_reconfig_dfe_cal_sim_sv.sv               -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/mentor/alt_xcvr_reconfig_dfe_adapt_tap_sim_sv.sv         -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/alt_xcvr_reconfig_adce.sv                                -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/mentor/alt_xcvr_reconfig_adce.sv                         -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/alt_xcvr_reconfig_adce_sv.sv                             -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/alt_xcvr_reconfig_adce_datactrl_sv.sv                    -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/mentor/alt_xcvr_reconfig_adce_sv.sv                      -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/mentor/alt_xcvr_reconfig_adce_datactrl_sv.sv             -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/alt_xcvr_reconfig_dcd.sv                                 -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/mentor/alt_xcvr_reconfig_dcd.sv                          -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/alt_xcvr_reconfig_dcd_sv.sv                              -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/alt_xcvr_reconfig_dcd_cal.sv                             -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/alt_xcvr_reconfig_dcd_control.sv                         -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/alt_xcvr_reconfig_dcd_datapath.sv                        -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/alt_xcvr_reconfig_dcd_pll_reset.sv                       -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/alt_xcvr_reconfig_dcd_eye_width.sv                       -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/alt_xcvr_reconfig_dcd_align_clk.sv                       -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/alt_xcvr_reconfig_dcd_get_sum.sv                         -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/alt_xcvr_reconfig_dcd_cal_sim_model.sv                   -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/mentor/alt_xcvr_reconfig_dcd_sv.sv                       -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/mentor/alt_xcvr_reconfig_dcd_cal.sv                      -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/mentor/alt_xcvr_reconfig_dcd_control.sv                  -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/mentor/alt_xcvr_reconfig_dcd_datapath.sv                 -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/mentor/alt_xcvr_reconfig_dcd_pll_reset.sv                -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/mentor/alt_xcvr_reconfig_dcd_eye_width.sv                -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/mentor/alt_xcvr_reconfig_dcd_align_clk.sv                -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/mentor/alt_xcvr_reconfig_dcd_get_sum.sv                  -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/mentor/alt_xcvr_reconfig_dcd_cal_sim_model.sv            -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/alt_xcvr_reconfig_mif.sv                                 -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/mentor/alt_xcvr_reconfig_mif.sv                          -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/sv_xcvr_reconfig_mif.sv                                  -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/sv_xcvr_reconfig_mif_ctrl.sv                             -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/sv_xcvr_reconfig_mif_avmm.sv                             -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/mentor/sv_xcvr_reconfig_mif.sv                           -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/mentor/sv_xcvr_reconfig_mif_ctrl.sv                      -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/mentor/sv_xcvr_reconfig_mif_avmm.sv                      -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/alt_xcvr_reconfig_pll.sv                                 -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/mentor/alt_xcvr_reconfig_pll.sv                          -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/sv_xcvr_reconfig_pll.sv                                  -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/sv_xcvr_reconfig_pll_ctrl.sv                             -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/mentor/sv_xcvr_reconfig_pll.sv                           -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/mentor/sv_xcvr_reconfig_pll_ctrl.sv                      -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/alt_xcvr_reconfig_soc.sv                                 -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/alt_xcvr_reconfig_cpu_ram.sv                             -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/alt_xcvr_reconfig_direct.sv                              -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/sv_xrbasic_l2p_addr.sv                                   -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/sv_xrbasic_l2p_ch.sv                                     -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/sv_xrbasic_l2p_rom.sv                                    -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/sv_xrbasic_lif_csr.sv                                    -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/sv_xrbasic_lif.sv                                        -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/sv_xcvr_reconfig_basic.sv                                -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/alt_arbiter_acq.sv                                       -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/alt_xcvr_reconfig_basic.sv                               -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/mentor/sv_xrbasic_l2p_addr.sv                            -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/mentor/sv_xrbasic_l2p_ch.sv                              -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/mentor/sv_xrbasic_l2p_rom.sv                             -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/mentor/sv_xrbasic_lif_csr.sv                             -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/mentor/sv_xrbasic_lif.sv                                 -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/mentor/sv_xcvr_reconfig_basic.sv                         -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/mentor/alt_arbiter_acq.sv                                -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/mentor/alt_xcvr_reconfig_basic.sv                        -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/alt_xcvr_arbiter.sv                                      -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/alt_xcvr_m2s.sv                                          -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s      %(sim_file_path)s/submodules/altera_wait_generate.v                                   -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/alt_xcvr_csr_selector.sv                                 -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/mentor/alt_xcvr_arbiter.sv                               -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/mentor/alt_xcvr_m2s.sv                                   -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s      %(sim_file_path)s/submodules/mentor/altera_wait_generate.v                            -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/mentor/alt_xcvr_csr_selector.sv                          -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/sv_reconfig_bundle_to_basic.sv                           -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/mentor/sv_reconfig_bundle_to_basic.sv                    -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s      %(sim_file_path)s/submodules/alt_xcvr_reconfig_cpu.v                                  -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s      %(sim_file_path)s/submodules/alt_xcvr_reconfig_cpu_reconfig_cpu.v                     -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s      %(sim_file_path)s/submodules/alt_xcvr_reconfig_cpu_reconfig_cpu_test_bench.v          -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s      %(sim_file_path)s/submodules/alt_xcvr_reconfig_cpu_mm_interconnect_0.v                -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/alt_xcvr_reconfig_cpu_irq_mapper.sv                      -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s      %(sim_file_path)s/submodules/altera_reset_controller.v                                -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s      %(sim_file_path)s/submodules/altera_reset_synchronizer.v                              -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/altera_merlin_master_translator.sv                       -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/altera_merlin_slave_translator.sv                        -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/altera_merlin_master_agent.sv                            -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/altera_merlin_slave_agent.sv                             -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/altera_merlin_burst_uncompressor.sv                      -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s      %(sim_file_path)s/submodules/altera_avalon_sc_fifo.v                                  -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/alt_xcvr_reconfig_cpu_mm_interconnect_0_router.sv        -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/alt_xcvr_reconfig_cpu_mm_interconnect_0_router_001.sv    -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/alt_xcvr_reconfig_cpu_mm_interconnect_0_router_002.sv    -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/alt_xcvr_reconfig_cpu_mm_interconnect_0_router_003.sv    -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/alt_xcvr_reconfig_cpu_mm_interconnect_0_cmd_demux.sv     -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/alt_xcvr_reconfig_cpu_mm_interconnect_0_cmd_demux_001.sv -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/altera_merlin_arbitrator.sv                              -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/alt_xcvr_reconfig_cpu_mm_interconnect_0_cmd_mux.sv       -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/alt_xcvr_reconfig_cpu_mm_interconnect_0_cmd_mux_001.sv   -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/alt_xcvr_reconfig_cpu_mm_interconnect_0_rsp_mux.sv       -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/alt_xcvr_reconfig_cpu_mm_interconnect_0_rsp_mux_001.sv   -work %(sim_dir_path)s/alt_xcvr_reconfig
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/alt_xcvr_reconfig_h.sv                                   -work %(sim_dir_path)s/pcie_reconfig_driver
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/altpcie_reconfig_driver.sv                               -work %(sim_dir_path)s/pcie_reconfig_driver
	vlog %(timescale)s      %(sim_file_path)s/submodules/altpcie_sv_hip_ast_hwtcl.v                               -work %(sim_dir_path)s/pcie_hip
	vlog %(timescale)s      %(sim_file_path)s/submodules/altpcie_hip_256_pipen1b.v                                -work %(sim_dir_path)s/pcie_hip
	vlog %(timescale)s      %(sim_file_path)s/submodules/altpcie_rs_serdes.v                                      -work %(sim_dir_path)s/pcie_hip
	vlog %(timescale)s      %(sim_file_path)s/submodules/altpcie_rs_hip.v                                         -work %(sim_dir_path)s/pcie_hip
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/altpcie_ptk.sv                                           -work %(sim_dir_path)s/pcie_hip
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/altpcie_monitor_sv_dlhip_sim.sv                          -work %(sim_dir_path)s/pcie_hip
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/altera_xcvr_functions.sv                                 -work %(sim_dir_path)s/pcie_hip
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/sv_pcs.sv                                                -work %(sim_dir_path)s/pcie_hip
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/sv_pcs_ch.sv                                             -work %(sim_dir_path)s/pcie_hip
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/sv_pma.sv                                                -work %(sim_dir_path)s/pcie_hip
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/sv_reconfig_bundle_to_xcvr.sv                            -work %(sim_dir_path)s/pcie_hip
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/sv_reconfig_bundle_to_ip.sv                              -work %(sim_dir_path)s/pcie_hip
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/sv_reconfig_bundle_merger.sv                             -work %(sim_dir_path)s/pcie_hip
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/sv_rx_pma.sv                                             -work %(sim_dir_path)s/pcie_hip
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/sv_tx_pma.sv                                             -work %(sim_dir_path)s/pcie_hip
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/sv_tx_pma_ch.sv                                          -work %(sim_dir_path)s/pcie_hip
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/sv_xcvr_h.sv                                             -work %(sim_dir_path)s/pcie_hip
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/sv_xcvr_avmm_csr.sv                                      -work %(sim_dir_path)s/pcie_hip
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/sv_xcvr_avmm_dcd.sv                                      -work %(sim_dir_path)s/pcie_hip
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/sv_xcvr_avmm.sv                                          -work %(sim_dir_path)s/pcie_hip
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/sv_xcvr_data_adapter.sv                                  -work %(sim_dir_path)s/pcie_hip
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/sv_xcvr_native.sv                                        -work %(sim_dir_path)s/pcie_hip
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/sv_xcvr_plls.sv                                          -work %(sim_dir_path)s/pcie_hip
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/alt_xcvr_resync.sv                                       -work %(sim_dir_path)s/pcie_hip
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/sv_hssi_10g_rx_pcs_rbc.sv                                -work %(sim_dir_path)s/pcie_hip
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/sv_hssi_10g_tx_pcs_rbc.sv                                -work %(sim_dir_path)s/pcie_hip
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/sv_hssi_8g_rx_pcs_rbc.sv                                 -work %(sim_dir_path)s/pcie_hip
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/sv_hssi_8g_tx_pcs_rbc.sv                                 -work %(sim_dir_path)s/pcie_hip
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/sv_hssi_8g_pcs_aggregate_rbc.sv                          -work %(sim_dir_path)s/pcie_hip
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/sv_hssi_common_pcs_pma_interface_rbc.sv                  -work %(sim_dir_path)s/pcie_hip
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/sv_hssi_common_pld_pcs_interface_rbc.sv                  -work %(sim_dir_path)s/pcie_hip
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/sv_hssi_pipe_gen1_2_rbc.sv                               -work %(sim_dir_path)s/pcie_hip
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/sv_hssi_pipe_gen3_rbc.sv                                 -work %(sim_dir_path)s/pcie_hip
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/sv_hssi_rx_pcs_pma_interface_rbc.sv                      -work %(sim_dir_path)s/pcie_hip
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/sv_hssi_rx_pld_pcs_interface_rbc.sv                      -work %(sim_dir_path)s/pcie_hip
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/sv_hssi_tx_pcs_pma_interface_rbc.sv                      -work %(sim_dir_path)s/pcie_hip
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/sv_hssi_tx_pld_pcs_interface_rbc.sv                      -work %(sim_dir_path)s/pcie_hip
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/sv_xcvr_emsip_adapter.sv                                 -work %(sim_dir_path)s/pcie_hip
	vlog %(timescale)s -sv  %(sim_file_path)s/submodules/sv_xcvr_pipe_native.sv                                   -work %(sim_dir_path)s/pcie_hip

compile-project:
	vlog %(timescale)s %(project_file_path)s/vsim/verilog/*.v   -work %(sim_dir_path)s/work

compile-common-verilog:
	vlog %(timescale)s %(common_verilog_path)s/verilog/*.v -work %(sim_dir_path)s/work

compile-generated-verilog:
	vlog %(timescale)s %(generated_verilog_path)s/*.v      -work %(sim_dir_path)s/work

compile-generated-testbench:
	vlog %(timescale)s %(generated_testbench)s/altera_pcie_testbench.v -work %(sim_dir_path)s/work
	vlog %(timescale)s %(generated_testbench)s/submodules/altpcie_tbed_sv_hwtcl.v -work %(sim_dir_path)s/pcie_hip_pcie_tb
	vlog %(timescale)s +incdir+%(generated_testbench)s/submodules/ %(generated_testbench)s/submodules/altpcietb_ltssm_mon.v -work %(sim_dir_path)s/pcie_hip_pcie_tb
	vlog %(timescale)s +incdir+%(generated_testbench)s/submodules/ %(generated_testbench)s/submodules/altpcietb_pipe_phy.v -work %(sim_dir_path)s/pcie_hip_pcie_tb
	vlog %(timescale)s +incdir+%(generated_testbench)s/submodules/ %(generated_testbench)s/submodules/altpcietb_pipe32_hip_interface.v -work %(sim_dir_path)s/pcie_hip_pcie_tb
	vlog %(timescale)s +incdir+%(generated_testbench)s/submodules/ %(generated_testbench)s/submodules/altpcietb_pipe32_driver.v -work %(sim_dir_path)s/pcie_hip_pcie_tb
	vlog %(timescale)s +incdir+%(generated_testbench)s/submodules/ %(generated_testbench)s/submodules/altpcie_tbed_sv_hwtcl.v -work %(sim_dir_path)s/pcie_hip_pcie_tb
	vlog %(timescale)s +incdir+%(generated_testbench)s/submodules/ %(generated_testbench)s/submodules/altpcietb_bfm_top_rp.v -work %(sim_dir_path)s/pcie_hip_pcie_tb
	vlog %(timescale)s +incdir+%(generated_testbench)s/submodules/ %(generated_testbench)s/submodules/altpcietb_bfm_rp_gen2_x8.v -work %(sim_dir_path)s/pcie_hip_pcie_tb
	cp %(sim_dir_path)s/../../verilog/altpcietb_bfm_driver_chaining.v %(generated_testbench)s/submodules/altpcietb_bfm_driver_chaining.v
	vlog %(timescale)s +incdir+%(generated_testbench)s/submodules/ %(generated_testbench)s/submodules/altpcietb_bfm_driver_chaining.v -work %(sim_dir_path)s/pcie_hip_pcie_tb

simulate:
	cd %(sim_dir_path)s; vsim -novopt -L work -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L stratixiv_hssi_ver -L stratixiv_pcie_hip_ver -L stratixiv_ver -L stratixv_ver -L stratixv_hssi_ver -L stratixv_pcie_hip_ver -L rst_controller -L alt_xcvr_reconfig -L pcie_hip -L pcie_hip_pcie_tb -L pcie_reconfig_driver %(top)s

simulatec:
	cd %(sim_dir_path)s; vsim -c -novopt -L work -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L stratixiv_hssi_ver -L stratixiv_pcie_hip_ver -L stratixiv_ver -L stratixv_ver -L stratixv_hssi_ver -L stratixv_pcie_hip_ver -L rst_controller -L alt_xcvr_reconfig -L pcie_hip -L pcie_hip_pcie_tb -L pcie_reconfig_driver %(top)s

all:
	make compile-libraries
	make compile-project
	make compile-common-verilog
	make compile-generated-verilog
	make compile-generated-testbench
'''

if __name__ == "__main__":
    quartus_rootdir=os.environ['QUARTUS_ROOTDIR']
    options = argparser.parse_args()
    sim_libs = options.simlibs

    (d, name) = os.path.split(options.output)
    if not os.path.exists(d):
        os.makedirs(d)
    make=open(options.output,'w')
    makefile=makeCompileTemplate % {
        'quartus_install_path': os.path.abspath(quartus_rootdir),
        'sim_file_path': os.path.abspath(options.simlibs),
        'sim_dir_path': os.path.abspath(options.simdir),
        'project_file_path': os.path.abspath(options.projdir),
        'common_verilog_path': os.path.abspath(options.connectaldir),
        'generated_verilog_path': os.path.abspath(options.generated),
        'generated_testbench': os.path.abspath(options.testbench),
        'top': options.topmodule,
        'timescale': timescale,
        }
    make.write(makefile)
    make.close()

