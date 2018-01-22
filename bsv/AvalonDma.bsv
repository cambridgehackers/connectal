// Copyright (c) 2015 Connectal Project.

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
`include "ConnectalProjectConfig.bsv"
import ConnectalConfig::*;
import FIFO::*;
import GetPut::*;
import Vector::*;
import ClientServer::*;
import ConnectalMemTypes::*;
import ConnectalMemory::*;
import AvalonMasterSlave::*;
import AvalonBits::*;
import AddressGenerator::*;
import AvalonSplitter::*;
import Connectable::*;

module mkAvalonDmaMaster#(PhysMemMaster#(addrWidth,dataWidth) master)(AvalonMMaster#(addrWidth,dataWidth));

   let verbose = True;
   Wire#(Bool) avalonWait <- mkDWire(False);
   Wire#(Bool) avalonRead <- mkDWire(False);
   Wire#(Bool) avalonWrite <- mkDWire(False);
   Wire#(Bit#(4)) burstcount <- mkDWire(0);
   Wire#(Bit#(4)) byteEnable <- mkDWire(0);
   Wire#(Bit#(dataWidth)) avalonReadData <- mkDWire(0);
   Wire#(Bool) avalonReadDataValid <- mkDWire(False);
   Wire#(Bit#(addrWidth)) avalonAddress <- mkDWire(0);
   Wire#(Bit#(dataWidth)) avalonWriteData <- mkDWire(0);

   Reg#(Bit#(addrWidth)) writeAddress <- mkReg(0);
   Reg#(Bit#(4)) writeBurstLen <- mkReg(0);
   Reg#(Bit#(4)) writeBurstCount <- mkReg(0);

   AddressGenerator#(addrWidth, dataWidth) readAddrGenerator <- mkAddressGenerator();

   Reg#(Bit#(32)) cycles <- mkReg(0);
   rule count;
      cycles <= cycles + 1;
   endrule

   AvalonArbiter#(addrWidth, dataWidth) arbiter <- mkAvalonArbiter();
   Vector#(2, FIFO#(AvalonMMRequest#(addrWidth, dataWidth))) req_fifo <- replicateM(mkFIFO);
   mapM(uncurry(mkConnection), zip(map(toGet, req_fifo), arbiter.in));

   FIFO#(AvalonMMData#(dataWidth)) resp_fifo <- mkFIFO;

   rule deq_dispatcher;
      let req <- toGet(resp_fifo).get;
      $display("%d: dispatcher to avalon %h", cycles, req.readdata);
   endrule

   rule read_req;
      let req <- master.read_client.readReq.get;
      AvalonMMRequest#(addrWidth, dataWidth) readReq;
      readReq.address = req.addr;
      readReq.data = ?;
      readReq.write = False;
      readReq.burstcount = truncate(req.burstLen >> 2);
      readReq.sof = True;
      readReq.eof = True;
      req_fifo[0].enq(readReq);
      if (verbose) $display("%d read_address %h bc %d", cycles, req.addr, req.burstLen);
   endrule

   rule read_data if (avalonReadDataValid);
      master.read_client.readData.put(MemData{data: avalonReadData, tag: 0, last: True});
   endrule

   rule write_req;
      let req <- master.write_client.writeReq.get();
      writeAddress <= req.addr;
      writeBurstLen <= truncate(req.burstLen);
      writeBurstCount <= truncate(req.burstLen >> 2);
      if (verbose) $display("%d write_addr %h bc %d", cycles, req.addr, req.burstLen);
   endrule

   rule write_data;
      let data <- master.write_client.writeData.get();
      AvalonMMRequest#(addrWidth, dataWidth) writeReq;
      writeReq.address = writeAddress;
      writeReq.data = data.data;
      writeReq.write = True;
      writeReq.burstcount = writeBurstLen;
      writeReq.sof = (writeBurstLen == writeBurstCount) ? True : False;
      writeReq.eof = (writeBurstCount == 0) ? True : False;
      writeBurstCount <= writeBurstCount - 1;
      req_fifo[1].enq(writeReq);
      if (verbose) $display("%d write_data %h write_address %h bc %d", cycles, data.data, writeAddress, writeBurstCount);
   endrule

   interface Get request = arbiter.toAvalon;
   interface Put response = toPut(resp_fifo);
endmodule

