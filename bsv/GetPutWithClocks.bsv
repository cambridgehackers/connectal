
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
import Connectable :: *;
import ClientServer :: *;
import Clocks :: *;
import MemTypes :: *;
import FIFOF :: *;
import ConnectalBramFifo::*;
import Pipe :: *;
import Probe::*;
import SyncAxisFifo32x8::*;
import AxiStream :: *;
`include "ConnectalProjectConfig.bsv"

////////////////////////////////////////////////////////////////////////////////
/// Typeclass Definition
////////////////////////////////////////////////////////////////////////////////
typeclass ConnectableWithClocks#(type a, type b);
   module mkConnectionWithClocks2#(a x1, b x2)(Empty);
   module mkConnectionWithClocks#(Clock inClock, Reset inReset, Clock outClock, Reset outReset, a x1, b x2)(Empty);
endtypeclass

instance ConnectableWithClocks#(Get#(a), Put#(a)) provisos (
							    Bits#(a, awidth),
							    Add#(1, a__, awidth),
    Add#(b__, awidth, TMul#(TDiv#(awidth, 32), 32)),
    Add#(c__, TDiv#(awidth, 8), TDiv#(TMul#(TDiv#(awidth, 32), 32), 8)),
    Mul#(TDiv#(awidth, 32), 4, TDiv#(TMul#(TDiv#(awidth, 32), 32), 8))
   );
   module mkConnectionWithClocks#(Clock inClock, Reset inReset, Clock outClock, Reset outReset, Get#(a) in, Put#(a) out)(Empty) provisos (Bits#(a, awidth), Add#(1, a__, awidth));
`ifndef GET_PUT_WITH_CLOCKS_USE_XILINX_FIFO
      SyncFIFOIfc#(a) synchronizer <- mkSyncFIFO(8, inClock, inReset, outClock);
      //FIFOF#(a) synchronizer <- mkDualClockBramFIFOF(inClock, inReset, outClock, outReset);
      let getProbe <= mkProbe();
      let putProbe <= mkProbe();
       rule mcwc_doGet;
           let v <- in.get();
	   getProbe <= v;
	   synchronizer.enq(v);
       endrule
       rule mcwc_doPut;
	  let v = synchronizer.first;
	  putProbe <= v;
	  synchronizer.deq;
	  out.put(v);
       endrule
`else
      SyncAxisFifo8#(awidth) fifo <- mkSyncAxisFifo8(inClock, inReset, outClock, outReset);
      mkConnection(in, fifo.s_axis, clocked_by inClock, reset_by inReset);
      mkConnection(fifo.m_axis, out, clocked_by outClock, reset_by outReset);
`endif
   endmodule

   module mkConnectionWithClocks2#(Get#(a) in, Put#(a) out)(Empty) provisos (Bits#(a, awidth), Add#(1, a__, awidth));
      Clock inClock = clockOf(in);
      Reset inReset = resetOf(in);
      Clock outClock = clockOf(out);
      Reset outReset = resetOf(out);

      mkConnectionWithClocks(inClock, inReset, outClock, outReset, in, out);
   endmodule: mkConnectionWithClocks2
endinstance: ConnectableWithClocks

instance ConnectableWithClocks#(PipeOut#(a), Put#(a)) provisos (
							    Bits#(a, awidth),
							    Add#(1, a__, awidth),
    Add#(b__, awidth, TMul#(TDiv#(awidth, 32), 32)),
    Add#(c__, TDiv#(awidth, 8), TDiv#(TMul#(TDiv#(awidth, 32), 32), 8)),
    Mul#(TDiv#(awidth, 32), 4, TDiv#(TMul#(TDiv#(awidth, 32), 32), 8))
   );
   module mkConnectionWithClocks#(Clock inClock, Reset inReset, Clock outClock, Reset outReset, PipeOut#(a) in, Put#(a) out)(Empty) provisos (Bits#(a, awidth), Add#(1, a__, awidth));
`ifndef GET_PUT_WITH_CLOCKS_USE_XILINX_FIFO
      SyncFIFOIfc#(a) synchronizer <- mkSyncFIFO(8, inClock, inReset, outClock);
      //FIFOF#(a) synchronizer <- mkDualClockBramFIFOF(inClock, inReset, outClock, outReset);
      let deqProbe <- mkProbe();
      let enqProbe <- mkProbe();
       rule mcwc_doGet;
          let v = in.first;
	  in.deq();
	  deqProbe <= v;
	   synchronizer.enq(v);
       endrule
       rule mcwc_doPut;
	  let v = synchronizer.first;
	  enqProbe <= v;
	  synchronizer.deq;
	  out.put(v);
       endrule
`else
      SyncAxisFifo8#(awidth) fifo <- mkSyncAxisFifo8(inClock, inReset, outClock, outReset);
      mkConnection(in, fifo.s_axis, clocked_by inClock, reset_by inReset);
      mkConnection(fifo.m_axis, out, clocked_by outClock, reset_by outReset);
`endif
   endmodule

   module mkConnectionWithClocks2#(PipeOut#(a) in, Put#(a) out)(Empty) provisos (Bits#(a, awidth), Add#(1, a__, awidth));
      Clock inClock = clockOf(in);
      Reset inReset = resetOf(in);
      Clock outClock = clockOf(out);
      Reset outReset = resetOf(out);

      mkConnectionWithClocks(inClock, inReset, outClock, outReset, in, out);
   endmodule: mkConnectionWithClocks2
endinstance: ConnectableWithClocks

instance ConnectableWithClocks#(Get#(a), PipeIn#(a)) provisos (
							    Bits#(a, awidth),
							    Add#(1, a__, awidth),
    Add#(b__, awidth, TMul#(TDiv#(awidth, 32), 32)),
    Add#(c__, TDiv#(awidth, 8), TDiv#(TMul#(TDiv#(awidth, 32), 32), 8)),
    Mul#(TDiv#(awidth, 32), 4, TDiv#(TMul#(TDiv#(awidth, 32), 32), 8))
   );
   module mkConnectionWithClocks#(Clock inClock, Reset inReset, Clock outClock, Reset outReset, Get#(a) in, PipeIn#(a) out)(Empty) provisos (Bits#(a, awidth), Add#(1, a__, awidth));
`ifndef GET_PUT_WITH_CLOCKS_USE_XILINX_FIFO
      SyncFIFOIfc#(a) synchronizer <- mkSyncFIFO(8, inClock, inReset, outClock);
      //FIFOF#(a) synchronizer <- mkDualClockBramFIFOF(inClock, inReset, outClock, outReset);
      let getProbe <- mkProbe();
      let putProbe <- mkProbe();
       rule mcwc_doGet;
           let v <- in.get();
	  getProbe <= v;
	   synchronizer.enq(v);
       endrule
       rule mcwc_doEnq;
	  let v = synchronizer.first;
	  synchronizer.deq;
	  putProbe <- v;
	  out.enq(v);
       endrule
`else
      SyncAxisFifo8#(awidth) fifo <- mkSyncAxisFifo8(inClock, inReset, outClock, outReset);
      mkConnection(in, fifo.s_axis, clocked_by inClock, reset_by inReset);
      mkConnection(fifo.m_axis, out, clocked_by outClock, reset_by outReset);
`endif
   endmodule

   module mkConnectionWithClocks2#(Get#(a) in, PipeIn#(a) out)(Empty) provisos (Bits#(a, awidth), Add#(1, a__, awidth));
      Clock inClock = clockOf(in);
      Reset inReset = resetOf(in);
      Clock outClock = clockOf(out);
      Reset outReset = resetOf(out);

      mkConnectionWithClocks(inClock, inReset, outClock, outReset, in, out);
   endmodule: mkConnectionWithClocks2
endinstance: ConnectableWithClocks

instance ConnectableWithClocks#(Client#(a,b), Server#(a,b))
   provisos (Bits#(a, awidth),
      Bits#(b, bwidth),
      Add#(1, a__, awidth),
      Add#(1, b__, bwidth),

      Add#(c__, TDiv#(awidth, 8), TDiv#(TMul#(TDiv#(awidth, 32), 32), 8)),
      Add#(d__, TDiv#(bwidth, 8), TDiv#(TMul#(TDiv#(bwidth, 32), 32), 8)),
      Add#(e__, awidth, TMul#(TDiv#(awidth, 32), 32)),
      Add#(f__, bwidth, TMul#(TDiv#(bwidth, 32), 32)),
      Mul#(TDiv#(awidth, 32), 4, TDiv#(TMul#(TDiv#(awidth, 32), 32), 8)),
      Mul#(TDiv#(bwidth, 32), 4, TDiv#(TMul#(TDiv#(bwidth, 32), 32), 8))
      );
   module mkConnectionWithClocks#(Clock inClock, Reset inReset, Clock outClock, Reset outReset, Client#(a,b) client, Server#(a,b) server)(Empty)
      provisos (ConnectableWithClocks#(Get#(a), Put#(a)),
		ConnectableWithClocks#(Get#(b), Put#(b)),
		Bits#(a, awidth),
		Bits#(b, bwidth));
      let reqCnx <- mkConnectionWithClocks(inClock, inReset, outClock, outReset, client.request, server.request);
      let respCnx <- mkConnectionWithClocks(inClock, inReset, outClock, outReset, server.response, client.response);
   endmodule
   module mkConnectionWithClocks2#(Client#(a,b) client, Server#(a,b) server)(Empty)
      provisos (ConnectableWithClocks#(Get#(a), Put#(a)),
		ConnectableWithClocks#(Get#(b), Put#(b)),
		Bits#(a, awidth),
		Bits#(b, bwidth));
      Clock inClock = clockOf(client);
      Reset inReset = resetOf(client);
      Clock outClock = clockOf(server);
      Reset outReset = resetOf(server);

      mkConnectionWithClocks(inClock, inReset, outClock, outReset, client, server);
   endmodule
endinstance

instance ConnectableWithClocks#(PhysMemReadClient#(addrWidth, dataWidth),
				PhysMemReadServer#(addrWidth, dataWidth))
   provisos (
      ConnectableWithClocks#(Get#(PhysMemRequest#(addrWidth,dataWidth)),Put#(PhysMemRequest#(addrWidth,dataWidth))),
      ConnectableWithClocks#(Get#(MemData#(dataWidth)),Put#(MemData#(dataWidth)))
      );
   module mkConnectionWithClocks#(Clock inClock, Reset inReset, Clock outClock, Reset outReset,
				   PhysMemReadClient#(addrWidth, dataWidth) client,
				   PhysMemReadServer#(addrWidth, dataWidth) server)(Empty);
      let reqCnx <- mkConnectionWithClocks(inClock, inReset, outClock, outReset, client.readReq, server.readReq);
      let dataCnx <- mkConnectionWithClocks(outClock, outReset, inClock, inReset, server.readData, client.readData);
   endmodule
   module mkConnectionWithClocks2#(PhysMemReadClient#(addrWidth, dataWidth) client,
				  PhysMemReadServer#(addrWidth, dataWidth) server)(Empty);
      Clock inClock = clockOf(client);
      Reset inReset = resetOf(client);
      Clock outClock = clockOf(server);
      Reset outReset = resetOf(server);
      mkConnectionWithClocks(inClock, inReset, outClock, outReset, client, server);
   endmodule
endinstance

instance ConnectableWithClocks#(PhysMemWriteClient#(addrWidth, dataWidth),
				PhysMemWriteServer#(addrWidth, dataWidth))
   provisos (
    ConnectableWithClocks#(Get#(PhysMemRequest#(addrWidth, dataWidth)), Put#(PhysMemRequest#(addrWidth, dataWidth))),
    ConnectableWithClocks#(Get#(MemData#(dataWidth)),Put#(MemData#(dataWidth)))
      );

   module mkConnectionWithClocks#(Clock inClock, Reset inReset, Clock outClock, Reset outReset, 
				   PhysMemWriteClient#(addrWidth, dataWidth) client,
				   PhysMemWriteServer#(addrWidth, dataWidth) server)(Empty);
      let reqCnx <- mkConnectionWithClocks(inClock, inReset, outClock, outReset, client.writeReq, server.writeReq);
      let dataCnx <- mkConnectionWithClocks(inClock, inReset, outClock, outReset, client.writeData, server.writeData);
      let doneCnx <- mkConnectionWithClocks(outClock, outReset, inClock, inReset, server.writeDone, client.writeDone);
   endmodule
   module mkConnectionWithClocks2#(PhysMemWriteClient#(addrWidth, dataWidth) client,
				  PhysMemWriteServer#(addrWidth, dataWidth) server)(Empty);
      Clock inClock = clockOf(client);
      Reset inReset = resetOf(client);
      Clock outClock = clockOf(server);
      Reset outReset = resetOf(server);
      mkConnectionWithClocks(inClock, inReset, outClock, outReset, client, server);
   endmodule
endinstance

instance ConnectableWithClocks#(PhysMemMaster#(addrWidth, dataWidth), PhysMemSlave#(addrWidth, dataWidth))
   provisos (
    ConnectableWithClocks#(PhysMemWriteClient#(addrWidth,dataWidth),PhysMemWriteServer#(addrWidth,dataWidth))
      );
   module mkConnectionWithClocks#(Clock inClock, Reset inReset, Clock outClock, Reset outReset, 
				   PhysMemMaster#(addrWidth, dataWidth) client,
				   PhysMemSlave#(addrWidth, dataWidth) server)(Empty);
      let readCnx <- mkConnectionWithClocks(inClock, inReset, outClock, outReset, client.read_client, server.read_server);
      let writeCnx <- mkConnectionWithClocks(inClock, inReset, outClock, outReset, client.write_client, server.write_server);
   endmodule
   module mkConnectionWithClocks2#(PhysMemMaster#(addrWidth, dataWidth) client,
				  PhysMemSlave#(addrWidth, dataWidth) server)(Empty);
      Clock inClock = clockOf(client);
      Reset inReset = resetOf(client);
      Clock outClock = clockOf(server);
      Reset outReset = resetOf(server);
      mkConnectionWithClocks(inClock, inReset, outClock, outReset, client, server);
   endmodule
endinstance

module mkClockBinder#(a ifc) (a);
   return ifc;
endmodule
