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


import BRAM::*;
import FIFO::*;
import Vector::*;
import Gearbox::*;
import FIFOF::*;


import BRAMFIFOFLevel::*;
import GetPutF::*;
import DMA::*;

interface DMAReadServer2BRAM#(type a);
   method Action start(DmaMemHandle h, a x);
   method ActionValue#(Bool) finished();
endinterface

module mkDMAReadServer2BRAM#(DMAReadServer#(busWidth) rs, BRAMServer#(a,d) br)(DMAReadServer2BRAM#(a))
   provisos(Bits#(d,dsz),
	    Div#(busWidth,dsz,nd),
	    Mul#(nd,dsz,busWidth),
	    Eq#(a),
	    Ord#(a),
	    Arith#(a),
	    Bits#(a,b__),
	    Add#(d__,b__,DmaAddrSize),
	    Add#(1, c__, nd),
	    Add#(a__, dsz, busWidth));
   
   Clock clk <- exposeCurrentClock;
   Reset rst <- exposeCurrentReset;
   
   FIFO#(void) f <- mkSizedFIFO(1);
   Gearbox#(nd,1,d) gb <- mkNto1Gearbox(clk,rst,clk,rst); 
   Reg#(a) i <- mkReg(0);
   Reg#(Bool) iv <- mkReg(False);
   Reg#(a) j <- mkReg(0);
   Reg#(Bool) jv <- mkReg(False);
   Reg#(a) n <- mkReg(0);
   Reg#(DmaMemHandle) readHandle <- mkReg(0);

   rule loadReq(iv);
      rs.readReq.put(DMAAddressRequest {handle: readHandle, address: zeroExtend(pack(i)), burstLen: 1, tag: 0});
      i <= i+fromInteger(valueOf(nd));
      iv <= (i < n);
   endrule
   
   rule loadResp;
      let rv <- rs.readData.get();
      Vector#(nd,d) rvv = unpack(rv.data);
      gb.enq(rvv);
   endrule
   
   rule load(jv);
      br.request.put(BRAMRequest{write:True, responseOnWrite:False, address:j, datain:gb.first[0]});
      gb.deq;
      jv <= (j < n);
      j <= j+1;
      if (j == n)
	 f.enq(?);
   endrule
   
   rule discard(!jv);
      gb.deq;
   endrule
   
   method Action start(DmaMemHandle h, a x);
      iv <= True;
      jv <= True;
      i <= 0;
      j <= 0;
      n <= x;
      readHandle <= h;
   endmethod
   
   method ActionValue#(Bool) finished();
      f.deq;
      return True;
   endmethod
   
endmodule


//
// @brief A buffer for reading from a bus of width bsz.
//
// @param bsz The number of bits in the bus.
// @param maxBurst The number of words to buffer
//
interface DMAReadBuffer#(numeric type bsz, numeric type maxBurst);
   interface DMAReadServer #(bsz) dmaServer;
   interface DMAReadClient#(bsz) dmaClient;
endinterface

//
// @brief A buffer for writing to a bus of width bsz.
//
// @param bsz The number of bits in the bus.
// @param maxBurst The number of words to buffer
//
interface DMAWriteBuffer#(numeric type bsz, numeric type maxBurst);
   interface DMAWriteServer#(bsz) dmaServer;
   interface DMAWriteClient#(bsz) dmaClient;
endinterface

//
// @brief Makes a DMA buffer for reading wordSize words from memory.
//
// @param dsz The width of the bus in bits.
// @param maxBurst The max number of words to transfer per request.
//
module mkDMAReadBuffer(DMAReadBuffer#(dsz, maxBurst))
   provisos(Add#(1,a__,dsz),
	    Add#(b__, TAdd#(1,TLog#(maxBurst)), 8));

   FIFOFLevel#(DMAData#(dsz),maxBurst)  readBuffer <- mkBRAMFIFOFLevel;
   FIFOF#(DMAAddressRequest)        reqOutstanding <- mkFIFOF();
   Ratchet#(TAdd#(1,TLog#(maxBurst))) unfulfilled <- mkRatchet(0);
   
   // only issue the readRequest when sufficient buffering is available.  This includes the bufering we have already comitted.
   Bit#(TAdd#(1,TLog#(maxBurst))) sreq = pack(satPlus(Sat_Bound, unpack(truncate(reqOutstanding.first.burstLen)), unfulfilled.read()));

   interface DMAReadServer dmaServer;
      interface PutF readReq = toPutF(reqOutstanding);
      interface GetF readData = toGetF(readBuffer);
   endinterface
   interface DMAReadClient dmaClient;
      interface GetF readReq;
	 method ActionValue#(DMAAddressRequest) get if (readBuffer.lowWater(sreq));
	    reqOutstanding.deq;
	    unfulfilled.increment(unpack(truncate(reqOutstanding.first.burstLen)));
	    return reqOutstanding.first;
	 endmethod
         method Bool notEmpty();
	    return readBuffer.lowWater(sreq);
	 endmethod
      endinterface
      interface PutF readData;
	 method Action put(DMAData#(dsz) x);
	    readBuffer.fifo.enq(x);
	    unfulfilled.decrement(1);
	 endmethod
	 method notFull();
	    return readBuffer.fifo.notFull();
	 endmethod
      endinterface
   endinterface
endmodule

//
// @brief Makes a DMA channel for writing wordSize words from memory.
//
// @param bsz The width of the bus in bits.
// @param maxBurst The max number of words to transfer per request.
//
module mkDMAWriteBuffer(DMAWriteBuffer#(bsz, maxBurst))
   provisos(Add#(1,a__,bsz),
	    Add#(b__, TAdd#(1, TLog#(maxBurst)), 8));

   FIFOFLevel#(DMAData#(bsz),maxBurst) writeBuffer <- mkBRAMFIFOFLevel;
   FIFOF#(DMAAddressRequest)        reqOutstanding <- mkFIFOF();
   FIFOF#(Bit#(6))                        doneTags <- mkFIFOF();
   Ratchet#(TAdd#(1,TLog#(maxBurst)))  unfulfilled <- mkRatchet(0);
   
   // only issue the writeRequest when sufficient data is available.  This includes the data we have already comitted.
   Bit#(TAdd#(1,TLog#(maxBurst))) sreq = pack(satPlus(Sat_Bound, unpack(truncate(reqOutstanding.first.burstLen)), unfulfilled.read()));

   interface DMAWriteServer dmaServer;
      interface PutF writeReq = toPutF(reqOutstanding);
      interface PutF writeData = toPutF(writeBuffer);
      interface GetF writeDone = toGetF(doneTags);
   endinterface
   interface DMAWriteClient dmaClient;
      interface GetF writeReq;
	 method ActionValue#(DMAAddressRequest) get if (writeBuffer.highWater(sreq));
	    reqOutstanding.deq;
	    unfulfilled.increment(unpack(truncate(reqOutstanding.first.burstLen)));
	    return reqOutstanding.first;
	 endmethod
	 method Bool notEmpty();
	    return writeBuffer.highWater(sreq);
	 endmethod
      endinterface
      interface GetF writeData;
	 method ActionValue#(DMAData#(bsz)) get();
	    unfulfilled.decrement(1);
	    writeBuffer.fifo.deq;
	    return writeBuffer.fifo.first;
	 endmethod
	 method Bool notEmpty();
	    return writeBuffer.fifo.notEmpty;
	 endmethod
      endinterface
      interface PutF writeDone = toPutF(doneTags);
   endinterface
endmodule
