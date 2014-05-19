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
import FIFO::*;
import Vector::*;

/* This is a serial to parallel converter for messages of type a
 * The data register is assumed to always be available, so an arriving
 * message must be removed ASAP or be overwritten 
 */
interface LinkIn#(type a);
   method Action frame(bit f);
   method Action data(bit d);
   interface FIFO#(?) new;
   interface ReadOnly#(a) r;
endinterface

interface LinkOut;
   method bit frame();
   method bit data();
endinterface





typedef struct {
	Bit#(4) address;
	Bit#(64) payload;
	} DataMessage deriving(Bits);

typedef struct {
	Bit#(4) lsn;
	Bit#(12) busy;
	} FlowMessage deriving(Bits);



interface NocNode;
   interface NocNodeIn in;
   interface NocNodeOut inrev;
   interface NocNodeOut out;
   interface NocNodeIn outrev;
endinterface

interface SpiReg#(type a);
   interface NocNode tap;
   interface FIFO#(a) send;
   interface FIFO#(a) recv;
endinterface



instance Connectable#(NocNodeOut, NocNodeIn);
   module mkConnection#(NocNodeOut out, NocNodeIn in)(Empty);
      rule move_data;
	 in.frame(out.frame());
	 in.data(out.data());
	 endrule
   endmodule
endinstance

module mkNocNode#(Bit#(4) id)(NocNode#(a))
   provisos(Bits#(a,asize)),
            Log#(asize, k);





   NocLink east <- mkNocLink();
   NocLink west <- mkNocLink();
   NocHost host <- mkNocHost();



endmodule
/* numlinks controls how many fifos to other links there are */

module mkLinkIn(

module mkLinkIn(LinkIn#(a))
       provisos(Bits#(a,asize)),
	        Log#(asize, k);

   // registers for receiving data messages
   Reg#(bit) framebit <- mkReg(0);
   Reg#(bit) databit <- mkReg(0);
   Reg#(Bit#(6)) incount <= mkReg(0);
   Reg#(a) shifter <- mkReg(0);
   Reg#(a) data <- mkReg(0);


   rule handleDataFrame;
      if (datainframebit == 0)
	 begin
            dataincount <= 0;
	 end
      else
	 dataincount <= dataincount + 1;
   endrule
   
   rule handleDataInShift (datainframebit == 1);
      Bit#(SizeOf(DataMessage)) tmp = datainshifter;
      tmp = tmp >> 1;
      tmp[SizeOf(DataMessage)-1] = datainbit;
      datainshifter <= tmp;
      if (dataincount == (SizeOf(DataMessage) - 1))
         begin
	 let msg
	 end;
   endrule
   
   interface LinkIn;
   
   		method Action frame(bit i );
	    frameinbit <= i ;
	 endmethod
   
	 method Action data( bit i );
	    datainbit <= i;
	 endmethod

	       endinterface





   // registers for sending flow control messages
   Wire#(bit) fcoutwire <- mkDWire(0);

   // registers for sending data messages
   Wire#(bit) dataoutwire <- mkDWire(0);

   // registers for receiving flow control messages
   Reg#(bit) fcinbit <- mkReg(0);
   Reg#(bit) fcinframeinbit <- mkReg(0);
   Reg#(Bit#(6)) fcincount <= mkReg(0);
   Reg#(FlowMessage) fcinshifter <- mkReg(0);
   Reg#(FlowMessage) fcindata <- mkReg(0);

   // buffers for incoming messages

   FIFOF#(DataMessage) bufinhost <- mkSizedFIFOF(4);
   Vector#(numlinks, FIFOF#(DataMessage)) bufinlink = newVector; 

   for (Integer i = 0; i < numlinks; i = i + 1) 
   begin
     bufinlink[i] = mkSizedFIFOF#(4);
   end
   // XXX how to decode address?  Source routing? Node id?



















   interface NocNode tap;
   
      interface NocNodeIn in;
   
	 method Action frame(bit i );
	    frameinbit <= i ;
	 endmethod
   
	 method Action data( bit i );
	    datainbit <= i;
	 endmethod

      endinterface
   
      interface NocNodeOut out;
      
	 method bit frame();
	    return frameinbit;
	 endmethod
      
	 method bit data();
	    return dataoutwire;
	 endmethod
   
      endinterface
   
   endinterface

   interface Reg r;

      method Action _write(a v);
	 data <= pack(v);
      endmethod
   
      method a _read();
	 return(unpack(data));
      endmethod

   endinterface

endmodule

