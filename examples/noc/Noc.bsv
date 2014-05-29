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

import SerialFIFO::*;
import NocNode::*;
import LinkHost::*;
import Connectable::*;
import StmtFSM::*;
import Vector::*;
import FIFOF::*;

interface NocIndication;
   method Action ack(Bit#(4) recvnode, Bit#(4) to, Bit#(32) message);
endinterface
      
interface NocRequest;
   method Action send(Bit#(4) sendnode, Bit#(4) to, Bit#(32) message);
endinterface


module mkNocRequest#(NocIndication indication)(NocRequest);
   
   SerialFIFO#(DataMessage) xxx <- mkSerialFIFO();
   Vector#(5, SerialFIFO#(DataMessage)) we <- replicateM( mkSerialFIFO );
   Vector#(5, SerialFIFO#(DataMessage)) ew <- replicateM( mkSerialFIFO );

   // discard traffic from loose ends
   rule discardeast;
      $display("we[4] discard %x", we[4].out.first);
      we[4].out.deq();
      endrule

   rule discardwest;
      $display("ew[0] discard %x", ew[0].out.first);
      ew[0].out.deq();
      endrule

   Vector#(4, NocNode) node;

    for (Bit#(4) i = 0; i < 4; i = i + 1)
    begin
        node[i] <- mkNocNode(unpack(i), 
	    SerialFIFO {in: ew[i+0].in, out: we[i+0].out},
	    SerialFIFO {in: we[i+1].in, out: ew[i+1].out});
    end


  
  // fsm to read from host ports and generate indications

  Reg#(Bit#(4)) id <- mkReg(0);

  Stmt readindications =
    seq
    while(True) seq
      for(id <= 0; id < 4; id <= id + 1)
          if (node[id].host.tohost.notEmpty())
	      seq
		 indication.ack(id, node[id].host.tohost.first.address,
	            node[id].host.tohost.first.payload);
		 node[id].host.tohost.deq();
              endseq
      endseq
    endseq;

    mkAutoFSM(readindications);
 
   method Action send(Bit#(4) sendnode, Bit#(4) to, Bit#(32) message);
      node[sendnode].host.tonet.enq(DataMessage{address: to, payload: message});
   endmethod
  
   
endmodule
