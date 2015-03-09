
// Copyright (c) 2013 Nokia, Inc.
// Copyright (c) 2013 Quanta Research Cambridge, Inc.

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

import Repeat::*;
import Vector::*;

interface PortalPerfRequest;
   method Action swallow();
   method Action swallowl(Bit#(32) v1);
   method Action swallowll(Bit#(32) v1, Bit#(32) v2);
   method Action swallowlll(Bit#(32) v1, Bit#(32) v2, Bit#(32) v3);
   method Action swallowllll(Bit#(32) v1, Bit#(32) v2, Bit#(32) v3, Bit#(32) v4);
   method Action swallowd(Bit#(64) v1);
   method Action swallowdd(Bit#(64) v1, Bit#(64) v2);
   method Action swallowddd(Bit#(64) v1, Bit#(64) v2, Bit#(64) v3);
   method Action swallowdddd(Bit#(64) v1, Bit#(64) v2, Bit#(64) v3, Bit#(64) v4);
   method Action startspit(Bit#(16) spitType, Bit#(16) loops);
endinterface


interface PortalPerfIndication;
   method Action spit();
   method Action spitl(Bit#(32) v1);
   method Action spitll(Bit#(32) v1, Bit#(32) v2);
   method Action spitlll(Bit#(32) v1, Bit#(32) v2, Bit#(32) v3);
   method Action spitllll(Bit#(32) v1, Bit#(32) v2, Bit#(32) v3, Bit#(32) v4);
   method Action spitd(Bit#(64) v1);
   method Action spitdd(Bit#(64) v1, Bit#(64) v2);
   method Action spitddd(Bit#(64) v1, Bit#(64) v2, Bit#(64) v3);
   method Action spitdddd(Bit#(64) v1, Bit#(64) v2, Bit#(64) v3, Bit#(64) v4);
endinterface



module mkPortalPerfRequest#(PortalPerfIndication indication) (PortalPerfRequest);
   
   Reg#(Bit#(32)) sinkl1 <- mkReg(0);

   Reg#(Bit#(32)) sinkll1 <- mkReg(0);
   Reg#(Bit#(32)) sinkll2 <- mkReg(0);

   Reg#(Bit#(32)) sinklll1 <- mkReg(0);
   Reg#(Bit#(32)) sinklll2 <- mkReg(0);
   Reg#(Bit#(32)) sinklll3 <- mkReg(0);

   Reg#(Bit#(32)) sinkllll1 <- mkReg(0);
   Reg#(Bit#(32)) sinkllll2 <- mkReg(0);
   Reg#(Bit#(32)) sinkllll3 <- mkReg(0);
   Reg#(Bit#(32)) sinkllll4 <- mkReg(0);
   
   Reg#(Bit#(64)) sinkd1 <- mkReg(0);
   
   Reg#(Bit#(64)) sinkdd1 <- mkReg(0);
   Reg#(Bit#(64)) sinkdd2 <- mkReg(0);
   
   Reg#(Bit#(64)) sinkddd1 <- mkReg(0);
   Reg#(Bit#(64)) sinkddd2 <- mkReg(0);
   Reg#(Bit#(64)) sinkddd3 <- mkReg(0);
   
   Reg#(Bit#(64)) sinkdddd1 <- mkReg(0);
   Reg#(Bit#(64)) sinkdddd2 <- mkReg(0);
   Reg#(Bit#(64)) sinkdddd3 <- mkReg(0);
   Reg#(Bit#(64)) sinkdddd4 <- mkReg(0);
   

   function Action dospit();
      return  
	 action 
	 indication.spit(); 
	 endaction 
	 ;
   endfunction

   function Action dospitl();
      return ( action 
	 indication.spitl(sinkl1);
	 endaction );
   endfunction

   function Action dospitll();
      return ( action 
	 indication.spitll(sinkll1, sinkll2);
	 endaction );
   endfunction

   function Action dospitlll();
      return ( action 
	 indication.spitlll(sinklll1, sinklll2, sinklll3);
	 endaction );
   endfunction

   function Action dospitllll();
      return ( action 
	 indication.spitllll(sinkllll1, sinkllll2, sinkllll3, sinkllll4);
	 endaction );
   endfunction

   function Action dospitd();
      return ( action 
	 indication.spitd(sinkd1);
	 endaction );
   endfunction

   function Action dospitdd();
      return ( action 
	 indication.spitdd(sinkdd1, sinkdd2);
	 endaction );
   endfunction

   function Action dospitddd();
      return ( action 
	 indication.spitddd(sinkddd1, sinkddd2, sinkddd3);
	 endaction );
   endfunction

   function Action dospitdddd();
      return ( action 
	 indication.spitdddd(sinkdddd1, sinkdddd2, sinkdddd3, sinkdddd4);
	 endaction );
   endfunction

   Vector#(9, Repeat) rfns = ?;
   rfns[0] <- mkRepeat(dospit);
   rfns[1] <- mkRepeat(dospitl);
   rfns[2] <- mkRepeat(dospitll);
   rfns[3] <- mkRepeat(dospitlll);
   rfns[4] <- mkRepeat(dospitllll);
   rfns[5] <- mkRepeat(dospitd);
   rfns[6] <- mkRepeat(dospitdd);
   rfns[7] <- mkRepeat(dospitddd);
   rfns[8] <- mkRepeat(dospitdddd);

   method Action swallowl(Bit#(32) v1);
      sinkl1 <= v1;
   endmethod

   method Action swallow();
   endmethod

   method Action swallowll(Bit#(32) v1, Bit#(32) v2);
      sinkll1 <= v1;
      sinkll2 <= v2;
   endmethod

   method Action swallowlll(Bit#(32) v1, Bit#(32) v2, Bit#(32) v3);
      sinklll1 <= v1;
      sinklll2 <= v2;
      sinklll3 <= v3;
   endmethod

   method Action swallowllll(Bit#(32) v1, Bit#(32) v2, Bit#(32) v3, Bit#(32) v4);
      sinkllll1 <= v1;
      sinkllll2 <= v2;
      sinkllll3 <= v3;
      sinkllll4 <= v4;
   endmethod

   method Action swallowd(Bit#(64) v1);
      sinkd1 <= v1;
   endmethod

   method Action swallowdd(Bit#(64) v1, Bit#(64) v2);
      sinkdd1 <= v1;
      sinkdd2 <= v2;
   endmethod

   method Action swallowddd(Bit#(64) v1, Bit#(64) v2, Bit#(64) v3);
      sinkddd1 <= v1;
      sinkddd2 <= v2;
      sinkddd3 <= v3;
   endmethod

   method Action swallowdddd(Bit#(64) v1, Bit#(64) v2, Bit#(64) v3, Bit#(64) v4
      );
      sinkdddd1 <= v1;
      sinkdddd2 <= v2;
      sinkdddd3 <= v3;
      sinkdddd4 <= v4;
   endmethod

   method Action startspit(Bit#(16) spitType, Bit#(16) loops);
      rfns[spitType].start(loops);
   endmethod

endmodule