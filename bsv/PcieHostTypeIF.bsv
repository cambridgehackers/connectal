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

import Vector            :: *;
import GetPut            :: *;
import ClientServer      :: *;
import PCIE               :: *;
import PCIEWRAPPER       :: *;
import PcieCsr           :: *;
import MemSlave          :: *;
import MemTypes          :: *;
import Bscan             :: *;
`ifndef BSIM
import PcieEndpointX7    :: *;
`endif

`ifndef DataBusWidth
`define DataBusWidth 64
`endif
`ifndef PinType
`define PinType Empty
`endif

typedef `DataBusWidth DataBusWidth;
typedef `NumberOfMasters NumberOfMasters;
typedef `PinType PinType;

interface PcieHost#(numeric type dsz, numeric type nSlaves);
   interface Vector#(16,MSIX_Entry)              msixEntry;
   interface MemMaster#(32,32)                   master;
   interface Vector#(nSlaves,MemSlave#(40,dsz))  slave;
   interface Put#(Tuple2#(Bit#(64),Bit#(32)))    interruptRequest;
   interface Client#(TLPData#(16), TLPData#(16)) pci;
   interface BscanTop bscanif;
endinterface

interface PcieHostTop;
   interface Clock tepClock125;
   interface Reset tepReset125;
   interface PcieHost#(DataBusWidth, NumberOfMasters) tpciehost;
`ifndef BSIM
   interface Clock tsys_clk_200mhz;
   interface Clock tsys_clk_200mhz_buf;
   interface Clock tpci_clk_100mhz_buf;
   interface PcieEndpointX7#(PcieLanes) tep7;
`endif
endinterface

typedef PcieHostTop HostType;
