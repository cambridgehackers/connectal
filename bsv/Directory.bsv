
// Copyright (c) 2013-2014 Quanta Research Cambridge, Inc.

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

// bsv libraries
import Vector::*;
import FIFO::*;
import FIFOF::*;
import RegFile::*;
import SpecialFIFOs::*;
import GetPut::*;
import BRAM::*;
import Assert::*;

//portz libraries
import Portal::*;
import MemTypes::*;
import Ctrl2BRAM::*;

interface Directory#(numeric type _n,
		     numeric type _a, 
		     numeric type _d);
   interface MemPortal#(_a,_d) portalIfc;
endinterface

typedef Directory#(16,16,32) StdDirectory;

typedef 6 StartDirectoryOffset;

module mkStdDirectoryPortalIfc#(BRAMServer#(Bit#(16), Bit#(32)) br)(StdPortal);
   MemSlave#(16,32) ctrl <- mkCtrl2BRAM(br);
   method Bit#(32) ifcId();
      return 0;
   endmethod
   method Bit#(32) ifcType();
      return 0;
   endmethod
   interface MemSlave slave = ctrl;
   interface ReadOnly interrupt;
      method Bool _read;
	 return False;
      endmethod
   endinterface
endmodule

module mkStdDirectory#(Vector#(n,StdPortal) portals) (StdDirectory);

   Reg#(Bit#(64)) cycle_count <- mkReg(0);
   Reg#(Bit#(32))    snapshot <- mkReg(0);
   FIFOF#(Bit#(16))  addrFifo <- mkSizedFIFOF(1);
   FIFO#(Bit#(32))   dataFifo <- mkSizedFIFO(1);
   let startDirectoryOffset=valueOf(StartDirectoryOffset);
   
   let base = 128;
   
   rule count;
      cycle_count <= cycle_count+1;
   endrule
   
   
   rule req1;
      let addr = addrFifo.first;
      addrFifo.deq;
      let idx = (addr-fromInteger(startDirectoryOffset)-base);
      if (idx[0] == 0)
	 dataFifo.enq(portals[idx>>1].ifcId);
      else
	 dataFifo.enq(portals[idx>>1].ifcType);
   endrule
   
   let br = (interface BRAMServer#(Bit#(16), Bit#(32));
		interface Put request;
		   method Action put(BRAMRequest#(Bit#(16),Bit#(32)) req) if (!addrFifo.notEmpty);
		      if (!req.write) begin
      			 if (req.address == 0+base)
			    dataFifo.enq(2); // directory version
			 else if (req.address == 1+base)
			    dataFifo.enq(`TimeStamp);
			 else if (req.address == 2+base)
			    dataFifo.enq(fromInteger(valueOf(n)));
			 else if (req.address == 3+base)
			    dataFifo.enq(16); // portal Addr bits
			 else if (req.address == 4+base) begin
			    snapshot <= truncate(cycle_count);
			    dataFifo.enq(cycle_count[63:32]);
			 end
			 else if (req.address == 5+base)
			    dataFifo.enq(snapshot);
			 else begin
			    addrFifo.enq(truncate(req.address));
			 end
		      end
		   endmethod
		endinterface
		interface Get response;
		   method ActionValue#(Bit#(32)) get;
		      dataFifo.deq;
		      return dataFifo.first;
      		   endmethod
		endinterface
      	     endinterface);
   let ifc <- mkStdDirectoryPortalIfc(br);
   interface StdPortal portalIfc = ifc;
endmodule



