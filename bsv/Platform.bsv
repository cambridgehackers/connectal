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
import ConnectalConfig::*;
import Vector::*;
import BuildVector::*;
import Portal::*;
import HostInterface::*;
import ConnectalMMU::*;
import MemServer::*;
import ConnectalMemTypes::*;
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
import IfcNames::*;
`include "ConnectalProjectConfig.bsv"
import `PinTypeInclude::*;

interface Platform;
   interface PhysMemSlave#(32,32) slave;
   interface Vector#(NumberOfMasters,PhysMemMaster#(PhysAddrWidth, DataBusWidth)) masters;
   interface Vector#(MaxNumberOfPortals,ReadOnly#(Bool)) interrupt;
   interface `PinType pins;
endinterface

typedef TMax#(TLog#(TSub#(NumberOfTiles,1)),1) TileTagBits;
function Bit#(TSub#(MemTagSize,TileTagBits)) tagLsb(Bit#(MemTagSize) tag); return truncate(tag); endfunction
function Bit#(TileTagBits) tagMsb(Bit#(MemTagSize) tag); return truncate(tag >> valueOf(TSub#(MemTagSize,TileTagBits))); endfunction

module renameReads#(Integer tile, MemReadClient#(DataBusWidth) reader, MemServerIndication err)(MemReadClient#(DataBusWidth));
   interface Get readReq;
      method ActionValue#(MemRequest) get;
	 let req <- reader.readReq.get;
	 Bit#(TSub#(MemTagSize,TileTagBits)) lsb = tagLsb(req.tag);
	 Bit#(TileTagBits) msb = tagMsb(req.tag);
	 if(req.tag != extend(lsb) && valueOf(NumberOfTiles) > 2) begin // one mgmt tile and one user tile
	    $display("renameReads tile tag out of range: 'h%h", req.tag);
	    err.error(extend(pack(DmaErrorTileTagOutOfRange)), req.sglId, extend(req.tag), fromInteger(tile));
	 end
	 req.tag = {fromInteger(tile),lsb};
	 return req;
      endmethod
   endinterface
   interface Put readData;
      method Action put(MemData#(DataBusWidth) v);
	 reader.readData.put(MemData{data:v.data,
                                     tag:{0,tagLsb(v.tag)},
`ifdef BYTE_ENABLES_MEM_DATA
				     byte_enables: v.byte_enables,
`endif
                                     last:v.last});
      endmethod
   endinterface
endmodule

module renameWrites#(Integer tile, MemWriteClient#(DataBusWidth) writer, MemServerIndication err)(MemWriteClient#(DataBusWidth));
   interface Get writeReq;
      method ActionValue#(MemRequest) get;
	 let req <- writer.writeReq.get;
	 Bit#(TSub#(MemTagSize,TileTagBits)) lsb = tagLsb(req.tag);
	 Bit#(TileTagBits) msb = tagMsb(req.tag);
	 if(req.tag != extend(lsb) && valueOf(NumberOfTiles) > 2) begin // one mgmt tile and one user tile
	    $display("renameWrites tile tag out of range: 'h%h", req.tag);
	    err.error(extend(pack(DmaErrorTileTagOutOfRange)), req.sglId, extend(req.tag), fromInteger(tile));
	 end
	 req.tag = {fromInteger(tile),lsb};
	 return req;
      endmethod
   endinterface
   interface Get writeData;
      method ActionValue#(MemData#(DataBusWidth)) get;
	 let rv <- writer.writeData.get;
   	 return MemData{data:rv.data,
                        tag:{0,tagLsb(rv.tag)},
`ifdef BYTE_ENABLES_MEM_DATA
                             byte_enables: rv.byte_enables,
`endif
                             last:rv.last};
      endmethod
   endinterface
   interface Put writeDone;
      method Action put(Bit#(MemTagSize) v);
	 writer.writeDone.put({0,tagLsb(v)});
      endmethod
   endinterface
endmodule

module mkPlatform#(Vector#(NumberOfUserTiles, ConnectalTop#(`PinType)) tiles)(Platform);
   /////////////////////////////////////////////////////////////
   // connecting up the tiles

   Vector#(NumberOfUserTiles, PhysMemSlave#(18,32)) tile_slaves;
   Vector#(NumberOfUserTiles, ReadOnly#(Bool)) tile_interrupts;
   Vector#(NumberOfUserTiles, Vector#(NumReadClients, MemReadClient#(DataBusWidth))) tile_read_clients;
   Vector#(NumberOfUserTiles, Vector#(NumWriteClients, MemWriteClient#(DataBusWidth))) tile_write_clients;
   Vector#(NumberOfUserTiles, Vector#(NumReadClients, Integer)) read_client_tile_numbers;
   Vector#(NumberOfUserTiles, Vector#(NumWriteClients, Integer)) write_client_tile_numbers;
   for(Integer i = 0; i < valueOf(NumberOfUserTiles); i=i+1) begin
      tile_slaves[i] = tiles[i].slave;
      let imux <- mkInterruptMux(tiles[i].interrupt);
      //ReadOnly#(Bool) imux = tiles[i].interrupt;
      tile_interrupts[i] = imux;
      tile_read_clients[i] = tiles[i].readers;
      tile_write_clients[i] = tiles[i].writers;
      read_client_tile_numbers[i] = replicate(i);
      write_client_tile_numbers[i] = replicate(i);
   end

   /////////////////////////////////////////////////////////////
   // framework internal portals

   MMUIndicationProxy lMMUIndicationProxy <- mkMMUIndicationProxy(PlatformIfcNames_MMUIndicationH2S);
   MemServerIndicationProxy lMemServerIndicationProxy <- mkMemServerIndicationProxy(PlatformIfcNames_MemServerIndicationH2S);

`ifdef USE_SIMPLE_MMU
   MMU#(PhysAddrWidth) lMMU <- mkSimpleMMU(0,True, lMMUIndicationProxy.ifc);
`else
   MMU#(PhysAddrWidth) lMMU <- mkMMU(0,True, lMMUIndicationProxy.ifc);
`endif
   Vector#(TMul#(NumberOfUserTiles,NumReadClients), MemReadClient#(DataBusWidth)) tile_read_clients_renamed <- zipWith3M(renameReads, concat(read_client_tile_numbers), concat(tile_read_clients), replicate(lMemServerIndicationProxy.ifc));
   Vector#(TMul#(NumberOfUserTiles,NumWriteClients), MemWriteClient#(DataBusWidth)) tile_write_clients_renamed <- zipWith3M(renameWrites, concat(write_client_tile_numbers), concat(tile_write_clients), replicate(lMemServerIndicationProxy.ifc));
   MemServer#(PhysAddrWidth,DataBusWidth,NumberOfMasters) lMemServer <- mkMemServer(tile_read_clients_renamed, tile_write_clients_renamed, vec(lMMU), lMemServerIndicationProxy.ifc);

   MMURequestWrapper lMMURequestWrapper <- mkMMURequestWrapper(PlatformIfcNames_MMURequestS2H, lMMU.request);
   MemServerRequestWrapper lMemServerRequestWrapper <- mkMemServerRequestWrapper(PlatformIfcNames_MemServerRequestS2H, lMemServer.request);

   Vector#(4,StdPortal) framework_portals;
   framework_portals[0] = lMMUIndicationProxy.portalIfc;
   framework_portals[1] = lMemServerIndicationProxy.portalIfc;
   framework_portals[2] = lMMURequestWrapper.portalIfc;
   framework_portals[3] = lMemServerRequestWrapper.portalIfc;
   PhysMemSlave#(18,32) framework_ctrl_mux <- mkSlaveMux(framework_portals);
   let framework_intr <- mkInterruptMux(getInterruptVector(framework_portals));
   
   /////////////////////////////////////////////////////////////
   // expose interface to top

   PhysMemSlave#(32,32) ctrl_mux <- mkPhysMemSlaveMux(cons(framework_ctrl_mux,tile_slaves));
   Vector#(MaxNumberOfPortals, ReadOnly#(Bool)) interrupts = replicate(interface ReadOnly; method Bool _read(); return False; endmethod endinterface);
   interrupts[0] = framework_intr;
   for (Integer i = 1; i < valueOf(NumberOfTiles); i = i + 1)
      interrupts[i] = tile_interrupts[i-1];
   interface interrupt = interrupts;
   interface slave = ctrl_mux;
   interface masters = lMemServer.masters;
   interface pins = tiles[0].pins;
endmodule
