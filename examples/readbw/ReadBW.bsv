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

import FIFO::*;
import GetPut::*;
import AxiClientServer::*;
import PcieToAxiBridge::*;
import PortalMemory::*;
import SGList::*;

interface CoreIndication;
    method Action loadValue(Bit#(128) value, Bit#(32) cycles);
endinterface

interface CoreRequest;
    method Action load(Bit#(64) addr, Bit#(32) length);
    method Action store(Bit#(64) addr, Bit#(64) value);

    method Action sglist(Bit#(32) off, Bit#(40) addr, Bit#(32) len);
    method Action paref(Bit#(32) addr, Bit#(32) len);
endinterface

interface ReadBWIndication;
    interface CoreIndication coreIndication;
endinterface

interface ReadBWRequest;
   interface CoreRequest coreRequest;
   interface Axi3Client#(40,128,16,12) m_axi;
   interface TlpTrace trace;
endinterface

instance PortalMemory#(CoreRequest);
endinstance
instance PortalMemory#(ReadBWRequest);
endinstance

module mkReadBWRequest#(ReadBWIndication ind)(ReadBWRequest);

    FIFO#(Bit#(40)) readAddrFifo <- mkFIFO;
    FIFO#(Bit#(4)) readLenFifo <- mkFIFO;
    FIFO#(Bit#(40)) writeAddrFifo <- mkFIFO;
    FIFO#(Bit#(128)) writeDataFifo <- mkFIFO;
    FIFO#(Tuple2#(Bit#(128),Bit#(32))) readDataFifo <- mkSizedFIFO(32);
    FIFO#(TimestampedTlpData) ttdFifo <- mkFIFO;

    Reg#(Bit#(4)) readBurstCount <- mkReg(0);
    Reg#(Bit#(32)) readStartTime <- mkReg(0);
    Reg#(Bit#(32)) timer <- mkReg(0);
    rule updateTimer;
        timer <= timer + 1;
    endrule

   rule receivedData;
      let v = readDataFifo.first;
      readDataFifo.deq;
      ind.coreIndication.loadValue(tpl_1(v), tpl_2(v));
   endrule

    interface CoreRequest coreRequest;
        method Action load(Bit#(64) addr, Bit#(32) len);
    	    readAddrFifo.enq(truncate(addr));
	    readLenFifo.enq(truncate(len));
	endmethod: load
        method Action store(Bit#(64) addr, Bit#(64) value);
	    writeAddrFifo.enq(truncate(addr));
	    writeDataFifo.enq({value,value});
	endmethod: store
    endinterface: coreRequest

    interface Axi3Client m_axi;
	interface Axi3WriteClient write;
	   method ActionValue#(Axi3WriteRequest#(40, 12)) address();
	       writeAddrFifo.deq;
	       return Axi3WriteRequest { address: writeAddrFifo.first, burstLen: 0, id: 0 };
	   endmethod
	   method ActionValue#(Axi3WriteData#(128, 16, 12)) data();
	       writeDataFifo.deq;
	       return Axi3WriteData { data: writeDataFifo.first, byteEnable: 16'hffff, last: 1, id: 0 };
	   endmethod
	   method Action response(Axi3WriteResponse#(12) r);
	   endmethod
	endinterface: write
	interface Axi3ReadClient read;
	   method ActionValue#(Axi3ReadRequest#(40, 12)) address() if (readBurstCount == 0);
	       TimestampedTlpData ttd = unpack(0);
	       ttd.unused = 1;
	       Bit#(153) trace = 0;
	       trace[127:64] = zeroExtend(readLenFifo.first + 1);
	       trace[31:0] = 0;
	       ttd.tlp = unpack(trace);
	       ttdFifo.enq(ttd);

	       readAddrFifo.deq;
	       readLenFifo.deq;
	       readStartTime <= timer;
	       readBurstCount <= readLenFifo.first + 1;
	       return Axi3ReadRequest { address: readAddrFifo.first, burstLen: readLenFifo.first, id: 0};
	   endmethod
	   method Action data(Axi3ReadResponse#(128, 12) response) if (readBurstCount > 0);
	      let latency = timer - readStartTime;

	      TimestampedTlpData ttd = unpack(0);
	      ttd.unused = 2;
	      Bit#(153) trace = 0;
	      trace[127:96] = response.data[127:96];
	      trace[95:64] = latency;
	      trace[31:0] = zeroExtend(readBurstCount);
	      ttd.tlp = unpack(trace);
	      ttdFifo.enq(ttd);

	       readBurstCount <= readBurstCount - 1;
	       if (readBurstCount == 1)
	           readDataFifo.enq(tuple2(response.data, latency));
	   endmethod
	endinterface: read
    endinterface: m_axi
   interface TlpTrace trace;
      interface Get tlp;
	  method ActionValue#(TimestampedTlpData) get();
	     ttdFifo.deq;
	     return ttdFifo.first();
	  endmethod
      endinterface: tlp
   endinterface: trace
endmodule: mkReadBWRequest
