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

import Vector::*;
import Connectable::*;

import Portal::*;
import CtrlMux::*;
import HostInterface::*;
import Tile::*;
import Memread::*;
import MMU::*;
import MemServer::*;
import MemTypes::*;

import MemreadRequest::*;
import MemreadIndication::*;
import MMURequest::*;
import MMUIndication::*;
import MemServerIndication::*;
import MemServerRequest::*;


typedef enum {MemreadIndicationH2S, MMUIndicationH2S,MemServerIndicationH2S, 
	      MemreadRequestS2H,MMURequestS2H,MemServerRequestS2H} IfcNames deriving (Eq,Bits);

module mkMemreadTile(Tile);
   
   MemreadIndicationProxy lMemreadIndicationProxy <- mkMemreadIndicationProxy(MemreadIndicationH2S);
   Memread lMemread <- mkMemread(lMemreadIndicationProxy.ifc);
   MemreadRequestWrapper lMemreadRequestWrapper <- mkMemreadRequestWrapper(MemreadRequestS2H, lMemread.request);
   
   Vector#(2,StdPortal) portal_vec;
   portal_vec[0] = lMemreadIndicationProxy.portalIfc;
   portal_vec[1] = lMemreadRequestWrapper.portalIfc;
   PhysMemSlave#(20,32) ctrl_mux <- mkSlaveMux(portal_vec);
   let interrupts <- mkInterruptMux(getInterruptVector(portal_vec));
   
   interface portals = ctrl_mux;
   interface interrupt = interrupts;
   interface readers = append(lMemread.dmaClient,replicate(null_mem_read_client));
   interface writers = replicate(null_mem_write_client);
   interface pins = ?;
      
endmodule

module mkFramework(Framework#(numTiles,Empty,numMasters))
   provisos(Add#(a__, TLog#(TAdd#(1, numTiles)), 12)
	    ,Add#(b__, TLog#(c__), 6)
	    ,Mul#(c__, numMasters, numTiles)
	    );
   
   
   Vector#(numTiles, PhysMemConnector#(20,32)) portal_connectors <- replicateM(mkPhysMemConnector);
   Vector#(numTiles, MemReadClient#(DataBusWidth)) tile_read_clients = newVector;
   Vector#(numTiles, MemWriteClient#(DataBusWidth)) tile_write_clients = newVector;
   Vector#(numTiles, TileSocket) tss = newVector;
   for(Integer i = 0; i < valueOf(numTiles); i=i+1) begin
	 
   end


   /////////////////////////////////////////////////////////////
   // framework internal portals

   MMUIndicationProxy lMMUIndicationProxy <- mkMMUIndicationProxy(MMUIndicationH2S);
   MemServerIndicationProxy lMemServerIndicationProxy <- mkMemServerIndicationProxy(MemServerIndicationH2S);

   MMU#(PhysAddrWidth) lMMU <- mkMMU(0,True, lMMUIndicationProxy.ifc);
   MemServer#(PhysAddrWidth,DataBusWidth,numMasters) lMemServer <- mkMemServerRW(lMemServerIndicationProxy.ifc, tile_read_clients, tile_write_clients, cons(lMMU,nil));

   MMURequestWrapper lMMURequestWrapper <- mkMMURequestWrapper(MMURequestS2H, lMMU.request);
   MemServerRequestWrapper lMemServerRequestWrapper <- mkMemServerRequestWrapper(MemServerRequestS2H, lMemServer.request);

   Vector#(4,StdPortal) framework_portals;
   framework_portals[0] = lMMUIndicationProxy.portalIfc;
   framework_portals[1] = lMemServerIndicationProxy.portalIfc;
   framework_portals[2] = lMMURequestWrapper.portalIfc;
   framework_portals[3] = lMemServerRequestWrapper.portalIfc;
   PhysMemSlave#(20,32) framework_ctrl_mux <- mkSlaveMux(framework_portals);
   
   //
   /////////////////////////////////////////////////////////////

   Vector#(TAdd#(1,numTiles), PhysMemSlave#(20,32)) foo = cons(framework_ctrl_mux, map(getPhysMemConnectorSlave, portal_connectors)); 
   PhysMemSlave#(32,32) ctrl_mux <- mkMemSlaveMux(foo);

   interface interrupt = getInterruptVector(framework_portals);
   interface slave = ctrl_mux;
   interface masters = lMemServer.masters;
   interface pins = ?; 
   interface sockets = tss;

endmodule


module mkConnectalTop(ConnectalTop#(PhysAddrWidth,DataBusWidth,Empty,1));

   Framework#(1,Empty,1) f <- mkFramework;
   Tile memreadTile <- mkMemreadTile;
   mkConnection(memreadTile, f.sockets[0]);

   interface interrupt = f.interrupt;
   interface slave = f.slave;
   interface masters = f.masters;
   interface pins = f.pins;

endmodule : mkConnectalTop
