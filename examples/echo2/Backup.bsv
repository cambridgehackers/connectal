module mkPcieTop#(Clock pci_sys_clk_p, 
		  Clock pci_sys_clk_n,
		  Clock sys_clk_p, 
		  Clock sys_clk_n, 
		  Reset pci_sys_reset_n) (KC705_FPGA);

   Top top <- mkTop;
   let contentId = 64'h4563686f; // should identify the design loaded at runtime
   X7PcieBridgeIfc#(8) x7pcie <- mkX7PcieBridge(pci_sys_clk_p, pci_sys_clk_n, sys_clk_p, sys_clk_n, pci_sys_reset_n,
						2, // number of portals used in the design 
						contentId );

   mkConnection(top.ctrl, x7pcie.portal0);
   mkConnection(top.m_axi, x7pcie.foo);
   mkConnection(top.interrupt, x7pcie.interrupts);
   interface pcie = x7pcie.pcie
   methods leds = top.leds;

endmodule
