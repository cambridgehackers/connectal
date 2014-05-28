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
   Bit#(32) payload;
   } DataMessage deriving(Bits);

interface NocNode;
   interface LinkHost#(DataMessage) host;
endinterface
      
function Action movetolink(FIFOF#(DataMessage) from, SerialFIFOIn#(DataMessage) to);
   return action
	     $display("movetolink %x", from.first);
	     to.enq(from.first);
	     from.deq();
	  endaction;
endfunction

function Action move(FIFOF#(DataMessage) from, FIFOF#(DataMessage) to);
   return action
	     $display("move %x", from.first);
	     to.enq(from.first);
	     from.deq();
	  endaction;
endfunction

function Action outputarbitrate(FIFOF#(DataMessage) a,
				FIFOF#(DataMessage) b,
				Reg#(Bit#(1)) select,
				SerialFIFOIn#(DataMessage) r);
   return action
	     if (a.notEmpty && !b.notEmpty)
		movetolink(a, r);
	     else if (!a.notEmpty && b.notEmpty)
		movetolink(b, r);
	     else if (a.notEmpty && b.notEmpty)
		begin
		   if (select == 1)
		      movetolink(a, r);
		   else
		      movetolink(b, r);
		   select <= select ^ 1;
		end
	  endaction;
endfunction

module mkNocNode#(Bit#(4) id, 
		  SerialFIFO#(DataMessage) west,
		  SerialFIFO#(DataMessage) east)(NocNode);
//	    Log#(asize, k),
//	    PrimSelectable#(DataMessage, Bit#(1)),
//	    Bitwise#(DataMessage),
//            Literal#(DataMessage));

   Reg#(Bit#(1)) oeselect <- mkReg(0);
   Reg#(Bit#(1)) owselect <- mkReg(0);

   // out Links
   LinkHost#(DataMessage) lhost <- mkLinkHost();
  
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
   
   
   rule genow;
      outputarbitrate(ew, hw, owselect, west.in);
   endrule
   
   // arbiter to send data messages to e
   
   
   rule genoe;
      outputarbitrate(we, he, oeselect, east.in);
   endrule
   
   // Handle arriving messages from East
   
   rule fromeast;
      if (east.out.first.address == id)
	 eh.enq(east.out.first);
      else
	 ew.enq(east.out.first);
      east.out.deq();
   endrule
   
   // Handle arriving messages from West

   rule fromwest;
      if (west.out.first.address == id)
	 wh.enq(west.out.first);
      else
	 we.enq(west.out.first);
      west.out.deq();
      endrule
   
   
  // interface wiring

   interface LinkHost host = lhost;

endmodule

