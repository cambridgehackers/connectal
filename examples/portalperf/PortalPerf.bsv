
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

interface SwallowRequest;
   method Action swallowl(Bit#(32) v1);
   method Action swallowll(Bit#(32) v1, Bit#(32) v2);
   method Action swallowlll(Bit#(32) v1, Bit#(32) v2, Bit#(32) v3);
   method Action swallowllll(Bit#(32) v1, Bit#(32) v2, Bit#(32) v3, Bit#(32) v4);
   method Action swallowd(Bit#(64) v1);
   method Action swallowdd(Bit#(64) v1, Bit#(64) v2);
   method Action swallowddd(Bit#(64) v1, Bit#(64) v2, Bit#(64) v3);
   method Action swallowdddd(Bit#(64) v1, Bit#(64) v2, Bit#(64) v3, Bit#(64) v4);
   method Action dospitl();
   method Action dospitll();
   method Action dospitlll();
   method Action dospitllll();
   method Action dospitd();
   method Action dospitdd();
   method Action dospitddd();
   method Action dospitdddd();
endinterface


interface SwallowIndication;
   method Action spitl(Bit#(32) v1);
   method Action spitll(Bit#(32) v1, Bit#(32) v2);
   method Action spitlll(Bit#(32) v1, Bit#(32) v2, Bit#(32) v3);
   method Action spitllll(Bit#(32) v1, Bit#(32) v2, Bit#(32) v3, Bit#(32) v4);
   method Action spitd(Bit#(64) v1);
   method Action spitdd(Bit#(64) v1, Bit#(64) v2);
   method Action spitddd(Bit#(64) v1, Bit#(64) v2, Bit#(64) v3);
   method Action spitdddd(Bit#(64) v1, Bit#(64) v2, Bit#(64) v3, Bit#(64) v4);
endinterface


module mkSwallow#(SwallowIndication indication) (SwallowRequest);

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

   method Action swallowl(Bit#(32) v1);
      sinkl1 <= v1;
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

   method Action swallowd(Bit#(64) v);
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

   method Action dospitl();
      indication.spitl(sinkl1);
   endmethod

   method Action dospitll();
      indication.spitll(sinkll1, sinkll2);
   endmethod

   method Action dospitlll();
      indication.spitlll(sinklll1, sinklll2, sinklll3);
   endmethod

   method Action dospitllll();
      indication.spitlll(sinkllll1, sinkllll2, sinkllll3, sinklll4);
   endmethod

   method Action dospitd();
      indication.spitd(sinkd1);
   endmethod

   method Action dospitdd();
      indication.spitdd(sinkdd1, sinkdd2);
   endmethod

   method Action dospitddd();
      indication.spitddd(sinkddd1, sinkddd2, sinkddd3);
   endmethod

   method Action dospitdddd();
      indication.spitdddd(sinkdddd1, sinkdddd2, sinkdddd3, sinkdddd4);
   endmethod


endmodule
