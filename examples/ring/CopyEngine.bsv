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
import GetPut::*;
import ClientServer::*;
import PortalRMemory::*;
import RingTypes::*;

module mkCopyEngine#(ReadChan#(Bit#(64)) copy_read_chan, WriteChan#(Bit#(64)) copy_write_chan) ( Server#(CommandStruct, Bit#(32)));
    FIFO#(CommandStruct) f_in  <- mkFIFO;    // to buffer incoming requests
    FIFO#(Bit#(32)) f_out <- mkFIFO;    // to buffer outgoing responses
    Reg#(Bit#(16)) copyReadCount <- mkReg(0);
    Reg#(Bit#(16)) copyWriteCount <- mkReg(0);
    Reg#(Bit#(40)) copyReadAddr <- mkReg(0);
    Reg#(Bit#(40)) copyWriteAddr <- mkReg(0);
    Reg#(Bit#(32)) copyTag <- mkReg(0);
    Reg#(Bool) copyBusy <- mkReg(False);
    
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
    
    rule copyWriteCompleteRule (copyBusy);
       let v <- copy_write_chan.writeDone.get;
       $display("copyWrite count %h", copyWriteCount);
       if (copyWriteCount == 8) begin
	  copyBusy <= False;
	  f_out.enq(copyTag);
       end
       copyWriteCount <= copyWriteCount - 8;
    endrule
    
    rule copyStart (!copyBusy);
       let cmd = f_in.first;
       $display("doCopy %h %h %h", cmd.fromAddress, cmd.toAddress, cmd.count);
       copyReadAddr <= cmd.fromAddress;
       copyWriteAddr <= cmd.toAddress;
       copyReadCount <= cmd.count;
       copyWriteCount <= cmd.count;
       copyTag <= cmd.tag;
       copyBusy <= True;
       f_in.deq();
    endrule
   
   interface Put request = toPut(f_in);
   interface Get response = toGet (f_out);
endmodule: mkCopyEngine

