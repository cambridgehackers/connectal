
interface Tiny3Indication;
   method Action outputdata(Bit#(32) v);
   method Action inputresponse();
endinterface

interface Tiny3Request;
   method Action inputdata(Bit#(32) v);
endinterface

