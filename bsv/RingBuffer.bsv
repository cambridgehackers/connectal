typedef Bit#(40) Address;

interface RingInterface;
	  method Action set(RingBufferReg reg, Address addr);
	  method Address get(RingBufferReg reg);
endinterface

module mkRingBuffer(RingInterface);

	Reg#(Address) base <- mkReg;
	Reg#(Address) end <- mkReg;
	Reg#(Address) first <- mkReg;
	Reg#(Address) last <- mkReg;

	method Action set(RingBufferReg reg Address addr);
	  if (reg == RegBase) base <= addr;
	  else if (reg == RegEnd) end <= addr;
	  else if (reg == RegFirst) first <= addr;
	  else last <= addr;
	  endmethod
  
	  method Address get(RingBufferReg reg);
            return case(reg)
	    RegBase: base;
	    RegEnd: end;
	    RegFirst: first;
	    default: last;              
	    endmethod;
endmodule
