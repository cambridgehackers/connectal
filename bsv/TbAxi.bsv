
// Copyright (c) 2012 Nokia, Inc.

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

import RegFile::*;
import FIFOF::*;
import AxiMasterSlave::*;
import FifoToAxi::*;
 
typedef enum {
        EnqWrites,
        WaitForWriteCompletion,
        WaitForReadCompletion,
        TestCompleted,
        Idle
} TbState deriving (Bits, Eq, Bounded, FShow);

interface AxiTester;
    method Action start(Bit#(32) base, Bit#(32) numWords);
    method ActionValue#(Bool) completed();
endinterface

module mkAxiTester#(FifoToAxi#(busWidth, busWidthBytes) fifoToAxi,
                    FifoFromAxi#(busWidth) fifoFromAxi,
                    Bit#(32) numWords)
                   (AxiTester);

    let verbose = False;
    Reg#(TbState) state <- mkReg(Idle);

    Reg#(Bit#(32)) writeAddrReg <- mkReg(0);
    Reg#(Bit#(32)) readAddrReg <- mkReg(0);

    Reg#(Bit#(32)) writeCountReg <- mkReg(0);
    Reg#(Bit#(32)) readCountReg <- mkReg(0);
    Reg#(Bit#(32)) numWordsReg <- mkReg(0);
    Reg#(Bit#(busWidth)) valueReg <- mkReg(13);

    RegFile#(Bit#(32), Bit#(busWidth)) testDataRegFile <- mkRegFile(0, numWords);

    rule enqTestData if (state == EnqWrites && writeCountReg < numWordsReg);
        let v = valueReg << 3 + 17;
        valueReg <= v;
        testDataRegFile.upd(writeAddrReg/fromInteger(valueOf(busWidthBytes)), v);
        writeAddrReg <= writeAddrReg + fromInteger(valueOf(busWidthBytes));
        if (writeCountReg == numWordsReg-1)
            state <= WaitForWriteCompletion;
        writeCountReg <= writeCountReg + 1;
        fifoToAxi.enq(v);
    endrule

    rule waitForWriteCompletion if (state == WaitForWriteCompletion && !fifoToAxi.notEmpty);
        $display("Writes Completed");
        state <= WaitForReadCompletion;
        fifoFromAxi.enabled <= True;
    endrule

    rule waitForReadCompletion if (state == WaitForReadCompletion && fifoFromAxi.notEmpty);
        let data = fifoFromAxi.first;
        fifoFromAxi.deq;
        let testData = testDataRegFile.sub(readAddrReg/fromInteger(valueOf(busWidthBytes)));
        readAddrReg <= readAddrReg + fromInteger(valueOf(busWidthBytes));

        if (verbose)
            $display("received read data %h %s", data,
                     (data == testData) ? "" : "mismatch");
        else if (data != testData)
            $display("mismatched data %h got %h expected %h", readAddrReg, data, testData);
        readCountReg <= readCountReg + 1;
        if (readCountReg == numWordsReg-1)
            state <= TestCompleted;
    endrule

    method Action start(Bit#(32) base, Bit#(32) numWords) if (state == Idle);
        $display("Starting");
        fifoToAxi.enabled <= True;
        fifoFromAxi.enabled <= False;
        writeAddrReg <= 0;
        readAddrReg <= 0;
        writeCountReg <= 0;
        readCountReg <= 0;
        valueReg <= 13;
        numWordsReg <= numWords;

        fifoToAxi.base <= base;
        fifoFromAxi.base <= base;
        fifoToAxi.bounds <= fifoToAxi.base + numWords*fromInteger(valueOf(busWidthBytes));
        fifoFromAxi.bounds <= fifoToAxi.base + numWords*fromInteger(valueOf(busWidthBytes));

        state <= EnqWrites;
    endmethod

    method ActionValue#(Bool) completed() if (state == TestCompleted);
        $display("Test Completed");

        fifoToAxi.enabled <= False;
        fifoFromAxi.enabled <= False;

        state <= Idle;
        return True;
    endmethod
endmodule

typedef enum {
        TbAxiStart,
        TbAxiRunning,
        TbAxiRunning2,
        TbAxiRunning3,
        TbAxiCompleted1,
        TbAxiCompleted2,
        TbAxiIdle
} TbAxiState deriving (Bits, Eq);

module mkTbAxi();

    Bool verbose = True;

    Bit#(32) numWords = 128;
    Bit#(32) busWidth = 64;
    Bit#(32) busWidthBytes = busWidth/8;

    AxiSlave#(64,8) axiSlave <- mkAxiSlaveRegFile;
    FifoToAxi#(64,8) fifoToAxi <- mkFifoToAxi();
    FifoFromAxi#(64) fifoFromAxi <- mkFifoFromAxi();
    mkMasterSlaveConnection(fifoToAxi.axi, fifoFromAxi.axi, axiSlave);

    AxiTester axiTester <- mkAxiTester(fifoToAxi, fifoFromAxi, numWords);

    Reg#(TbAxiState) state <- mkReg(TbAxiStart);

    rule testStart if (state == TbAxiStart);
        state <= TbAxiRunning;

        axiTester.start(0, numWords);
    endrule

    rule testCompleted1 if (state == TbAxiRunning);
        let v <- axiTester.completed;
        $display("Test 1 Completed");
        state <= TbAxiCompleted1;
    endrule
    rule testStart2 if (state == TbAxiCompleted1);
        axiTester.start(0, numWords);    
        state <= TbAxiRunning2;
    endrule

    rule testCompleted2 if (state == TbAxiRunning2);
        let v <- axiTester.completed;
        $display("Test 2 Completed");
        state <= TbAxiCompleted2;
    endrule

    rule testStart3 if (state == TbAxiCompleted2);
        axiTester.start(0, numWords);
        state <= TbAxiRunning3;
    endrule

    rule testCompleted3 if (state == TbAxiRunning3);
        let v <- axiTester.completed;
        $display("Test 3 Completed");
        state <= TbAxiIdle;
    endrule

endmodule
