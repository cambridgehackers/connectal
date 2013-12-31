import Portal            :: *;
import Connectable       :: *;
import Xilinx            :: *;
import XilinxPCIE        :: *;
import Xilinx7PcieBridge :: *;
import PcieToAxiBridge   :: *;
import Top               :: *;

(* no_default_clock, no_default_reset *)
module mkPcieTop #(Clock pci_sys_clk_p, Clock pci_sys_clk_n,
                          Clock sys_clk_p,     Clock sys_clk_n,
                          Reset pci_sys_reset_n)
                         (VC707_FPGA);

   let contentId = 64'h4563686f;

   X7PcieBridgeIfc#(8) x7pcie <- mkX7PcieBridge( pci_sys_clk_p, pci_sys_clk_n, sys_clk_p, sys_clk_n, pci_sys_reset_n,
                                                 contentId );
   
   Reg#(Bool) interruptRequested <- mkReg(False, clocked_by x7pcie.clock125, reset_by x7pcie.reset125);

   // instantiate user portals
   let portalTop <- mkMemwriteTop(clocked_by x7pcie.clock125, reset_by x7pcie.reset125);

   // connect them to PCIE
   mkConnection(x7pcie.portal0, portalTop.ctrl, clocked_by x7pcie.clock125, reset_by x7pcie.reset125);

   AxiSlaveEngine#(64,8) axiSlaveEngine <- mkAxiSlaveEngine(x7pcie.pciId(), clocked_by x7pcie.clock125, reset_by x7pcie.reset125);
   mkConnection(tpl_1(x7pcie.slave), tpl_2(axiSlaveEngine.tlps), clocked_by x7pcie.clock125, reset_by x7pcie.reset125);
   mkConnection(tpl_1(axiSlaveEngine.tlps), tpl_2(x7pcie.slave), clocked_by x7pcie.clock125, reset_by x7pcie.reset125);
   mkConnection(portalTop.m_axi, axiSlaveEngine.slave3, clocked_by x7pcie.clock125, reset_by x7pcie.reset125);

   rule requestInterrupt;
      if (portalTop.interrupt && !interruptRequested)
	 x7pcie.interrupt();
      interruptRequested <= portalTop.interrupt;
   endrule

   interface pcie = x7pcie.pcie;
   //interface ddr3 = x7pcie.ddr3;
   method leds = zeroExtend({  pack(x7pcie.isCalibrated)
			     , pack(True)
			     , pack(False)
			     , pack(x7pcie.isLinkUp)
			     });

endmodule: mkPcieTop
