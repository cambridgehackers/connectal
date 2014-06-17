import FIFOF::*;
import GetPut::*;
import ClientServer::*;
import FloatingPoint::*;
import DefaultValue::*;
import Randomizable::*;
import Vector::*;
import StmtFSM::*;
import Pipe::*;
import FIFO::*;
import BUtils::*;
import PipeMul::*;
import FpMul::*;
import FpAdd::*;

////////////////////////////////////////////////////////////////////////////////
/// Floating point fused multiple accumulate
////////////////////////////////////////////////////////////////////////////////
///
/// copied from FloatingPoint.bsv and modified.
/// this version is no longer IEEE compliant :)
///
////////////////////////////////////////////////////////////////////////////////

typedef struct {
   Maybe#(FloatingPoint#(e,m)) res;
   Exception exc;
   RoundMode rmode;
   } CommonState#(numeric type e, numeric type m) deriving (Bits, Eq);

function Bit#(e) unbias( FloatingPoint#(e,m) din );
   return (din.exp - fromInteger(bias(din)));
endfunction

function Bit#(m) zExtendLSB(Bit#(n) value)
   provisos( Add#(n,m,k) );
   Bit#(k) out = { value, 0 };
   return out[valueof(k)-1:valueof(n)];
endfunction

function Integer minexp( FloatingPoint#(e,m) din );
  return 1-bias(din);
endfunction

function Bit#(1) getHiddenBit( FloatingPoint#(e,m) din );
   return (isSubNormal(din)) ? 0 : 1;
endfunction

function Integer bias( FloatingPoint#(e,m) din );
   return (2 ** (valueof(e)-1)) - 1;
endfunction

function Integer minexp_subnormal( FloatingPoint#(e,m) din );
   return minexp(din)-valueof(m);
endfunction

function Integer maxexp( FloatingPoint#(e,m) din );
   return bias(din);
endfunction

function Tuple2#(FloatingPoint#(e,m),Exception) round( RoundMode rmode, FloatingPoint#(e,m) din, Bit#(2) guard )
   provisos(  Add#(m, 1, m1)
	    , Add#(m, 2, m2)
	    );

   FloatingPoint#(e,m) out = defaultValue;
   Exception exc = defaultValue;

   if (isNaNOrInfinity(din)) begin
      out = din;
   end
   else begin
      let din_inc = din;

      Bit#(TAdd#(m,2)) sfd = unpack({1'b0, getHiddenBit(din), din.sfd}) + 1;

      if (msb(sfd) == 1) begin
	 if (din.exp == fromInteger(maxexp(din) + bias(out))) begin
	    din_inc = infinity(din_inc.sign);
	 end
	 else begin
	    din_inc.exp = din_inc.exp + 1;
	    din_inc.sfd = truncate(sfd >> 1);
	 end
      end
      else if ((din.exp == 0) && (truncateLSB(sfd) == 2'b01)) begin
	 din_inc.exp = 1;
	 din_inc.sfd = truncate(sfd);
      end
      else begin
	 din_inc.sfd = truncate(sfd);
      end

      if (guard != 0) begin
	 exc.inexact = True;
      end

      case(rmode)
	 Rnd_Nearest_Even:
	 begin
	    case (guard)
	       'b00: out = din;
	       'b01: out = din;
	       'b10: out = (lsb(din.sfd) == 1) ? din_inc : din;
	       'b11: out = din_inc;
	    endcase
	 end

	 Rnd_Nearest_Away_Zero:
	 begin
	    case (guard)
	       'b00: out = din;
	       'b01: out = din_inc;
	       'b10: out = din_inc;
	       'b11: out = din_inc;
	    endcase
	 end

	 Rnd_Plus_Inf:
	 begin
	    if (guard == 0)
	       out = din;
	    else if (din.sign)
	       out = din;
	    else
	       out = din_inc;
	 end

	 Rnd_Minus_Inf:
	 begin
	    if (guard == 0)
	       out = din;
	    else if (din.sign)
	       out = din_inc;
	    else
	       out = din;
	 end

	 Rnd_Zero:
	 begin
	    out = din;
	 end
      endcase
   end

   if (isInfinity(out)) begin
      exc.overflow = True;
   end

   return tuple2(out,exc);
endfunction

function Tuple3#(FloatingPoint#(e,m),Bit#(2),Exception) normalize( FloatingPoint#(e,m) din, Bit#(x) sfdin )
   provisos(
      Add#(1, a__, x),
      Add#(m, b__, x),
      // per request of bsc
      Add#(c__, TLog#(TAdd#(1, x)), TAdd#(e, 1))
      );

   FloatingPoint#(e,m) out = din;
   Bit#(2) guard = 0;
   Exception exc = defaultValue;

   Int#(TAdd#(e,1)) exp = isSubNormal(out) ? fromInteger(minexp(out)) : signExtend(unpack(unbias(out)));
   let zeros = countZerosMSB(sfdin);

   if ((zeros == 0) && (exp == fromInteger(maxexp(out)))) begin
      out.exp = maxBound - 1;
      out.sfd = maxBound;
      guard = '1;
      exc.overflow = True;
      exc.inexact = True;
   end
   else begin
      if (zeros == 0) begin
	 // carry, no sfd adjust necessary

	 if (out.exp == 0)
	    out.exp = 2;
	 else
	    out.exp = out.exp + 1;

	 // carry bit
	 sfdin = sfdin << 1;
      end
      else if (zeros == 1) begin
	 // already normalized

	 if (out.exp == 0)
	    out.exp = 1;

	 // carry, hidden bits
	 sfdin = sfdin << 2;
      end
      else if (zeros == fromInteger(valueOf(x))) begin
	 // exactly zero
	 out.exp = 0;
      end
      else begin
	 // try to normalize
	 Int#(TAdd#(e,1)) shift = zeroExtend(unpack(pack(zeros - 1)));
	 Int#(TAdd#(e,1)) maxshift = exp - fromInteger(minexp(out));

	 if (shift > maxshift) begin
	    // result will be subnormal

	    sfdin = sfdin << maxshift;
	    out.exp = 0;
	 end
	 else begin
	    // result will be normal

	    sfdin = sfdin << shift;
	    out.exp = out.exp - truncate(pack(shift));
	 end

 	 // carry, hidden bits
	 sfdin = sfdin << 2;
      end

      out.sfd = unpack(truncateLSB(sfdin));
      sfdin = sfdin << fromInteger(valueOf(m));

      guard[1] = unpack(truncateLSB(sfdin));
      sfdin = sfdin << 1;

      guard[0] = |sfdin;
   end

   if ((out.exp == 0) && (guard != 0))
      exc.underflow = True;

   return tuple3(out,guard,exc);
endfunction

function Bool isNaNOrInfinity( FloatingPoint#(e,m) din );
   return (din.exp == '1);
endfunction

module mkFpMac#(RoundMode rmode)(Server#(Tuple3#(Maybe#(FloatingPoint#(e,m)), FloatingPoint#(e,m), FloatingPoint#(e,m)), Tuple2#(FloatingPoint#(e,m),Exception)))
   provisos(
      Add#(e,2,ebits),
      Add#(m,1,mbits),
      Add#(m,5,m5bits),
      Add#(mbits,mbits,mmbits),
      // per request of bsc
      Add#(1, a__, mmbits),
      Add#(m, b__, mmbits),
      Add#(c__, TLog#(TAdd#(1, mmbits)), TAdd#(e, 1)),
      Add#(d__, TLog#(TAdd#(1, m5bits)), TAdd#(e, 1)),
      Add#(1, TAdd#(1, TAdd#(m, 3)), m5bits),
      Add#(e__, mmbits, TMul#(2, mmbits)),
      // for PipeMul2
      Add#(16, f__, mbits),
      Add#(16, g__, TMul#(2, mbits)),
      Add#(h__, mbits, TMul#(2, mbits)),
      Add#(16, i__, mmbits),
      Add#(j__, TSub#(mbits, 16), mmbits),
      Add#(mmbits,0,48)
      );

   FIFOF#(Tuple3#(Maybe#(FloatingPoint#(e,m)),
		 FloatingPoint#(e,m),
		 FloatingPoint#(e,m))) fOperand_S0 <- mkLFIFOF();

   Reg#(Tuple7#(CommonState#(e,m),
		Bool,
		FloatingPoint#(e,m),
		Bool,
		Int#(ebits),
		Bit#(mbits),
		Bit#(mbits))) rState_S1 <- mkReg(unpack(0));
   Reg#(Bool) rValid_S1 <- mkReg(False);

   FIFOF#(Tuple2#(FloatingPoint#(e,m),Exception)) fResult_S9 <- mkLFIFOF();

   Reg#(Tuple5#(CommonState#(e,m),
		Bool,
		FloatingPoint#(e,m),
		Bool,
		Int#(ebits))) rState_S2 <- mkReg(unpack(0));
   Reg#(Bool) rValid_S2 <- mkReg(False);
   Reg#(UInt#(mmbits)) rProd_S2lsb <- mkReg(0);
   Reg#(UInt#(mmbits)) rProd_S2msb <- mkReg(0);

   Reg#(Tuple5#(CommonState#(e,m),
      Bool,
      FloatingPoint#(e,m),
      Bool,
      Int#(ebits))) rState_S3 <- mkReg(unpack(0));
   Reg#(Bool) rValid_S3 <- mkReg(False);
   Reg#(UInt#(mmbits)) rProd_S3 <- mkReg(0);
   Reg#(Tuple4#(Bool, Bool, Bool, Bool)) rConditions_S3 <- mkReg(unpack(0));

   Reg#(CommonState#(e,m)) rState_S4_s <- mkReg(unpack(0));
   Reg#(Bool) rState_S4_acc <- mkReg(False);
   Reg#(FloatingPoint#(e,m)) rState_S4_opA <- mkReg(unpack(0));
   Reg#(FloatingPoint#(e,m)) rState_S4_bc <- mkReg(unpack(0));
   Reg#(Bit#(2)) rState_S4_guardBC <- mkReg(unpack(0));
   Reg#(Bool) rValid_S4 <- mkReg(False);

   Reg#(Tuple8#(CommonState#(e,m),
		Bool,
		Bool,
		Bool,
		Int#(ebits),
		Int#(ebits),
		Bit#(m5bits),
		Bit#(m5bits))) rState_S5 <- mkReg(unpack(0));
   Reg#(Bool) rValid_S5 <- mkReg(False);

   Reg#(Tuple7#(CommonState#(e,m),
		Bool,
		Bool,
		Bool,
		Int#(ebits),
		Bit#(m5bits),
		Bit#(m5bits))) rState_S6 <- mkReg(unpack(0));
   Reg#(Bool) rValid_S6 <- mkReg(False);

   Reg#(Tuple7#(CommonState#(e,m),
		Bool,
		Bool,
		Bool,
		Int#(ebits),
		Bit#(m5bits),
		Bit#(m5bits))) rState_S7 <- mkReg(unpack(0));
   Reg#(Bool) rValid_S7 <- mkReg(False);

   Reg#(Tuple5#(CommonState#(e,m),
		 Bool,
		 FloatingPoint#(e,m),
		 Bit#(2),
		 Bool)) rState_S8 <- mkReg(unpack(0));
   Reg#(Bool) rValid_S8 <- mkReg(False);

   // check operands, compute exponent for multiply
   rule s1_stage;
      begin
	 Tuple3#(Maybe#(FloatingPoint#(e,m)),FloatingPoint#(e,m),FloatingPoint#(e,m)) req = unpack(0);
	 let valid = False;
	 if (fOperand_S0.notEmpty()) begin
	    req = fOperand_S0.first();
	    fOperand_S0.deq();
	    valid = True;
	 end
	 match { .mopA, .opB, .opC } = req;

	 CommonState#(e,m) s = CommonState {
	    res: tagged Invalid,
	    exc: defaultValue,
	    rmode: rmode
	    };

	 Bool acc = False;
	 FloatingPoint#(e,m) opA = 0;

	 if (mopA matches tagged Valid .opA_) begin
	    opA = opA_;
	    acc = True;
	 end

	 Int#(ebits) expB = isSubNormal(opB) ? fromInteger(minexp(opB)) : signExtend(unpack(unbias(opB)));
	 Int#(ebits) expC = isSubNormal(opC) ? fromInteger(minexp(opC)) : signExtend(unpack(unbias(opC)));

	 Bit#(mbits) sfdB = { getHiddenBit(opB), opB.sfd };
	 Bit#(mbits) sfdC = { getHiddenBit(opC), opC.sfd };

	 Bool sgnBC = opB.sign != opC.sign;
	 Bool infBC = isInfinity(opB) || isInfinity(opC);
	 Bool zeroBC = isZero(opB) || isZero(opC);
	 Int#(ebits) expBC = expB + expC;

	 if (isSNaN(opA)) begin
	    s.res = tagged Valid nanQuiet(opA);
	    s.exc.invalid_op = True;
	 end
	 else if (isSNaN(opB)) begin
	    s.res = tagged Valid nanQuiet(opB);
	    s.exc.invalid_op = True;
	 end
	 else if (isSNaN(opC)) begin
	    s.res = tagged Valid nanQuiet(opC);
	    s.exc.invalid_op = True;
	 end
	 else if (isQNaN(opA)) begin
	    s.res = tagged Valid opA;
	 end
	 else if (isQNaN(opB)) begin
	    s.res = tagged Valid opB;
	 end
	 else if (isQNaN(opC)) begin
	    s.res = tagged Valid opC;
	 end
	 else if ((isInfinity(opB) && isZero(opC)) || (isZero(opB) && isInfinity(opC)) || (isInfinity(opA) && infBC && (opA.sign != sgnBC))) begin
	    // product of zero and infinity or addition of opposite sign infinity
	    s.res = tagged Valid qnan();
	    s.exc.invalid_op = True;
	 end
	 else if (isInfinity(opA)) begin
	    s.res = tagged Valid opA;
	 end
	 else if (infBC) begin
	    s.res = tagged Valid infinity(sgnBC);
	 end
	 else if (isZero(opA) && zeroBC && (opA.sign == sgnBC)) begin
	    s.res = tagged Valid opA;
	 end


	 rState_S1 <= tuple7(s,
			     acc,
			     opA,
			     sgnBC,
			     expBC,
			     sfdB,
			     sfdC);
	 rValid_S1 <= valid;
      end
   //endrule

   // start multiply
      //rule s2_stage if (fResult_S9.notFull());
      begin
	 match { .s, .acc, .opA, .sgnBC, .expBC, .sfdB, .sfdC } = rState_S1;
	 let valid = rValid_S1;

	 UInt#(mbits) sfdClsb = extend(unpack(sfdC[15:0]));
	 UInt#(TSub#(mbits,16)) sfdCmsb = unpack(sfdC[valueOf(mbits)-1:16]);
	 rProd_S2lsb <= extend(unpack(sfdB))*extend(sfdClsb);
	 rProd_S2msb <= extend(unpack(sfdB))*extend(sfdCmsb);

	 rState_S2 <= tuple5(s,
			     acc,
			     opA,
			     sgnBC,
			     expBC);
	 rValid_S2 <= valid;
      end
   //endrule

   //   add partial multiplies
      //rule s3_stage if (fResult_S9.notFull());
      begin
	 match { .s, .acc, .opA, .sgnBC, .expBC } = rState_S2;
	 let valid = rValid_S2;

	 UInt#(mmbits) sfdBC = rProd_S2lsb + (rProd_S2msb << 16);
	 rProd_S3 <= sfdBC;

	 rState_S3 <= tuple5(s,
			     acc,
			     opA,
			     sgnBC,
			     expBC);
	 rValid_S3 <= valid;


	 Bool overflow = False;
	 Bool underflow = False;
	 Bool inbounds = False;
	 Bool denorm = False;
	 let shift = 0;
	 FloatingPoint#(e,m) bc = defaultValue;
	 if (s.res matches tagged Invalid) begin
	    if (expBC > fromInteger(maxexp(bc))) begin
	       overflow = True;
	    end
	    else if (expBC < (fromInteger(minexp_subnormal(bc))-2)) begin
	       underflow = True;
	    end
	    else begin
	       inbounds = True;
	       shift = fromInteger(minexp(bc)) - expBC;
	       if (shift > 0) begin
		  denorm = True;
	       end
	    end
	 end
	 rConditions_S3 <= tuple4(overflow, underflow, inbounds, denorm);
      end
   //endrule

   // normalize multiplication result
      //rule s4_stage if (fResult_S9.notFull());
      begin
	 match { .s, .acc, .opA, .sgnBC, .expBC } = rState_S3;
	 match { .overflow, .underflow, .inbounds, .denorm } = rConditions_S3;
	 let valid = rValid_S3;

	 let sfdBC = pack(rProd_S3);

	 FloatingPoint#(e,m) bc = defaultValue;
	 Bit#(2) guardBC = ?;

	 //if (s.res matches tagged Invalid) begin
	 //if (expBC > fromInteger(maxexp(bc))) begin
	 if (overflow) begin
	       bc.sign = sgnBC;
	       bc.exp = maxBound - 1;
	       bc.sfd = maxBound;
	       guardBC = '1;

	       s.exc.overflow = True;
	       s.exc.inexact = True;
	 end
	 //else if (expBC < (fromInteger(minexp_subnormal(bc))-2)) begin
	 else if (underflow) begin
	       bc.sign = sgnBC;
	       bc.exp = 0;
	       bc.sfd = 0;
	       guardBC = 0;

	       if (|sfdBC == 1) begin
		  guardBC = 1;
		  s.exc.underflow = True;
		  s.exc.inexact = True;
	       end
	    end
	 //else begin
	 else if (inbounds) begin
	    //if (shift > 0) begin
	    if (denorm) begin
	       // subnormal
	       //Bit#(1) sfdlsb = |(sfdBC << (fromInteger(valueOf(mmbits)) - shift));
	       //sfdBC = sfdBC >> shift;
	       //sfdBC[0] = sfdBC[0] | sfdlsb;
	       //bc.exp = 0;
	       bc.exp = 0;
	       sfdBC = 0;
	       s.exc.underflow = True;
	       s.exc.inexact = True;
	    end
	    else begin
	       bc.exp = cExtend(expBC + fromInteger(bias(bc)));
	    end

	    bc.sign = sgnBC;
	    let y = normalize(bc, sfdBC);
	    bc = tpl_1(y);
	    guardBC = tpl_2(y);
	    s.exc = s.exc | tpl_3(y);
	 end
	 //end

	 rState_S4_s <= s;
	 rState_S4_acc <= acc;
	 rState_S4_opA <= opA;
	 rState_S4_bc <= bc;
	 rState_S4_guardBC <= guardBC;
	 rValid_S4 <= valid;
      end
   //endrule

   // calculate shift and sign for add
      //rule s5_stage if (fResult_S9.notFull());
      begin
	 //match { .s, .acc, .opA, .opBC, .guardBC } = rState_S4;
	 let s = rState_S4_s;
	 let acc = rState_S4_acc;
	 let opA = rState_S4_opA;
	 let opBC = rState_S4_bc;
	 let guardBC = rState_S4_guardBC;
	 let valid = rValid_S4;

	 Int#(ebits) expA = isSubNormal(opA) ? fromInteger(minexp(opA)) : signExtend(unpack(unbias(opA)));
	 Int#(ebits) expBC = isSubNormal(opBC) ? fromInteger(minexp(opBC)) : signExtend(unpack(unbias(opBC)));

	 Bit#(m5bits) sfdA = {1'b0, getHiddenBit(opA), opA.sfd, 3'b0};
	 Bit#(m5bits) sfdBC = {1'b0, getHiddenBit(opBC), opBC.sfd, guardBC, 1'b0};

	 Bool sub = opA.sign != opBC.sign;

	 Int#(ebits) exp = ?;
	 Int#(ebits) shift = ?;
	 Bit#(m5bits) x = ?;
	 Bit#(m5bits) y = ?;
	 Bool sgn = ?;

	 if ((!acc) || (expBC > expA) || ((expBC == expA) && (sfdBC > sfdA))) begin
	    exp = expBC;
	    shift = expBC - expA;
	    x = sfdBC;
	    y = sfdA;
	    sgn = opBC.sign;
	 end
	 else begin
	    exp = expA;
	    shift = expA - expBC;
	    x = sfdA;
	    y = sfdBC;
	    sgn = opA.sign;
	 end

	 rState_S5 <= tuple8(s,
			     acc,
			     sub,
			     sgn,
			     exp,
			     shift,
			     x,
			     y);
	 rValid_S5 <= valid;
      end
   //endrule

   // shift second add operand
   //rule s6_stage if (fResult_S9.notFull());
      begin
	 match { .s, .acc, .sub, .sgn, .exp, .shift, .x, .y } = rState_S5;
	 let valid = rValid_S5;

	 if (s.res matches tagged Invalid) begin
	    if (shift < fromInteger(valueOf(m5bits))) begin
	       Bit#(m5bits) guard;

	       guard = y << (fromInteger(valueOf(m5bits)) - shift);
	       y = y >> shift;
	       y[0] = y[0] | (|guard);
	    end
	    else if (|y == 1) begin
	       y = 1;
	    end
	 end

	 rState_S6 <= tuple7(s,
			     acc,
			     sub,
			     sgn,
			     exp,
			     x,
			     y);
	 rValid_S6 <= valid;
      end
   //endrule

   // add/subtract sfd
   //rule s7_stage if (fResult_S9.notFull());
      begin
	 match { .s, .acc, .sub, .sgn, .exp, .x, .y } = rState_S6;
	 let valid = rValid_S6;

	 let sum = x + y;
	 let diff = x - y;

	 rState_S7 <= tuple7(s,
			     acc,
			     sub,
			     sgn,
			     exp,
			     sum,
			     diff);
	 rValid_S7 <= valid;
      end
   //endrule

   // normalize addition result
   //rule s8_stage if (fResult_S9.notFull());
      begin
	 match { .s, .acc, .sub, .sgn, .exp, .sum, .diff } = rState_S7;
	 let valid = rValid_S7;

	 FloatingPoint#(e,m) out = defaultValue;
	 Bit#(2) guard = 0;

	 if (s.res matches tagged Invalid) begin
	    Bit#(m5bits) sfd;

	    sfd = sub ? diff : sum;

	    out.sign = sgn;
	    out.exp = cExtend(exp + fromInteger(bias(out)));

	    let y = normalize(out, sfd);
	    out = tpl_1(y);
	    guard = tpl_2(y);
	    s.exc = s.exc | tpl_3(y);
	 end

	 rState_S8 <= tuple5(s,
			     acc,
			     out,
			     guard,
			     sub);
	 rValid_S8 <= valid;
      end
   //endrule

   // round result
   //rule s9_stage if (fResult_S9.notFull());
      begin
	 match { .s, .acc, .out, .guard, .sub } = rState_S8;
	 let valid = rValid_S8;

	 if (s.res matches tagged Valid .x) begin
	    out = x;
	 end
	 else begin
	    let y = round(rmode, out, guard);
	    out = tpl_1(y);
	    s.exc = s.exc | tpl_2(y);

	    // adjust sign for exact zero result
	    if (acc && isZero(out) && !s.exc.inexact && sub) begin
	       out.sign = (rmode == Rnd_Minus_Inf);
	    end
	 end

	 if (valid)
	    fResult_S9.enq(tuple2(out,s.exc));
      end
   endrule

   interface Put request;
   method Action put(Tuple3#(Maybe#(FloatingPoint#(e,m)),FloatingPoint#(e,m),FloatingPoint#(e,m)) req);
      fOperand_S0.enq(req);
   endmethod
   endinterface
   interface Get response;
      method ActionValue#(Tuple2#(FloatingPoint#(e,m),Exception)) get();
	 let resp <- toGet(fResult_S9).get();
	 return resp;
      endmethod
   endinterface
endmodule

////////////////////////////////////////////////////////////////////////////////
/// Pipelined Floating Point Adder
////////////////////////////////////////////////////////////////////////////////

module mkFPAdder#(RoundMode rmode)(Server#(Tuple2#(FloatingPoint#(e,m), FloatingPoint#(e,m)), Tuple2#(FloatingPoint#(e,m),Exception)))
   provisos(
      // per request of bsc
      Add#(a__, TLog#(TAdd#(1, TAdd#(m, 5))), TAdd#(e, 1))
      );

   ////////////////////////////////////////////////////////////////////////////////
   /// S0
   ////////////////////////////////////////////////////////////////////////////////
   FIFOF#(Tuple2#(FloatingPoint#(e,m),
		  FloatingPoint#(e,m)))                 fOperands_S0        <- mkLFIFOF;

   ////////////////////////////////////////////////////////////////////////////////
   /// S1 - subtract exponents
   ////////////////////////////////////////////////////////////////////////////////
   Reg#(Tuple7#(CommonState#(e,m),
		Bit#(TAdd#(m,5)),
		Bit#(TAdd#(m,5)),
		Bool,
		Bool,
		Bit#(e),
		Bit#(e))) rState_S1 <- mkReg(unpack(0));
   Reg#(Bool) rValid_S1 <- mkReg(False);

   Reg#(Tuple6#(CommonState#(e,m),
		Bit#(TAdd#(m,5)),
		Bit#(TAdd#(m,5)),
		Bool,
		Bool,
		Bit#(e))) rState_S2 <- mkReg(unpack(0));
   Reg#(Bool) rValid_S2 <- mkReg(False);

   Reg#(Tuple6#(CommonState#(e,m),
		Bit#(TAdd#(m,5)),
		Bit#(TAdd#(m,5)),
		Bool,
		Bool,
		Bit#(e))) rState_S3 <- mkReg(unpack(0));
   Reg#(Bool) rValid_S3 <- mkReg(False);

   Reg#(Tuple4#(CommonState#(e,m),
		FloatingPoint#(e,m),
		Bit#(2),
		Bool)) rState_S4 <- mkReg(unpack(0));
   Reg#(Bool) rValid_S4 <- mkReg(False);

   FIFO#(Tuple2#(FloatingPoint#(e,m),Exception)) fResult_S5          <- mkFIFO;

   rule s1_stage;
      begin
	 let req = unpack(0);
	 let valid = False;
	 if (fOperands_S0.notEmpty) begin
	    req <- toGet(fOperands_S0).get;
	    valid = True;
	 end
	 match { .opA, .opB } = req;
	 CommonState#(e,m) s = CommonState {
	    res: tagged Invalid,
	    exc: defaultValue,
	    rmode: rmode
	    };

	 Int#(TAdd#(e,2)) expA = isSubNormal(opA) ? fromInteger(minexp(opA)) : signExtend(unpack(unbias(opA)));
	 Int#(TAdd#(e,2)) expB = isSubNormal(opB) ? fromInteger(minexp(opB)) : signExtend(unpack(unbias(opB)));

	 Bit#(TAdd#(m,5)) sfdA = {1'b0, getHiddenBit(opA), opA.sfd, 3'b0};
	 Bit#(TAdd#(m,5)) sfdB = {1'b0, getHiddenBit(opB), opB.sfd, 3'b0};

	 Bit#(TAdd#(m,5)) x;
	 Bit#(TAdd#(m,5)) y;
	 Bool sgn;
	 Bool sub;
	 Bit#(e) exp;
	 Bit#(e) expdiff;

	 if ((expB > expA) || ((expB == expA) && (sfdB > sfdA))) begin
	    exp = opB.exp;
	    expdiff = truncate(pack(expB - expA));
	    x = sfdB;
	    y = sfdA;
	    sgn = opB.sign;
	    sub = (opB.sign != opA.sign);
	 end
	 else begin
	    exp = opA.exp;
	    expdiff = truncate(pack(expA - expB));
	    x = sfdA;
	    y = sfdB;
	    sgn = opA.sign;
	    sub = (opA.sign != opB.sign);
	 end

	 if (isSNaN(opA)) begin
	    s.res = tagged Valid nanQuiet(opA);
	    s.exc.invalid_op = True;
	 end
	 else if (isSNaN(opB)) begin
	    s.res = tagged Valid nanQuiet(opB);
	    s.exc.invalid_op = True;
	 end
	 else if (isQNaN(opA)) begin
	    s.res = tagged Valid opA;
	 end
	 else if (isQNaN(opB)) begin
	    s.res = tagged Valid opB;
	 end
	 else if (isInfinity(opA) && isInfinity(opB)) begin
	    if (opA.sign == opB.sign)
	       s.res = tagged Valid infinity(opA.sign);
	    else begin
	       s.res = tagged Valid qnan();
	       s.exc.invalid_op = True;
	    end
	 end
	 else if (isInfinity(opA)) begin
	    s.res = tagged Valid opA;
	 end
	 else if (isInfinity(opB)) begin
	    s.res = tagged Valid opB;
	 end

	 rState_S1 <= tuple7(s,
			     x,
			     y,
			     sgn,
			     sub,
			     exp,
			     expdiff);
	 rValid_S1 <= valid;
      end
   //endrule

   ////////////////////////////////////////////////////////////////////////////////
   /// S2 - align significands
   ////////////////////////////////////////////////////////////////////////////////

   //rule s2_stage;
      begin
	 match {.s, .opA, .opB, .sign, .subtract, .exp, .diff} = rState_S1;
	 let valid = rValid_S1;

	 if (s.res matches tagged Invalid) begin
	    if (diff < fromInteger(valueOf(m) + 5)) begin
	       Bit#(TAdd#(m,5)) guard = opB;

	       guard = opB << (fromInteger(valueOf(m) + 5) - diff);
	       opB = opB >> diff;
	       opB[0] = opB[0] | (|guard);
	    end
	    else if (|opB == 1) begin
	       opB = 1;
	    end
	 end

	 rState_S2 <= tuple6(s,
			     opA,
			     opB,
			     sign,
			     subtract,
			     exp);
	 rValid_S2 <= valid;
      end
   //endrule

   ////////////////////////////////////////////////////////////////////////////////
   /// S3 - add/subtract significands
   ////////////////////////////////////////////////////////////////////////////////

   //rule s3_stage;
      begin
	 match {.s, .a, .b, .sign, .subtract, .exp} = rState_S2;
	 let valid = rValid_S2;

	 let sum = a + b;
	 let diff = a - b;

	 rState_S3 <= tuple6(s,
			     sum,
			     diff,
			     sign,
			     subtract,
			     exp);
	 rValid_S3 <= valid;
      end
   //endrule

   ////////////////////////////////////////////////////////////////////////////////
   /// S4 - normalize
   ////////////////////////////////////////////////////////////////////////////////
   //rule s4_stage;
      begin
	 match {.s, .addres, .subres, .sign, .subtract, .exp} = rState_S3;
	 let valid = rValid_S3;

	 FloatingPoint#(e,m) out = defaultValue;
	 Bit#(2) guard = 0;

	 if (s.res matches tagged Invalid) begin
	    Bit#(TAdd#(m,5)) result;

	    if (subtract) begin
	       result = subres;
	    end
	    else begin
               result = addres;
	    end

	    out.sign = sign;
	    out.exp = exp;

	    // $display("out = ", fshow(out));
	    // $display("result = 'h%x", result);
	    // $display("zeros = %d", countZerosMSB(result));

	    let y = normalize(out, result);
	    out = tpl_1(y);
	    guard = tpl_2(y);
	    s.exc = s.exc | tpl_3(y);
	 end

	 rState_S4 <= tuple4(s,
			     out,
			     guard,
			     subtract);
	 rValid_S4 <= valid;
      end
   //endrule

   ////////////////////////////////////////////////////////////////////////////////
   /// S5 - round result
   ////////////////////////////////////////////////////////////////////////////////

   //rule s5_stage;
      begin
	 match {.s, .rnd, .guard, .subtract} = rState_S4;
	 let valid = rValid_S4;
	 FloatingPoint#(e,m) out = rnd;

	 if (s.res matches tagged Valid .x) begin
	    out = x;
	 end
	 else begin
	    let y = round(s.rmode, out, guard);
	    out = tpl_1(y);
	    s.exc = s.exc | tpl_2(y);
	 end

	 // adjust sign for exact zero result
	 if (isZero(out) && !s.exc.inexact && subtract) begin
	    out.sign = (s.rmode == Rnd_Minus_Inf);
	 end

	 if (valid)
	    fResult_S5.enq(tuple2(out,s.exc));
      end
   endrule

   ////////////////////////////////////////////////////////////////////////////////
   /// Interface Connections / Methods
   ////////////////////////////////////////////////////////////////////////////////
   interface request = toPut(fOperands_S0);
   interface response = toGet(fResult_S5);

endmodule: mkFPAdder

////////////////////////////////////////////////////////////////////////////////
/// Pipelined Floating Point Multiplier
////////////////////////////////////////////////////////////////////////////////
module mkFPMultiplier#(RoundMode rmode)(Server#(Tuple2#(FloatingPoint#(e,m), FloatingPoint#(e,m)), Tuple2#(FloatingPoint#(e,m),Exception)))
   provisos(
      // per request of bsc
      Add#(a__, TLog#(TAdd#(1, TAdd#(TAdd#(m, 1), TAdd#(m, 1)))), TAdd#(e, 1)),
      Add#(b__, 16, TAdd#(m, 1))
      );

   let implementSubnormal = False;

   ////////////////////////////////////////////////////////////////////////////////
   /// S0
   ////////////////////////////////////////////////////////////////////////////////
   FIFOF#(Tuple2#(FloatingPoint#(e,m),
		  FloatingPoint#(e,m)))                 fOperands_S0        <- mkLFIFOF;

   ////////////////////////////////////////////////////////////////////////////////
   /// S1 - calculate the new exponent/sign
   ////////////////////////////////////////////////////////////////////////////////
   Reg#(Tuple5#(CommonState#(e,m),
		Bit#(TAdd#(m,1)),
		Bit#(TAdd#(m,1)),
		Int#(TAdd#(e,2)),
		Bool)) rState_S1 <- mkReg(unpack(0));
   Reg#(Bool) rValid_S1 <- mkReg(False);

   Reg#(Tuple3#(CommonState#(e,m),
		Int#(TAdd#(e,2)),
		Bool)) rState_S2 <- mkReg(unpack(0));
   Reg#(Tuple3#(Bool, Bool, Bool)) rCond_S3 <- mkReg(unpack(0));
   Reg#(Int#(TAdd#(e,2))) rShift_S3 <- mkReg(0);
   Reg#(UInt#(TAdd#(TAdd#(m,1),TAdd#(m,1)))) rsfdres_S2_lsb <- mkReg(0);
   Reg#(UInt#(TAdd#(TAdd#(m,1),TAdd#(m,1)))) rsfdres_S2_msb <- mkReg(0);

   Reg#(Bool) rValid_S2 <- mkReg(False);

   Reg#(Tuple3#(CommonState#(e,m),
		 Int#(TAdd#(e,2)),
		 Bool)) rState_S3 <- mkReg(unpack(0));
   Reg#(UInt#(TAdd#(TAdd#(m,1),TAdd#(m,1)))) rsfdres_S3 <- mkReg(0);
   Reg#(Bool) rValid_S3 <- mkReg(False);

   Reg#(Tuple3#(CommonState#(e,m),
		FloatingPoint#(e,m),
		Bit#(2))) rState_S4 <- mkReg(unpack(0));
   Reg#(Bool) rValid_S4 <- mkReg(False);

   FIFO#(Tuple2#(FloatingPoint#(e,m),Exception)) fResult_S5  <- mkFIFO;

   rule s1_stage;
      begin
	 let req = unpack(0);
	 let valid = False;
	 if (fOperands_S0.notEmpty()) begin
	    req <- toGet(fOperands_S0).get;
	    valid = True;
	 end
	 match { .opA, .opB } = req;

	 CommonState#(e,m) s = CommonState {
	    res: tagged Invalid,
	    exc: defaultValue,
	    rmode: rmode
	    };

	 Int#(TAdd#(e,2)) expA = isSubNormal(opA) ? fromInteger(minexp(opA)) : signExtend(unpack(unbias(opA)));
	 Int#(TAdd#(e,2)) expB = isSubNormal(opB) ? fromInteger(minexp(opB)) : signExtend(unpack(unbias(opB)));
	 Int#(TAdd#(e,2)) newexp = expA + expB;

	 Bool sign = (opA.sign != opB.sign);

	 Bit#(TAdd#(m,1)) opAsfd = { getHiddenBit(opA), opA.sfd };
	 Bit#(TAdd#(m,1)) opBsfd = { getHiddenBit(opB), opB.sfd };

	 if (isSNaN(opA)) begin
	    s.res = tagged Valid nanQuiet(opA);
	    s.exc.invalid_op = True;
	 end
	 else if (isSNaN(opB)) begin
	    s.res = tagged Valid nanQuiet(opB);
	    s.exc.invalid_op = True;
	 end
	 else if (isQNaN(opA)) begin
	    s.res = tagged Valid opA;
	 end
	 else if (isQNaN(opB)) begin
	    s.res = tagged Valid opB;
	 end
	 else if ((isInfinity(opA) && isZero(opB)) || (isZero(opA) && isInfinity(opB))) begin
	    s.res = tagged Valid qnan();
	    s.exc.invalid_op = True;
	 end
	 else if (isInfinity(opA) || isInfinity(opB)) begin
	    s.res = tagged Valid infinity(opA.sign != opB.sign);
	 end
	 else if (isZero(opA) || isZero(opB)) begin
	    s.res = tagged Valid zero(opA.sign != opB.sign);
	 end
	 else if (newexp > fromInteger(maxexp(opA))) begin
	    FloatingPoint#(e,m) out;
	    out.sign = (opA.sign != opB.sign);
	    out.exp = maxBound - 1;
	    out.sfd = maxBound;

	    s.exc.overflow = True;
	    s.exc.inexact = True;

	    let y = round(rmode, out, '1);
	    s.res = tagged Valid tpl_1(y);
	    s.exc = s.exc | tpl_2(y);
	 end
	 else if (newexp < (fromInteger(minexp_subnormal(opA))-2)) begin
	    FloatingPoint#(e,m) out;
	    out.sign = (opA.sign != opB.sign);
	    out.exp = 0;
	    out.sfd = 0;

	    s.exc.underflow = True;
	    s.exc.inexact = True;

	    let y = round(rmode, out, 'b01);
	    s.res = tagged Valid tpl_1(y);
	    s.exc = s.exc | tpl_2(y);
	 end

	 rState_S1 <= tuple5(s,
			     opAsfd,
			     opBsfd,
			     newexp,
			     sign);
	 rValid_S1 <= valid;
      end
   //endrule

   ////////////////////////////////////////////////////////////////////////////////
   /// S2
   ////////////////////////////////////////////////////////////////////////////////
   //rule s2_stage;
      begin
	 match {.s, .opAsfd, .opBsfd, .exp, .sign} = rState_S1;
	 let valid = rValid_S1;

	 //Bit#(TAdd#(TAdd#(m,1),TAdd#(m,1))) sfdres = primMul(opAsfd, opBsfd);
	 UInt#(TAdd#(m,1)) opBsfd_lsb = extend(unpack(opBsfd[15:0]));
	 UInt#(TSub#(TAdd#(m,1),16)) opBsfd_msb  = unpack(opBsfd[valueOf(TAdd#(m,1))-1:16]);
	 rsfdres_S2_lsb <= extend(unpack(opAsfd))*extend(opBsfd_lsb);
	 rsfdres_S2_msb <= extend(unpack(opAsfd))*extend(opBsfd_msb);

	 rState_S2 <= tuple3(s,
			     exp,
			     sign);
	 rValid_S2 <= valid;
      end
   //endrule

   ////////////////////////////////////////////////////////////////////////////////
   /// S3
   ////////////////////////////////////////////////////////////////////////////////

   //rule s3_stage;
      begin
	 let x = rState_S2;
	 let valid = rValid_S2;
	 rsfdres_S3 <= (rsfdres_S2_msb << 16) + rsfdres_S2_lsb;
	 rState_S3 <= x;
	 rValid_S3 <= valid;

	 match {.s, .exp, .sign} = x;
	 FloatingPoint#(e,m) result = defaultValue;
	 Bit#(2) guard = ?;

	 let sresInvalid = False;
	 let subnormal = False;
	 let inbounds = False;
	 let shift = fromInteger(minexp(result)) - exp;
	 
	 if (s.res matches tagged Invalid) begin
	    sresInvalid = True;
	    if (shift > 0) begin
	       subnormal = True;
	       // subnormal
	    end
	    else begin
	       inbounds = True;
	    end
	 end
	 rCond_S3 <= tuple3(sresInvalid, subnormal, inbounds);
	 if (implementSubnormal)
	    rShift_S3 <= shift;
      end
   //endrule

   ////////////////////////////////////////////////////////////////////////////////
   /// S4
   ////////////////////////////////////////////////////////////////////////////////
   //rule s4_stage;
      begin
	 match {.s, .exp, .sign} = rState_S3;
	 match {.sresInvalid, .subnormal, .inbounds} = rCond_S3;
	 let shift = 0;
	 if (implementSubnormal)
	    shift = rShift_S3;
	 let sfdres = pack(rsfdres_S3);
	 let valid = rValid_S3;

	 FloatingPoint#(e,m) result = defaultValue;
	 Bit#(2) guard = ?;

	 //if (s.res matches tagged Invalid) begin
	 if (sresInvalid) begin
	    //$display("sfdres = 'h%x", sfdres);

	    //let shift = fromInteger(minexp(result)) - exp;
	    //if (shift > 0) begin
	    if (subnormal) begin
	       // subnormal
	       if (implementSubnormal) begin
		  Bit#(1) sfdlsb = |(sfdres << (fromInteger(valueOf(TAdd#(TAdd#(m,1),TAdd#(m,1)))) - shift));

		  //$display("sfdlsb = |'h%x = 'b%b", (sfdres << (fromInteger(valueOf(TAdd#(TAdd#(m,1),TAdd#(m,1)))) - shift)), sfdlsb);

		  sfdres = sfdres >> shift;
		  sfdres[0] = sfdres[0] | sfdlsb;
	       end
	       else begin
		  sfdres = 0;
	       end

	       result.exp = 0;
	    end
	    else begin
	       // inbounds
	       result.exp = cExtend(exp + fromInteger(bias(result)));
	    end

	    // $display("shift = %d", shift);
	    // $display("sfdres = 'h%x", sfdres);
	    // $display("result = ", fshow(result));
	    // $display("exc = 'b%b", pack(exc));
	    // $display("zeros = %d", countZerosMSB(sfdres));

	    result.sign = sign;
	    let y = normalize(result, sfdres);
	    result = tpl_1(y);
	    guard = tpl_2(y);
	    s.exc = s.exc | tpl_3(y);

	    // $display("result = ", fshow(result));
	    // $display("exc = 'b%b", pack(exc));
	 end

	 rState_S4 <= tuple3(s,
			     result,
			     guard);
	 rValid_S4 <= valid;
      end
   //endrule

   ////////////////////////////////////////////////////////////////////////////////
   /// S5
   ////////////////////////////////////////////////////////////////////////////////

   //rule s5_stage;
      begin
	 match {.s, .rnd, .guard} = rState_S4;
	 let valid = rValid_S4;

	 FloatingPoint#(e,m) out = rnd;

	 if (s.res matches tagged Valid .x)
	    out = x;
	 else begin
	    let y = round(s.rmode, out, guard);
	    out = tpl_1(y);
	    s.exc = s.exc | tpl_2(y);
	 end

	 if (valid)
	    fResult_S5.enq(tuple2(out,s.exc));
      end
   endrule

   ////////////////////////////////////////////////////////////////////////////////
   /// Interface Connections / Methods
   ////////////////////////////////////////////////////////////////////////////////
   interface request = toPut(fOperands_S0);
   interface response = toGet(fResult_S5);

endmodule: mkFPMultiplier
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
/// Wrap Xilinx FP MUL
////////////////////////////////////////////////////////////////////////////////
module mkXilinxFPMultiplier#(RoundMode rmode)(Server#(Tuple2#(Float,Float), Tuple2#(Float,Exception)));

   let clock <- exposeCurrentClock();
   let reset <- exposeCurrentReset();

   let fpMul <- mkFpMul();
   Wire#(Bit#(1)) s_axis_ab_ready <- mkDWire(0);
   Wire#(Bit#(1)) m_axis_tready <- mkDWire(0);
   rule ab_ready;
      fpMul.s_axis_a.tvalid(s_axis_ab_ready);
      fpMul.s_axis_b.tvalid(s_axis_ab_ready);
   endrule
   rule c_ready;
      fpMul.m_axis_result.tready(m_axis_tready);
   endrule

   ////////////////////////////////////////////////////////////////////////////////
   /// Interface Connections / Methods
   ////////////////////////////////////////////////////////////////////////////////
   interface Put request;
      method Action put(Tuple2#(Float,Float) req) if (fpMul.s_axis_a.tready() == 1 && fpMul.s_axis_b.tready() == 1);
	 match { .a, .b } = req;
	 fpMul.s_axis_a.tdata(pack(a));
	 fpMul.s_axis_b.tdata(pack(b));
	 s_axis_ab_ready <= 1;
      endmethod
   endinterface
   interface Get response;
      method ActionValue#(Tuple2#(Float,Exception)) get() if (fpMul.m_axis_result.tvalid() == 1);
	 m_axis_tready <= 1;
	 return tuple2(unpack(fpMul.m_axis_result.tdata()), defaultValue);
      endmethod
   endinterface
endmodule: mkXilinxFPMultiplier
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
/// Wrap Xilinx FP ADD
////////////////////////////////////////////////////////////////////////////////
module mkXilinxFPAdder#(RoundMode rmode)(Server#(Tuple2#(Float, Float), Tuple2#(Float,Exception)));

   let clock <- exposeCurrentClock();
   let reset <- exposeCurrentReset();

   let fpAdd <- mkFpAdd();
   Wire#(Bit#(1)) s_axis_ab_ready <- mkDWire(0);
   Wire#(Bit#(1)) m_axis_tready <- mkDWire(0);
   rule ab_ready;
      fpAdd.s_axis_a.tvalid(s_axis_ab_ready);
      fpAdd.s_axis_b.tvalid(s_axis_ab_ready);
      fpAdd.s_axis_operation.tvalid(s_axis_ab_ready);
   endrule
   rule c_ready;
      fpAdd.m_axis_result.tready(m_axis_tready);
   endrule

   ////////////////////////////////////////////////////////////////////////////////
   /// Interface Connections / Methods
   ////////////////////////////////////////////////////////////////////////////////
   interface Put request;
      method Action put(Tuple2#(Float,Float) req) if (fpAdd.s_axis_a.tready() == 1 && fpAdd.s_axis_b.tready() == 1);
	 match { .a, .b } = req;
	 fpAdd.s_axis_a.tdata(pack(a));
	 fpAdd.s_axis_b.tdata(pack(b));
	 fpAdd.s_axis_operation.tdata(0);
	 s_axis_ab_ready <= 1;
      endmethod
   endinterface
   interface Get response;
      method ActionValue#(Tuple2#(Float,Exception)) get() if (fpAdd.m_axis_result.tvalid() == 1);
	 m_axis_tready <= 1;
	 return tuple2(unpack(fpAdd.m_axis_result.tdata()), defaultValue);
      endmethod
   endinterface
endmodule: mkXilinxFPAdder
////////////////////////////////////////////////////////////////////////////////

