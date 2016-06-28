// Copyright (c) 2016 Connectal Project

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
import GetPut::*;
import FIFOF::*;

import ConnectalConfig::*;
import MemTypes::*;

//
// provides softare ability to read/write a PhysMemSlave or MemServer
//
interface MemServerPortalRequest;
   method Action read32(Bit#(32) addr);
   method Action write32(Bit#(32) addr, Bit#(32) data);
   method Action read64(Bit#(32) addr);
   method Action write64(Bit#(32) addr, Bit#(64) data);
endinterface

interface MemServerPortalIndication;
   method Action read32Done(Bit#(32) data);
   method Action read64Done(Bit#(64) data);
   method Action writeDone();
endinterface

interface MemServerPortal;
   interface MemServerPortalRequest request;
endinterface

module mkPhysMemSlavePortal#(PhysMemSlave#(addrWidth,dataBusWidth) ms, MemServerPortalIndication ind)(MemServerPortal)
   provisos (Add#(dataBusWidth,7,a__)
	     ,Add#(b__,addrWidth,32)
	     ,Add#(c__, dataBusWidth, 128)
	     ,Bits#(MemTypes::MemData#(dataBusWidth), a__));

   FIFOF#(PhysMemRequest#(addrWidth,dataBusWidth)) araddrFifo <- mkFIFOF();
   FIFOF#(PhysMemRequest#(addrWidth,dataBusWidth)) awaddrFifo <- mkFIFOF();
   FIFOF#(MemData#(dataBusWidth))           rdataFifo <- mkFIFOF();
   FIFOF#(MemData#(dataBusWidth))           wdataFifo <- mkFIFOF();
   FIFOF#(Bit#(6))                doneFifo <- mkFIFOF();
   FIFOF#(Bit#(8))                        readLenFifo <- mkFIFOF();

   let araddrCnx <- mkConnection(toGet(araddrFifo), ms.read_server.readReq);
   let awaddrCnx <- mkConnection(toGet(awaddrFifo), ms.write_server.writeReq);
   let rdataCnx  <- mkConnection(ms.read_server.readData, toPut(rdataFifo));
   let wdataCnx  <- mkConnection(toGet(wdataFifo), ms.write_server.writeData);
   let doneCnx   <- mkConnection(ms.write_server.writeDone, toPut(doneFifo));

   rule rl_rdata32 if (readLenFifo.first == 32);
      let rdata <- toGet(rdataFifo).get();
      readLenFifo.deq();
      Bit#(128) data = extend(rdata.data);
      ind.read32Done(truncate(data));
   endrule
   rule rl_rdata64 if (readLenFifo.first == 32);
      let rdata <- toGet(rdataFifo).get();
      readLenFifo.deq();
      Bit#(128) data = extend(rdata.data);
      ind.read64Done(truncate(data));
   endrule

   rule rl_writeDone;
      let tag <- toGet(doneFifo).get();
      ind.writeDone();
   endrule

   interface MemServerPortalRequest request;
      method Action read32(Bit#(32) addr);
	 araddrFifo.enq(PhysMemRequest { addr: truncate(addr), burstLen: fromInteger(valueOf(TDiv#(32,8))), tag: 0 });
	 readLenFifo.enq(32);
      endmethod
      method Action write32(Bit#(32) addr, Bit#(32) value);
	 awaddrFifo.enq(PhysMemRequest { addr: truncate(addr), burstLen: fromInteger(valueOf(TDiv#(32,8))), tag: 0 });
	 Bit#(128) data = extend(value);
	 wdataFifo.enq(MemData {data: truncate(data), tag: 0, last: True});
      endmethod

      method Action read64(Bit#(32) addr);
	 araddrFifo.enq(PhysMemRequest { addr: truncate(addr), burstLen: fromInteger(valueOf(TDiv#(64,8))), tag: 0 });
	 readLenFifo.enq(64);
      endmethod
      method Action write64(Bit#(32) addr, Bit#(64) value);
	 awaddrFifo.enq(PhysMemRequest { addr: truncate(addr), burstLen: fromInteger(valueOf(TDiv#(64,8))), tag: 0 });
	 Bit#(128) data = extend(value);
	 wdataFifo.enq(MemData {data: truncate(data), tag: 0, last: True});
      endmethod
   endinterface
endmodule
