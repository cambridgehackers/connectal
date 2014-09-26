package Tiny3;

import FIFO::*;
import FIFOF::*;
import GetPut::*;
import TinyTypes::*;
import TinyAsm::*;
import BRAM::*;
import Vector::*;

interface TinyCompIfc;
   interface Put#(WordT) in;
   interface Get#(WordT) out;
endinterface 


module mkTinyComp(InstructionROM_T irom, TinyCompIfc ifc);
   Reg#(PCT) pc <- mkReg(0);
   Reg#(WordT) alu <- mkReg(0);
   Reg#(UInt#(3)) phase <- mkReg(7);
   Reg#(Bool) doSkip <- mkRegU;
   FIFOF#(WordT) inQ <- mkFIFOF;
   FIFO#(WordT) outQ <- mkFIFO;
   Vector#(TExp#(SizeOf#(PCT)),Reg#(WordT)) rf <- replicateM(mkRegU);
   Reg#(WordT) valRa <- mkRegU;
   Reg#(WordT) valRb <- mkRegU;
   Reg#(InstructionT) inst <- mkRegU;

   BRAM1Port#(PCT, WordT) im <- mkBRAM1Server(defaultValue);
   BRAM1Port#(PCT, WordT) dm <- mkBRAM1Server(defaultValue);
   Reg#(PCT) addr <- mkReg(0);
   
   // initialise instruction memory (im) contents from ROM
   rule do_init(phase==7);
      WordT data = unpack(pack(irom[addr]));
      im.portA.request.put(BRAMRequest{write: True, responseOnWrite: False,
					address: addr, datain: data});
      
      InstructionT inst = unpack(pack(data));
      if(inst.Normal.op!=OpReserved)
	 $display("%05t: init pm[%1d] = ",$time,addr,disassemble(inst));
      let next_addr = addr+1;
      addr <= next_addr;
      if(next_addr==0)
	 phase <= 0;
   endrule
   
   rule fetch(phase==0);
      im.portA.request.put(BRAMRequest{write: False, responseOnWrite: False, address: pc, datain: 0});
      $write("%05t: fetch",$time);
      phase <= 1;
   endrule

   rule register_fetch(phase==1);
      let read <- im.portA.response.get();
      let i = word2instruction(read);
      let ib = pack(i);
      inst <= i;
      $display(" pm[%2d] : ",pc,disassemble(i));
      // read registers
      valRa <= rf[ib[23:17]]; // hacky - fetch registers regardless of whether an immediate is going to be used
      valRb <= rf[ib[16:10]];
      phase <= 2;
   endrule
   
   rule execute(phase==2);
      WordT alu_result;
      case (inst) matches
	 tagged Normal {func:.func, shift:.shift, op:.op, skip:.skip}:
	    begin
	       WordT alu_calc;
	       doSkip <= ((skip==SkipNeg) && (alu<0)) ||
	                 ((skip==SkipZero) && (alu==0)) ||
 			 ((skip==SkipInRdy) && inQ.notEmpty);
	       // initiate loads
	       if(op==OpLoadDM)
		  dm.portA.request.put(BRAMRequest{write: False, responseOnWrite: False, address: unpack(truncate(pack(valRb))), datain: 0});
	       // first do the ALU operation
	       case(func)
		  FaADDb: alu_calc = valRa+valRb;
		  FaSUBb: alu_calc = valRa-valRb;
		  FINCb:  alu_calc = valRb+1;
		  FDECb:  alu_calc = valRb-1;
		  FaANDb: alu_calc = valRa & valRb;
		  FaORb:  alu_calc = valRa | valRb;
		  FaXORb: alu_calc = valRa ^ valRb;
		  default: begin alu_calc = 0; $finish; end
	       endcase
	       // then do the shifter (rotates)
	       Bit#(32) alub = pack(alu_calc); // ALU result in bits
	       case(shift)
		  ShiftNone:  alu_result = unpack(alub);
		  ShiftRCY1:  alu_result = unpack({alub[30:0],alub[31]});
		  ShiftRCY8:  alu_result = unpack({alub[23:0],alub[31:24]});
		  ShiftRCY16: alu_result = unpack({alub[15:0],alub[31:16]});
		  default:    alu_result = unpack(alub);
	       endcase
	    end
	 tagged Immediate {rw:.rw, imm:.imm}:
	    begin
	       doSkip <= False;
	       alu_result = zeroExtend(unpack(pack(imm)));
	    end
	 default: alu_result = 0;
      endcase
      alu <= alu_result;
      phase <= 3;
   endrule
   
   rule write_back(phase==3);
      $display("%05t: doSkip = %s",$time,doSkip ? "True" : "False");
      case (inst) matches
	 tagged Normal {op:.op, rw:.rw}:
	    begin
	       pc <= doSkip ? pc+2 : ((op==OpJump) ? unpack(truncate(pack(alu))) : pc+1);
	       Maybe#(WordT) wbval=tagged Invalid;
	       case (op)
		  OpNormal, OpStoreDM, OpStoreIM, OpOut: wbval = tagged Valid alu;
		  OpLoadDM: begin
			       let read <- dm.portA.response.get();
			       wbval = tagged Valid read;
			    end
		  OpIn:     begin
			       wbval = tagged Valid inQ.first;
			       inQ.deq;
			    end
	       endcase
	       if(isValid(wbval))
		  begin
		     rf[rw] <= fromMaybe(?,wbval);
		     $display("%05t: r%1d <- %1d",$time,rw,fromMaybe(?,wbval));
		  end
	       else
		  $display("%05t: alu = %1d",$time,alu);
	       PCT addr = unpack(truncate(pack(valRb)));
	       case (op)
		  OpStoreDM: dm.portA.request.put(BRAMRequest{write: True, responseOnWrite: False, address: addr, datain: valRa});
		  OpStoreIM: im.portA.request.put(BRAMRequest{write: True, responseOnWrite: False, address: addr, datain: valRa});
		  OpOut:     outQ.enq(alu);
		  OpReserved: $finish;
	       endcase
	    end
	 tagged Immediate {rw:.rw, imm:.imm}:
	    begin
	       pc <= pc+1;
	       rf[rw] <= alu;
	       $display("%05t: r%1d = imm = %1d",$time,rw,alu);
	    end
      endcase
      phase <= 0;
   endrule
   
   interface in = toPut(inQ);
   interface out = toGet(outQ);

endmodule


endpackage
