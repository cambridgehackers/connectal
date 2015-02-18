Procedure for creating part constraint files

Start Vivado
Create new project
  In New Vivado Project window
     click Next
  In Project Name window
     click next (but note the name, or change it)
  In Project Type window
    select RTL Project
    click next
  In Add Sources
     select Target language Verilog
     click next
  In Add Existing IP
     click next
  In Add Constraints
     click next
  In Default Part

If the board type is known to Vivado, select board and choose the right board
otherwise 
     Specify Parts
     Search for desired part
     click next
  In New Project Summary
     click finish

In Flow Navigator, 
   Create Block Design

In Block Design
   Add IP
      search for Processing System, add that
      Click Run Block Automation, to make DDR and Fixed_IO connections
   Add IP
      search for GPIO, add that
   Run connection automation
      use drop down box to select GPIO AXI

This will add the reset logic and other basic stuff


Ctrl-S or Save Block Design

In Hierarch winddow, select Sources tab
Right click Design top level
   Select Generate HDL wrapper

In Flow navigator
  Run Synthesis
 
(The file you need should be there now)
  Run Implementation
  Run Generate Bitstream

Exit Vivado
Go to project directory tree
Search for xdc files:

find .|grep .xdc

There should be one named something like


In part area, search for and select desired part

./project_6.srcs/sources_1/bd/design_1/ip/design_1_processing_system7_0_0/design_1_processing_system7_0_0.xdc

Copy this file to

.../connectal/constraints/xilinx/<partnumber>.xdc

Check this file into git, then edit it to add a comment about where it
came from and to comment out the create_clock and set_jitter
lines near the top

