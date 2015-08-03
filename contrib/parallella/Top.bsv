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
import ParallellaLibDefs::*;
import ParallellaLib::*;
import PParallellaLIB::*;
import AxiMasterSlave::*;
import AxiGather::*;
import AxiDma::*;



module mkConnectalTop#(HostInterface host)(ConnectalTop);
   Clock oneTrueClock <- exposeCurrentClock;
   Reset oneTrueReset <- exposeCurrentReset;
   ParallellaLib plib <- mkParallellaLib(oneTrueClock, oneTrueReset);


   mkConnection(host.ps7.m_axi_gp[1].client, plib.maxi.server);
   mkConnection(plib.saxi.client, host.ps7.s_axi_hp[3].server);
   interface ParallellaPins pins = plib.pins;

endmodule : mkConnectalTop
export mkConnectalTop;
export ParallellaLibDefs::*;
export PParallellaLIB::*;
