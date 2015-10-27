// Copyright (c) 2013 Quanta Research Cambridge, Inc.

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
import ConnectalConfig::*;
import Connectable::*;
import ConnectableWithTrace::*;
import Vector::*;
import HostInterface::*;
import PS7LIB::*;
import Portal::*;
import AxiMasterSlave::*;
import AxiDma::*;
import AxiBits::*;
import AxiGather::*;
import Platform::*;

`include "ConnectalProjectConfig.bsv"

`ifdef USE_ACP
typedef 1 NumAcp;
`else
typedef 0 NumAcp;
`endif

instance ConnectableWithTrace#(PS7, Platform, traceType)
   provisos (ConnectableWithTrace::ConnectableWithTrace#(AxiMasterSlave::Axi3Master#(32,64,6),AxiMasterSlave::Axi3Slave#(32, 64, 6),traceType),
             ConnectableWithTrace::ConnectableWithTrace#(AxiMasterSlave::Axi3Master#(32,32,12),AxiMasterSlave::Axi3Slave#(32,32,12),traceType));
   module mkConnectionWithTrace#(PS7 ps7, Platform top, traceType readout)(Empty)
      provisos (ConnectableWithTrace#(Axi3Master#(32,64,6), Axi3Slave#(32,64,6),traceType));

      Axi3Slave#(32,32,12) ctrl <- mkAxiDmaSlave(top.slave);
      mkConnectionWithTrace(ps7.m_axi_gp[0].client, ctrl, readout);

`ifdef USE_ACP
      begin
	 Axi3Master#(32,64,3) acp_m_axi <- mkAxiDmaMaster(top.masters[0]);
	 mkConnection(acp_m_axi, ps7.s_axi_acp[0].server);
      end
      rule acp_aruser;
	 ps7.s_axi_acp[0].extra.aruser(5'h1f);
      endrule
      rule acp_awuser;
	 ps7.s_axi_acp[0].extra.awuser(5'h1f);
      endrule
`endif
      module mkAxiMasterConnection#(Integer i)(Axi3Master#(32,64,6));
	 let m_axi <- mkAxiDmaMaster(top.masters[i+valueOf(NumAcp)]);
	 mkConnection(m_axi, ps7.s_axi_hp[i].server);
	 return m_axi;
      endmodule
      Vector#(TSub#(NumberOfMasters,NumAcp), Axi3Master#(32,64,6)) m_axis <- genWithM(mkAxiMasterConnection);
   endmodule
endinstance
