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
import GetPutF::*;
import PortalRMemory::*;
import RingTypes::*;
import StmtFSM::*;

// The interface to the copyengine is a pair of fifos which supply and accept
// blocks of 8 64 bit words
// A Command:
//  word 0: COPY[63:56] TAG[31:0]
//  word 1: readAddress[39:0]
//  word 2: writeAddress[39:0]
//  word 3: bytecount[15:0'
//  word 4-7 unused
// Status
//  word0-6 all 0
//  word7  TAG[31:0]

module mkCopyEngine#(DMAReadServer#(64) copy_read_chan, DMAWriteServer#(64) copy_write_chan) ( ServerF#(Bit#(64), Bit#(64)));
   FIFO#(Bit#(64)) f_in  <- mkSizedFIFO(16);    // to buffer incoming requests
   FIFO#(Bit#(64)) f_out <- mkSizedFIFO(16);    // to buffer outgoing responses
   Reg#(Bit#(16)) copyReadCount <- mkReg(0);
   Reg#(Bit#(16)) copyWriteCount <- mkReg(0);
   Reg#(Bit#(40)) copyReadAddr <- mkReg(0);
   Reg#(Bit#(40)) copyWriteAddr <- mkReg(0);
   Reg#(Bit#(32)) copyTag <- mkReg(0);
   Reg#(Bool) copyBusy <- mkReg(False);
    
   Stmt copyStart = 
   seq
      while(True)
	 seq
	    while (copyBusy) noAction;
	    copyTag <= f_in.first()[31:0];
	    f_in.deq();
	    copyReadAddr <= f_in.first()[39:0];
	    f_in.deq();
	    copyWriteAddr <= f_in.first()[39:0];
	    f_in.deq();
	    action
	       copyReadCount <= f_in.first()[15:0];
	       copyWriteCount <= f_in.first()[15:0];
	       f_in.deq();
	    endaction
	    for (ii <= 0; ii < 4; ii <= ii+1)
	       f_in.deq;
	    copyBusy <= True;
	 endseq
   endseq;
      
    rule copyReadRule (copyBusy && (copyReadCount != 0));
       $display("copyRead %h, count %h", copyReadAddr, copyReadCount);
       copy_read_chan.readReq.put(copyReadAddr);
       copyReadAddr <= copyReadAddr + 8;
       copyReadCount <= copyReadCount - 8;
    endrule
    
    rule copyReadWriteRule (copyBusy);
       let data <- copy_read_chan.readData.get;
       $display("copyReadWrite addr %h", copyWriteAddr);
       copy_write_chan.writeReq.put(copyWriteAddr);
       copy_write_chan.writeData.put(data);
       copyWriteAddr <= copyWriteAddr + 8;
    endrule
    
   Stmt copyFinish = 
   seq
      while(True)
	 seq
	    while (!copyBusy) noAction;
	    while (copyWriteCount > 0)
	       action
		  let v <- copy_write_chan.writeDone.get;
		  copyWriteCount <= copyWriteCount - 8;	 
	       endaction
	    for (ii <= 0; ii < 7; ii <= ii + 1)
	       f_out.enq(0);
	    f_out.enq(extend(copyTag));
	    copyBusy <= False;
	 endseq
   endseq;
      
   mkAutoFSM(copyStart);
   mkAutoFSM(copyFinish);
   
   interface PutF request = toPutF(f_in);
   interface GetF response = toGetF (f_out);
   
endmodule: mkCopyEngine

