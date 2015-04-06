// Copyright (c) 2014 Quanta Research Cambridge, Inc.

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
import Vector::*;
import GetPut::*;
import Connectable :: *;
import Clocks :: *;
import FIFO::*;
import Portal::*;
import HostInterface::*;
import CtrlMux::*;
import PS7LIB::*;
import PPS7LIB::*;
import ConnectalClocks::*;
import BlueScopeEventPIO::*;
import ParallellaLib::*;
import PParallellaLIB::*;
import AxiMasterSlave::*;
import AxiGather::*;



module mkConnectalTop#(HostType host)(ConnectalTop#(PhysAddrWidth,64,ParallellaPins,1));

   ParallellaLib plib <- mkParallella();
   Axi3Slave#(32,32,12) parctrl <- mkAxiDmaSlave(plib.maxi);
   Axi3Master#(32,64,6) parmaster <- mkAxiDmaNaster(plib.saxi);
   mkConnection(host.ps7.m_axi_gp[1].client, parslave);
   mkConnection(parmaster, host.ps7.m_axi_hp[3].client);
						    
   interface interrupt = getInterruptVector(portals);
   interface slave = ctrl_mux;
   interface masters = dma.masters;
   interface pins = pins;

endmodule : mkConnectalTop
