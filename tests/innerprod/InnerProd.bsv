
import GetPut::*;
import Clocks::*;
import FIFO::*;
import FIFOF::*;
import GetPut::*;
import Connectable::*;

import HostInterface::*;
import Dsp48E1::*;
import InnerProdInterface::*;
import ConnectalBramFifo::*;

interface InnerProd;
   interface InnerProdRequest request;
endinterface

interface InnerProdTile;
   interface Put#(Tuple4#(Int#(16),Int#(16),Bool,Bool)) request;
   interface Get#(Int#(48)) response;
endinterface

(* synthesize *)
module mkInnerProdTile(InnerProdTile);

   let dsp <- mkDsp48E1();

   interface Put request;
      method Action put(Tuple4#(Int#(16),Int#(16),Bool,Bool) req);
	 match { .a, .b, .first, .last } = req;
	 dsp.a(extend(pack(a)));
	 dsp.b(extend(pack(b)));
	 dsp.c('h22);
	 dsp.d(0);
	 let opmode = 7'h25;
	 if (first) opmode = 7'h05;
	 dsp.opmode(opmode);
	 dsp.inmode(0);
	 dsp.alumode(0);
	 dsp.last(pack(last));
      endmethod
   endinterface
   interface Get response;
      method ActionValue#(Int#(48)) get();
	 $display("InnerProdTile response.get %h", dsp.p());
	 return unpack(dsp.p());
      endmethod
   endinterface
endmodule

module mkInnerProd#(
`ifdef IMPORT_HOSTIF
		    HostInterface host,
`endif
		    InnerProdIndication ind)(InnerProd);

   let defaultClock <- exposeCurrentClock;
   let defaultReset <- exposeCurrentReset;
`ifdef IMPORT_HOSTIF
   let derivedClock = host.derivedClock;
`else
   let derivedClock = defaultClock;
`endif
   let derivedReset <- mkAsyncReset(2, defaultReset, derivedClock);
   let optionalReset = derivedReset; // noReset
   let syncIn <- mkDualClockBramFIFOF(defaultClock, defaultReset, derivedClock, derivedReset);
   FIFOF#(Int#(48)) bramFifo <- mkDualClockBramFIFOF(derivedClock, derivedReset, defaultClock, defaultReset);
   let started <- mkFIFOF();

   Reg#(Bit#(32)) cycles <- mkReg(0, clocked_by derivedClock, reset_by derivedReset);
   rule cyclesRule;
      cycles <= cycles+1;
   endrule

   let tile <- mkInnerProdTile(clocked_by derivedClock, reset_by optionalReset);
   rule syncRequestRule if (started.notEmpty());
      let req <- toGet(syncIn).get();
      $display("syncRequestRule a=%h b=%h", tpl_1(req), tpl_2(req));
      tile.request.put(req);
   endrule
   mkConnection(tile.response, toPut(bramFifo), clocked_by derivedClock, reset_by derivedReset);
   rule indRule;
      let r <- toGet(bramFifo).get();
      $display("%d: indRule v=%x %d", cycles, r, r);
      ind.innerProd(pack(r));
   endrule

   interface InnerProdRequest request;
      method Action innerProd(Bit#(16) a, Bit#(16) b, Bool first, Bool last);
	 $display("request.innerProd a=%h b=%h first=%d last=%d", a, b, first, last);
	 syncIn.enq(tuple4(unpack(a),unpack(b),first,last));
	 if (last)
	    started.enq(True);
	 $display("start");
      endmethod
      method Action start();
      endmethod
      method Action finish();
	 $dumpflush();
	 $finish();
      endmethod
   endinterface
endmodule
