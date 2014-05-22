// Copyright (c) 2014 Quanta Research Cambridge, Inc.
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

import Connectable::*;
import LinkIn::*;
import LinkOut::*;
import LinkHost::*;
import FIFO::*;
import Vector::*;

/* This is a serial to parallel converter for messages of type a
 * The data register is assumed to always be available, so an arriving
 * message must be removed ASAP or be overwritten 
 */

typedef struct {
	Bit#(4) address;
	Bit#(4) lsn;
	Bit#(64) payload;
	} DataMessage deriving(Bits);

typedef struct {
	Bit#(4) lsn;
	Bit#(2) busy;
	} FlowMessage deriving(Bits);

interface NocLinks;
   interface SerialLinkIn ie;
   interface SerialLinkIn iw;
   interface SerialLinkIn iefc;
   interface SerialLinkIn iwfc;
   interface SerialLinkOut oe;
   interface SerialLinkOut ow;
   interface SerialLinkOut oefc;
   interface SerialLinkOut owfc;
endinterface

interface NocNode#(type a);
   interface NocLinks links;
   interface LinkHost#(a) host;
endinterface
      
function Action move(FIFOF#(DataMessage) from, FIFOF#(DataMessage) to);
   to.enq(from.first);
   from.deq();
endfunction

function Action outputarbitrate(FIFOF#(DataMessage) a,
			       FIFOF#(DataMessage) b,
			       Reg#(Bool) select,
			       LinkOut#(DataMessage) r);
   if (a.notEmpty && !b.notEmpty)
      move(a, r.data);
   else if (!a.notEmpty && b.notEmpty)
      move(b, r.data);
   else if (a.notEmpty && b.notEmpty)
      begin
	 if (select == 0)
	    move(a, r.data);
	 else
	    move(b, r.data);
	 select <= select ^ 1;
      end
endfunction

module mkNocNode#(Bit#(4) id)(NocNode#(a))
   provisos(Bits#(a,asize)),
            Log#(asize, k);

   // out Links
   LinkHost#(DataMessage) lhost <- mkHost(id);
   LinkOut#(DataMessage) low <- mkLinkOut();
   LinkOut#(DataMessage) loe <- mkLinkOut();

   // in Links and flow control
   LinkIn#(DataMessage) liw <- mkLinkIn();
   LinkIn#(DataMessage) lie <- mkLinkIn();
   LinkOut#(FlowMessage) lowfc <- mkLinkOut();
   LinkOut#(FlowMessage) loefc <- mkLinkOut();
   LinkIn#(FlowMessage) liwfc <- mkLinkIn();
   LinkIn#(FlowMessage) liefc <- mkLinkIn();
   
   // buffers for crossbar switch
   
   FIFOF#(DataMessage) he <- mkSizedFIFOF(4);
   FIFOF#(DataMessage) hw <- mkSizedFIFOF(4);
   
   FIFOF#(DataMessage) ew <- mkSizedFIFOF(4);
   FIFOF#(DataMessage) we <- mkSizedFIFOF(4);
   FIFOF#(DataMessage) eh <- mkSizedFIFOF(4);
   FIFOF#(DataMessage) wh <- mkSizedFIFOF(4);
   
   
   Bit#(4) lastiwlsn <- mkReg(0);  // most recent lsn from w
   Bit#(4) lastielsn <- mkReg(0);  // most recent lsn from e
   
   
   // sort host messages to proper queue
   
   rule fromhost;
      if (lhost.tonet.first.address < id)
	 move(lhost.tonet, hw);
      else if (lhost.tonet.first.address == id)
	 move(lhost.tonet, lhost.tohost);
      else
	 move(lhost.tonet, he);
   endrule
   
   // arbiter to send data messages to e
   
   Bit#(1) owselect <- mkReg(0);
   Bit#(1) oeselect <- mkReg(0);
   
   rule genow;
      outputarbitrate(ew, hw, owselect, low);
   endrule
   
   // arbiter to send data messages to w
   
   rule genoe;
      outputarbitrate(we, he, oeselect, loe);
   endrule
   
   // composer to create flow message to e

   rule genoefc;
      owfc.enq(FlowMessage{lsn: lastielsn, busy: {eh.notFull, ew.notFull}});
   endrule

   // composer to create flow message to w
   
   rule genowfc;
      owfc.enq(FlowMessage{lsn: lastielsn, busy: {wh.notFull, ew.notFull}});
   endrule


   // Handle arriving messages from East

   rule fromeast (lie.dataready);
      lastielsn <= lie.ror.lsn;
      if (lie.ror.address == id)
	 eh.enq(lie.ror);
      else
	 ew.enq(lie.ror);
      lie.dataready <= False;
      endrule

   // Handle arriving messages from West

   rule fromwest (liw.dataready);
      lastiwlsn <= liw.ror.lsn;
      if (liw.ror.address == id)
	 wh.enq(liw.ror);
      else
	 we.enq(liw.ror);
      liw.dataready <= False;
   endrule



  // interface wiring


   interface SerialLinkOut oe = loe.link;
   interface SerialLinkOut ow = low.link;
   interface SerialLinkOut oefc = loefc.link;
   interface SerialLinkOut owfc = lowfc.link;
   interface SerialLinkIn ie = lie.link;
   interface SerialLinkIn iw = liw.link;
   interface SerialLinkIn iefc = liefc.link;
   interface SerialLinkIn iwfc = liwfc.link;

   interface LinkHost host = lhost;

endmodule

