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

// TODO: get rid of this connector (mdk)
interface PhysMemConnector#(numeric type addrWidth, numeric type dataWidth);
   interface PhysMemSlave#(addrWidth,dataWidth) slave;
   interface PhysMemMaster#(addrWidth,dataWidth) master;
endinterface
function PhysMemSlave#(aw,dw) getPhysMemConnectorSlave(PhysMemConnector#(aw,dw) s);
   return s.slave;
endfunction
module mkPhysMemConnector(PhysMemConnector#(addrWidth,dataWidth));
   FIFO#(PhysMemRequest#(addrWidth)) read_req <- mkBypassFIFO;
   FIFO#(PhysMemRequest#(addrWidth)) write_req <- mkBypassFIFO;
   FIFO#(MemData#(dataWidth)) read_data <- mkBypassFIFO;
   FIFO#(MemData#(dataWidth)) write_data <- mkBypassFIFO;
   FIFO#(Bit#(MemTagSize))    write_done <- mkBypassFIFO;
   interface PhysMemSlave slave;
      interface PhysMemReadServer read_server;
	 interface Put readReq;
	    method Action put(PhysMemRequest#(addrWidth) r);
	       read_req.enq(r);
	    endmethod
	 endinterface
	 interface Get readData;
	    method ActionValue#(MemData#(dataWidth)) get;
	       read_data.deq;
	       return read_data.first;
	    endmethod
	 endinterface
      endinterface
      interface PhysMemWriteServer write_server; 
	 interface Put writeReq;
	    method Action put(PhysMemRequest#(addrWidth) r);
	       write_req.enq(r);
	    endmethod
	 endinterface
	 interface Put writeData;
	    method Action put(MemData#(dataWidth) d);
	       write_data.enq(d);
	    endmethod
	 endinterface
	 interface Get writeDone;
	    method ActionValue#(Bit#(MemTagSize)) get;
	       write_done.deq;
	       return write_done.first;
	    endmethod
	 endinterface
      endinterface
   endinterface
   interface PhysMemMaster master;
      interface PhysMemReadClient read_client;
	 interface Get readReq;
	    method ActionValue#(PhysMemRequest#(addrWidth)) get;
	       read_req.deq;
	       return read_req.first;
	    endmethod
	 endinterface
	 interface Put readData;
	    method Action put(MemData#(dataWidth) d);
	       read_data.enq(d);
	    endmethod
	 endinterface
      endinterface
      interface PhysMemWriteClient write_client; 
	 interface Get writeReq;
	    method ActionValue#(PhysMemRequest#(addrWidth)) get;
	       write_req.deq;
	       return write_req.first;
	    endmethod
	 endinterface
	 interface Get writeData;
	    method ActionValue#(MemData#(dataWidth)) get;
	       write_data.deq;
	       return write_data.first;
	    endmethod
	 endinterface
	 interface Put writeDone;
	    method Action put(Bit#(MemTagSize) t);
	       write_done.enq(t);
	    endmethod
	 endinterface
      endinterface
   endinterface
endmodule

module mkPlatform(Platform#(numTiles,Empty,Empty,numMasters,numReadServers,numWriteServers))
   provisos(Add#(a__, TLog#(TAdd#(1, numTiles)), 14)
	    ,Add#(numReadServers, b__, TMul#(numReadServers, numTiles))
	    ,Add#(numWriteServers, c__, TMul#(numWriteServers, numTiles))
	    ,Mul#(d__, numMasters, TMul#(numWriteServers, numTiles))
	    ,Mul#(e__, numMasters, TMul#(numReadServers, numTiles))
	    );
   
   /////////////////////////////////////////////////////////////
   // framework internal portals

   MMUIndicationProxy lMMUIndicationProxy <- mkMMUIndicationProxy(MMUIndicationH2S);
   MemServerIndicationProxy lMemServerIndicationProxy <- mkMemServerIndicationProxy(MemServerIndicationH2S);

   MMU#(PhysAddrWidth) lMMU <- mkMMU(0,True, lMMUIndicationProxy.ifc);
   MemServer#(PhysAddrWidth,DataBusWidth,numMasters,TMul#(numReadServers,numTiles),TMul#(numWriteServers,numTiles)) lMemServer <- mkMemServer(lMemServerIndicationProxy.ifc, cons(lMMU,nil));

   MMURequestWrapper lMMURequestWrapper <- mkMMURequestWrapper(MMURequestS2H, lMMU.request);
   MemServerRequestWrapper lMemServerRequestWrapper <- mkMemServerRequestWrapper(MemServerRequestS2H, lMemServer.request);

   Vector#(4,StdPortal) framework_portals;
   framework_portals[0] = lMMUIndicationProxy.portalIfc;
   framework_portals[1] = lMemServerIndicationProxy.portalIfc;
   framework_portals[2] = lMMURequestWrapper.portalIfc;
   framework_portals[3] = lMemServerRequestWrapper.portalIfc;
   PhysMemSlave#(18,32) framework_ctrl_mux <- mkSlaveMux(framework_portals);
   let framework_intr <- mkInterruptMux(getInterruptVector(framework_portals));
   
   //
   /////////////////////////////////////////////////////////////

   /////////////////////////////////////////////////////////////
   // connecting up the tiles

   Vector#(numTiles, PhysMemConnector#(18,32)) portal_connectors <- replicateM(mkPhysMemConnector);
   Vector#(numTiles, Wire#(Bool)) tile_interrupts <- replicateM(mkWire);

   Vector#(numTiles, TileSocket#(Empty,numReadServers,numWriteServers)) tss = newVector;
   for(Integer i = 0; i < valueOf(numTiles); i=i+1) begin
      tss[i] = (interface TileSocket;
		   interface portals = portal_connectors[i].master; 
		   interface WriteOnly interrupt;
		      method Action _write(Bool v) = tile_interrupts[i]._write(v);
		   endinterface
		   interface readers = takeAt(i*valueOf(numReadServers),lMemServer.read_servers);
		   interface writers = takeAt(i*valueOf(numWriteServers),lMemServer.write_servers);
		   interface ext_socket = ?;
		endinterface);
   end

   //
   /////////////////////////////////////////////////////////////

   PhysMemSlave#(32,32) ctrl_mux <- mkMemSlaveMux(cons(framework_ctrl_mux, map(getPhysMemConnectorSlave, portal_connectors)));
   Vector#(16, ReadOnly#(Bool)) interrupts = replicate(interface ReadOnly; method Bool _read(); return False; endmethod endinterface);
   interrupts[0] = framework_intr;
   for (Integer i = 1; i < valueOf(TAdd#(1,numTiles)); i = i + 1)
      interrupts[i] = (interface ReadOnly;
			  method Bool _read();
			     return tile_interrupts[i-1]._read;
			  endmethod
		       endinterface);
   interface interrupt = interrupts;
   interface slave = ctrl_mux;
   interface masters = lMemServer.masters;
   interface pins = ?; 
   interface sockets = tss;

endmodule




