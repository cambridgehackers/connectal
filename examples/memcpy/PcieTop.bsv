// bsv libraries
import SpecialFIFOs::*;
import Vector::*;
import StmtFSM::*;
import FIFO::*;

import Xilinx            :: *;
import XilinxPCIE        :: *;

import Portal::*;
import Connectable       :: *;
import Xilinx7PcieBridge :: *;
import PcieToAxiBridge   :: *;

import Top::*;


(* no_default_clock, no_default_reset *)
module [Module] mkPcieTop #(Clock pci_sys_clk_p, Clock pci_sys_clk_n,
                          Clock sys_clk_p,     Clock sys_clk_n,
                          Reset pci_sys_reset_n)
                         (VC707_FPGA);

   let contentId = 64'h4563686f;

   let top <- mkPcieDmaTop(pci_sys_clk_p, pci_sys_clk_n, sys_clk_p, sys_clk_n, pci_sys_reset_n, contentId, mkPortalDmaTop);
   return top;
endmodule: mkPcieTop
