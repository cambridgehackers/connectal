import AxiBits::*;


interface HarnessRequest;
   method Action startTest(Bit#(16) v);
endinterface
interface HarnessResponse;
   method Action testStarted(Bit#(16) v);
endinterface

interface Harness;
   interface HarnessRequest request;
endinterface

module [Module] mkHarness#(HarnessResponse response)(Harness);
   let checker <- mkMkPhysMemSlaveChecker();

   interface HarnessRequest request;
      method Action startTest(Bit#(16) v);
	 $display("startTest %x is a no op", v);
	 response.testStarted(v);
      endmethod
   endinterface
endmodule
