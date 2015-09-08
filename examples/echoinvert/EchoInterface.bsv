
interface EchoIndication;
    method Action heard(Bit#(32) v);
    method Action heard2(Bit#(16) a, Bit#(16) b);
endinterface

interface EchoRequest;
   method Action say(Bit#(32) v);
   method Action say2(Bit#(16) a, Bit#(16) b);
   method Action setLeds(Bit#(8) v);
endinterface
