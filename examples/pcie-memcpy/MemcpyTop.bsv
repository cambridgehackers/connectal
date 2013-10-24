import Clocks            :: *;
import Connectable       :: *;
import Xilinx            :: *;
import XilinxPCIE        :: *;
import Kintex7PcieBridge :: *;
import MemcpyWrapper       :: *;

(* synthesize, no_default_clock, no_default_reset *)
module mkMemcpyTop #(Clock pci_sys_clk_p, Clock pci_sys_clk_n,
		  Clock sys_clk_p,     Clock sys_clk_n,
		  Clock user_clk_p, Clock user_clk_n,
		  Reset pci_sys_reset_n)
                 (KC705_FPGA);

   Clock user_clk <- mkClockIBUFDS(user_clk_p, user_clk_n);

   K7PcieBridgeIfc#(8) k7pcie <- mkK7PcieBridge( pci_sys_clk_p, pci_sys_clk_n, sys_clk_p, sys_clk_n, pci_sys_reset_n,
                                                 64'h05ce_0006_4340_2609 );
   
   Reg#(Bool) interruptRequested <- mkReg(False, clocked_by k7pcie.clock125, reset_by k7pcie.reset125);
   MemcpyWrapper memcpyWrapper <- mkMemcpyWrapper(clocked_by k7pcie.clock125, reset_by k7pcie.reset125);
   mkConnection(k7pcie.portal0, memcpyWrapper.ctrl, clocked_by k7pcie.clock125, reset_by k7pcie.reset125);
   //mkConnection(memcpyWrapper.trace, k7pcie.trace);
   mkConnection(memcpyWrapper.m_axi, k7pcie.slave, clocked_by k7pcie.clock125, reset_by k7pcie.reset125);

   rule requestInterrupt;
      Bool interrupt = (memcpyWrapper.interrupts[0] == 1);
      if (interrupt && !interruptRequested)
	 k7pcie.interrupt();
      interruptRequested <= interrupt;
   endrule

   interface pcie = k7pcie.pcie;
   //interface ddr3 = k7pcie.ddr3;
   method leds = zeroExtend({ pack(k7pcie.isCalibrated)
			     ,pack(False)
			     ,pack(False)
			     ,pack(k7pcie.isLinkUp)
			     });
endmodule: mkMemcpyTop
