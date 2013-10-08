package EchoWrapper;

import FIFO::*;
import FIFOF::*;
import GetPut::*;
import Connectable::*;
import Clocks::*;
import Vector::*;
import SpecialFIFOs::*;
import PCIE::*;
import Xilinx         :: *;
import XilinxPCIE     :: *;

import AxiDMA::*;
import Adapter::*;
import AxiMasterSlave::*;
import AxiClientServer::*;
import HDMI::*;
import Zynq::*;
import Imageon::*;
import Kintex7PcieBridge:: *;

import Echo::*;
import CoreEchoIndicationWrapper::*;
import CoreEchoRequestWrapper::*;
import AxiScratchPad::*;

interface EchoWrapper;
    interface Axi3Slave#(32,32,4,SizeOf#(TLPTag)) ctrl;
    interface Vector#(1,ReadOnly#(Bit#(1))) interrupts;



    interface LEDS leds;


endinterface

module mkEchoWrapper(EchoWrapper);
    Reg#(Bit#(TLog#(1))) axiSlaveWS <- mkReg(0);
    Reg#(Bit#(TLog#(1))) axiSlaveRS <- mkReg(0); 
    CoreEchoIndicationWrapper coreIndicationWrapper <- mkCoreEchoIndicationWrapper();

    EchoIndication indication = (interface EchoIndication;
        interface CoreEchoIndication coreIndication = coreIndicationWrapper.indication;
    endinterface);

    EchoRequest echoRequest <- mkEchoRequest( indication);

    CoreEchoRequestWrapper coreRequestWrapper <- mkCoreEchoRequestWrapper(echoRequest.coreRequest,coreIndicationWrapper);
    AxiScratchPad axiScratchPad <- mkAxiScratchPad();

    Vector#(2,Axi3Slave#(32,32,4,SizeOf#(TLPTag))) ctrls_v;
    Vector#(1,ReadOnly#(Bit#(1))) interrupts_v;
    ctrls_v[0] = coreIndicationWrapper.ctrl;
    ctrls_v[1] = axiScratchPad.ctrl;

    interrupts_v[0] = coreIndicationWrapper.interrupt;

    let ctrl_mux <- mkAxiSlaveMux(ctrls_v);



    interface LEDS leds = echoRequest.leds;


    interface ctrl = ctrl_mux;
    interface Vector interrupts = interrupts_v;
endmodule

(* synthesize, no_default_clock, no_default_reset *)
module mkEchoTop #(Clock pci_sys_clk_p, Clock pci_sys_clk_n,
		  Clock sys_clk_p,     Clock sys_clk_n,
		  Clock user_clk_p, Clock user_clk_n,
		  Reset pci_sys_reset_n)
                 (KC705_FPGA_DDR3);

   Clock user_clk <- mkClockIBUFDS(user_clk_p, user_clk_n);

   K7PcieBridgeIfc#(8) k7pcie <- mkK7PcieBridge( pci_sys_clk_p, pci_sys_clk_n, sys_clk_p, sys_clk_n, pci_sys_reset_n,
                                                 64'h05ce_0006_ecc0_2604 );
   
   EchoWrapper echoWrapper <- mkEchoWrapper(clocked_by k7pcie.clock125, reset_by k7pcie.reset125);
   mkConnection(k7pcie.portal0, echoWrapper.ctrl, clocked_by k7pcie.clock125, reset_by k7pcie.reset125);

   interface pcie = k7pcie.pcie;
   interface ddr3 = k7pcie.ddr3;
   method leds = zeroExtend({ pack(k7pcie.isCalibrated)
			     ,pack(False)
			     ,pack(False)
			     ,pack(k7pcie.isLinkUp)
			     });
endmodule: mkEchoTop

endpackage: EchoWrapper