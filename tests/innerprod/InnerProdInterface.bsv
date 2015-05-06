typedef enum {
   Z_X_Y_CIN=0, Z_NX_Y_NCIN=3, NZ_X_Y_CIN=1, NZ_NX_NY_NCIN_N1=2
   } Alumode deriving (Bits,Eq);

interface InnerProdRequest;
   method Action innerProd(Bit#(16) a, Bit#(16) b, Bool first, Bool last);
   method Action start();
   method Action finish();
endinterface
interface InnerProdIndication;
   method Action innerProd(Bit#(48) sum);
endinterface
