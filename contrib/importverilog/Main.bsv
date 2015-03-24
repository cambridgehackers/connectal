
// Copyright (c) 2013 Nokia, Inc.

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

import FIFOF::*;
import RegFile::*;
import Clocks::*;
import DefaultValue::*;
import StmtFSM::*;

interface MainRequest;
    method Action write_rf(Bit#(16) address, Bit#(16) data);
    method Action read_rf(Bit#(16) address, Bit#(16) data);
endinterface

interface Main;
   interface MainRequest request;
endinterface

typedef struct{
   Bit#(2) address;
   Bit#(8) data;
   } RFItem deriving (Bits);


module mkMain#(MainRequest indication)(Main);
   let verbose = False;
   Clock defaultClock <- exposeCurrentClock();

   Reset defaultReset <- exposeCurrentReset();
   RegFile rf <- mkRegFile(defaultClock, defaultReset, defaultReset);
   FIFOF#(RFItem) read_item <- mkSizedFIFOF(2);

   // The purpose of this state machine is to read
   
   Stmt handleRead =
   seq
      while(True)
   seq
      if (read_item.notEmpty())
	 seq
	    rf.read.address(zeroExtend(read_item.first().address));
	    action
	       read_item.deq();
	       indication.read_rf(zeroExtend(read_item.first().address), zeroExtend(rf.read.data()));
	    endaction
	 endseq
      endseq
   endseq;
   
  mkAutoFSM(handleRead);
   
   interface MainRequest request;

   method Action write_rf(Bit#(16) address, Bit#(16) data);
      if (verbose) $display("mkMain::write_rf");
      rf.write.address(truncate(address));
      rf.write.data(truncate(data));
      rf.write.en(1);
      indication.write_rf(address, data);
   endmethod

   method Action read_rf(Bit#(16) address, Bit#(16) data);
      if (verbose) $display("mkMain::read_rf");
      read_item.enq(RFItem{address:truncate(address), data:0});
    endmethod

   endinterface
endmodule
