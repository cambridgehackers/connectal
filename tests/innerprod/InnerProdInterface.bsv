
interface InnerProdRequest;
   method Action innerProd(Bit#(16) a, Bit#(16) b, Bool first, Bool last);
endinterface
interface InnerProdIndication;
   method Action innerProd(Bit#(16) sum);
endinterface
