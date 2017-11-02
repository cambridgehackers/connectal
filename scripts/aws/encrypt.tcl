# Amazon FPGA Hardware Development Kit
#
# Copyright 2016 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Amazon Software License (the "License"). You may not use
# this file except in compliance with the License. A copy of the License is
# located at
#
#    http://aws.amazon.com/asl/
#
# or in the "license" file accompanying this file. This file is distributed on
# an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or
# implied. See the License for the specific language governing permissions and
# limitations under the License.

# TODO:
# Add check if CL_DIR and HDK_SHELL_DIR directories exist
# Add check if /build and /build/src_port_encryption directories exist
# Add check if the vivado_keyfile exist

set HDK_SHELL_DIR $::env(HDK_SHELL_DIR)
set HDK_SHELL_DESIGN_DIR $::env(HDK_SHELL_DESIGN_DIR)
set CL_DIR $::env(CL_DIR)
set TARGET_DIR $CL_DIR/build/src_post_encryption
set UNUSED_TEMPLATES_DIR $HDK_SHELL_DESIGN_DIR/interfaces
set BLUESPECDIR $::env(BLUESPECDIR)
set CONNECTALDIR $::env(CONNECTALDIR)

# Remove any previously encrypted files, that may no longer be used
exec rm -f $TARGET_DIR/*

#---- Developr would replace this section with design files ----

## Change file names and paths below to reflect your CL area.  DO NOT include AWS RTL files.

foreach {file} [glob -nocomplain -- $CL_DIR/verilog/*.v $CL_DIR/verilog/*.sv $CL_DIR/verilog/*.vh $CL_DIR/generatedbsv/ConnectalProjectConfig.bsv] {
    file copy -force $file            $TARGET_DIR
}
foreach {dir} "$BLUESPECDIR/Verilog $BLUESPECDIR/Verilog.Vivado $CONNECTALDIR/verilog $HDK_SHELL_DIR/design/interfaces" {
    puts "Looking in directory $dir"
    foreach {pat} {FIFO BRAM Reg Counter cl_ unused aws} {
	foreach {file} [glob -nocomplain -- $dir/*$pat*.v $dir/*$pat*.vh $dir/*$pat*.inc $dir/*$pat*.sv] {
	    puts "Copying file $file"
	    file copy -force $file            $TARGET_DIR
	}
    }
}

#---- End of section replaced by Developr ---

# Make sure files have write permissions for the encryption
exec chmod +w {*}[glob $TARGET_DIR/*]

# encrypt .v/.sv/.vh/inc as verilog files
# encrypt -k $HDK_SHELL_DIR/build/scripts/vivado_keyfile.txt -lang verilog  [glob -nocomplain -- $TARGET_DIR/*.{v,sv}]
## [glob -nocomplain -- $TARGET_DIR/*.vh] [glob -nocomplain -- $TARGET_DIR/*.inc]

# encrypt *vhdl files
# encrypt -k $HDK_SHELL_DIR/build/scripts/vivado_vhdl_keyfile.txt -lang vhdl -quiet [ glob -nocomplain -- $TARGET_DIR/*.vhd? ]


