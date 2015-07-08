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
import Pipe::*;
import ConnectalMemory::*;
import MMURequest::*;
import MMUIndication::*;
import MemServerIndication::*;
import MemServerRequest::*;

module renameReads#(Integer tile, MemReadClient#(DataBusWidth) reader, MemServerIndication err)(MemReadClient#(DataBusWidth));
   interface Get readReq;
      method ActionValue#(MemRequest) get;
	 let rv <- reader.readReq.get;
	 Bit#(4) lsb = rv.tag[3:0];
	 Bit#(2) msb = rv.tag[5:4];
	 if(msb != 0) begin
	    $display("renameReads tile tag out of range: %h", rv.tag);
	    err.error(extend(pack(DmaErrorTileTagOutOfRange)), rv.sglId, extend(rv.tag), fromInteger(tile));
	 end
	 return MemRequest{sglId:rv.sglId, offset:rv.offset, burstLen:rv.burstLen, tag:{fromInteger(tile),lsb}};
      endmethod
   endinterface
   interface Put readData;
      method Action put(MemData#(DataBusWidth) v);
	 reader.readData.put(MemData{data:v.data, tag:{0,v.tag[3:0]}, last:v.last});
      endmethod
   endinterface
endmodule

module renameWrites#(Integer tile, MemWriteClient#(DataBusWidth) writer, MemServerIndication err)(MemWriteClient#(DataBusWidth));
   interface Get writeReq;
      method ActionValue#(MemRequest) get;
	 let rv <- writer.writeReq.get;
	 Bit#(4) lsb = rv.tag[3:0];
	 Bit#(2) msb = rv.tag[5:4];
	 if(msb != 0) begin
	    $display("renameWrites tile tag out of range: %h", rv.tag);
	    err.error(extend(pack(DmaErrorTileTagOutOfRange)), rv.sglId, extend(rv.tag), fromInteger(tile));
	 end
	 return MemRequest{sglId:rv.sglId, offset:rv.offset, burstLen:rv.burstLen, tag:{fromInteger(tile),lsb}};
      endmethod
   endinterface
   interface Get writeData;
      method ActionValue#(MemData#(DataBusWidth)) get;
	 let rv <- writer.writeData.get;
   	 return MemData{data:rv.data, tag:{0,rv.tag[3:0]}, last:rv.last};
      endmethod
   endinterface
   interface Put writeDone;
      method Action put(Bit#(MemTagSize) v);
	 writer.writeDone.put({0,v[3:0]});
      endmethod
   endinterface
endmodule

module mkPlatform#(Vector#(NumberOfTiles, Tile) tiles)(Platform);
   /////////////////////////////////////////////////////////////
   // connecting up the tiles

   Vector#(NumberOfTiles, PhysMemSlave#(18,32)) tile_slaves;
   Vector#(NumberOfTiles, ReadOnly#(Bool)) tile_interrupts;
   Vector#(NumberOfTiles, Vector#(NumReadClients, MemReadClient#(DataBusWidth))) tile_read_clients;
   Vector#(NumberOfTiles, Vector#(NumWriteClients, MemWriteClient#(DataBusWidth))) tile_write_clients;
   for(Integer i = 0; i < valueOf(NumberOfTiles); i=i+1) begin
      tile_slaves[i] = tiles[i].portals;
      tile_interrupts[i] = tiles[i].interrupt;
      tile_read_clients[i] = tiles[i].readers;
      tile_write_clients[i] = tiles[i].writers;
   end

   /////////////////////////////////////////////////////////////
   // framework internal portals

   MMUIndicationProxy lMMUIndicationProxy <- mkMMUIndicationProxy(IfcNames_MMUIndicationH2S);
   MemServerIndicationProxy lMemServerIndicationProxy <- mkMemServerIndicationProxy(IfcNames_MemServerIndicationH2S);

   MMU#(PhysAddrWidth) lMMU <- mkMMU(0,True, lMMUIndicationProxy.ifc);
   Vector#(TMul#(NumberOfTiles,NumReadClients), MemReadClient#(DataBusWidth)) tile_read_clients_renamed <- zipWith3M(renameReads, genVector, concat(tile_read_clients), replicate(lMemServerIndicationProxy.ifc));
   Vector#(TMul#(NumberOfTiles,NumWriteClients), MemWriteClient#(DataBusWidth)) tile_write_clients_renamed <- zipWith3M(renameWrites, genVector, concat(tile_write_clients), replicate(lMemServerIndicationProxy.ifc));
   MemServer#(PhysAddrWidth,DataBusWidth,NumberOfMasters) lMemServer <- mkMemServer(tile_read_clients_renamed, tile_write_clients_renamed, cons(lMMU,nil), lMemServerIndicationProxy.ifc);

   MMURequestWrapper lMMURequestWrapper <- mkMMURequestWrapper(IfcNames_MMURequestS2H, lMMU.request);
   MemServerRequestWrapper lMemServerRequestWrapper <- mkMemServerRequestWrapper(IfcNames_MemServerRequestS2H, lMemServer.request);

   Vector#(4,StdPortal) framework_portals;
   framework_portals[0] = lMMUIndicationProxy.portalIfc;
   framework_portals[1] = lMemServerIndicationProxy.portalIfc;
   framework_portals[2] = lMMURequestWrapper.portalIfc;
   framework_portals[3] = lMemServerRequestWrapper.portalIfc;
   PhysMemSlave#(18,32) framework_ctrl_mux <- mkSlaveMux(framework_portals);
   let framework_intr <- mkInterruptMux(getInterruptVector(framework_portals));
   
   /////////////////////////////////////////////////////////////
   // expose interface to top

   PhysMemSlave#(32,32) ctrl_mux <- mkMemPortalMux(cons(framework_ctrl_mux,tile_slaves));
   Vector#(16, ReadOnly#(Bool)) interrupts = replicate(interface ReadOnly; method Bool _read(); return False; endmethod endinterface);
   interrupts[0] = framework_intr;
   for (Integer i = 1; i < valueOf(TAdd#(1,NumberOfTiles)); i = i + 1)
      interrupts[i] = tile_interrupts[i-1];
   interface interrupt = interrupts;
   interface slave = ctrl_mux;
   interface masters = lMemServer.masters;
endmodule
