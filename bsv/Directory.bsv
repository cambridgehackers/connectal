// bsv libraries
import Vector::*;
import FIFO::*;
import RegFile::*;
import SpecialFIFOs::*;

//portz libraries
import Portal::*;
import AxiMasterSlave::*;

interface Directory#(numeric type _n, 
		     numeric type _a, 
		     numeric type _b, 
		     numeric type _c);
   interface Portal#(_n,_a,_b,_c) portalIfc;
   interface ReadOnly#(Bit#(64)) cycles;
   interface Vector#(3,WriteOnly#(Bit#(64))) writeIntervals;
   interface Vector#(3,WriteOnly#(Bit#(64))) readIntervals;
endinterface

typedef Directory#(16,32,32,12) StdDirectory;

module mkStdDirectoryPortalIfc#(RegFileA#(Bit#(32), Bit#(32)) rf)(StdPortal);
   Axi3Slave#(32,32,12) ctrl_mod <- mkAxi3SlaveFromRegFile(rf);
   method Bit#(32) ifcId();
      return 0;
   endmethod
   method Bit#(32) ifcType();
      return 0;
   endmethod
   interface Axi3Slave ctrl = ctrl_mod;
   interface ReadOnly interrupt;
      method Bool _read;
	 return False;
      endmethod
   endinterface
endmodule

module mkStdDirectory#(Vector#(n,StdPortal) portals) (StdDirectory);

   Vector#(3,Wire#(Bit#(64))) writeIntervalWires <- replicateM(mkDWire(64'hfecfecfecfec));
   Vector#(3,Wire#(Bit#(64))) readIntervalWires <- replicateM(mkDWire(64'hfecfecfecfec));

   function WriteOnly#(a) ww(Wire#(a) w);
      return (interface WriteOnly;
		 method Action _write(a x);
		    w <= x;
		 endmethod
	      endinterface);
   endfunction

   Reg#(Bit#(64)) cycle_count <- mkReg(0);
   Reg#(Bit#(32)) snapshot    <- mkReg(0);
   
   rule count;
      cycle_count <= cycle_count+1;
   endrule
   
   let rf = (interface RegFileA#(Bit#(32), Bit#(32));
		method Action upd(Bit#(32) addr, Bit#(32) data);
		   noAction;
		endmethod
		method ActionValue#(Bit#(32)) sub(Bit#(32) _addr);
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
		   else if (addr < cco+8) /* address in range [cco+2 .. cco+7] */ // read low order bits
      		      return truncate(append(readIntervalWires,writeIntervalWires)[addr-(cco+2)]);
		   else if (addr < cco+13) /* address in range [cco+8 .. cco+13] */ // read high order bits
      		      return truncate(append(readIntervalWires,writeIntervalWires)[addr-(cco+8)]>>32);
		   else begin
      		      $display("directory addr out bounds %d", addr);
		      return 0;
		   end
		endmethod
      	     endinterface);
   let ifc <- mkStdDirectoryPortalIfc(rf);
   interface StdPortal portalIfc = ifc;
   interface ReadOnly cycles = regToReadOnly(cycle_count);
   interface Vector writeIntervals = map(ww, writeIntervalWires);
   interface Vector readIntervals  = map(ww, readIntervalWires);

endmodule



