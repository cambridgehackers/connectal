
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

import FIFO::*;
import Leds::*;

interface Core0Indication;
    method Action heard(Bit#(32) v);
endinterface

interface Core0Request;
    method Action say(Bit#(32) v);
endinterface

interface Core1Indication;
    method Action heard(Bit#(32) v);
endinterface

interface Core1Request;
    method Action say(Bit#(32) v);
endinterface

interface Core2Indication;
    method Action heard(Bit#(32) v);
endinterface

interface Core2Request;
    method Action say(Bit#(32) v);
endinterface

interface Core3Indication;
    method Action heard(Bit#(32) v);
endinterface

interface Core3Request;
    method Action say(Bit#(32) v);
endinterface

interface QuadIndication;
    interface Core0Indication core0Indication;
    interface Core1Indication core1Indication;
    interface Core2Indication core2Indication;
    interface Core3Indication core3Indication;
endinterface

interface QuadRequest;
    interface Core0Request core0Request;
    interface Core1Request core1Request;
    interface Core2Request core2Request;
    interface Core3Request core3Request;
endinterface: QuadRequest

module mkQuadRequest#(QuadIndication indication)(QuadRequest);
    FIFO#(Bit#(32)) delay0 <- mkSizedFIFO(8);
    FIFO#(Bit#(32)) delay1 <- mkSizedFIFO(8);
    FIFO#(Bit#(32)) delay2 <- mkSizedFIFO(8);
    FIFO#(Bit#(32)) delay3 <- mkSizedFIFO(8);

    rule heard0;
        delay0.deq;
        indication.core0Indication.heard(delay0.first);
    endrule
   
   rule heard1;
        delay1.deq;
        indication.core1Indication.heard(delay1.first);
    endrule

    rule heard2;
        delay2.deq;
        indication.core2Indication.heard(delay2.first);
    endrule

    rule heard3;
        delay3.deq;
        indication.core3Indication.heard(delay3.first);
    endrule

    interface Core0Request core0Request;
	method Action say(Bit#(32) v);
	    delay0.enq(v);
	endmethod
    endinterface

    interface Core1Request core1Request;
	method Action say(Bit#(32) v);
	    delay1.enq(v);
	endmethod
    endinterface

    interface Core2Request core2Request;
	method Action say(Bit#(32) v);
	    delay2.enq(v);
	endmethod
    endinterface

    interface Core3Request core3Request;
	method Action say(Bit#(32) v);
	    delay3.enq(v);
	endmethod
    endinterface
       
endmodule
