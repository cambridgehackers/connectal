typedef enum {
   Z_X_Y_CIN=0, Z_NX_Y_NCIN=3, NZ_X_Y_CIN=1, NZ_NX_NY_NCIN_N1=2
   } Alumode deriving (Bits,Eq);

interface InnerProdRequest;
   method Action innerProd(Bit#(16) tile, Bit#(16) a, Bool first, Bool last, Bool update);
   method Action write(Bit#(16) addr, Bit#(16) val);
   method Action startIndividualConv(Bit#(16) xbase, Bit#(16) xlimit, Bit#(16) ybase, Bit#(16) ylimit);
   method Action startConv(Bit#(32) readPointer, Bit#(32) writePointer, Bit#(16) xbase, Bit#(16) xlimit, Bit#(16) ybase, Bit#(16) ylimit);
   method Action finish();
endinterface
interface InnerProdIndication;
   method Action innerProd(Bit#(16) tile, Bit#(16) sum);
endinterface
