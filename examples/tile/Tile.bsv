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
import MemTypes::*;
import HostInterface::*;

typedef 4 MaxTileMemClients;

interface TilePins;
endinterface

interface ITilePins;
endinterface

instance Connectable#(TilePins,ITilePins);
   module mkConnection#(TilePins t, ITilePins it)(Empty);
   endmodule
endinstance

interface TileSocket;
   interface PhysMemMaster#(18,32) portals;
   interface WriteOnly#(Bool) interrupt;
   interface Vector#(MaxTileMemClients, MemReadServer#(DataBusWidth)) readers;
   interface Vector#(MaxTileMemClients, MemWriteServer#(DataBusWidth)) writers;
   interface ITilePins pins;
endinterface

interface Tile;
   interface PhysMemSlave#(18,32) portals;
   interface ReadOnly#(Bool) interrupt;
   interface Vector#(MaxTileMemClients, MemReadClient#(DataBusWidth)) readers;
   interface Vector#(MaxTileMemClients, MemWriteClient#(DataBusWidth)) writers;
   interface TilePins pins;
endinterface

interface Framework#(numeric type numTiles, type pins, numeric type numMasters);
   interface Vector#(numTiles, TileSocket) sockets;
   interface PhysMemSlave#(32,32) slave;
   interface Vector#(numMasters,PhysMemMaster#(PhysAddrWidth, DataBusWidth)) masters;
   interface Vector#(16,ReadOnly#(Bool)) interrupt;
   interface pins             pins;
endinterface

instance Connectable#(Tile,TileSocket);
   module mkConnection#(Tile t, TileSocket ts)(Empty);
      mkConnection(ts.portals,t.portals);
      rule connect_interrupt;
	 ts.interrupt <= t.interrupt;
      endrule
      mapM(uncurry(mkConnection), zip(t.readers,ts.readers));
      mapM(uncurry(mkConnection), zip(t.writers,ts.writers));
      mkConnection(t.pins,ts.pins);
   endmodule
endinstance