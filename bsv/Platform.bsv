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
import MMU::*;
import MemServer::*;
import PlatformTypes::*;
import MemTypes::*;
import CtrlMux::*;
import FIFO::*;
import GetPut::*;
import SpecialFIFOs::*;

import MMURequest::*;
import MMUIndication::*;
import MemServerIndication::*;
import MemServerRequest::*;

module mkPlatform#(Vector#(numTiles, Tile#(Empty, numReadClients, numWriteClients)) tiles)(Platform#(Empty,numMasters))
   provisos(Add#(a__, TLog#(TAdd#(1, numTiles)), 14)
	    ,Add#(TMul#(numTiles, numWriteClients), b__, TMul#(TDiv#(TMul#(numTiles,numWriteClients), numMasters), numMasters))
	    ,Add#(TMul#(numTiles, numReadClients), c__, TMul#(TDiv#(TMul#(numTiles,numReadClients), numMasters), numMasters))
	    );

   /////////////////////////////////////////////////////////////
   // connecting up the tiles

   Vector#(numTiles, PhysMemSlave#(18,32)) tile_slaves;
   Vector#(numTiles, ReadOnly#(Bool)) tile_interrupts;
   Vector#(numTiles, Vector#(numReadClients, MemReadClient#(DataBusWidth))) tile_read_clients;
   Vector#(numTiles, Vector#(numWriteClients, MemWriteClient#(DataBusWidth))) tile_write_clients;
   for(Integer i = 0; i < valueOf(numTiles); i=i+1) begin
      tile_slaves[i] = tiles[i].portals;
      tile_interrupts[i] = tiles[i].interrupt;
      tile_read_clients[i] = tiles[i].readers;
      tile_write_clients[i] = tiles[i].writers;
   end


   /////////////////////////////////////////////////////////////
   // framework internal portals

   MMUIndicationProxy lMMUIndicationProxy <- mkMMUIndicationProxy(MMUIndicationH2S);
   MemServerIndicationProxy lMemServerIndicationProxy <- mkMemServerIndicationProxy(MemServerIndicationH2S);

   MMU#(PhysAddrWidth) lMMU <- mkMMU(0,True, lMMUIndicationProxy.ifc);
   MemServer#(PhysAddrWidth,DataBusWidth,numMasters) lMemServer <- mkMemServer(concat(tile_read_clients), concat(tile_write_clients), cons(lMMU,nil), lMemServerIndicationProxy.ifc);

   MMURequestWrapper lMMURequestWrapper <- mkMMURequestWrapper(MMURequestS2H, lMMU.request);
   MemServerRequestWrapper lMemServerRequestWrapper <- mkMemServerRequestWrapper(MemServerRequestS2H, lMemServer.request);

   Vector#(4,StdPortal) framework_portals;
   framework_portals[0] = lMMUIndicationProxy.portalIfc;
   framework_portals[1] = lMemServerIndicationProxy.portalIfc;
   framework_portals[2] = lMMURequestWrapper.portalIfc;
   framework_portals[3] = lMemServerRequestWrapper.portalIfc;
   PhysMemSlave#(18,32) framework_ctrl_mux <- mkSlaveMux(framework_portals);
   let framework_intr <- mkInterruptMux(getInterruptVector(framework_portals));
   
   /////////////////////////////////////////////////////////////
   // expose interface to top

   PhysMemSlave#(32,32) ctrl_mux <- mkMemSlaveMux(cons(framework_ctrl_mux, tile_slaves));
   Vector#(16, ReadOnly#(Bool)) interrupts = replicate(interface ReadOnly; method Bool _read(); return False; endmethod endinterface);
   interrupts[0] = framework_intr;
   for (Integer i = 1; i < valueOf(TAdd#(1,numTiles)); i = i + 1)
      interrupts[i] = tile_interrupts[i-1];

   interface interrupt = interrupts;
   interface slave = ctrl_mux;
   interface masters = lMemServer.masters;
   interface pins = ?; 

endmodule




