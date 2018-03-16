
import GetPut::*;
import FIFOF::*;
import VaddBvi::*;

interface VaddRequest;
   method Action data(Bit#(32) in0, Bit#(32) in1);
   method Action start();
endinterface
interface VaddResponse;
   method Action data(Bit#(32) out);
   method Action done();
endinterface

interface Vadd;
   interface VaddRequest request;
endinterface

module mkVadd#(VaddResponse response)(Vadd);
   Vadd64 vadd64 <- mkVadd64(64);

   rule rl_response;
      let v <- vadd64.out.get();
      response.data(v);
   endrule

   rule rl_done;
      let v <- vadd64.done();
      response.done();
   endrule

   interface VaddRequest request;
      method Action data(Bit#(32) in0, Bit#(32) in1);
	 vadd64.in0.put(in0);
	 vadd64.in1.put(in1);
      endmethod
      method Action start();
	 vadd64.start();
      endmethod
   endinterface
endmodule
