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
import Connectable       :: *;
import FIFOF             :: *;
import Pipe              :: *;
import Portal            :: *;
import MsgFormat         :: *;
import CnocPortal        :: *;

interface SimLink#(numeric type dataWidth);
   method Action start(Bool listening);
   interface PipeOut#(Bit#(dataWidth)) rx;
   interface PipeIn#(Bit#(dataWidth)) tx;
endinterface

import "BDPI" function Action                 bsimLinkOpen(String name, Bool listening);
import "BDPI" function Bool                   bsimLinkCanReceive(String name, Bool listening);
import "BDPI" function Bool                   bsimLinkCanTransmit(String name, Bool listening);
import "BDPI" function ActionValue#(Bit#(32)) bsimLinkReceive32(String name, Bool listening);
import "BDPI" function Action                 bsimLinkTransmit32(String name, Bool listening, Bit#(32) value);
import "BDPI" function ActionValue#(Bit#(64)) bsimLinkReceive64(String name, Bool listening);
import "BDPI" function Action                 bsimLinkTransmit64(String name, Bool listening, Bit#(64) value);

typeclass SelectLinkWidth#(numeric type dsz);
   function ActionValue#(Bit#(dsz)) bsimLinkReceive(String name, Bool listening);
   function Action bsimLinkTransmit(String name, Bool listening, Bit#(dsz) value);
endtypeclass

instance SelectLinkWidth#(32);
   function ActionValue#(Bit#(32)) bsimLinkReceive(String name, Bool listening);
   actionvalue
      let v <- bsimLinkReceive32(name, listening);
      return v;
   endactionvalue
   endfunction
   function Action bsimLinkTransmit(String name, Bool listening, Bit#(32) value);
   action
      bsimLinkTransmit32(name, listening, value);
   endaction
   endfunction
endinstance
instance SelectLinkWidth#(64);
   function ActionValue#(Bit#(64)) bsimLinkReceive(String name, Bool listening);
   actionvalue
      let v <- bsimLinkReceive64(name, listening);
      return v;
   endactionvalue
   endfunction
   function Action bsimLinkTransmit(String name, Bool listening, Bit#(64) value);
   action
      bsimLinkTransmit64(name, listening, value);
   endaction
   endfunction
endinstance

module mkSimLink#(String name)(SimLink#(dataWidth)) provisos (SelectLinkWidth#(dataWidth));
   FIFOF#(Bit#(dataWidth)) rxFifo <- mkFIFOF();
   FIFOF#(Bit#(dataWidth)) txFifo <- mkFIFOF();
   Reg#(Bool) opened    <- mkReg(False);
   Reg#(Bool) listening <- mkReg(False);
   Reg#(Bool) started   <- mkReg(False);

   rule open if (!opened && started);
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
   method Action start(Bool l);
      started <= True;
      listening <= l;
   endmethod
endmodule
