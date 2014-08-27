typedef struct { Bit#(16) a; Bit#(16) b; } Rec;

typedef Bit#(16) Signal;

interface PTestRequest;
   method Action func2(Rec data); 
   method Action func1(Signal data); 
endinterface

interface PTestIndication;
   method Action func3(Signal data);
endinterface

