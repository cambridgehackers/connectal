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

`include "ConnectalProjectConfig.bsv"

interface SimLink#(numeric type dataWidth);
   method Action start(Bit#(32) linknumber, Bool listening);
   method Bool   linkUp();
   interface PipeOut#(Bit#(dataWidth)) rx;
   interface PipeIn#(Bit#(dataWidth)) tx;
endinterface

`ifdef BOARD_bluesim
import "BDPI" function Action                 bsimLinkOpen(Bit#(32) linknumber, Bool listening);
import "BDPI" function Bit#(1)                bsimLinkUp(Bit#(32) linknumber, Bool listening);
import "BDPI" function Bool                   bsimLinkCanReceive(Bit#(32) linknumber, Bool listening);
import "BDPI" function Bool                   bsimLinkCanTransmit(Bit#(32) linknumber, Bool listening);
import "BDPI" function ActionValue#(Bit#(32)) bsimLinkReceive32(Bit#(32) linknumber, Bool listening);
import "BDPI" function Action                 bsimLinkTransmit32(Bit#(32) linknumber, Bool listening, Bit#(32) value);
import "BDPI" function ActionValue#(Bit#(64)) bsimLinkReceive64(Bit#(32) linknumber, Bool listening);
import "BDPI" function Action                 bsimLinkTransmit64(Bit#(32) linknumber, Bool listening, Bit#(64) value);

typeclass SelectLinkWidth#(numeric type dsz);
   function ActionValue#(Bit#(dsz)) bsimLinkReceive(Bit#(32) linknumber, Bool listening);
   function Action bsimLinkTransmit(Bit#(32) linknumber, Bool listening, Bit#(dsz) value);
endtypeclass

instance SelectLinkWidth#(32);
   function ActionValue#(Bit#(32)) bsimLinkReceive(Bit#(32) linknumber, Bool listening);
   actionvalue
      let v <- bsimLinkReceive32(linknumber, listening);
      return v;
   endactionvalue
   endfunction
   function Action bsimLinkTransmit(Bit#(32) linknumber, Bool listening, Bit#(32) value);
   action
      bsimLinkTransmit32(linknumber, listening, value);
   endaction
   endfunction
endinstance
instance SelectLinkWidth#(64);
   function ActionValue#(Bit#(64)) bsimLinkReceive(Bit#(32) linknumber, Bool listening);
   actionvalue
      let v <- bsimLinkReceive64(linknumber, listening);
      return v;
   endactionvalue
   endfunction
   function Action bsimLinkTransmit(Bit#(32) linknumber, Bool listening, Bit#(64) value);
   action
      bsimLinkTransmit64(linknumber, listening, value);
   endaction
   endfunction
endinstance

module mkSimLink(SimLink#(dataWidth)) provisos (SelectLinkWidth#(dataWidth));
   FIFOF#(Bit#(dataWidth)) rxFifo <- mkFIFOF();
   FIFOF#(Bit#(dataWidth)) txFifo <- mkFIFOF();
   Reg#(Bit#(32)) linknumber <- mkReg(0);
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
   method Action start(Bit#(32) number, Bool l);
      linknumber <= number;
      started <= True;
      listening <= l;
   endmethod
   method Bool linkUp();
      if (started)
	 return unpack(bsimLinkUp(linknumber, listening));
      else
	 return False;
   endmethod
endmodule
`endif

`ifdef SVDPI
import "BVI" XsimLink =
module mkSimLink(SimLink#(dataWidth));
   parameter DATAWIDTH=valueOf(dataWidth);
   method start(start_linknumber, start_listening) enable (en_start);
   method link_up linkUp();
   interface PipeOut rx;
      method rx_first first() ready (rdy_rx_first);
      method deq() enable (en_rx_deq) ready (rdy_rx_deq);
      method rx_not_empty notEmpty();
   endinterface
   interface PipeIn tx;
      method enq(tx_enq_v) enable (en_tx_enq) ready (rdy_tx_enq);
      method tx_not_full notFull();
   endinterface
   schedule (rx_first, rx_notEmpty, tx_notFull, rx_deq, tx_enq, start, linkUp) CF (rx_first, rx_notEmpty, tx_notFull, rx_deq, tx_enq, start, linkUp);
endmodule
`endif //SVDPI
