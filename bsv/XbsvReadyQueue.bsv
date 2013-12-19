import Vector::*;
import Assert::*;
import StmtFSM::*;

interface ReadyQueue#(type nports, type tagtype, type priotype);
   interface ReadOnly#(Tuple2#(tagtype, priotype)) maxPriorityRequest;
   interface Vector#(nports, Reg#(Bool)) readyBits;
endinterface

module mkFirstReadyQueue(ReadyQueue#(nports,Bit#(tagtypesz),Bit#(priotypesz)))
   provisos (Add#(1,s,nports));

    Vector#(nports, Reg#(Bool)) readyBitsRegs <- replicateM(mkReg(False));

    function Tuple2#(Bit#(tagtypesz), Bit#(priotypesz)) getMaxPriorityRequest();
       Vector#(nports, Bit#(tagtypesz)) idxs = genWith(fromInteger);
       function Bit#(priotypesz) ready2Prio(Reg#(Bool) r);
	  return r._read ? 1 : 0;
       endfunction
       function Tuple2#(Bit#(tagtypesz),Bit#(priotypesz)) maxreq(Tuple2#(Bit#(tagtypesz),Bit#(priotypesz)) a, Tuple2#(Bit#(tagtypesz),Bit#(priotypesz)) b);
	  if (tpl_2(a) != 0)
             return a;
          else
             return b;
       endfunction
       return fold(maxreq, zip(idxs, map(ready2Prio,readyBitsRegs)));
    endfunction

   interface readyBits = readyBitsRegs;

   interface ReadOnly maxPriorityRequest;
      method Tuple2#(Bit#(tagtypesz), Bit#(priotypesz)) _read;
	 return getMaxPriorityRequest;
      endmethod
   endinterface

endmodule

module mkPriorityQueue(ReadyQueue#(nports,Bit#(tagtypesz),Bit#(priotypesz)))
   provisos (Add#(1,s,nports));
    Reg#(Vector#(nports, Bit#(priotypesz))) priorities <- mkReg(replicate(0));
    Vector#(nports, Reg#(Bool)) readyBitsRegs <- replicateM(mkReg(False));

    function Bit#(priotypesz) maxPriority(); return fold(max, priorities); endfunction

    function Tuple2#(Bit#(tagtypesz), Bit#(priotypesz)) getMaxPriorityRequest();
        function Bit#(tagtypesz) channelNumber(Integer i); UInt#(tagtypesz) c = fromInteger(i); return pack(c); endfunction
        Vector#(nports, Bit#(tagtypesz)) requests = genWith(channelNumber);
        function Tuple2#(Bit#(tagtypesz),Bit#(priotypesz)) maxreq(Tuple2#(Bit#(tagtypesz),Bit#(priotypesz)) a, Tuple2#(Bit#(tagtypesz),Bit#(priotypesz)) b);
           if (tpl_2(a) > tpl_2(b))
               return a;
           else
               return b;
        endfunction
        return fold(maxreq, zip(requests, priorities));
    endfunction

   Reg#(Tuple2#(Bit#(tagtypesz),Bit#(priotypesz))) maxPriorityRequestReg <- mkReg(tuple2(0,0));

    rule updatePriorities;
       function Bit#(a) add(Bit#(a) x, Bit#(a) y); return x + y; endfunction

       function Bit#(priotypesz) newPrio(Tuple2#(Bit#(priotypesz), Reg#(Bool)) pair);
           if (tpl_2(pair)._read && tpl_1(pair) == 0)
	      return 1;
	   else
	      return 0;
       endfunction

       Vector#(nports, Tuple2#(Bit#(priotypesz), Reg#(Bool))) zipped = zip(priorities, readyBitsRegs);
       Bit#(priotypesz) numNewRequests = fold(add, map(newPrio, zipped));

       function Bit#(priotypesz) updatePrio(Tuple2#(Bit#(priotypesz), Reg#(Bool)) pair);
	  Bool b = tpl_2(pair)._read;
	  if (b) begin
	     let v = tpl_1(pair);
	     if (v == 0)
		return 1;
	     else
		return v + numNewRequests;
	  end
	  else begin
	     return 0;
	  end
       endfunction
       priorities <= map(updatePrio, zipped);
       $display("priorities=%h numNewRequests=%d", priorities, numNewRequests);
    endrule
    rule updateMaxPriorityRequest;
        maxPriorityRequestReg <= getMaxPriorityRequest();
    endrule
   
   interface readyBits = readyBitsRegs;
   interface maxPriorityRequest = regToReadOnly(maxPriorityRequestReg);
endmodule

module mkRQTB(Empty);
   ReadyQueue#(4, Bit#(4), Bit#(4)) pq <- mkFirstReadyQueue;
   function Vector#(4, Bool) readyBools();
      function Bool readReg(Reg#(Bool) r); return r._read; endfunction
      return map(readReg, pq.readyBits);
   endfunction
   
   mkAutoFSM(
      seq
         pq.readyBits[1] <= True;
	 $display("readyBits %h max prio req %h %h", readyBools(), tpl_1(pq.maxPriorityRequest), tpl_2(pq.maxPriorityRequest));
         pq.readyBits[1] <= False;
	 $display("readyBits %h max prio req %h %h", readyBools(), tpl_1(pq.maxPriorityRequest), tpl_2(pq.maxPriorityRequest));
	 pq.readyBits[3] <= True;
	 $display("readyBits %h max prio req %h %h", readyBools(), tpl_1(pq.maxPriorityRequest), tpl_2(pq.maxPriorityRequest));
	 par
	    pq.readyBits[0] <= True;
	    pq.readyBits[2] <= True;
	 endpar
	 $display("readyBits %h max prio req %h %h", readyBools(), tpl_1(pq.maxPriorityRequest), tpl_2(pq.maxPriorityRequest));
	 pq.readyBits[0] <= False;
	 $display("readyBits %h max prio req %h %h", readyBools(), tpl_1(pq.maxPriorityRequest), tpl_2(pq.maxPriorityRequest));
	 pq.readyBits[2] <= False;
	 $display("readyBits %h max prio req %h %h", readyBools(), tpl_1(pq.maxPriorityRequest), tpl_2(pq.maxPriorityRequest));
	 pq.readyBits[3] <= False;
	 $display("readyBits %h max prio req %h %h", readyBools(), tpl_1(pq.maxPriorityRequest), tpl_2(pq.maxPriorityRequest));
	 $display("readyBits %h max prio req %h %h", readyBools(), tpl_1(pq.maxPriorityRequest), tpl_2(pq.maxPriorityRequest));
	 $display("readyBits %h max prio req %h %h", readyBools(), tpl_1(pq.maxPriorityRequest), tpl_2(pq.maxPriorityRequest));
	 $finish(0);
      endseq
      );
endmodule
