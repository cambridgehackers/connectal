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
import SerialFIFO::*;
import LinkHost::*;
import FIFOF::*;
import Vector::*;

typedef struct {
	Bit#(4) address;
	Bit#(4) lsn;
	Bit#(64) payload;
	} DataMessage deriving(Bits);

interface NocNode#(type a);
   interface LinkHost#(a) host;
endinterface
      
function Action movetolink(FIFOF#(DataMessage) from, SerialFIFOIn#(DataMessage) to);
   return action
	     to.enq(from.first);
	     from.deq();
	  endaction;
endfunction

function Action outputarbitrate(FIFOF#(DataMessage) a,
				FIFOF#(DataMessage) b,
			       Reg#(Bool) select,
			       SerialFIFOIn#(DataMessage) r);
   return action
	     if (a.notEmpty && !b.notEmpty)
		movetolink(a, r);
	     else if (!a.notEmpty && b.notEmpty)
		movetolink(b, r);
	     else if (a.notEmpty && b.notEmpty)
		begin
		   if (select)
		      movetolink(a, r);
		   else
		      movetolink(b, r);
		   select <= select != True;
		end
	  endaction;
endfunction

module mkNocNode#(Bit#(4) id, 
   SerialFIFO#(DataMessage) east,
   SerialFIFO#(DataMessage) west)(NocNode#(a))
   provisos(Bits#(a,asize),
            Log#(asize, k));

   // out Links
   LinkHost#(DataMessage) lhost <- mkLinkHost(id);
  
   // buffers for crossbar switch
   
   FIFOF#(DataMessage) he <- mkSizedFIFOF(4);
   FIFOF#(DataMessage) hw <- mkSizedFIFOF(4);
   
   FIFOF#(DataMessage) ew <- mkSizedFIFOF(4);
   FIFOF#(DataMessage) we <- mkSizedFIFOF(4);

   FIFOF#(DataMessage) eh <- mkSizedFIFOF(4);
   FIFOF#(DataMessage) wh <- mkSizedFIFOF(4);
   
   // sort host messages to proper queue
   
   rule fromhost;
      if (lhost.tonet.first.address < id)
	 move(lhost.tonet, hw);
      else if (lhost.tonet.first.address == id)
	 move(lhost.tonet, lhost.tohost);
      else
	 move(lhost.tonet, he);
   endrule
   
   // arbiter to send data messages to w
   
   Bit#(1) owselect <- mkReg(0);
   
   rule genow;
      outputarbitrate(ew, hw, owselect, low);
   endrule
   
   // arbiter to send data messages to e
   
   Bit#(1) oeselect <- mkReg(0);

   rule genoe;
      outputarbitrate(we, he, oeselect, loe);
   endrule
   
   // Handle arriving messages from East

   rule fromeast;
      if (east.first.address == id)
	 eh.enq(east.first);
      else
	 ew.enq(east.first);
      east.deq();
      endrule

   // Handle arriving messages from West

   rule fromwest;
      if (west.first.address == id)
	 wh.enq(west.first);
      else
	 we.enq(west.first);
      west.deq();
      endrule


  // interface wiring

   interface LinkHost host = lhost;

endmodule

