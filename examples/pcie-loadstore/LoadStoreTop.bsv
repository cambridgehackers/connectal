import Clocks            :: *;
import Connectable       :: *;
import Assert            :: *;
import Xilinx            :: *;
import XilinxPCIE        :: *;
import Kintex7PcieBridge :: *;
import Virtex7PcieBridge :: *;
import LoadStoreWrapper       :: *;

(* synthesize, no_default_clock, no_default_reset *)
module mkLoadStoreTop #(Clock pci_sys_clk_p, Clock pci_sys_clk_n,
		  Clock sys_clk_p,     Clock sys_clk_n,
		  Clock user_clk_p, Clock user_clk_n,
		  Reset pci_sys_reset_n)
                 (KC705_FPGA);

   Clock user_clk <- mkClockIBUFDS(user_clk_p, user_clk_n);

   let contentId = 64'h05ce_0006_4c53_260d;

`ifdef Virtex7
   K7PcieBridgeIfc#(8) x7pcie <- mkK7PcieBridge( pci_sys_clk_p, pci_sys_clk_n, sys_clk_p, sys_clk_n, pci_sys_reset_n,
                                                 contentId );
`elsif Kintex7
   V7PcieBridgeIfc#(8) x7pcie <- mkV7PcieBridge( pci_sys_clk_p, pci_sys_clk_n, sys_clk_p, sys_clk_n, pci_sys_reset_n,
                                                 contentId );
`else
   staticAssert(False, "Define preprocessor macro Virtex7 or Kintex7 to configure platform.");
`endif

   
   Reg#(Bool) interruptRequested <- mkReg(False, clocked_by x7pcie.clock125, reset_by x7pcie.reset125);
   LoadStoreWrapper loadStoreWrapper <- mkLoadStoreWrapper(clocked_by x7pcie.clock125, reset_by x7pcie.reset125);
   mkConnection(x7pcie.portal0, loadStoreWrapper.ctrl, clocked_by x7pcie.clock125, reset_by x7pcie.reset125);
   //mkConnection(loadStoreWrapper.trace, x7pcie.trace);
   mkConnection(loadStoreWrapper.m_axi, x7pcie.slave, clocked_by x7pcie.clock125, reset_by x7pcie.reset125);
   rule numPortals;
       x7pcie.numPortals <= loadStoreWrapper.numPortals;
   endrule
   

   rule requestInterrupt;
      Bool interrupt = (loadStoreWrapper.interrupts[0] == 1);
      if (interrupt && !interruptRequested)
	 x7pcie.interrupt();
      interruptRequested <= interrupt;
   endrule

   interface pcie = x7pcie.pcie;
   //interface ddr3 = x7pcie.ddr3;
   method leds = zeroExtend({ pack(x7pcie.isCalibrated)
			     ,pack(False)
			     ,pack(False)
			     ,pack(x7pcie.isLinkUp)
			     });
endmodule: mkLoadStoreTop
