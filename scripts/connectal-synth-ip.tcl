# Copyright (c) 2014 Quanta Research Cambridge, Inc
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.

set scriptsdir [file dirname [info script] ]
source "$scriptsdir/../../fpgamake/tcl/ipcore.tcl"

# Altera Specific
proc create_xcvr_reconfig {core_name core_version ip_name n_interface} {
 	set params [ dict create ]
	dict set params number_of_reconfig_interfaces $n_interface
	set component_parameters {}
	foreach item [dict keys $params] {
		set val [dict get $params $item]
		lappend component_parameters --component-parameter=$item=$val
	}
    fpgamake_altera_ipcore $core_name $core_version $ip_name QUARTUS_SYNTH $component_parameters
}

proc connectal_synth_ip {core_name core_version ip_name params} {
   fpgamake_ipcore $core_name $core_version $ip_name $params
}

proc connectal_altera_synth_ip {core_name core_version ip_name params} {
   fpgamake_altera_ipcore $core_name $core_version $ip_name QUARTUS_SYNTH $params
}

proc connectal_altera_simu_ip {core_name core_version ip_name params} {
   fpgamake_altera_ipcore $core_name $core_version $ip_name SIM_VERILOG $params
}

