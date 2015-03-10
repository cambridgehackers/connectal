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

import GetPut            :: *;
import FIFOF             :: *;
import Pipe              :: *;


interface BsimLink;
   method Action start(String name, Bool listening);
   interface PipeOut#(Bit#(32)) rx;
   interface PipeIn#(Bit#(32)) tx;
endinterface

import "BDPI" function Action                 bsimLinkOpen(String name, Bool listening);
import "BDPI" function Bool                   bsimLinkCanReceive(String name, Bool listening);
import "BDPI" function Bool                   bsimLinkCanTransmit(String name, Bool listening);
import "BDPI" function ActionValue#(Bit#(32)) bsimLinkReceive(String name, Bool listening);
import "BDPI" function Action                 bsimLinkTransmit(String name, Bool listening, Bit#(32) value);

module mkBsimLink#(String name)(BsimLink);
   FIFOF#(Bit#(32)) rxFifo <- mkFIFOF();
   FIFOF#(Bit#(32)) txFifo <- mkFIFOF();
   Reg#(Bool) opened    <- mkReg(False);
   Reg#(Bool) listening <- mkReg(False);
   Reg#(Bool) started   <- mkReg(False);

   rule open if (!opened && started);
      bsimLinkOpen(name, listening);
      bsimLinkOpen(name, listening);
      opened <= True;
   endrule

   rule receive if (bsimLinkCanReceive(name, listening));
      let v <- bsimLinkReceive(name, listening);
      rxFifo.enq(v);
   endrule

   rule transmit if (bsimLinkCanTransmit(name, listening));
      let v <- toGet(txFifo).get();
      bsimLinkTransmit(name, listening, v);
   endrule

   interface rx = toPipeOut(rxFifo);
   interface tx = toPipeIn(txFifo);
   method Action start(String n, Bool l);
      started <= True;
      listening <= l;
   endmethod
endmodule
