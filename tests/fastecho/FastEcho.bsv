// Copyright (c) 2017 Connectal Project

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

interface FastEchoIndicationA;
    method Action indication(Bit#(64) a, Bit#(64) b, Bit#(64) c, Bit#(64) d);
endinterface

interface FastEchoRequestA;
    method Action request(Bit#(64) a, Bit#(64) b, Bit#(64) c, Bit#(64) d);
endinterface

interface FastEchoIndicationB;
    method Action indication(Bit#(64) a, Bit#(64) b, Bit#(64) c, Bit#(64) d);
endinterface

interface FastEchoRequestB;
    method Action request(Bit#(64) a, Bit#(64) b, Bit#(64) c, Bit#(64) d);
endinterface

interface FastEchoIndicationC;
    method Action indication(Bit#(64) a, Bit#(64) b, Bit#(64) c, Bit#(64) d);
endinterface

interface FastEchoRequestC;
    method Action request(Bit#(64) a, Bit#(64) b, Bit#(64) c, Bit#(64) d);
endinterface

interface FastEchoIndicationD;
    method Action indication(Bit#(64) a, Bit#(64) b, Bit#(64) c, Bit#(64) d);
endinterface

interface FastEchoRequestD;
    method Action request(Bit#(64) a, Bit#(64) b, Bit#(64) c, Bit#(64) d);
endinterface

interface FastEcho;
   interface FastEchoRequestA requestA;
   interface FastEchoRequestB requestB;
   interface FastEchoRequestC requestC;
   interface FastEchoRequestD requestD;
endinterface

module mkFastEcho#(
            FastEchoIndicationA indicationA,
            FastEchoIndicationB indicationB,
            FastEchoIndicationC indicationC,
            FastEchoIndicationD indicationD
        )(FastEcho);
    Reg#(Bool)     validDataA <- mkReg(False);
    Reg#(Bit#(64)) aRegA      <- mkReg(0);
    Reg#(Bit#(64)) bRegA      <- mkReg(0);
    Reg#(Bit#(64)) cRegA      <- mkReg(0);
    Reg#(Bit#(64)) dRegA      <- mkReg(0);

    Reg#(Bool)     validDataB <- mkReg(False);
    Reg#(Bit#(64)) aRegB      <- mkReg(0);
    Reg#(Bit#(64)) bRegB      <- mkReg(0);
    Reg#(Bit#(64)) cRegB      <- mkReg(0);
    Reg#(Bit#(64)) dRegB      <- mkReg(0);

    Reg#(Bool)     validDataC <- mkReg(False);
    Reg#(Bit#(64)) aRegC      <- mkReg(0);
    Reg#(Bit#(64)) bRegC      <- mkReg(0);
    Reg#(Bit#(64)) cRegC      <- mkReg(0);
    Reg#(Bit#(64)) dRegC      <- mkReg(0);

    Reg#(Bool)     validDataD <- mkReg(False);
    Reg#(Bit#(64)) aRegD      <- mkReg(0);
    Reg#(Bit#(64)) bRegD      <- mkReg(0);
    Reg#(Bit#(64)) cRegD      <- mkReg(0);
    Reg#(Bit#(64)) dRegD      <- mkReg(0);

    rule sendIndicationA(validDataA);
        indicationA.indication(aRegA, bRegA, cRegA, dRegA);
        validDataA <= False;
    endrule
    rule sendIndicationB(validDataB);
        indicationB.indication(aRegB, bRegB, cRegB, dRegB);
        validDataB <= False;
    endrule
    rule sendIndicationC(validDataC);
        indicationC.indication(aRegC, bRegC, cRegC, dRegC);
        validDataC <= False;
    endrule
    rule sendIndicationD(validDataD);
        indicationD.indication(aRegD, bRegD, cRegD, dRegD);
        validDataD <= False;
    endrule

    interface FastEchoRequestA requestA;
        method Action request(Bit#(64) a, Bit#(64) b, Bit#(64) c, Bit#(64) d) if (!validDataA);
            validDataA <= True;
            aRegA <= a;
            bRegA <= b;
            cRegA <= c;
            dRegA <= d;
        endmethod
    endinterface
    interface FastEchoRequestB requestB;
        method Action request(Bit#(64) a, Bit#(64) b, Bit#(64) c, Bit#(64) d) if (!validDataB);
            validDataB <= True;
            aRegB <= a;
            bRegB <= b;
            cRegB <= c;
            dRegB <= d;
        endmethod
    endinterface
    interface FastEchoRequestC requestC;
        method Action request(Bit#(64) a, Bit#(64) b, Bit#(64) c, Bit#(64) d) if (!validDataC);
            validDataC <= True;
            aRegC <= a;
            bRegC <= b;
            cRegC <= c;
            dRegC <= d;
        endmethod
    endinterface
    interface FastEchoRequestD requestD;
        method Action request(Bit#(64) a, Bit#(64) b, Bit#(64) c, Bit#(64) d) if (!validDataD);
            validDataD <= True;
            aRegD <= a;
            bRegD <= b;
            cRegD <= c;
            dRegD <= d;
        endmethod
    endinterface
endmodule
