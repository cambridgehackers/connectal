/*****************************************************************************
 TinyTypes
 =========
 Simon Moore
 August 2011
 
 Types for Chuck Thacker's Tiny3 processor
 *****************************************************************************/

package TinyTypes;

typedef enum {OpNormal, OpStoreDM, OpStoreIM, OpOut, OpLoadDM, OpIn, OpJump, OpReserved} OpcodeT deriving (Bits,Eq);
typedef enum {FaADDb, FaSUBb, FINCb, FDECb, FaANDb, FaORb, FaXORb, Freserved} FuncT deriving (Bits,Eq);
typedef enum {ShiftNone, ShiftRCY1, ShiftRCY8, ShiftRCY16} ShiftT deriving (Bits,Eq);
typedef enum {SkipNever, SkipNeg, SkipZero, SkipInRdy} SkipT deriving (Bits,Eq);
typedef UInt#(7) RegT;
typedef Int#(32) WordT;
typedef UInt#(24) ImmT;
typedef UInt#(10) PCT;

typedef union tagged {
   struct {
      RegT   rw;
      RegT   ra;
      RegT   rb;
      FuncT  func;
      ShiftT shift;
      SkipT  skip;
      OpcodeT op;
   } Normal;
   struct {
      RegT   rw;
      ImmT   imm;
      } Immediate;
} InstructionT deriving (Bits, Eq);


function String func2string(FuncT f);
   String r="ERROR";
   case(f)
      FaADDb: r="FaADDb";
      FaSUBb: r="FaSUBb";
      FINCb:  r="FINCb";
      FDECb:  r="FDECb";
      FaANDb: r="FaANDb";
      FaORb:  r="FaORb";
      FaXORb: r="FaXORb";
      Freserved: r="Freserved";
   endcase
   return r;
endfunction


function String shift2string(ShiftT s);
   String r="ERROR";
   case(s)
      ShiftNone: r="ShiftNone";
      ShiftRCY1: r="ShiftRCY1";
      ShiftRCY8: r="ShiftRCY8";
      ShiftRCY16: r="ShiftRCY16";
   endcase
   return r;
endfunction


function String skip2string(SkipT s);
   String r="ERROR";
   case(s)
      SkipNever: r="SkipNever";
      SkipNeg:   r="SkipNeg";
      SkipZero:  r="SkipZero";
      SkipInRdy: r="SkipInRdy";
   endcase
   return r;
endfunction


function String opcode2string(OpcodeT op);
   String r="ERROR";
   case(op)
      OpNormal:   r="OpNormal";
      OpStoreDM:  r="OpStoreDM";
      OpStoreIM:  r="OpStoreIM";
      OpOut:      r="OpOut";
      OpLoadDM:   r="OpLoadDM";
      OpIn:       r="OpIn";
      OpJump:     r="OpJump";
      OpReserved: r="OpReserved";
   endcase
   return r;
endfunction


function WordT instruction2word(InstructionT i);
   return unpack(pack(i));
endfunction

function InstructionT word2instruction(WordT w);
   return unpack(pack(w));
endfunction

endpackage: TinyTypes
