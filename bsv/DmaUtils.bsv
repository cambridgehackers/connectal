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
import Dma::*;

interface DmaReadServer2BRAM#(type a);
   method Action start(DmaPointer h, a x);
   method ActionValue#(Bool) finished();
endinterface

module mkDmaReadServer2BRAM#(DmaReadServer#(busWidth) rs, BRAMServer#(a,d) br)(DmaReadServer2BRAM#(a))
   provisos(Bits#(d,dsz),
	    Div#(busWidth,dsz,nd),
	    Mul#(nd,dsz,busWidth),
	    Div#(busWidth,8,nb),
	    Eq#(a),
	    Ord#(a),
	    Arith#(a),
	    Bits#(a,b__),
	    Add#(d__,b__,DmaOffsetSize),
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
   Reg#(DmaPointer) ptr <- mkReg(0);
   Reg#(Bit#(DmaOffsetSize)) off <- mkReg(0);

   rule loadReq(iv);
      //$display("lloadReq %d %d", ptr, i);
      rs.readReq.put(DmaRequest {pointer: ptr, offset: off, burstLen: 1, tag: 0});
      i <= i+fromInteger(valueOf(nd));
      off <= off+fromInteger(valueOf(nb));
      iv <= (i < n);
   endrule
   
   rule loadResp;
      let rv <- rs.readData.get();
      Vector#(nd,d) rvv = unpack(rv.data);
      gb.enq(rvv);
   endrule
   
   rule load(jv);
      //$display("%d %d", ptr, gb.first[0]);
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
   
   method Action start(DmaPointer h, a x);
      iv <= True;
      jv <= True;
      i <= 0;
      j <= 0;
      n <= x;
      ptr <= h;
      off <= 0;
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
interface DmaReadBuffer#(numeric type bsz, numeric type maxBurst);
   interface DmaReadServer #(bsz) dmaServer;
   interface DmaReadClient#(bsz) dmaClient;
endinterface

//
// @brief A buffer for writing to a bus of width bsz.
//
// @param bsz The number of bits in the bus.
// @param maxBurst The number of words to buffer
//
interface DmaWriteBuffer#(numeric type bsz, numeric type maxBurst);
   interface DmaWriteServer#(bsz) dmaServer;
   interface DmaWriteClient#(bsz) dmaClient;
endinterface

//
// @brief Makes a Dma buffer for reading wordSize words from memory.
//
// @param dsz The width of the bus in bits.
// @param maxBurst The max number of words to transfer per request.
//
module mkDmaReadBuffer(DmaReadBuffer#(dsz, maxBurst))
   provisos(Add#(1,a__,dsz),
	    Add#(b__, TAdd#(1,TLog#(maxBurst)), 8));

   FIFOFLevel#(DmaData#(dsz),maxBurst)  readBuffer <- mkBRAMFIFOFLevel;
   FIFOF#(DmaRequest)        reqOutstanding <- mkFIFOF();
   Ratchet#(TAdd#(1,TLog#(maxBurst))) unfulfilled <- mkRatchet(0);
   
   // only issue the readRequest when sufficient buffering is available.  This includes the bufering we have already comitted.
   Bit#(TAdd#(1,TLog#(maxBurst))) sreq = pack(satPlus(Sat_Bound, unpack(truncate(reqOutstanding.first.burstLen)), unfulfilled.read()));

   interface DmaReadServer dmaServer;
      interface PutF readReq = toPutF(reqOutstanding);
      interface GetF readData = toGetF(readBuffer);
   endinterface
   interface DmaReadClient dmaClient;
      interface GetF readReq;
	 method ActionValue#(DmaRequest) get if (readBuffer.lowWater(sreq));
	    reqOutstanding.deq;
	    unfulfilled.increment(unpack(truncate(reqOutstanding.first.burstLen)));
	    return reqOutstanding.first;
	 endmethod
         method Bool notEmpty();
	    return readBuffer.lowWater(sreq);
	 endmethod
      endinterface
      interface PutF readData;
	 method Action put(DmaData#(dsz) x);
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
// @brief Makes a Dma channel for writing wordSize words from memory.
//
// @param bsz The width of the bus in bits.
// @param maxBurst The max number of words to transfer per request.
//
module mkDmaWriteBuffer(DmaWriteBuffer#(bsz, maxBurst))
   provisos(Add#(1,a__,bsz),
	    Add#(b__, TAdd#(1, TLog#(maxBurst)), 8));

   FIFOFLevel#(DmaData#(bsz),maxBurst) writeBuffer <- mkBRAMFIFOFLevel;
   FIFOF#(DmaRequest)        reqOutstanding <- mkFIFOF();
   FIFOF#(Bit#(6))                        doneTags <- mkFIFOF();
   Ratchet#(TAdd#(1,TLog#(maxBurst)))  unfulfilled <- mkRatchet(0);
   
   // only issue the writeRequest when sufficient data is available.  This includes the data we have already comitted.
   Bit#(TAdd#(1,TLog#(maxBurst))) sreq = pack(satPlus(Sat_Bound, unpack(truncate(reqOutstanding.first.burstLen)), unfulfilled.read()));

   interface DmaWriteServer dmaServer;
      interface PutF writeReq = toPutF(reqOutstanding);
      interface PutF writeData = toPutF(writeBuffer);
      interface GetF writeDone = toGetF(doneTags);
   endinterface
   interface DmaWriteClient dmaClient;
      interface GetF writeReq;
	 method ActionValue#(DmaRequest) get if (writeBuffer.highWater(sreq));
	    reqOutstanding.deq;
	    unfulfilled.increment(unpack(truncate(reqOutstanding.first.burstLen)));
	    return reqOutstanding.first;
	 endmethod
	 method Bool notEmpty();
	    return writeBuffer.highWater(sreq);
	 endmethod
      endinterface
      interface GetF writeData;
	 method ActionValue#(DmaData#(bsz)) get();
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
