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
import ConnectalConfig::*;
`include "ConnectalProjectConfig.bsv"

////////////////////////////// common /////////////////////////////////


////////////////////////////// Bsim /////////////////////////////////
`ifdef BsimHostInterface

import Vector            :: *;
import AxiMasterSlave    :: *;
import MemTypes          :: *;

// this interface should allow for different master and slave bus paraters;		 
interface BsimHost#(numeric type clientAddrWidth, numeric type clientBusWidth, numeric type clientIdWidth,  
		    numeric type serverAddrWidth, numeric type serverBusWidth, numeric type serverIdWidth,
		    numeric type nSlaves);
   interface PhysMemMaster#(clientAddrWidth, clientBusWidth)  mem_client;
   interface Vector#(nSlaves,PhysMemSlave#(serverAddrWidth,  serverBusWidth))  mem_servers;
   interface Clock derivedClock;
   interface Reset derivedReset;
endinterface

typedef BsimHost#(32,32,12,40,DataBusWidth,6,NumberOfMasters) HostInterface;
`endif

////////////////////////////// Xsim /////////////////////////////////
`ifdef XsimHostInterface

import Vector            :: *;
import AxiMasterSlave    :: *;
import MemTypes          :: *;

// this interface should allow for different master and slave bus paraters;
interface XsimHost;
   interface Clock derivedClock;
   interface Reset derivedReset;
endinterface

typedef XsimHost HostInterface;
`endif

////////////////////////////// PciE /////////////////////////////////
`ifndef PcieHostIF
`ifdef PcieHostInterface
`define PcieHostIF
`endif
`endif

`ifdef PcieHostIF

import Vector            :: *;
import GetPut            :: *;
import ClientServer      :: *;
import BRAM              :: *;
import PCIE              :: *;
import Bscan             :: *;
import PcieCsr           :: *;
import PcieTracer        :: *;
import MemTypes          :: *;
`ifndef BSIM
`ifdef XILINX
`ifdef PCIE1
import PCIEWRAPPER       :: *;
import PcieEndpointX7    :: *;
`endif // pcie1
`ifdef PCIE2
import PCIEWRAPPER2       :: *;
import PcieEndpointX7Gen2 :: *;
`endif // pcie2
`ifdef PCIE3
import PCIEWRAPPER3      :: *;
import Pcie3EndpointX7   :: *;
`endif
`elsif ALTERA
import PcieEndpointS5    :: *;
`elsif VSIM
import PcieEndpointS5    :: *;
`endif
`endif
typedef 40 PciePhysAddrWidth;
interface PcieHost#(numeric type dsz, numeric type nSlaves);
   interface Vector#(16,ReadOnly_MSIX_Entry)     msixEntry;
   interface PhysMemMaster#(32,32)                   master;
   interface Vector#(nSlaves,PhysMemSlave#(PciePhysAddrWidth,dsz))  slave;
   interface Put#(Tuple2#(Bit#(64),Bit#(32)))    interruptRequest;
`ifdef PCIE3
   interface Client#(TLPData#(16), TLPData#(16)) pcir;
   interface Client#(TLPData#(16), TLPData#(16)) pcic;
`else
   interface Client#(TLPData#(16), TLPData#(16)) pci;
`endif
   interface Put#(TimestampedTlpData) trace;
`ifdef PCIE_BSCAN
   interface BscanTop bscanif;
`else
`ifdef PCIE_TRACE_PORT
   interface BRAMServer#(Bit#(TAdd#(TlpTraceAddrSize,1)), TimestampedTlpData) traceBramServer;
`endif
`endif
endinterface

interface PcieHostTop;
   interface PcieHost#(DataBusWidth, NumberOfMasters) tpciehost;
`ifdef XILINX
`ifdef XILINX_SYS_CLK
   interface Clock tsys_clk_200mhz;
   interface Clock tsys_clk_200mhz_buf;
`endif
   interface Clock tpci_clk_100mhz_buf;
   interface PcieEndpointX7#(PcieLanes) tep7;
`elsif ALTERA
   interface PcieEndpointS5#(PcieLanes) tep7;
`elsif VSIM
   interface PcieEndpointS5#(PcieLanes) tep7;
`endif
   interface Clock pcieClock;
   interface Reset pcieReset;
   interface Clock portalClock;
   interface Reset portalReset;
   interface Clock derivedClock;
   interface Reset derivedReset;
endinterface
`endif

`ifdef PcieHostInterface
typedef PcieHostTop HostInterface;
`endif

////////////////////////////// Zynq /////////////////////////////////
`ifdef ZynqHostInterface
import PS7LIB::*;
import Bscan::*;

interface HostInterface;
    interface PS7 ps7;
    interface Clock portalClock;
    interface Reset portalReset;
    interface Clock derivedClock;
    interface Reset derivedReset;
    interface BscanTop bscan;
endinterface

//export PS7LIB::*;
//export BscanTop;
//export HostInterface;
//export DataBusWidth;
//export NumberOfMasters;
//export PhysAddrWidth;
`endif
