/*****************************************************************************
 TinyTypes
 =========
 Simon Moore
 August 2011
 October 2014 - made use of FShow
 
 Types for Chuck Thacker's Tiny3 processor
 *****************************************************************************/

package TinyTypes;

typedef enum {OpNormal, OpStoreDM, OpStoreIM, OpOut,
              OpLoadDM, OpIn, OpJump, OpReserved} OpcodeT
             deriving (Bits,Eq,FShow);
typedef enum {FaADDb, FaSUBb, FINCb, FDECb, FaANDb,
              FaORb, FaXORb, Freserved} FuncT
             deriving (Bits,Eq,FShow);
typedef enum {ShiftNone, ShiftRCY1, ShiftRCY8, ShiftRCY16} ShiftT
             deriving (Bits,Eq,FShow);
typedef enum {SkipNever, SkipNeg, SkipZero, SkipInRdy} SkipT
             deriving (Bits,Eq,FShow);
typedef enum {INIT, IF, DC, EX, WB} PhaseT
             deriving (Bits,Eq,FShow);

typedef UInt#(7)  RegT;
typedef Int#(32)  WordT;
typedef UInt#(24) ImmT;
typedef UInt#(10) PCT;

typedef union tagged {
   struct {
      RegT    rw;
      RegT    ra;
      RegT    rb;
      FuncT   func;
      ShiftT  shift;
      SkipT   skip;
      OpcodeT op;
   } Normal;
   struct {
      RegT    rw;
      ImmT    imm;
   } Immediate;
} InstructionT deriving (Bits, Eq);

// helper functions
function WordT instruction2word(InstructionT i) = unpack(pack(i));
function InstructionT word2instruction(WordT w) = unpack(pack(w));
function WordT pc2word(PCT p) = unpack(zeroExtend(pack(p)));
function PCT word2pc(WordT w) = unpack(truncate(pack(w)));
function WordT imm2word(ImmT i) = unpack(zeroExtend(pack(i)));
function WordT int2word(Int#(32) i) = unpack(pack(i));

// provide fshow() to display an instruction (i.e. disassemble)
instance FShow#(InstructionT);
  function Fmt fshow(InstructionT inst);
    Fmt dash = $format("-");
    case(inst) matches
      tagged Normal { op: .op, func: .func, shift: .shift,
                     skip: .skip, rw: .rw, ra: .ra, rb: .rb}:
	return fshow(op) + dash + fshow(func) + dash + fshow(shift) + dash + fshow(skip) +
	       $format("  r%1d <- r%1d, r%1d", rw, ra, rb);
      tagged Immediate { rw: .rw, imm: .imm }:
        return $format("r%1d = %1d",rw,imm);
    endcase
  endfunction
endinstance


endpackage: TinyTypes
