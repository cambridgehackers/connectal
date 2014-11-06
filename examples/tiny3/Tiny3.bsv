package Tiny3;

import FIFO::*;
import FIFOF::*;
import GetPut::*;
import TinyTypes::*;
import TinyAsm::*;
import BRAM::*;
import Vector::*;

function WordT alu(FuncT func, WordT raVal, WordT rbVal);
  case (func)
    FaADDb:     return raVal + rbVal;
    FaSUBb:     return raVal - rbVal;
    FINCb:      return rbVal + 1;
    FDECb:      return rbVal - 1;
    FaANDb:     return raVal & rbVal;
    FaORb:      return raVal | rbVal;
    FaXORb:     return raVal ^ rbVal;
    default:    return 0;
  endcase
endfunction

    
function WordT shifter(WordT val, ShiftT shift);
  Bit#(32) valb = pack(val); // val in bits
  case (shift)
    ShiftNone:  return val;
    ShiftRCY1:  return unpack({valb[0], valb[31:1]});
    ShiftRCY8:  return unpack({valb[7:0], valb[31:8]});
    ShiftRCY16: return unpack({valb[15:0], valb[31:16]});
    default:    return val;
  endcase
endfunction


function PCT pc_mux(OpcodeT op, PCT prog_counter, WordT alu_ret, Bool skip);
  if (skip)               return prog_counter + 2;
  else if (op == OpJump)  return word2pc(alu_ret);
  else                    return prog_counter + 1;
endfunction


function Maybe#(WordT) result_mux(OpcodeT op, PCT prog_counter, WordT alu_ret, WordT dm_ret, WordT in_ret);
  case (op)
    OpNormal,
    OpStoreDM,
    OpStoreIM,
    OpOut:      return tagged Valid alu_ret;
    OpLoadDM:   return tagged Valid dm_ret;
    OpIn:       return tagged Valid in_ret;
    OpJump:     return tagged Valid pc2word(prog_counter + 1);
    default:    return tagged Invalid;
  endcase
endfunction


function Bool skip_detect(InstructionT instruction, WordT alu_ret, Bool inQready);
  case (instruction) matches
    tagged Normal {skip:.skip}:      
      case (skip)
	SkipNever:  return False;
	SkipNeg:    return (alu_ret < 0);
	SkipZero:   return (alu_ret == 0);
	SkipInRdy:  return (inQready);
	default:    return False;
      endcase
    tagged Immediate {}:
      return False;
  endcase
endfunction


interface TinyCompIfc;
    interface Put#(WordT) in;
    interface Get#(WordT) out;
endinterface 


module mkTinyComp(InstructionROM_T irom, TinyCompIfc ifc);
    
  Reg#(PhaseT)        phase <- mkReg(INIT);
  Reg#(PCT)              pc <- mkReg(0);
  Reg#(InstructionT)   inst <- mkRegU;
  Reg#(WordT)    alu_result <- mkReg(0);
  Reg#(Bool)         doSkip <- mkRegU;
  
  FIFOF#(WordT)         inQ <- mkFIFOF;
  FIFO#(WordT)         outQ <- mkFIFO;
    
  Vector#(TExp#(SizeOf#(PCT)),Reg#(WordT))
                         rf <- replicateM(mkRegU);
  Reg#(WordT)         valRa <- mkRegU;
  Reg#(WordT)         valRb <- mkRegU;
    
  BRAM1Port#(PCT, WordT) im <- mkBRAM1Server(defaultValue);
  BRAM1Port#(PCT, WordT) dm <- mkBRAM1Server(defaultValue);
  Reg#(PCT)            addr <- mkReg(0); 

  // initialise instruction memory (im) contents from ROM
  rule do_init (phase == INIT);
    WordT data = int2word(irom[addr]);
    im.portA.request.put(BRAMRequest{write: True, responseOnWrite: False,
				     address: addr, datain: data});      
    InstructionT inst = word2instruction(data);
    if (inst.Normal.op != OpReserved)
      begin
	$write("%05t: init pm[%1d] = ", $time, addr);
	$display(fshow(inst));
      end
    let next_addr = addr + 1;
    addr <= next_addr;
    if (next_addr == 0)
      phase <= IF;
  endrule
   
  rule fetch (phase == IF);
    im.portA.request.put(
       BRAMRequest{
	  write: False,
	  responseOnWrite: False,
	  address: pc,
	  datain: 0});
    $write("%05t: fetch", $time);
    phase <= DC;
  endrule
  
  rule register_fetch (phase == DC);
    let read <- im.portA.response.get();
    let i = word2instruction(read);
    inst <= i;
    $display(" pm[%2d] : ", pc, fshow(i));
    // read registers
    if (i matches tagged Normal .normalInst)
      begin
	valRa <= rf[normalInst.ra];
	valRb <= rf[normalInst.rb];
      end
    phase <= EX;
  endrule
  
  rule execute (phase == EX);
    case (inst) matches
      tagged Normal {func:.func, shift:.shift, op:.op, skip:.skip}:
        begin // memory accesses
	  let addr=word2pc(valRb);
	  case(op) 
	    OpLoadDM:
	    begin
	      dm.portA.request.put(BRAMRequest{write: False,
		 responseOnWrite: False, address: addr, datain: 0});
	      $display("%05t: load dm[%1d] initiated", $time, addr);
	    end
	    OpStoreDM:
	    begin
	      dm.portA.request.put(BRAMRequest{write: True,
		 responseOnWrite: False, address: addr, datain: valRa});
	      $display("%05t: dm[%1d] = %1d", $time, addr, valRa);
	    end
	    OpStoreIM:
	    begin
	      im.portA.request.put(BRAMRequest{write: True,
		 responseOnWrite: False, address: addr, datain: valRa});
	      $display("%05t: pm[%1d] = %1d", $time, addr, valRa);
	    end
	  endcase
	  alu_result <= shifter(alu(func, valRa, valRb), shift); // ALU+shift
	end
      tagged Immediate {rw:.rw, imm:.imm}:
	  alu_result <= imm2word(imm);
      default: alu_result <= 0;
    endcase
    phase <= WB;
  endrule
   
  rule write_back (phase == WB);
    Bool doSkip = skip_detect(inst, alu_result, inQ.notEmpty);
    if(doSkip)
      $display("%05t: doSkip", $time);
    case (inst) matches
      tagged Normal {op:.op, rw:.rw}: begin
	pc <= pc_mux(op, pc, alu_result, doSkip);
	WordT dm_result = 0, in_result = 0;
	PCT addr = word2pc(valRb);
	case (op)
	  OpLoadDM:
	    begin
	      dm_result <- dm.portA.response.get();
	      $display("%05t: dm returned %1d", $time, dm_result);
	    end
	  OpIn:
	    begin
	      in_result = inQ.first;
	      inQ.deq;
	    end
	  OpOut:
	    outQ.enq(alu_result);
	  OpReserved: $finish;
	endcase
        Maybe#(WordT) wbval = result_mux(op, pc, alu_result, dm_result, in_result);
        if(isValid(wbval))
          begin
            rf[rw] <= fromMaybe(?, wbval);
            $display("%05t: r%1d <- %1d", $time, rw, fromMaybe(?, wbval));
          end
        else
          $display("%05t: alu = %1d", $time, alu_result); 
	if(op==OpJump) // mark jumps
	  $display("%05t: -----------------------------------------------------------------",$time);
      end
      tagged Immediate {rw:.rw, imm:.imm}:
        begin
          pc <= pc + 1;
          rf[rw] <= alu_result;
          $display("%05t: r%1d = imm = %1d", $time, rw, alu_result);
        end
    endcase
    phase <= IF;
  endrule
   
  interface in = toPut(inQ);
  interface out = toGet(outQ);

endmodule

endpackage: Tiny3
