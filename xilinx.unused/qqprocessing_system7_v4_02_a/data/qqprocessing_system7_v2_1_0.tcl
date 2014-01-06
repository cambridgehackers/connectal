##-----------------------------------------------------------------------------
##-- (c) Copyright 2010 Xilinx, Inc. All rights reserved.
##--
##-- This file contains confidential and proprietary information
##-- of Xilinx, Inc. and is protected under U.S. and
##-- international copyright and other intellectual property
##-- laws.
##--
##-- DISCLAIMER
##-- This disclaimer is not a license and does not grant any
##-- rights to the materials distributed herewith. Except as
##-- otherwise provided in a valid license issued to you by
##-- Xilinx, and to the maximum extent permitted by applicable
##-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
##-- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
##-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
##-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
##-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
##-- (2) Xilinx shall not be liable (whether in contract or tort,
##-- including negligence, or under any other theory of
##-- liability) for any loss or damage of any kind or nature
##-- related to, arising under or in connection with these
##-- materials, including for any direct, or any indirect,
##-- special, incidental, or consequential loss or damage
##-- (including loss of data, profits, goodwill, or any type of
##-- loss or damage suffered as a result of any action brought
##-- by a third party) even if such damage or loss was
##-- reasonably foreseeable or Xilinx had been advised of the
##-- possibility of the same.
##--
##-- CRITICAL APPLICATIONS
##-- Xilinx products are not designed or intended to be fail-
##-- safe, or for use in any application requiring fail-safe
##-- performance, such as life-support or safety devices or
##-- systems, Class III medical devices, nuclear facilities,
##-- applications related to the deployment of airbags, or any
##-- other applications that could lead to death, personal
##-- injury, or severe property or environmental damage
##-- (individually and collectively, "Critical
##-- Applications"). Customer assumes the sole risk and
##-- liability of any use of Xilinx products in Critical
##-- Applications, subject only to applicable laws and
##-- regulations governing limitations on product liability.
##--
##-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
##-- PART OF THIS FILE AT ALL TIMES.
##-----------------------------------------------------------------------------




set extn so
global tcl_platform
if { [ string equal $tcl_platform(platform) windows ] } {
    set extn dll
}


## load the backend dll...
if [ catch "load libZynqConfig.${extn}" err] {
    error "Error in loading ZynqConfig library !" $err mdt_error
}



proc constraints_file { mhsinst } {

    set  filePath [xget_ncf_dir $mhsinst]
    file mkdir    $filePath
    set    instname   [xget_hw_parameter_value $mhsinst "INSTANCE"]
    set    name_lower [string   tolower   $instname]
    set    fileName   $name_lower
    append filePath   $fileName

    # Open a file for writing
    return $filePath

}


##
## EDK doesn't give IP a chance to catch closing and opening a function.
## from this TCL .. no MHS is updated .. only ASSIGNMENT = UPDATE parameters
## are created
##
## Currently this functions always re-opens the project ..
##


proc zynqconfig_do { mhsinst update_params check_params generate_constraints add_coregenrationattribute } {

    ## TODO .. BE MORE INTELLIGENT HERE .. IS IT NEEDED ?
    set sys [xget_hw_name [xget_hw_parent_handle $mhsinst ] ]
    set constrbase [constraints_file $mhsinst] 
    _zynqconfig_init $sys data __xps $constrbase


    if { [ string equal $update_params y ] } {
	set param_values [ _zynqconfig_params ] 
	#puts $param_values
	foreach param_value  $param_values {
	    set param [lindex $param_value 0 ]
	    set value [lindex $param_value 1 ]
	    set handle [ xget_hw_parameter_handle $mhsinst  $param]
            if { ! [ string equal $handle {} ] } {
	        #puts "$param ( $handle ) = $value"
                xset_hw_parameter_value $handle $value
            }
	}
    }
    
    if { [ string equal $check_params y ] } {
        set param_values [ _zynqconfig_params ] 
        foreach param_value  $param_values {
            set param [lindex $param_value 0 ]
            set value [lindex $param_value 1 ]
            set handle [ xget_hw_parameter_handle $mhsinst  $param]
            if { ! [ string equal $handle {} ] } {
                set mhs_value     [ xget_hw_subproperty_value $handle MHS_VALUE ]
                #puts "FOO: $param .. $value .. $mhs_value " 
                if { ! [ string equal $mhs_value {} ] } {
                    if { ! [ string equal $mhs_value $value] } {
                        #error "MHS file editing for Zynq related parameters is not allowed. Please use Zynq tab in XPS for PS configuration.\n Value of parameter $param ($mhs_value) in MHS conflicts with the setting in Zynq tab. Value of $param should be $value " "" mdt_error
                    }
                }
            }
        }
    }
    if { [ string equal $generate_constraints y ] } { 
     set partnumber [xget_hw_proj_setting fpga_partname]
    # puts $partnumber
    _zynqconfig_setpartnumber $partnumber
    enable_fpga_clocks $mhsinst
	_zynqconfig_save
    }
    
     if { [ string equal $add_coregenrationattribute y ] } {
     set par_val [ _zynqconfig_configparams ]
     set finalstr ""
     foreach par_val  $par_val {
         set par [lindex $par_val 0 ]
         set modpar [string map {:: _ PCW C} $par]
	 set val [lindex $par_val 1 ]
         set str  "${modpar} = ${val}"
	 set finalstr "${finalstr},${str}"
	 } 
      set finalstr [string replace $finalstr 0 0  ]
      set attr_par "CORE_GENERATION_INFO"
      set instname [xget_hw_parameter_value $mhsinst "INSTANCE"]
      set attr_val "${instname},qqprocessing_system7,{${finalstr}}"
      xadd_hw_ipinst_attribute $mhsinst $attr_par $attr_val
      }

    _zynqconfig_term
}

# Determine if bus is connected
proc enable_fpga_clocks { mhsinst } {
    set fclk0 [port_is_connected $mhsinst "FCLK_CLK0"]
    if {$fclk0} {
      _zynqconfig_setfpgaclocks 0 
    }  
    set fclk1 [port_is_connected $mhsinst "FCLK_CLK1"]
    if {$fclk1} {
      _zynqconfig_setfpgaclocks 1 
    }  
    set fclk2 [port_is_connected $mhsinst "FCLK_CLK2"]
    if {$fclk2} {
      _zynqconfig_setfpgaclocks 2 
    }  
    set fclk3 [port_is_connected $mhsinst "FCLK_CLK3"]
    if {$fclk3} {
      _zynqconfig_setfpgaclocks 3 
    }  
}

# Determine if bus is connected
proc bus_is_connected { mhsinst bus } {
   set bus_handle [xget_hw_busif_handle $mhsinst $bus]
   if {$bus_handle == ""} {
     return ""
   }
   set bus_name [xget_hw_value $bus_handle]
   if {$bus_name != ""} {
     return $bus_name
   }
   return ""
}

proc port_is_connected {mhsinst port_name} {
     set connector  [xget_hw_port_value  $mhsinst  $port_name]
     if {[llength $connector] == 0} {
             return FALSE
     } 

     set mhs_handle   [xget_hw_parent_handle $mhsinst]
     set sink_ports [xget_hw_connected_ports_handle $mhs_handle $connector "SINK"]
     if {[llength $sink_ports] == 0 } {
             return FALSE
     } else {
             return TRUE
     }
}



proc zynqconfig_bus_DRC { mhsinst } {
    
    set master_list(1) [ bus_is_connected $mhsinst "M_AXI_GP0" ]
    set master_list(2) [ bus_is_connected $mhsinst "M_AXI_GP1" ]
    
    set slave_list(1) [ bus_is_connected $mhsinst "S_AXI_GP0" ]
    set slave_list(2) [ bus_is_connected $mhsinst "S_AXI_GP1" ]
    set slave_list(3) [ bus_is_connected $mhsinst "S_AXI_HP0" ]
    set slave_list(4) [ bus_is_connected $mhsinst "S_AXI_HP1" ]
    set slave_list(5) [ bus_is_connected $mhsinst "S_AXI_HP2" ]
    set slave_list(6) [ bus_is_connected $mhsinst "S_AXI_HP3" ]
    set slave_list(7) [ bus_is_connected $mhsinst "S_AXI_ACP" ]
    
    foreach {n master} [array get master_list] {
	foreach {n slave} [array get slave_list] {
	    if {(![ string equal $master "" ]) && (![ string equal $slave "" ])} {
		if {[string equal $master $slave]} {
		    error "Master M_AXI_GP0/1 bus interfaces are not allowed to be connected to Slave bus interfaces of processing_system7 on the same interconnect ($master) due to ID width mismatch."
		}
	    }
	}
    }
# Check address ranges 
syslevel_check_ranges $mhsinst $slave_list(1) $slave_list(2) $slave_list(3) $slave_list(4) $slave_list(5) $slave_list(6) $slave_list(7)
    
}

#################################################################################
# check if the C_S_AXI_HP0_HIGHOCM_BASEADDR/HIGHADDR address is within a valid range

proc syslevel_check_ranges { mhsinst gp0_en gp1_en hp0_en hp1_en hp2_en hp3_en acp_en } {

    set ddr_baseaddr_val [xget_hw_parameter_value $mhsinst "C_DDR_RAM_BASEADDR"]
    set ddr_highaddr_val [xget_hw_parameter_value $mhsinst "C_DDR_RAM_HIGHADDR"]
    
	  	
	set ddr_hwidth [ expr ((( $ddr_highaddr_val - $ddr_baseaddr_val ) + 1 ) / 2) ];		
	set ddr_hwidth_hex [ format %X $ddr_hwidth ]
		
	xeput "INFO" "INFO: DDR Base and High address in current configuration is $ddr_baseaddr_val and $ddr_highaddr_val respectively."
	xeput "INFO" "INFO: You can modify the DDR address range accessed by Programmable Logic through the processing_system7 AXI slave interfaces. If MicroBlaze is a master on processing_system7 AXI slave interfaces, please use the top half of the address range (Base Address = 0x$ddr_hwidth_hex; High Address = $ddr_highaddr_val). For all other master, any subset of the DDR address can be used. See Xilinx Answer 47167 for more information."
		
	if {!([ string equal $hp0_en "" ])} {
	   set def_range(1) "C_S_AXI_HP0_BASEADDR"
      set def_range(2) "C_S_AXI_HP0_HIGHADDR"
	 } 
	if {!([ string equal $hp1_en "" ])} {
	   set def_range(3) "C_S_AXI_HP1_BASEADDR"
      set def_range(4) "C_S_AXI_HP1_HIGHADDR"
	 } 
	if {!([ string equal $hp2_en "" ])} {
	   set def_range(5) "C_S_AXI_HP2_BASEADDR"
      set def_range(6) "C_S_AXI_HP2_HIGHADDR"
	 }
	if {!([ string equal $hp3_en "" ])} {
	   set def_range(7) "C_S_AXI_HP3_BASEADDR"
      set def_range(8) "C_S_AXI_HP3_HIGHADDR"
	 } 

	   foreach {n def_slv_addr} [array get def_range] {
		   if {!([string equal $def_slv_addr ""])} {
				pass_slave_addrs $mhsinst $def_slv_addr $ddr_baseaddr_val $ddr_highaddr_val
			}
		}
}

proc pass_slave_addrs { mhsinst slv_addr slv_ddr_baseaddr_val slv_ddr_highaddr_val} {

	 set slv_addr_val [xget_hw_parameter_value $mhsinst $slv_addr]
	 check_slv_addr_range $slv_addr $slv_addr_val $slv_ddr_baseaddr_val $slv_ddr_highaddr_val
}

#Checking HP0, HP1, HP2, HP3 High addresses 
proc check_slv_addr_range {slv_param_name slv_param_value ddr_baddr ddr_haddr} {

    if { ($slv_param_value > $ddr_haddr)} {
		    error "$slv_param_name has an allowable range of $ddr_baddr to $ddr_haddr."
    }
	 
}
#################################################################################


proc iplevel_drc_proc { mhsinst }  {
    #puts "ps7: iplevel_drc_proc"
    #zynqconfig_do $mhsinst n y n n
    zynqconfig_bus_DRC $mhsinst
    
}

proc syslevel_drc_proc { mhsinst }  {
    #puts "ps7: syslevel_drc_proc"
    zynqconfig_do $mhsinst n y n n

    ## TODO xget_hw_value C_.... 

}

proc platgen_syslevel_update_proc { mhsinst }  {
    #puts "ps7: platgen_syslevel_update_proc"
    zynqconfig_do $mhsinst y n y y
}

proc syslevel_update_proc { mhsinst }  {
    #puts "ps7: syslevel_update_proc"
    zynqconfig_do $mhsinst y n n n
}
###############################################################################
## compute VEC
proc update_params_vec { string mpdhandle } { 

    if {[ regexp {[a-zA-Z]} $string match ] } { 
        while { [regexp {([a-zA-Z]\w+)(.+)} $string match m1 m2] } { 
            set paramVAL [xget_hw_parameter_value $mpdhandle $m1];
            regsub $m1 $string $paramVAL string;
        }   
        return [expr $string];

    } else { return $string; }

}


#################################################################################

proc update_num_intr_inputs {intrport mhsinst} {


		set num_intr_inputs 0

		set mergedmhs [xget_hw_parent_handle        $mhsinst]
		set connlist  [xget_hw_port_connectors_list $mhsinst $intrport]
		foreach conn $connlist {

			if { [ regexp {0b(.*)} $conn zeros_num znum] } {
				set zval [string length $znum]
				incr num_intr_inputs $zval

			} else {

			 
			if { [ regexp {\[(.+):(.+)\]} $conn ] } {
				regexp {\[(.+):(.+)\]} $conn match_vec msbvec lsbvec;
				set selbwidth [expr {abs($msbvec - $lsbvec) + 1}];
				incr num_intr_inputs $selbwidth;			

			} else {

			if { [ regexp {\[(.*)]} $conn ] } {
			    incr num_intr_inputs
			} else {

					set connportlist [xget_hw_connected_ports_handle $mergedmhs $conn "SOURCE"]
					
					foreach connport $connportlist {
						set cpname      [xget_hw_name $connport];
						set vec         [xget_hw_subproperty_value $connport "VEC"];
						set parentMPD   [xget_hw_parent_handle $connport];
		 	 
					if {$vec != ""} {
	  
						regexp {\[(.+):(.+)\]} $vec bvec tfvec tsvec;  
						set fvec [hw_qqprocessing_system7_v4_02_a::update_params_vec $tfvec $parentMPD];
						set svec [hw_qqprocessing_system7_v4_02_a::update_params_vec $tsvec $parentMPD];
						set bwidth [expr {abs($svec - $fvec) + 1}];

						incr num_intr_inputs $bwidth;

					} else { incr num_intr_inputs }

				} 
			}
		}   
	}
}

    # compute the value to 1 even when there is no interrupt input connected
    # by users, and let platgen connect the signal to net_gnd
    if { $num_intr_inputs == 0 } {

       return 1
    }

   return $num_intr_inputs

}


###############################################################################

# compute C_NUM_F2P_INTR_INPUTS
proc syslevel_update_num_intr_inputs { param_handle } {

    set mhsinst      [xget_hw_parent_handle $param_handle]
    set mhs_handle   [xget_hw_parent_handle $mhsinst]

##    xload_hw_library processing_system7_v2_00_a

    return [hw_qqprocessing_system7_v4_02_a::update_num_intr_inputs "IRQ_F2P" $mhsinst]

}
###############################################################################


proc iplevel_update_for_hp_ports {param_handle} {

    set mhsinst [xget_hw_parent_handle $param_handle]
    set ddr_highaddr_val [xget_hw_parameter_value $mhsinst "C_DDR_RAM_HIGHADDR"]		

    #xeput "INFO" "INFO: DDR Base and High address in current configuration is $ddr_highaddr_val and $ddr_highaddr_val respectively."
    #xeput "INFO" "INFO: You can modify the DDR address range accessed by Programmable Logic through the processing_system7 AXI slave interfaces. If MicroBlaze with reset vector at '0' is a master on processing_system7 AXI slave interfaces, please use the top half of the address range (Base Address = 0x$ddr_hwidth_hex; High Address = $ddr_highaddr_val). For all other master, any subset of the DDR address can be used. See Xilinx Answer 47167 for more information."

    return $ddr_highaddr_val
}

proc iplevel_update_for_package { mhsinst} {
     
	return "[xget_hw_proj_setting fpga_package]"
}

proc iplevel_update_for_dq_ports {mhsinst} {

	if {[xget_hw_proj_setting fpga_package] == "clg225" } {
		return 16
	} 

	return 32 

}

proc iplevel_update_for_dqs_ports {mhsinst} {

	if {[xget_hw_proj_setting fpga_package] == "clg225" } {
		return 2
	} 

	return 4 

}

proc iplevel_update_for_dm_ports {mhsinst} {

	if {[xget_hw_proj_setting fpga_package] == "clg225" } {
		return 2
	} 

	return 4 

}

proc iplevel_update_for_mio_primitive {mhsinst} {

	if {[xget_hw_proj_setting fpga_package] == "clg225" } {
		return 32
	} 

	return 54 

}
##############################################################################

# update param fclk buffer based on fclk clock connections
proc syslevel_update_use_fclkbuff {param_handle} {
    set mhsinst [xget_hw_parent_handle $param_handle]
    set mhs_handle [xget_hw_parent_handle $mhsinst]
  
    set param_name [xget_hw_name $param_handle]
    set port_name [string trim [string range $param_name [string first _ $param_name] [string last _ $param_name]] _]
 
    set connector  [xget_hw_port_value  $mhsinst  $port_name]
    if {[llength $connector] == 0} {
      return FALSE
    } 

    set sink_ports [xget_hw_connected_ports_handle $mhs_handle $connector "SINK"]
    if {[llength $sink_ports] == 0 } {
      return FALSE
    } else {
      return TRUE
    }
 }

###############################################################################

# compute C_M_AXI_GP0_THREAD_ID_WIDTH width based on C_M_AXI_GP0_ENABLE_STATIC_REMAP
proc syslevel_update_thread_id0_num { param_handle } {

    set mhsinst      [xget_hw_parent_handle $param_handle]
    set value0_p [xget_hw_parameter_value $mhsinst "C_M_AXI_GP0_ENABLE_STATIC_REMAP"]
    return [hw_qqprocessing_system7_v4_02_a::update_thread_id_width $value0_p $mhsinst]
}

# compute C_M_AXI_GP1_THREAD_ID_WIDTH width based on C_M_AXI_GP1_ENABLE_STATIC_REMAP
proc syslevel_update_thread_id1_num { param_handle } {

    set mhsinst      [xget_hw_parent_handle $param_handle]
    set value1_p [xget_hw_parameter_value $mhsinst "C_M_AXI_GP1_ENABLE_STATIC_REMAP"]
    return [hw_qqprocessing_system7_v4_02_a::update_thread_id_width $value1_p $mhsinst]
}

#################################################################################

proc update_thread_id_width {param_value mhsinst} {
    if { $param_value == "1" } {
        return 6
    } else {
    return 12
	 }
}

#################################################################################

