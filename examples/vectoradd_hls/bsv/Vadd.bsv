
import GetPut::*;
import FIFOF::*;
import VaddBvi::*;

// requests from software to hardware
interface VaddRequest;
   method Action data(Bit#(32) in0, Bit#(32) in1);
   method Action start();
endinterface

// responses from hardware to software
interface VaddResponse;
   method Action data(Bit#(32) out);
   method Action done();
endinterface

interface Vadd;
   interface VaddRequest request;
endinterface

module mkVadd#(VaddResponse response)(Vadd);
   Vaddhls vaddhls <- mkVaddhls(64);

   rule rl_response;
      let v <- vaddhls.out.get();
      response.data(v);
   endrule

   rule rl_done;
      let v <- vaddhls.done();
      response.done();
   endrule

   interface VaddRequest request;
      method Action data(Bit#(32) in0, Bit#(32) in1);
	 vaddhls.in0.put(in0);
	 vaddhls.in1.put(in1);
      endmethod
      method Action start();
	 vaddhls.start();
      endmethod
   endinterface
endmodule
