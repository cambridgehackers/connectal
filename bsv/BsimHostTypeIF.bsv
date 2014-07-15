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

`ifndef DataBusWidth
`define DataBusWidth 64
`endif
`ifndef PinType
`define PinType Empty
`endif

typedef `PinType PinType;
typedef `NumberOfMasters NumberOfMasters;
typedef `DataBusWidth DataBusWidth;

// this interface should allow for different master and slave bus paraters;		 
interface BsimHost#(numeric type clientAddrWidth, numeric type clientBusWidth, numeric type clientIdWidth,  
		    numeric type serverAddrWidth, numeric type serverBusWidth, numeric type serverIdWidth,
		    numeric type nSlaves);
   interface MemMaster#(clientAddrWidth, clientBusWidth)  mem_client;
   interface Vector#(nSlaves,Axi3Slave#(serverAddrWidth,  serverBusWidth, serverIdWidth))  axi_servers;
endinterface

typedef BsimHost#(32,32,12,40,DataBusWidth,6,NumberOfMasters) HostType;
