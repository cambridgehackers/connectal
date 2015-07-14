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
import Vector::*;
import Portal::*;
import HostInterface::*;
import PlatformTypes::*;
import Platform::*;
import CtrlMux::*;
import MemServer::*;
import MemTypes::*;
import ReadTest::*;
import ReadTestEnum::*;
import ReadTestRequest::*;
import ReadTestIndication::*;

(* synthesize *)
module mkTile(Tile);
   ReadTestIndicationProxy lReadTestIndicationProxy <- mkReadTestIndicationProxy(IfcNames_ReadTestIndicationH2S);
   ReadTest lReadTest <- mkReadTest(lReadTestIndicationProxy.ifc);
   ReadTestRequestWrapper lReadTestRequestWrapper <- mkReadTestRequestWrapper(IfcNames_ReadTestRequestS2H, lReadTest.request);
   Vector#(NumReadClients,MemReadClient#(DataBusWidth)) nullReaders = replicate(null_mem_read_client());
   
   Vector#(2,StdPortal) portal_vec;
   portal_vec[0] = lReadTestRequestWrapper.portalIfc;
   portal_vec[1] = lReadTestIndicationProxy.portalIfc;
   PhysMemSlave#(18,32) portal_slave <- mkSlaveMux(portal_vec);
   let interrupts <- mkInterruptMux(getInterruptVector(portal_vec));
   interface interrupt = interrupts;
   interface slave = portal_slave;
   interface readers = take(append(lReadTest.dmaClient, nullReaders));
   interface writers = replicate(null_mem_write_client());
   interface pins = ?;
endmodule

module mkConnectalTop(ConnectalTop#(PhysAddrWidth,DataBusWidth,`PinType,NumberOfMasters));
   Vector#(NumberOfUserTiles,Tile) ts <- replicateM(mkTile);
   Platform f <- mkPlatform(ts);
   interface interrupt = f.interrupt;
   interface slave = f.slave;
   interface masters = f.masters;
   interface pins = f.pins;
endmodule : mkConnectalTop
