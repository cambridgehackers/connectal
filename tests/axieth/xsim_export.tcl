
set partname {xc7vx690tffg1761-2}

create_project -in_memory -name fooproject
set_property PART $partname [current_project]

read_ip /home/jamey/connectal/out/vc709/axi_ethernet_0/axi_ethernet_0.xci
generate_target simulation [get_ips axi_ethernet_0]

read_ip /home/jamey/connectal/out/vc709/axi_dma_0/axi_dma_0.xci
generate_target simulation [get_ips axi_dma_0]

read_ip /home/jamey/connectal/out/vc709/axi_intc_0/axi_intc_0.xci
generate_target simulation [get_ips axi_intc_0]

#puts [get_files -compile_order sources -used_in simulation -of_objects [get_ips axi_ethernet_0]]

add_files [glob /home/jamey/connectal/verilog/*.sv]
add_files [glob xsim/verilog/*.v]
add_files [glob /home/jamey/connectal/verilog/*.v]
add_files [glob /scratch/bluespec/Bluespec-2015.09.beta2/lib/Verilog.Vivado/*.v]
add_files [glob /scratch/bluespec/Bluespec-2015.09.beta2/lib/Verilog/FIFO1.v]
add_files [glob /scratch/bluespec/Bluespec-2015.09.beta2/lib/Verilog/FIFO2.v]

add_files [get_files -compile_order sources -used_in simulation -of_objects [get_ips axi_ethernet_0]]
add_files [get_files -compile_order sources -used_in simulation -of_objects [get_ips axi_dma_0]]
add_files [get_files -compile_order sources -used_in simulation -of_objects [get_ips axi_intc_0]]
set_property TOP xsimtop [get_filesets sim_1]
export_simulation -simulator xsim
