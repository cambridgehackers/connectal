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
import Connectable::*;
import StmtFSM::*;
import Vector::*;
import FIFOF::*;
import Pipe::*;

interface NocIndication;
   method Action ack(Bit#(8) recvnode, Bit#(8) to, Bit#(32) message);
endinterface
      
interface NocRequest;
   method Action send(Bit#(8) sendnode, Bit#(8) to, Bit#(32) message);
endinterface

module mkPipeOutDiscard#(PipeOut#(Bit#(1)) x)(Empty);
   rule toss;
      x.deq();
   endrule
endmodule



module mkNocRequest#(NocIndication indication)(NocRequest);
   
  
   Vector#(4, Vector#(4, NocNode#(2))) node = replicate(newVector);

   for (Bit#(4) x = 0; x < 4; x = x + 1)
      for (Bit#(4) y = 0; y < 4; y = y + 1)
	 begin
	    Vector#(2, Bit#(4)) id = newVector;
	    id[0] = x;
	    id[1] = y;
	    node[x][y] <- mkNocNode(id);
	 end

   // wire up the links in the x direction
   Vector#(3, Integer) indexes3 = genVector();
   Vector#(4, Integer) indexes4 = genVector();
   module mkXLinks#(Integer x)(Empty);
      module mkXLink#(Integer x, Integer y)(Empty);
	 mkConnection(node[x][y].linkupout[0], node[x+1][y].linkdownin[0]);
	 mkConnection(node[x+1][y].linkdownout[0], node[x][y].linkupin[0]);
      endmodule
      mapM_(mkXLink(x), indexes4);
   endmodule

   mapM_(mkXLinks, indexes3);

   // wire up the links in the y direction
   
   module mkYLinks#(Integer y)(Empty);
   module mkYLink#(Integer y, Integer x)(Empty);
      mkConnection(node[x][y].linkupout[1], node[x][y+1].linkdownin[1]);
      mkConnection(node[x][y+1].linkdownout[1], node[x][y].linkupin[1]);
   endmodule
      mapM_(mkYLink(y), indexes4);
   endmodule
   mapM_(mkYLinks, indexes3);

   // discard traffic from loose ends in y direction
   for (Bit#(4) x = 0; x < 4; x = x + 1)
      begin
	 mkPipeOutDiscard(node[x][0].linkdownout[1]);
	 mkPipeOutDiscard(node[x][3].linkupout[1]);
      end
   // discard traffic from loose ends in x direction
   for (Bit#(4) y = 0; y < 4; y = y + 1)
      begin
	 mkPipeOutDiscard(node[0][y].linkdownout[0]);
	 mkPipeOutDiscard(node[3][y].linkupout[0]);
      end
   
  // fsm to read from host ports and generate indications

  Reg#(Bit#(4)) idx <- mkReg(0);
  Reg#(Bit#(4)) idy <- mkReg(0);

  Stmt readindications =
    seq
    while(True) seq
      for(idx <= 0; idx < 4; idx <= idx + 1)
	 for(idy <= 0; idy < 4; idy <= idy + 1)
            if (node[idx][idy].nodetohost.notEmpty())
	      seq
		 $display("recv at [%d,%d] to [%d,%d] m %x", 
		    idx,idy,
		    node[idx][idy].nodetohost.first.address[0],
		    node[idx][idy].nodetohost.first.address[1],
	            node[idx][idy].nodetohost.first.payload);
		 indication.ack((zeroExtend(idx)<<4) + zeroExtend(idy), 
		    (zeroExtend(node[idx][idy].nodetohost.first.address[0])<<4)+
		    zeroExtend(node[idx][idy].nodetohost.first.address[1]),
	            node[idx][idy].nodetohost.first.payload);
		 node[idx][idy].nodetohost.deq();
              endseq
      endseq
    endseq;

    mkAutoFSM(readindications);
 
   method Action send(Bit#(8) sendnode, Bit#(8) to, Bit#(32) message);
      Vector#(2,Bit#(4)) id = newVector;
      Vector#(2,Bit#(4)) dest = newVector;
      id[0] = sendnode[7:4];
      id[1] = sendnode[3:0];
      dest[0] = to[7:4];
      dest[1] = to[3:0];
      $display("send f %x t %x m %x", sendnode, to, message);
      node[id[0]][id[1]].hosttonode.enq(DataMessage{address: dest, payload: message});
   endmethod
  
   
endmodule
