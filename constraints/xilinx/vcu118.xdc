######################################################################################################
##  File name :       vcu118.xdc
##

######################################################################################################
# PIN ASSIGNMENTS
######################################################################################################
#set_property LOC AL9  [get_ports { CLK_pci_sys_clk_p }]
#set_property LOC AL8  [get_ports { CLK_pci_sys_clk_n }]
set_property LOC AC9  [get_ports { CLK_pci_sys_clk_p }]
set_property LOC AC8  [get_ports { CLK_pci_sys_clk_n }]
set_property LOC AM17 [get_ports { RST_N_pci_sys_reset_n }]
    
set_property LOC G31  [get_ports { CLK_sys_clk_300_p }]
set_property IOSTANDARD DIFF_SSTL12 [get_ports { CLK_sys_clk_300_p }]
set_property LOC F31  [get_ports { CLK_sys_clk_300_n }]
set_property IOSTANDARD DIFF_SSTL12 [get_ports { CLK_sys_clk_300_n }]


set_property PACKAGE_PIN E12 [ get_ports { CLK_sys_clk1_250_p } ]
set_property IOSTANDARD DIFF_SSTL12 [ get_ports { CLK_sys_clk1_250_p } ]
set_property PACKAGE_PIN D12 [ get_ports { CLK_sys_clk1_250_n } ]
set_property IOSTANDARD DIFF_SSTL12 [ get_ports { CLK_sys_clk1_250_n } ]

    
set_property PACKAGE_PIN AW26 [ get_ports { CLK_sys_clk2_250_p } ]
set_property IOSTANDARD DIFF_SSTL12 [ get_ports { CLK_sys_clk2_250_p } ]
set_property PACKAGE_PIN AW27 [ get_ports { CLK_sys_clk2_250_n } ]
set_property IOSTANDARD DIFF_SSTL12 [ get_ports { CLK_sys_clk2_250_n } ]




set_property IOSTANDARD LVCMOS18    [get_ports { RST_N_pci_sys_reset_n }]
set_property PULLUP     true        [get_ports { RST_N_pci_sys_reset_n }]
