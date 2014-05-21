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
	Bit#(64) payload;
	} DataMessage deriving(Bits);

typedef struct {
	Bit#(4) lsn;
	Bit#(2) busy;
	} FlowMessage deriving(Bits);

interface NocLinks;
   interface LinkIn#(DataMessage) ie;
   interface LinkIn#(DataMessage) iw;
   interface LinkIn#(FlowMessage) iefc;
   interface LinkIn#(FlowMessage) iwfc;
   interface LinkOut#(DataMessage) oe;
   interface LinkOut#(DataMessage) ow;
   interface LinkOut#(FlowMessage) oefc;
   interface LinkOut#(FlowMessage) owfc;
   interface LinkHost#(DataMessage) host;
endinterface

module mkNocNode#(Bit#(4) id)(NocNode#(a))
   provisos(Bits#(a,asize)),
            Log#(asize, k);

   NocLink east <- mkNocLink();
   NocLink west <- mkNocLink();
   NocHost host <- mkNocHost();

endmodule
/* numlinks controls how many fifos to other links there are */

module mkLinkIn(

   // buffers for transiting messages

   FIFOF#(DataMessage) ew <- mkSizedFIFOF(4);
   FIFOF#(DataMessage) we <- mkSizedFIFOF(4);
   FIFOF#(DataMessage) eh <- mkSizedFIFOF(4);
   FIFOF#(DataMessage) wh <- mkSizedFIFOF(4);
   Bit#(4) lastiwlsn <- mkReg(0);  // most recent lsn from w
   Bit#(4) lastielsn <- mkReg(0);  // most recent lsn from e
   
   
   // arbiter to send data messages to e
   
   rule genow;
   endrule
   
   // arbiter to send data messages to w
   
   rule genoe;
   endrule
   
   // composer to create flow message to e

   rule genoefc;
      owfc.enq(FlowMessage{lsn: lastielsn, busy: {eh.notFull, ew.notFull});
   endrule

   // composer to create flow message to w
   
   rule genowfc;
      owfc.enq(FlowMessage{lsn: lastielsn, busy: {wh.notFull, ew.notFull});
   endrule













endmodule

