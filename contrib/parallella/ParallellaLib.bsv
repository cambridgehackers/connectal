// Copyright (c) 2015 Quanta Research Cambridge, Inc.

// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use, copy,
// modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
// BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
// ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Clocks::*;
import DefaultValue::*;
import GetPut::*;
import Connectable::*;
import ConnectableWithTrace::*;
import Bscan::*;
import Vector::*;
import ELink::*;
import Portal::*;
import AxiMasterSlave::*;
import AxiDma::*;
import XilinxCells::*;
import ConnectalXilinxCells::*;
import ConnectalClocks::*;
import AxiBits::*;
import AxiGather::*;
import ParallellaLibDefs::*;
   

module mkParallellaLib#(Clock axi_clock, Reset axi_reset)(ParallellaLib);

   ELink foo <- mkELink( 
      axi_clock,  axi_clock, 
      axi_reset, axi_reset,
      axi_reset, axi_reset,
       axi_reset, axi_reset );
      AxiSlaveCommon#(32,32,12,Empty) vtopm_axi_gp;
    AxiMasterCommon#(32,64,6) vtops_axi_hp;
    vtopm_axi_gp <- mkAxi3SlaveGather(foo.maxi, clocked_by axi_clock, reset_by axi_reset);
    vtops_axi_hp <- mkAxi3MasterGather(foo.saxi, clocked_by axi_clock, reset_by axi_reset);
    interface maxi = vtopm_axi_gp;
    interface saxi = vtops_axi_hp;
    interface  ParallellaPins pins;
     interface  tx = foo.tx;
      interface  rx = foo.rx;
   endinterface
   interface  misc = foo.misc;
      
endmodule
