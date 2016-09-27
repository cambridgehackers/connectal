
// Copyright (c) 2013,2014 Quanta Research Cambridge, Inc.

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

import GetPut :: *;
import ClientServer :: *;
import Clocks :: *;
import MemTypes :: *;
import FIFOF :: *;
import ConnectalBramFifo::*;
import Probe::*;

////////////////////////////////////////////////////////////////////////////////
/// Typeclass Definition
////////////////////////////////////////////////////////////////////////////////
typeclass ConnectableWithClocks#(type a, type b);
   module mkConnectionWithClocks#(a x1, b x2)(Empty);
   module mkConnectionWithClocks2#(Clock inClock, Reset inReset, Clock outClock, Reset outReset, a x1, b x2)(Empty);
endtypeclass

instance ConnectableWithClocks#(Get#(a), Put#(a)) provisos (Bits#(a, awidth), Add#(1, a__, awidth));
   module mkConnectionWithClocks2#(Clock inClock, Reset inReset, Clock outClock, Reset outReset, Get#(a) in, Put#(a) out)(Empty) provisos (Bits#(a, awidth), Add#(1, a__, awidth));
      //SyncFIFOIfc#(a) synchronizer <- mkSyncFIFO(8, inClock, inReset, outClock);
      FIFOF#(a) synchronizer <- mkDualClockBramFIFOF(inClock, inReset, outClock, outReset);
       rule mcwc_doGet;
           let v <- in.get();
	   synchronizer.enq(v);
       endrule
       rule mcwc_doPut;
	  let v = synchronizer.first;
	  synchronizer.deq;
	  out.put(v);
       endrule
   endmodule

   module mkConnectionWithClocks#(Get#(a) in, Put#(a) out)(Empty) provisos (Bits#(a, awidth), Add#(1, a__, awidth));
      Clock inClock = clockOf(in);
      Reset inReset = resetOf(in);
      Clock outClock = clockOf(out);
      Reset outReset = resetOf(out);

      mkConnectionWithClocks2(inClock, inReset, outClock, outReset, in, out);
   endmodule: mkConnectionWithClocks
endinstance: ConnectableWithClocks

instance ConnectableWithClocks#(Client#(a,b), Server#(a,b)) provisos (Bits#(a, awidth), Bits#(b, bwidth), Add#(1, a__, awidth), Add#(1, b__, bwidth));
   module mkConnectionWithClocks2#(Clock inClock, Reset inReset, Clock outClock, Reset outReset, Client#(a,b) client, Server#(a,b) server)(Empty)
      provisos (ConnectableWithClocks#(Get#(a), Put#(a)),
		ConnectableWithClocks#(Get#(b), Put#(b)),
		Bits#(a, awidth),
		Bits#(b, bwidth));
      let reqCnx <- mkConnectionWithClocks(client.request, server.request);
      let respCnx <- mkConnectionWithClocks(server.response, client.response);
   endmodule
   module mkConnectionWithClocks#(Client#(a,b) client, Server#(a,b) server)(Empty)
      provisos (ConnectableWithClocks#(Get#(a), Put#(a)),
		ConnectableWithClocks#(Get#(b), Put#(b)),
		Bits#(a, awidth),
		Bits#(b, bwidth));
      Clock inClock = clockOf(client);
      Reset inReset = resetOf(client);
      Clock outClock = clockOf(server);
      Reset outReset = resetOf(server);

      mkConnectionWithClocks2(inClock, inReset, outClock, outReset, client, server);
   endmodule
endinstance

instance ConnectableWithClocks#(PhysMemReadClient#(addrWidth, dataWidth),
				PhysMemReadServer#(addrWidth, dataWidth));
   module mkConnectionWithClocks2#(Clock inClock, Reset inReset, Clock outClock, Reset outReset,
				   PhysMemReadClient#(addrWidth, dataWidth) client,
				   PhysMemReadServer#(addrWidth, dataWidth) server)(Empty);
      let reqCnx <- mkConnectionWithClocks(client.readReq, server.readReq);
      let dataCnx <- mkConnectionWithClocks(server.readData, client.readData);
   endmodule
   module mkConnectionWithClocks#(PhysMemReadClient#(addrWidth, dataWidth) client,
				  PhysMemReadServer#(addrWidth, dataWidth) server)(Empty);
      Clock inClock = clockOf(client);
      Reset inReset = resetOf(client);
      Clock outClock = clockOf(server);
      Reset outReset = resetOf(server);
      mkConnectionWithClocks2(inClock, inReset, outClock, outReset, client, server);
   endmodule
endinstance

instance ConnectableWithClocks#(PhysMemWriteClient#(addrWidth, dataWidth),
				PhysMemWriteServer#(addrWidth, dataWidth));
   module mkConnectionWithClocks2#(Clock inClock, Reset inReset, Clock outClock, Reset outReset, 
				   PhysMemWriteClient#(addrWidth, dataWidth) client,
				   PhysMemWriteServer#(addrWidth, dataWidth) server)(Empty);
      let reqCnx <- mkConnectionWithClocks(client.writeReq, server.writeReq);
      let dataCnx <- mkConnectionWithClocks(client.writeData, server.writeData);
      let doneCnx <- mkConnectionWithClocks(server.writeDone, client.writeDone);
   endmodule
   module mkConnectionWithClocks#(PhysMemWriteClient#(addrWidth, dataWidth) client,
				  PhysMemWriteServer#(addrWidth, dataWidth) server)(Empty);
      Clock inClock = clockOf(client);
      Reset inReset = resetOf(client);
      Clock outClock = clockOf(server);
      Reset outReset = resetOf(server);
      mkConnectionWithClocks2(inClock, inReset, outClock, outReset, client, server);
   endmodule
endinstance

instance ConnectableWithClocks#(PhysMemMaster#(addrWidth, dataWidth), PhysMemSlave#(addrWidth, dataWidth));
   module mkConnectionWithClocks2#(Clock inClock, Reset inReset, Clock outClock, Reset outReset, 
				   PhysMemMaster#(addrWidth, dataWidth) client,
				   PhysMemSlave#(addrWidth, dataWidth) server)(Empty);
      let readCnx <- mkConnectionWithClocks(client.read_client, server.read_server);
      let writeCnx <- mkConnectionWithClocks(client.write_client, server.write_server);
   endmodule
   module mkConnectionWithClocks#(PhysMemMaster#(addrWidth, dataWidth) client,
				  PhysMemSlave#(addrWidth, dataWidth) server)(Empty);
      Clock inClock = clockOf(client);
      Reset inReset = resetOf(client);
      Clock outClock = clockOf(server);
      Reset outReset = resetOf(server);
      mkConnectionWithClocks2(inClock, inReset, outClock, outReset, client, server);
   endmodule
endinstance

module mkClockBinder#(a ifc) (a);
   return ifc;
endmodule
