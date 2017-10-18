// Copyright (c) 2013 Nokia, Inc.
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
import Connectable::*;
import FIFO::*;
import GetPut::*;
import Vector::*;
import TestProgram::*;
import AvalonBfmWrapper::*;
import AvalonMasterSlave::*;
import AvalonBits::*;
import AvalonDma::*;
import AvalonGather::*;
import ConnectalMemTypes::*;
import MemServerIndication::*;
import MMUIndication::*;

interface EchoIndication;
   method Action heard(Bit#(32) v);
   method Action heard2(Bit#(16) a, Bit#(16) b);
endinterface

interface EchoRequest;
   method Action writeData(Bit#(16) addr, Bit#(64) data);
   method Action readData(Bit#(16) addr, Bit#(64) data);
endinterface

interface Echo;
   interface EchoRequest request;
endinterface

typedef 12 AddressWidth;
typedef 32 DataWidth;
typedef TDiv#(DataWidth, 32) WordsPerBeat;

module mkEcho#(EchoIndication indication)(Echo);
   FIFO#(Bit#(32)) delay <- mkSizedFIFO(8);

   // read client interface
   FIFO#(PhysMemRequest#(AddressWidth, DataWidth)) readReqFifo <- mkSizedFIFO(4);
   FIFO#(MemData#(DataWidth)) readDataFifo <- mkSizedFIFO(32);
   PhysMemReadClient#(AddressWidth, DataWidth) readClient = (interface PhysMemReadClient;
      interface Get readReq = toGet(readReqFifo);
      interface Put readData = toPut(readDataFifo);
   endinterface);

   // write client interface
   FIFO#(PhysMemRequest#(AddressWidth, DataWidth)) writeReqFifo <- mkSizedFIFO(4);
   FIFO#(MemData#(DataWidth)) writeDataFifo <- mkSizedFIFO(32);
   FIFO#(Bit#(MemTagSize)) writeDoneFifo <- mkSizedFIFO(4);
   PhysMemWriteClient#(AddressWidth, DataWidth) writeClient = (interface PhysMemWriteClient;
      interface Get writeReq = toGet(writeReqFifo);
      interface Get writeData = toGet(writeDataFifo);
      interface Put writeDone = toPut(writeDoneFifo);
   endinterface);

   // PhysMemMaster interface
   PhysMemMaster#(AddressWidth, DataWidth) memMaster = (interface PhysMemMaster;
      interface read_client = readClient;
      interface write_client = writeClient;
   endinterface);

   Empty test_program <- mkTestProgram();
   AvalonBfmWrapper#(AddressWidth, DataWidth) dut <- mkAvalonBfmWrapper();
   AvalonMSlave#(AddressWidth, DataWidth) slaveGather <- mkAvalonMSlaveGather(dut.slave_0);
   AvalonMMaster#(AddressWidth, DataWidth) master <- mkAvalonDmaMaster(memMaster);
   mkConnection(master, slaveGather);

   interface EchoRequest request;
      method Action writeData(Bit#(16) addr, Bit#(64) data);
         writeReqFifo.enq(PhysMemRequest{ addr: truncate(addr),
                                          burstLen: 4,
                                          tag: 0});
         function Bit#(8) plusi(Integer i); return fromInteger(i); endfunction
         Vector#(TMul#(4, WordsPerBeat), Bit#(8)) v = genWith(plusi);
         writeDataFifo.enq(MemData {data: pack(v), tag: 0, last: True});
      endmethod
      method Action readData(Bit#(16) addr, Bit#(64) data);
         readReqFifo.enq(PhysMemRequest{addr: truncate(addr),
                                        burstLen: 16,
                                        tag: 0});
      endmethod
   endinterface
endmodule
