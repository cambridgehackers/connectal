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
import PcieToAxiBridge::*;
import ConnectalMemory::*;
import ConnectalMMU::*;

interface CoreIndication;
    method Action loadValue(Bit#(128) value, Bit#(32) cycles);
    method Action storeAddress(Bit#(64) addr);
    method Action loadMultipleLatency(Bit#(32) busWidth, Bit#(32) length, Bit#(32) count, Bit#(32) startTime, Bit#(32) endTime);
endinterface

interface CoreRequest;
    method Action loadMultiple(Bit#(64) addr, Bit#(32) length, Bit#(32) repetitions);
    method Action load(Bit#(64) addr, Bit#(32) length);
    method Action store(Bit#(64) addr, Bit#(128) value);

    //method Action sglist(Bit#(32) off, Bit#(40) addr, Bit#(32) len);
    method Action paref(Bit#(32) addr, Bit#(32) len);
endinterface

interface ReadBWIndication;
    interface CoreIndication coreIndication;
endinterface

interface ReadBWRequest;
   interface CoreRequest coreRequest;
   interface Axi4Master#(40,128,12) m_axi;
   interface TlpTrace trace;
endinterface

instance ConnectalMemory#(CoreRequest);
endinstance
instance ConnectalMemory#(ReadBWRequest);
endinstance

module mkReadBWRequest#(ReadBWIndication ind)(ReadBWRequest);

    FIFO#(Bit#(40)) readAddrFifo <- mkFIFO;
    FIFO#(Bit#(8)) readLenFifo <- mkFIFO;
    FIFO#(Bit#(40)) writeAddrFifo <- mkFIFO;
    FIFO#(Bit#(128)) writeDataFifo <- mkFIFO;
    FIFO#(TimestampedTlpData) ttdFifo <- mkFIFO;

    Reg#(Bit#(9)) readBurstCount <- mkReg(0);
   FIFO#(Tuple2#(Bit#(9),Bit#(32))) readBurstCountStartTimeFifo <- mkSizedFIFO(4);

   Reg#(Bit#(40)) readMultipleAddr <- mkReg(0);
   Reg#(Bit#(8)) readMultipleLen <- mkReg(0);
   Reg#(Bit#(8)) readMultipleCount <- mkReg(0);

    Reg#(Bit#(32)) timer <- mkReg(0);
    rule updateTimer;
        timer <= timer + 1;
    endrule

   Reg#(Bit#(16)) addrCount <- mkReg(0);
   rule readMultipleAddrGenerator if (addrCount > 0);
      readAddrFifo.enq(readMultipleAddr);
      readLenFifo.enq(readMultipleLen);

      addrCount <= addrCount - 1;
   endrule

   Reg#(Bit#(32)) loadMultipleStartTime <- mkReg(0);
   Reg#(Bit#(16)) completedCount <- mkReg(0);

   FIFO#(Tuple2#(Bit#(128),Bit#(32))) readDataFifo <- mkSizedFIFO(32);
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
        method Action loadMultiple(Bit#(64) addr, Bit#(32) len, Bit#(32) count) if (completedCount == 0);
	   loadMultipleStartTime <= timer;
    	   readMultipleAddr <= truncate(addr);
	   readMultipleLen <= truncate(len);
	   readMultipleCount <= truncate(count);
	   addrCount <= truncate(count);
	   completedCount <= truncate(count);
	endmethod: loadMultiple
        method Action store(Bit#(64) addr, Bit#(128) value);
	    writeAddrFifo.enq(truncate(addr));
	    writeDataFifo.enq(value);
	endmethod: store
    endinterface: coreRequest

    interface Axi4Master m_axi;
	interface Axi4WriteClient write;
	   method ActionValue#(Axi4WriteRequest#(40, 12)) address();
	       writeAddrFifo.deq;
	      ind.coreIndication.storeAddress(zeroExtend(writeAddrFifo.first));
	       return Axi4WriteRequest { address: writeAddrFifo.first, burstLen: 0, id: 0 };
	   endmethod
	   method ActionValue#(Axi4WriteData#(128, 16, 12)) data();
	       writeDataFifo.deq;
	       return Axi4WriteData { data: writeDataFifo.first, byteEnable: 16'hffff, last: 1, id: 0 };
	   endmethod
	   method Action response(Axi4WriteResponse#(12) r);
	   endmethod
	endinterface: write
	interface Axi4ReadClient read;
	   method ActionValue#(Axi4ReadRequest#(40, 12)) address();
	       Bit#(9) numWords = zeroExtend(readLenFifo.first) + 1;
	       TimestampedTlpData ttd = unpack(0);
	       ttd.unused = 1;
	       Bit#(153) trace = 0;
	       trace[127:64] = zeroExtend(numWords);
	       trace[31:0] = readAddrFifo.first[31:0];
	       ttd.tlp = unpack(trace);
	       ttdFifo.enq(ttd);

	       readAddrFifo.deq;
	       readLenFifo.deq;
	       readBurstCountStartTimeFifo.enq(tuple2(numWords, timer));
	       return Axi4ReadRequest { address: readAddrFifo.first, burstLen: readLenFifo.first, id: 0};
	   endmethod
	   method Action data(Axi4ReadResponse#(128, 12) response);

	      let rbc = readBurstCount;
	      if (rbc == 0) begin
		 rbc = tpl_1(readBurstCountStartTimeFifo.first);
	      end

	      let readStartTime = tpl_2(readBurstCountStartTimeFifo.first);
	      let latency = timer - readStartTime;

	      TimestampedTlpData ttd = unpack(0);
	      ttd.unused = 2;
	      Bit#(153) trace = 0;
	      trace[127:96] = response.data[127:96];
	      trace[95:64] = latency;
	      trace[31:0] = zeroExtend(rbc);
	      ttd.tlp = unpack(trace);

	      if (rbc == 1) begin
		 ttdFifo.enq(ttd);

	         readDataFifo.enq(tuple2(response.data, latency));
		 // this request is done, dequeue its information
		 readBurstCountStartTimeFifo.deq;

		 if (completedCount == 1)
		    ind.coreIndication.loadMultipleLatency(128, zeroExtend(readMultipleLen), zeroExtend(readMultipleCount), loadMultipleStartTime, timer);

		 if (completedCount > 0)
		    completedCount <= completedCount - 1;

	      end

	      readBurstCount <= rbc - 1;

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
