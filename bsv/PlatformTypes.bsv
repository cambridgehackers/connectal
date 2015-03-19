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
import Connectable::*;

import Portal::*;
import MemTypes::*;
import HostInterface::*;

typedef enum {MMUIndicationH2S, MemServerIndicationH2S, MMURequestS2H, MemServerRequestS2H} PlatformNames deriving (Eq,Bits);

interface TileSocket#(type ext_socket_type, numeric type numReadServers, numeric type numWriteServers);
   interface PhysMemMaster#(18,32) portals;
   interface WriteOnly#(Bool) interrupt;
   interface Vector#(numReadServers,MemReadServer#(DataBusWidth)) readers;
   interface Vector#(numWriteServers,MemWriteServer#(DataBusWidth)) writers;
   interface ext_socket_type ext_socket;
endinterface

interface Tile#(type ext_type, numeric type numReadClients, numeric type numWriteClients);
   interface PhysMemSlave#(18,32) portals;
   interface ReadOnly#(Bool) interrupt;
   interface Vector#(numReadClients,MemReadClient#(DataBusWidth)) readers;
   interface Vector#(numWriteClients,MemWriteClient#(DataBusWidth)) writers;
   interface ext_type ext;
endinterface

interface Platform#(numeric type numTiles, type ext_socket_type, type pins, numeric type numMasters, numeric type numReadServers, numeric type numWriteServers);
   interface Vector#(numTiles, TileSocket#(ext_socket_type, numReadServers, numWriteServers)) sockets;
   interface PhysMemSlave#(32,32) slave;
   interface Vector#(numMasters,PhysMemMaster#(PhysAddrWidth, DataBusWidth)) masters;
   interface Vector#(16,ReadOnly#(Bool)) interrupt;
   interface pins pins;
endinterface

instance Connectable#(Empty,Empty);
   module mkConnection#(Empty a, Empty b)(Empty);
   endmodule
endinstance

instance Connectable#(Tile#(ext_type, num_readers, num_writers),TileSocket#(ext_socket_type, num_readers, num_writers))
   provisos(Connectable#(ext_type, ext_socket_type));
   module mkConnection#(Tile#(ext_type, num_readers, num_writers) t, TileSocket#(ext_socket_type, num_readers, num_writers) ts)(Empty);
      mkConnection(ts.portals,t.portals);
      zipWithM(mkConnection, t.readers,ts.readers);
      zipWithM(mkConnection, t.writers,ts.writers);
      mkConnection(t.ext,ts.ext_socket);
      rule connect_interrupt;
	 ts.interrupt <= t.interrupt;
      endrule
   endmodule
endinstance


