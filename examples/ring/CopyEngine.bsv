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

import FIFOF::*;
import GetPutF::*;
import Dma::*;
import RingTypes::*;
import StmtFSM::*;

// The interface to the copyengine is a pair of fifos which supply and accept
// blocks of 8 64 bit words
// A Command:
//  word 0: COPY[63:56] TAG[31:0]
//  word 1: readMemHandle[63:32]
//  word 1: readAddress[23:0]
//  word 2  writeMemHandle[63:32]
//  word 2: writeAddress[23:0]
//  word 3: bytecount[15:0]
//  word 4-7 unused
// Status
//  word0-6 all 0
//  word7  TAG[31:0]

module mkCopyEngine#(DmaReadServer#(64) copy_read_chan, DmaWriteServer#(64) copy_write_chan) ( ServerF#(Bit#(64), Bit#(64)));
   FIFOF#(Bit#(64)) f_in  <- mkSizedFIFOF(16);    // to buffer incoming requests
   FIFOF#(Bit#(64)) f_out <- mkSizedFIFOF(16);    // to buffer outgoing responses
   Reg#(Bit#(16)) copyReadCount <- mkReg(0);
   Reg#(Bit#(16)) copyWriteCount <- mkReg(0);
   Reg#(Bit#(DmaAddrSize)) copyReadAddr <- mkReg(0);
   Reg#(Bit#(DmaAddrSize)) copyWriteAddr <- mkReg(0);
   Reg#(DmaPointer) copyReadHandle <- mkReg(0);
   Reg#(DmaPointer) copyWriteHandle <- mkReg(0);
   Reg#(Bit#(32)) copyTag <- mkReg(0);
   Reg#(Bool) copyBusy <- mkReg(False);
   Reg#(Bit#(4)) cmdCtr <- mkReg(0);
   Stmt copyStart = 
   seq
      while(True)
	 seq
	    while (copyBusy) noAction;
	    for (cmdCtr <= 0; cmdCtr < 8; cmdCtr <= cmdCtr + 1) 
	       action
		  $display("COPY %h %h", cmdCtr, f_in.first());
		  f_in.deq();
	       endaction
	    
	    /*
	    action
	       copyTag <= f_in.first()[31:0];
	       f_in.deq();  // word 0
	    endaction
	    action
	       copyReadHandle <= f_in.first()[63:32];
	       copyReadAddr <= f_in.first()[23:0];
	       f_in.deq();  // word 1
	    endaction
	    action
	       copyWriteHandle <= f_in.first()[63:32];
	       copyWriteAddr <= f_in.first()[23:0];
	       f_in.deq();  // word 2
	    endaction
	    action
	       copyReadCount <= f_in.first()[15:0];
	       copyWriteCount <= f_in.first()[15:0];
	       f_in.deq();  // word 3
	    endaction
	       f_in.deq;  // discard words 4-7
	       f_in.deq;  // discard words 4-7
	       f_in.deq;  // discard words 4-7
	       f_in.deq;  // discard words 4-7
	    $display("copyStart from %h to %h count %h",
	       copyReadAddr, copyWriteAddr, copyReadCount);
	    copyBusy <= True;
	     */
	 endseq
   endseq;
      
    rule copyReadRule (copyBusy && (copyReadCount != 0));
       $display("copyRead %h, count %h", copyReadAddr, copyReadCount);
       copy_read_chan.readReq.put(DmaRequest{handle: copyReadHandle, address: copyReadAddr, burstLen: 1, tag: copyReadAddr[8:3]});
       copyReadAddr <= copyReadAddr + 8;
       copyReadCount <= copyReadCount - 8;
    endrule
    
    rule copyReadWriteRule (copyBusy);
       let data <- copy_read_chan.readData.get;
       $display("copyReadWrite addr %h", copyWriteAddr);
       copy_write_chan.writeReq.put(DmaRequest{handle: copyWriteHandle, address: copyWriteAddr, burstLen: 1, tag: copyWriteAddr[8:3]});
       copy_write_chan.writeData.put(DmaData{data: data.data, tag: copyWriteAddr[8:3]});
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
		  $display("copyWriteAck");
		  copyWriteCount <= copyWriteCount - 8;	 
	       endaction
	    f_out.enq(0);
	    f_out.enq(0);
	    f_out.enq(0);
	    f_out.enq(0);
	    f_out.enq(0);
	    f_out.enq(0);
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

