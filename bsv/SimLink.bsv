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

`ifdef BSIM
import "BDPI" function Action                 bsimLinkOpen(Integer linknumber, Bool listening);
import "BDPI" function Bool                   bsimLinkCanReceive(Integer linknumber, Bool listening);
import "BDPI" function Bool                   bsimLinkCanTransmit(Integer linknumber, Bool listening);
import "BDPI" function ActionValue#(Bit#(32)) bsimLinkReceive32(Integer linknumber, Bool listening);
import "BDPI" function Action                 bsimLinkTransmit32(Integer linknumber, Bool listening, Bit#(32) value);
import "BDPI" function ActionValue#(Bit#(64)) bsimLinkReceive64(Integer linknumber, Bool listening);
import "BDPI" function Action                 bsimLinkTransmit64(Integer linknumber, Bool listening, Bit#(64) value);

typeclass SelectLinkWidth#(numeric type dsz);
   function ActionValue#(Bit#(dsz)) bsimLinkReceive(Integer linknumber, Bool listening);
   function Action bsimLinkTransmit(Integer linknumber, Bool listening, Bit#(dsz) value);
endtypeclass

instance SelectLinkWidth#(32);
   function ActionValue#(Bit#(32)) bsimLinkReceive(Integer linknumber, Bool listening);
   actionvalue
      let v <- bsimLinkReceive32(linknumber, listening);
      return v;
   endactionvalue
   endfunction
   function Action bsimLinkTransmit(Integer linknumber, Bool listening, Bit#(32) value);
   action
      bsimLinkTransmit32(linknumber, listening, value);
   endaction
   endfunction
endinstance
instance SelectLinkWidth#(64);
   function ActionValue#(Bit#(64)) bsimLinkReceive(Integer linknumber, Bool listening);
   actionvalue
      let v <- bsimLinkReceive64(linknumber, listening);
      return v;
   endactionvalue
   endfunction
   function Action bsimLinkTransmit(Integer linknumber, Bool listening, Bit#(64) value);
   action
      bsimLinkTransmit64(linknumber, listening, value);
   endaction
   endfunction
endinstance

module mkSimLink#(Integer linknumber)(SimLink#(dataWidth)) provisos (SelectLinkWidth#(dataWidth));
   FIFOF#(Bit#(dataWidth)) rxFifo <- mkFIFOF();
   FIFOF#(Bit#(dataWidth)) txFifo <- mkFIFOF();
   Reg#(Bool) opened    <- mkReg(False);
   Reg#(Bool) listening <- mkReg(False);
   Reg#(Bool) started   <- mkReg(False);

   rule open if (!opened && started);
      bsimLinkOpen(linknumber, listening);
      opened <= True;
   endrule

   rule receive if (bsimLinkCanReceive(linknumber, listening));
      let v <- bsimLinkReceive(linknumber, listening);
      rxFifo.enq(v);
   endrule

   rule transmit if (bsimLinkCanTransmit(linknumber, listening));
      let v <- toGet(txFifo).get();
      bsimLinkTransmit(linknumber, listening, v);
   endrule

   interface rx = toPipeOut(rxFifo);
   interface tx = toPipeIn(txFifo);
   method Action start(Bool l);
      started <= True;
      listening <= l;
   endmethod
endmodule
`endif

`ifdef XSIM
import "BVI" XsimLink =
module mkSimLink#(Integer linknumber)(SimLink#(32));
   parameter LINKNUMBER=linknumber;

   method start(listening) enable (EN_start);
   interface PipeOut rx;
      method rx_first first() ready (rdy_rx_first);
      method deq() enable (en_rx_deq) ready (rdy_rx_deq);
      method rx_not_empty notEmpty();
   endinterface
   interface PipeIn tx;
      method enq(tx_enq_v) enable (en_tx_enq);
      method tx_not_full notFull();
   endinterface
   schedule (rx_first, rx_notEmpty, tx_notFull, rx_deq, tx_enq, start) CF (rx_first, rx_notEmpty, tx_notFull, rx_deq, tx_enq, start);
endmodule
`endif
