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
import PParallellaLIB::*;
import Portal::*;
import AxiMasterSlave::*;
import AxiDma::*;
import XilinxCells::*;
import ConnectalXilinxCells::*;
import ConnectalClocks::*;
import AxiBits::*;
import AxiGather::*;

interface ParallellaPins;
   interface Par_txo txo;
   interface Par_txi txi;
   interface Par_rxo rxo;
   interface Par_rxi rxi;
endinterface

interface ParallellaLib;
   interface ParallellaPins pins;
   interface AxiSlaveCommon#(32,32,12) maxi;  // this will connect to a master
   interface AxiMasterCommon#(32,64,6) saxi;  // this will connect to a slave
   interface Par_misc misc;
endinterface
   

module mkParallellaLIB#(Clock axi_clock, Reset axi_reset)(ParallellaLIB);
   PParallellaLIB foo <- mkPParallellaLIB( 
      axiclk,  axiclk, 
      axi_reset, axi_reset,
      axi_reset, axi_reset,
      //Reset reset_chip, Reset reset_fpga
       axi_reset, axi_reset
 );
   AxiSlaveCommon#(32,32,12) vtopm_axi_gp;
   AxiMasterCommon#(32,64,6,Empty) vtops_axi_hp;
   vtopm_axi_gp <- mkAxi3SlaveGather(foo.maxigp0, clocked_by axi_clock, reset_by axi_reset);
   vtops_axi_hp <- mkAxi3MasterGather(foo.saxihp0, clocked_by axi_clock, reset_by axi_reset);
   interface maxi = vtopm_axi_gp;
   interface saxi = vtops_axi_hp;
   interface ParallellaPins pins;
      interface Par_txo txo = foo.txo;
      interface Par_txi txi = foo.txi;
      interface Par_rxo rxo = foo.rxo;
      interface Par_rxi rxi = foo.rxi;
   endinterface
   interface Par_misc misc = foo.misc;
      
endmodule