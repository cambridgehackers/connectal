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

import FIFOF::*;
import FIFO::*;
import GetPut::*;
import Connectable::*;
import RegFile::*;
import MemTypes::*;
import ConnectalConfig::*;

typedef struct {
   Bit#(addrWidth) addr;
   Bit#(BurstLenSize) bc;
   Bit#(MemTagSize) tag;
   Bool    last;
   } AddrBeat#(numeric type addrWidth) deriving (Bits);

interface AddressGenerator#(numeric type addrWidth, numeric type dataWidth);
   interface Put#(PhysMemRequest#(addrWidth,dataWidth)) request;
   interface Get#(AddrBeat#(addrWidth)) addrBeat;
endinterface

module mkAddressGenerator(AddressGenerator#(addrWidth, dataWidth))
   provisos (Div#(dataWidth,8,dataWidthBytes),
	     Log#(dataWidthBytes,beatShift));
   FIFOF#(PhysMemRequest#(addrWidth,dataWidth)) requestFifo <- mkFIFOF1();
   FIFOF#(AddrBeat#(addrWidth)) addrBeatFifo <- mkFIFOF();
   Reg#(Bit#(addrWidth)) addrReg <- mkReg(0);
   Reg#(Bit#(BurstLenSize)) burstCountReg <- mkReg(0);
   Reg#(Bool) isFirstReg <- mkReg(True);
   Reg#(Bool) isLastReg <- mkReg(False);

   rule addrBeatRule;
      let req = requestFifo.first();
      let addr = addrReg;
      let burstCount = burstCountReg;
      let isLast = isLastReg;
      if (isFirstReg) begin
	 addr = req.addr;
	 burstCount = req.burstLen >> valueOf(beatShift);
	 isLast = (req.burstLen == fromInteger(valueOf(dataWidthBytes)));
         //$display("addr=%h, burstCount=%h, isLast=%h", addr, burstCount, isLast);
      end

      let nextIsLast = burstCount == 2;
      let nextBurstCount = burstCount - 1;

      addrReg <= addr + 1;
      burstCountReg <= nextBurstCount;
      isLastReg <= nextIsLast;
      Bool nextIsFirst = False;
      if (isLast) begin
	 requestFifo.deq();
	 nextIsFirst = True;
      end
      isFirstReg <= nextIsFirst;

      //$display("addr=%h, burstCount=%h, isLast=%h", addr, burstCount, isLast);
      addrBeatFifo.enq(AddrBeat { addr: addr, bc: burstCount, last: isLast, tag: req.tag});
   endrule

   interface Put request;
      method Action put(PhysMemRequest#(addrWidth,dataWidth) req);
	 requestFifo.enq(req);
      endmethod
   endinterface
   interface Get addrBeat;
      method ActionValue#(AddrBeat#(addrWidth)) get();
	 addrBeatFifo.deq();
	 return addrBeatFifo.first();
      endmethod
   endinterface
endmodule


