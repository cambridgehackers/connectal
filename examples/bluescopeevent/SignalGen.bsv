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

interface SignalGenIndication;
   method Action ack1(Bit#(32) d1);
   method Action ack2(Bit#(32) d1, Bit#(32) d2);
endinterface
      
interface SignalgenRequest;
   method Action send1(Bit#(32) d1);
   method Action send2(Bit#(32) d1, Bit#(32) d2);
endinterface


module mkSignalgenRequest#(method Action dataIn(Bit#(32)), SignalgenIndication indication)(Signalgen Request);
 
   method Action send1(Bit#(32) d1);
      dataIn(d1);
      indication.ack1(d1);
   endmethod
  
   method Action send2(Bit#(32) d1, Bit#(32) d2);
      dataIn(d1);
      dataIn(d2);
      indication.ack2(d1, d2);
   endmethod
   
endmodule
