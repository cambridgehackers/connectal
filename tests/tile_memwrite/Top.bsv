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
import Memwrite::*;
import MemwriteEnum::*;
import MemwriteRequest::*;
import MemwriteIndication::*;
import `PinTypeInclude::*;

(* synthesize *)
module mkTile(Tile);
   MemwriteIndicationProxy lMemwriteIndicationProxy <- mkMemwriteIndicationProxy(IfcNames_MemwriteIndicationH2S);
   Memwrite lMemwrite <- mkMemwrite(lMemwriteIndicationProxy.ifc);
   MemwriteRequestWrapper lMemwriteRequestWrapper <- mkMemwriteRequestWrapper(IfcNames_MemwriteRequestS2H, lMemwrite.request);
   Vector#(NumWriteClients,MemWriteClient#(DataBusWidth)) nullWriters = replicate(null_mem_write_client());
   
   Vector#(2,StdPortal) portal_vec;
   portal_vec[0] = lMemwriteRequestWrapper.portalIfc;
   portal_vec[1] = lMemwriteIndicationProxy.portalIfc;
   PhysMemSlave#(18,32) portal_slave <- mkSlaveMux(portal_vec);
   let interrupts <- mkInterruptMux(getInterruptVector(portal_vec));
   interface interrupt = interrupts;
   interface slave = portal_slave;
   interface readers = replicate(null_mem_read_client());
   interface writers = take(append(lMemwrite.dmaClient, nullWriters));
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
