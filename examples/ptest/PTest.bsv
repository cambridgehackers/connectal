
typedef Bit#(16) Signal;

interface PTestRequest;
   method Action func1(Signal data); 
endinterface

interface PTestIndication;
   method Action fun2(Signal data);
endinterface

