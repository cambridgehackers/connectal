// Copyright (c) 2015 Connectal Project

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

`include "ConnectalProjectConfig.bsv"

`ifndef DataBusWidth
`define DataBusWidth 64
`endif

// typedef TDiv#(TMax#(128,DataBusWidth),8) TlpDataBytes;
// typedef TDiv#(TMax#(128,DataBusWidth),32) TlpDataWords;

typedef TDiv#(128,8) TlpDataBytes;
typedef TDiv#(128,32) TlpDataWords;


typedef `PhysAddrWidth PhysAddrWidth;
typedef `SlaveDataBusWidth SlaveDataBusWidth;
typedef `DataBusWidth DataBusWidth;
typedef `NumberOfMasters NumberOfMasters;
typedef `SlaveControlAddrWidth SlaveControlAddrWidth;
typedef `NumberOfUserTiles NumberOfUserTiles;
typedef TAdd#(`NumberOfUserTiles,1) NumberOfTiles;
`ifndef NumReadClients
typedef 2 NumReadClients;
`else
typedef `NumReadClients NumReadClients;
`endif
`ifndef NumWriteClients
typedef 2 NumWriteClients;
`else
typedef `NumWriteClients NumWriteClients;
`endif
//typedef `PinType TileExtType;
//typedef `PinType PinType;
typedef 16 MaxNumberOfPortals;
`ifdef PcieLanes
typedef `PcieLanes PcieLanes;
`endif
