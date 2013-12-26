// bsv libraries
//import SpecialFIFOs::*;
//import Vector::*;
//import StmtFSM::*;
//import FIFO::*;
//import Connectable::*;

// portz libraries
//import AxiMasterSlave::*;
//import Directory::*;
//import CtrlMux::*;
//import Portal::*;
//import Leds::*;
import Top::*;
import PS7::*;

module mkZynqTop(AxiTop);
   let axiTop <- mkAxiTop();
//PS7#(4, 32, 4, 32, 64/*gpio_width*/, 12, 54) ps7 <- mkPS7(4, 32, 4, 32, 64/*gpio_width*/, 12, 54);
   return axiTop;
endmodule : mkZynqTop

