
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
import ConnectalMemTypes :: *;
import FIFOF :: *;
import ConnectalBramFifo::*;
import Pipe :: *;
import Probe::*;
import SyncAxisFifo32x8::*;
import AxiStream :: *;
import Vector::*;
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
      SyncFIFOIfc#(a) synchronizer <- mkSyncFIFO(32, inClock, inReset, outClock);
      //FIFOF#(a) synchronizer <- mkDualClockBramFIFOF(inClock, inReset, outClock, outReset);
      let getProbe <- mkProbe(clocked_by inClock, reset_by inReset);
      let putProbe <- mkProbe(clocked_by outClock, reset_by outReset);
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
      let deqProbe <- mkProbe(clocked_by inClock, reset_by inReset);
      let enqProbe <- mkProbe(clocked_by outClock, reset_by outReset);
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
      let getProbe <- mkProbe(clocked_by inClock, reset_by inReset);
      let putProbe <- mkProbe(clocked_by outClock, reset_by outReset);
       rule mcwc_doGet;
           let v <- in.get();
	  getProbe <= v;
	   synchronizer.enq(v);
       endrule
       rule mcwc_doEnq;
	  let v = synchronizer.first;
	  synchronizer.deq;
	  putProbe <= v;
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
      let respCnx <- mkConnectionWithClocks(outClock, outReset, inClock, inReset, server.response, client.response);
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


typeclass ConnectableWithGearbox#(type a, type b);
   module mkConnectionWithGearbox#(Clock inClock, Reset inReset, Clock outClock, Reset outReset, a x1, b x2)(Empty);
endtypeclass


instance ConnectableWithGearbox#(PhysMemMaster#(addrWidth, masterdw), PhysMemSlave#(addrWidth, slavedw))
   provisos (
      Add#(a__, slavedw, masterdw), // master is wider than slave, i.e. master is at slower clock freq
      // Div#(slavedw, 32, slavedw),
      // Div#(masterdw, 32, masterdw),
      // Add#(TMul#(slavewords, 32), 0, slaveword), // 32-bit word aligned
      // Add#(TMul#(masterwords, 32), 0, masterword), // 32-bit word aligned
      // Div#(masterdw, slavedw, ratio),
      // Add#(0, TMul#(ratio, slavedw), masterdw), // ratio is integer      
      // Add#(0, TExp#(TLog#(ratio)), ratio), // ratio is power of two
      Bits#(Vector#(ratio, Bit#(slavedw)), masterdw),
      ConnectableWithClocks#(Get#(PhysMemRequest#(addrWidth, slavedw)), Put#(PhysMemRequest#(addrWidth,slavedw))),
      ConnectableWithClocks#(Get#(PhysMemRequest#(addrWidth, masterdw)), Put#(PhysMemRequest#(addrWidth,masterdw))),
      ConnectableWithClocks#(Get#(MemData#(masterdw)), Put#(MemData#(masterdw))),
      ConnectableWithClocks#(Get#(MemData#(slavedw)), Put#(MemData#(slavedw)))
      );
   
   module mkConnectionWithGearbox#(Clock inClock, Reset inReset, Clock outClock, Reset outReset,
                                   PhysMemMaster#(addrWidth, masterdw) client,
                                   PhysMemSlave#(addrWidth, slavedw) server)(Empty);
   

      // Gearbox#(1, ratio, Bit#(slavedw)) readGB <- mk1toNGearbox(outClock, outReset, inClock, inReset);
      // Gearbox#(ratio, 1, Bit#(slavedw)) writeGB <- mkNto1Gearbox(inClock, inReset, outClock, outReset);

      
      `ifndef BYTE_ENABLES
      let rdReqGet = (interface Get#(PhysMemRequest#(addrWidth,slavedw));
                         method ActionValue#(PhysMemRequest#(addrWidth,slavedw)) get;
                            let req <- client.read_client.readReq.get;
                            return PhysMemRequest{addr: req.addr, burstLen: req.burstLen, tag: req.tag};
                         endmethod
                      endinterface);
   
      let wrReqGet = (interface Get#(PhysMemRequest#(addrWidth,slavedw));
                         method ActionValue#(PhysMemRequest#(addrWidth,slavedw)) get;
                            let req <- client.write_client.writeReq.get;
                            return PhysMemRequest{addr: req.addr, burstLen: req.burstLen, tag: req.tag};
                         endmethod
                      endinterface);
   
      `endif
   
      Reg#(Bit#(TLog#(ratio))) rdBeats <- mkReg(0,  clocked_by inClock, reset_by inReset);
      FIFOF#(MemData#(slavedw)) rdDataQ <- mkFIFOF(clocked_by inClock, reset_by inReset);
      
      Reg#(Bit#(masterdw)) rdData <- mkRegU(clocked_by inClock, reset_by inReset);
   
      rule doRdData;
         rdBeats <= rdBeats + 1;
         
         let rdPayload <- toGet(rdDataQ).get;
         
         let newReadData = truncateLSB({rdPayload.data,rdData});
         
         rdData <= newReadData;
         
         if ( rdBeats == -1 ) 
            client.read_client.readData.put(MemData{data:newReadData, tag: rdPayload.tag, last:rdPayload.last});
      endrule
   
      Reg#(Bit#(TLog#(ratio))) wrBeats <- mkReg(0, clocked_by outClock, reset_by outReset);
      FIFOF#(MemData#(masterdw)) wrDataQ <- mkFIFOF(clocked_by outClock, reset_by outReset);
      
      //Reg#(MemData#(masterdw)) wrData <- mkRegU(clocked_by outClock, reset_by outReset);
   
   
      rule doWrData;
         wrBeats <= wrBeats + 1;
         
         let currMemData = wrDataQ.first;
         if ( wrBeats == -1 ) begin
            wrDataQ.deq;
         end
         
         Vector#(ratio, Bit#(slavedw)) payload = unpack(currMemData.data);
         
         server.write_server.writeData.put(MemData{data:payload[wrBeats], tag: currMemData.tag, last: currMemData.last && wrBeats == -1});
      endrule
   


      GetPutWithClocks::mkConnectionWithClocks(inClock, inReset, outClock, outReset,
                             client.write_client.writeData, toPut(wrDataQ));

      GetPutWithClocks::mkConnectionWithClocks(outClock, outReset, inClock, inReset,
                             server.read_server.readData, toPut(rdDataQ));


      GetPutWithClocks::mkConnectionWithClocks(inClock, inReset, outClock, outReset,
                             rdReqGet, server.read_server.readReq);
      GetPutWithClocks::mkConnectionWithClocks(inClock, inReset, outClock, outReset,
                             wrReqGet, server.write_server.writeReq);
      GetPutWithClocks::mkConnectionWithClocks(outClock, outReset, inClock, inReset, 
                             server.write_server.writeDone, client.write_client.writeDone);
   
   
      // rule doReadDataEnq;
      //    let v <- server.read_server.readData.get;
      //    readGB.enq(unpack(v));
      // endrule
   
      // rule doReadDataDeq;
      //    let v = readGB.first;
      //    readGB.deq;
      //    client.read_client.readData.put(pack(v));
      // endrule

      // rule doWriteDataEnq;
      //    let v <- client.write_client.writeData.get;
      //    writeGB.enq(unpack(v));
      // endrule
   
      // rule doWriteDataDeq;
      //    let v = writeGB.first;
      //    writeGB.deq;
      //    server.write_server.writeData.put(pack(v));
      // endrule
   endmodule
   
endinstance
