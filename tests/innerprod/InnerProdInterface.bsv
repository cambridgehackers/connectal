
interface InnerProdRequest;
   method Action innerProd(Bit#(16) a, Bit#(16) b);
endinterface
interface InnerProdIndication;
   method Action innerProd(Bit#(16) sum);
endinterface
