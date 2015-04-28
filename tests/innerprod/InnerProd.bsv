
import GetPut::*;
import Clocks::*;

import HostInterface::*;
import Dsp48E1::*;
import InnerProdInterface::*;

interface InnerProd;
   interface InnerProdRequest request;
endinterface

interface InnerProdTile;
   interface Put#(Tuple4#(Int#(16),Int#(16),Bool,Bool)) request;
   interface Get#(Int#(16)) response;
endinterface

(* synthesize *)
module mkInnerProdTile(InnerProdTile);

   let dsp <- mkDsp48E1();

   interface Put request;
      method Action put(Tuple4#(Int#(16),Int#(16),Bool,Bool) req);
	 match { .a, .b, .first, .last } = req;
	 dsp.a(extend(pack(a)));
	 dsp.b(extend(pack(b)));
	 dsp.alumode(0);
	 let opmode = 7'h45; // p = M + P
	 if (first)
	    opmode = 7'h05; // P = M + 0
	 dsp.opmode(opmode);
	 dsp.last(pack(last));
      endmethod
   endinterface
   interface Get response;
      method ActionValue#(Int#(16)) get();
	 return unpack(dsp.p()[31:16]);
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
   let derivedReset <- mkAsyncReset(2, defaultReset, host.derivedClock);
   let syncIn <- mkSyncFIFO(2, defaultClock, defaultReset, host.derivedClock);
   let syncOut <- mkSyncFIFO(2, host.derivedClock, derivedReset, defaultClock);

   let tile <- mkInnerProdTile(clocked_by host.derivedClock, reset_by noReset);
   rule syncRequestRule;
      let req <- toGet(syncIn).get();
      tile.request.put(req);
   endrule
   rule responseRule;
      let r <- tile.response.get();
      syncOut.enq(r);
   endrule
   rule indRule;
      let r <- toGet(syncOut).get();
      ind.innerProd(pack(r));
   endrule

   interface InnerProdRequest request;
      method Action innerProd(Bit#(16) a, Bit#(16) b, Bool first, Bool last);
	 syncIn.enq(tuple4(unpack(a),unpack(b),first,last));
      endmethod
   endinterface
endmodule
