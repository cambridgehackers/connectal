// Copyright (c) 2015 Quanta Research Cambridge, Inc.

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

import Clocks::*;
import Vector::*;
import FIFO::*;
import FIFOF::*;
import BRAMFIFO::*;
import CBus::*; // extendNP and truncateNP

import Arith::*;

(* always_ready, always_enabled *)
interface X7FifoSyncMacro#(numeric type data_width);
   method Bit#(1) empty();
   method Bit#(1) full();
   method Action din(Bit#(data_width) v);
   method Action wren(Bit#(1) wren);
   method Bit#(data_width) dout();
   method Action rden(Bit#(1) rden);
   method Bit#(9) wrcount();
   method Bit#(9) rdcount();
endinterface

import "BVI" FIFO_DUALCLOCK_MACRO =
module  vmkBramFifo#(Clock wrclk, String fifo_size)(X7FifoSyncMacro#(data_width));
   parameter DEVICE = "7SERIES";
   parameter DATA_WIDTH = valueOf(data_width);
   parameter FIFO_SIZE = fifo_size;
   parameter FIRST_WORD_FALL_THROUGH = 1;
   default_clock clk(RDCLK);
   default_reset rst(RST);
   input_clock wrclk(WRCLK) = wrclk;
   method EMPTY empty();
   method FULL full();
   method din(DI) enable ((*inhigh*)EN_di);
   method wren(WREN) enable ((*inhigh*)EN_wren);
   method DO dout();
   method rden(RDEN) enable ((*inhigh*)EN_rden);
   // wrcount and rdcount ports are needed for xsim
   method WRCOUNT wrcount();
   method RDCOUNT rdcount();
   schedule (empty, full, dout, din, wren, rden, wrcount, rdcount) CF (empty, full, dout, din, wren, rden, wrcount, rdcount);
endmodule

module mkSizedBRAMFIFOF#(Integer m)(FIFOF#(t))
   provisos (Bits#(t,sizet),
	     Add#(1,a__,sizet));
   String fifo_size = "36Kb";
   let defaultClock <- exposeCurrentClock;
   let defaultReset <- exposeCurrentReset;
   let invertReset <- mkResetInverter(defaultReset);
   Vector#(TDiv#(sizet,72),X7FifoSyncMacro#(72)) fifos <- replicateM(vmkBramFifo(defaultClock, fifo_size, reset_by invertReset));
   Wire#(Bit#(1)) rdenWire <- mkDWire(0);
   Wire#(Bit#(1)) wrenWire <- mkDWire(0);
   Vector#(TDiv#(sizet,72),Wire#(Bit#(72))) dinWires <- replicateM(mkDWire(0));

   for (Integer i = 0; i < valueOf(TDiv#(sizet,72)); i = i+1) begin
      Reg#(Bit#(9)) rdcount <- mkReg(0);
      Reg#(Bit#(9)) wrcount <- mkReg(0);
      rule enables;
	 fifos[i].rden(rdenWire);
	 fifos[i].wren(wrenWire);
      endrule
      rule inputs;
	 fifos[i].din(dinWires[i]);
      endrule
      rule counts;
	 rdcount <= fifos[i].rdcount();
	 wrcount <= fifos[i].wrcount();
      endrule
   end

   function Bool fifoNotEmpty(Integer i); return fifos[i].empty == 0; endfunction
   function Bool fifoNotFull(Integer i); return fifos[i].full == 0; endfunction
   Vector#(TDiv#(sizet,72), Bool) vNotEmpty = genWith(fifoNotEmpty);
   Vector#(TDiv#(sizet,72), Bool) vNotFull = genWith(fifoNotFull);

   method t first() if (fifos[0].empty == 0);
      function Bit#(72) fifoFirst(Integer i); return fifos[i].dout(); endfunction
      Vector#(TDiv#(sizet,72), Bit#(72)) v = genWith(fifoFirst);
      return unpack(truncateNP(pack(v)));
   endmethod
   method Action deq() if (fifos[0].empty == 0);
      rdenWire <= 1;
   endmethod
   method notEmpty = (fifos[0].empty == 0);
   method Action enq(t v) if (fifos[0].full == 0);
      Vector#(TDiv#(sizet,72), Bit#(72)) vs = unpack(extendNP(pack(v)));
      Vector#(TDiv#(sizet,72), Integer) indices = genVector();
      function Action fifoEnq(Integer i); action dinWires[i] <= vs[i]; endaction endfunction
      mapM_(fifoEnq, indices);
      wrenWire <= 1;
   endmethod
   method notFull = (fifos[0].full == 0);
endmodule

module mkSizedBRAMFIFO#(Integer m)(FIFO#(t))
   provisos (Bits#(t,sizet),
	     Add#(1,a__,sizet));
   let fifo <- mkSizedBRAMFIFOF(m);
   method first = fifo.first;
   method deq = fifo.deq;
   method enq = fifo.enq;
endmodule
