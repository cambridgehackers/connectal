
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
import RegFile::*;
import SpecialFIFOs::*;

//Connectal libraries
import Portal::*;
import ConnectalMemTypes::*;
import RegFileA::*;

interface Directory#(numeric type _n,
		     numeric type _a, 
		     numeric type _d);
   interface Portal#(_a,_d) portalIfc;
endinterface

typedef Directory#(16,16,32) StdDirectory;

module mkStdDirectoryPortalIfc#(RegFileA#(Bit#(16), Bit#(32)) rf)(StdPortal);
   MemSlave#(16,32) ctrl <- mkMemSlaveFromRegFile(rf);
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
   Reg#(Bit#(32)) snapshot    <- mkReg(0);

   rule count;
      cycle_count <= cycle_count+1;
   endrule
   
   let rf = (interface RegFileA#(Bit#(16), Bit#(32));
		method Action upd(Bit#(16) addr, Bit#(32) data);
		   noAction;
		endmethod
		method ActionValue#(Bit#(32)) sub(Bit#(16) _addr);
		   let base = 128;
		   let cco = fromInteger(valueOf(TAdd#(TMul#(2,n),4)))+base;
		   let addr = _addr[15:0]; 
		   if (addr == 0+base)
		      return 1; // directory version
		   else if (addr == 1+base)
		      return `TimeStamp;
		   else if (addr == 2+base)
		      return fromInteger(valueOf(n));
		   else if (addr == 3+base)
		      return 16; // portal Addr bits
		   else if (addr < cco) begin
		      let idx = (addr-4-base);
		      if (idx[0] == 0)
		   	 return portals[idx>>1].ifcId;
		      else
		   	 return portals[idx>>1].ifcType;
		   end
		   else if (addr == cco) begin
		      snapshot <= truncate(cycle_count);
		      return cycle_count[63:32];
		   end
		   else if (addr == cco+1)
		      return snapshot;
		   else begin
      		      $display("directory addr out bounds %d", addr);
		      return 0;
		   end
		endmethod
      	     endinterface);
   let ifc <- mkStdDirectoryPortalIfc(rf);
   interface StdPortal portalIfc = ifc;
endmodule



