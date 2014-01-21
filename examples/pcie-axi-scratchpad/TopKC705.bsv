import SceMi      :: *;
import Kintex7PcieBridge:: *;

// Setup for PCIE to a Kintex7
import Xilinx         :: *;
import XilinxPCIE     :: *;
import Clocks         :: *;
import DefaultValue   :: *;
import Connectable    :: *;
import CommitIfc      :: *;
import TieOff         :: *;
import Memory         :: *;
import GetPut         :: *;
import ClientServer   :: *;
import BUtils         :: *;
import EchoWrapper    :: *;
import AxiScratchPad  :: *;

(* synthesize, no_default_clock, no_default_reset *)
module mkBridge #(Clock pci_sys_clk_p, Clock pci_sys_clk_n,
		  Clock sys_clk_p,     Clock sys_clk_n,
		  Clock user_clk_p, Clock user_clk_n,
		  Reset pci_sys_reset_n)
                 (KC705_FPGA_DDR3);

   Clock user_clk <- mkClockIBUFDS(user_clk_p, user_clk_n);

   K7PcieBridgeIfc#(8) k7pcie <- mkK7PcieBridge( pci_sys_clk_p, pci_sys_clk_n, sys_clk_p, sys_clk_n, pci_sys_reset_n,
                                                 64'h05ce_0006_7050_2603 );
   
   AxiScratchPad echoWrapper <- mkAxiScratchPad(clocked_by k7pcie.clock125, reset_by k7pcie.reset125);
   mkConnection(k7pcie.portal0, echoWrapper.ctrl, clocked_by k7pcie.clock125, reset_by k7pcie.reset125);

   interface pcie = k7pcie.pcie;
   interface ddr3 = k7pcie.ddr3;
   method leds = zeroExtend({ pack(k7pcie.isCalibrated)
			     ,pack(False)
			     ,pack(False)
			     ,pack(k7pcie.isLinkUp)
			     });
endmodule: mkBridge

