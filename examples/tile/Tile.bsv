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

interface TilePins;
endinterface

interface ITilePins;
endinterface

instance Connectable#(TilePins,ITilePins);
   module mkConnection#(TilePins t, ITilePins it)(Empty);
   endmodule
endinstance

// implementation of a Portal as a physical memory slave
interface MemPortalSocket#(numeric type slaveAddrWidth, numeric type slaveDataWidth);
   interface PhysMemMaster#(slaveAddrWidth,slaveDataWidth) slave;
   interface WriteOnly#(Bool) interrupt;
   interface ReadOnly#(Bool) top;
endinterface

interface TileSocket;
   interface PhysMemMaster#(18,32) portals;
   interface WriteOnly#(Bool) interrupt;
   interface MemReadServer#(DataBusWidth) reader;
   interface MemWriteServer#(DataBusWidth) writer;
   interface ITilePins pins;
endinterface

interface Tile;
   interface PhysMemSlave#(18,32) portals;
   interface ReadOnly#(Bool) interrupt;
   interface MemReadClient#(DataBusWidth) reader;
   interface MemWriteClient#(DataBusWidth) writer;
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
      mkConnection(t.reader,ts.reader);
      mkConnection(t.writer,ts.writer);
      mkConnection(t.pins,ts.pins);
   endmodule
endinstance


