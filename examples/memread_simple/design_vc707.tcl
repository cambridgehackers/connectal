###############################################################
###   Tcl Variables
###############################################################
#set tclParams [list <param1> <value> <param2> <value> ... <paramN> <value>]
set tclParams [list place.closeImportedSites  1 \
                    hd.StrictContainRouting   1 \
              ]

#Define location for "Tcl" directory. Defaults to "../Tcl"
set tclHome "../../scripts/xilinx/tcl"
if {[file exists $tclHome]} {
   set tclDir $tclHome
} elseif {[file exists "./Tcl"]} {
   set tclDir  "./Tcl"
} else {
   error "ERROR: No valid location found for required Tcl scripts. Set \$tclDir in design.tcl to a valid location."
}

###############################################################
### Part Variables - Define Device, Package, Speedgrade 
###############################################################
set device       "xc7vx485t"
set package      "ffg1761"
set speed        "-2"
set part         $device$package$speed

###############################################################
###  Setup Variables
###############################################################
####flow control
set run.topSynth   0
set run.oocSynth   1
set run.tdImpl     1
set run.oocImpl    1
set run.topImpl    1
set run.flatImpl   0

####Report and DCP controls - values: 0-required min; 1-few extra; 2-all
set verbose      1
set dcpLevel     1

####Output Directories
set synthDir  "./Synth"
set implDir   "./Implement"
set dcpDir    "./Checkpoint"

####Input Directories
set srcDir     "./vc707"
set rtlDir     "$srcDir/verilog"
set prjDir     "$srcDir/prj"
set xdcDir     "$srcDir/constraints"
set coreDir    "$srcDir/cores"
set netlistDir "$srcDir/netlist"

####Source required Tcl Procs
source $tclDir/design_utils.tcl
source $tclDir/synth_utils.tcl
source $tclDir/impl_utils.tcl
source $tclDir/hd_floorplan_utils.tcl

###############################################################
### Top Definition
###############################################################
set top "mkPcieTop"
add_module $top
set_attribute module $top    top_level     1
set_attribute module $top    vlog          [concat [glob $rtlDir/top/*.v] [glob $rtlDir/lib/*.v] ]
set_attribute module $top    ip            []
#set_attribute module $top    vlog_headers  [glob $rtlDir/top/*Stub.v]
set_attribute module $top    synth         ${run.topSynth}

add_implementation $top
set_attribute impl $top      top           $top
set_attribute impl $top      implXDC       [glob $xdcDir/vc707.xdc]
set_attribute impl $top      impl          ${run.topImpl}
set_attribute impl $top      hd.impl       1

####################################################################
### OOC Module Definition and OOC Implementation for each instance
####################################################################
set module1 "mkPcieHost"
add_module $module1
set_attribute module $module1 vlog          [concat [glob $rtlDir/lib/*.v] [glob $rtlDir/pciehost/*.v]]
set_attribute module $module1 ip            []
set_attribute module $module1 synth        ${run.oocSynth}

set instance "pciehost"
add_ooc_implementation $instance
set_attribute ooc $instance   module       $module1
set_attribute ooc $instance   inst         $instance
set_attribute ooc $instance   hierInst     $instance
set_attribute ooc $instance   implXDC      [list $xdcDir/${instance}_phys.xdc \
						 $xdcDir/${instance}_ooc_timing.xdc \
						 $xdcDir/${instance}_ooc_budget.xdc \
						 $xdcDir/${instance}_ooc_optimize.xdc \
						]
set_attribute ooc $instance   impl         ${run.oocImpl}
set_attribute ooc $instance   preservation routing

set module2 "mkPCIExpressEndpointX7"
add_module $module2
set_attribute module $module2 vlog          [concat [glob $rtlDir/lib/*.v] [list $rtlDir/ep7/mkPCIExpressEndpointX7.v]]
set_attribute module $module2 ip            [glob /scratch/jamey/connectal/generated/xilinx/vc707/*/*.xci]
set_attribute module $module2 synth        ${run.oocSynth}

set instance "ep7"
add_ooc_implementation $instance
set_attribute ooc $instance   module       $module2
set_attribute ooc $instance   inst         $instance
set_attribute ooc $instance   hierInst     $instance
set_attribute ooc $instance   implXDC      [list $xdcDir/${instance}_phys.xdc \
						 $xdcDir/${instance}_ooc_timing.xdc \
						 $xdcDir/${instance}_ooc_budget.xdc \
						 $xdcDir/${instance}_ooc_optimize.xdc \
						]
set_attribute ooc $instance   impl         ${run.oocImpl}
set_attribute ooc $instance   preservation routing

# set module3 "mkSynthesizeableConnectalTop"
# add_module $module3
# set_attribute module $module3 vlog          [concat [glob $rtlDir/lib/*.v] [list $rtlDir/portal/mkSynthesizeableConnectalTop.v]]
# set_attribute module $module3 ip            []
# set_attribute module $module3 synth        ${run.oocSynth}

# set instance "portalTop"
# add_ooc_implementation $instance
# set_attribute ooc $instance   module       $module3
# set_attribute ooc $instance   inst         $instance
# set_attribute ooc $instance   hierInst     $instance
# set_attribute ooc $instance   implXDC      [list $xdcDir/${instance}_phys.xdc \
# 						 $xdcDir/${instance}_ooc_timing.xdc \
# 						 $xdcDir/${instance}_ooc_budget.xdc \
# 						 $xdcDir/${instance}_ooc_optimize.xdc \
# 						]
# set_attribute ooc $instance   impl         ${run.oocImpl}
# set_attribute ooc $instance   preservation routing

####################################################################
### Create TopDown implementation run 
####################################################################
set module1File "$synthDir/$module1/${module1}_synth.dcp"
set module2File "$synthDir/$module2/${module2}_synth.dcp"
#set module3File "$synthDir/$module3/${module3}_synth.dcp"
add_implementation TopDown
set_attribute impl TopDown      top          $top
set_attribute impl TopDown      implXDC      [list $xdcDir/floorplan_vc707.xdc $xdcDir/vc707.xdc]
set_attribute impl TopDown      td.impl      1
set_attribute impl TopDown      cores        [list $module1File                          \
                                                   $module2File                          \
                                                   [get_attribute module $top cores]     \
                                                   [get_attribute module $module1 cores] \
                                                   [get_attribute module $module2 cores] \
                                             ] 
set_attribute impl TopDown      impl         ${run.tdImpl}
set_attribute impl TopDown      route        0

####################################################################
### Create Flat implementation run 
####################################################################
add_implementation Flat
set_attribute impl Flat         top          $top
set_attribute impl Flat         implXDC      [list $xdcDir/${top}_flpn.xdc $xdcDir/vc707.xdc]
set_attribute impl Flat         cores        [list $module1File                          \
                                                   $module2File                          \
                                                   [get_attribute module $top cores]     \
                                                   [get_attribute module $module1 cores] \
                                                   [get_attribute module $module2 cores] \
                                             ] 
set_attribute impl Flat         impl         ${run.flatImpl}

########################################################################
### Task / flow portion
########################################################################

set_property SEVERITY {Warning} [get_drc_checks HDOOC-4]

# Build the designs
source $tclDir/run.tcl

exit
