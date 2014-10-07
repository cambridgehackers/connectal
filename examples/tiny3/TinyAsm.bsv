/*****************************************************************************
 TinyAsm
 =======
 Simon Moore
 August 2011
 
 Assembler for Chuck Thacker's Tiny3 processor embedded by Bluespec
 
 *****************************************************************************/

package TinyAsm;

import List::*;
import FIFO::*;
import GetPut::*;
import ClientServer::*;
import TinyTypes::*;

typedef Tuple2#(String,InstructionT) AsmLineT; // type of a line of assembler
typedef List#(String) LabelTblT; // type of assembler label table
typedef List#(WordT) InstructionROM_T;   

/********** functions to create (label,instruction) pairs **********/
function AsmLineT asm(String label, OpcodeT op, FuncT func, ShiftT shift, SkipT skip, RegT rw, RegT ra, RegT rb);
   return tuple2(label,tagged Normal{rw:rw, ra:ra, rb:rb, func:func, shift:shift, skip:skip, op:op});
endfunction

function AsmLineT asmi(String label, RegT rw, ImmT imm);
   return tuple2(label,tagged Immediate{rw:rw, imm:imm});
endfunction

// returns the position of string "tofind" in "list"
function Maybe#(Integer) find_pos_string (String tofind, List#(String) list);
   Maybe#(Integer) rtn = tagged Invalid;
   for(Integer j=0; (j<length(list)) && !isValid(rtn); j=j+1)
      if(list[j]==tofind)
	 rtn=tagged Valid fromInteger(j);
   return rtn;
endfunction

// returns True if "tofind" is in "list", otherwise False
function Bool find_str(String tofind, List#(String) list)
   = isValid(find_pos_string(tofind,list));

function InstructionROM_T assembler(function List#(AsmLineT) program_source(function ImmT findaddr(String label)));
   
      
   /********** phase 0 of the assembly process **********/   
   function ImmT no_label(String label) = -1;
      
   List#(AsmLineT) prog_phase_0 = program_source(no_label);
   let label_tbl = tpl_1(unzip(prog_phase_0));
      
   /********** phase 1 of the assembly process **********/   
   function ImmT label_lookup(String label) =
      fromInteger(fromMaybe(-1,find_pos_string(label,label_tbl)));

   List#(AsmLineT) prog_phase_1 = program_source(label_lookup);
   Integer prog_len = length(prog_phase_1);
   List#(WordT) rom = map(instruction2word, tpl_2(unzip(prog_phase_1)));
   
   return rom;
endfunction
   
									       
function Tuple2#(Bool,Fmt) find_duplicate_labels(function List#(AsmLineT) program_source(function ImmT findaddr(String label)));

   function Tuple2#(Bool,Fmt) report_duplicates(List#(String) labels);
      Fmt msg = $format("");
      Bool error = False;
      if(labels!=Nil)
	 begin
	    if((head(labels)!="") && find_str(head(labels),tail(labels)))
	       begin
		  msg = $format("Assembler error: label \"%s\" defined more than once\n",head(labels));
		  error = True;
	       end
	    let rd = report_duplicates(tail(labels));
	    error = error || tpl_1(rd);
	    msg = msg + tpl_2(rd);
	 end
      return tuple2(error,msg);
   endfunction
   
   function ImmT no_label(String label) = -1;
   List#(AsmLineT) labelled_prog = program_source(no_label);
   Tuple2#(List#(String), List#(InstructionT)) lab_prog = unzip(labelled_prog);
   let labels = tpl_1(lab_prog);
   return report_duplicates(labels);
endfunction


function Fmt disassemble(InstructionT inst);
   Fmt msg = $format("");

   case(inst) matches
      tagged Normal { op: .op, func: .func, shift: .shift, skip: .skip, rw: .rw, ra: .ra, rb: .rb}:
	 msg = msg + $format("%s-%s-%s-%s r%1d <- r%1d, %1d",
			     opcode2string(op),
			     func2string(func),
			     shift2string(shift),
			     skip2string(skip),
			     rw, ra, rb);
      tagged Immediate { rw: .rw, imm: .imm }:
	 msg = msg + $format("r%1d = %1d",rw,imm);
   endcase
   return msg;
   
endfunction
											    
   
function Fmt disassembleROM(InstructionROM_T rom);
   Fmt msg = $format("");   
   for(Integer a=0; a<length(rom); a=a+1)
      begin
	 InstructionT inst = word2instruction(rom[a]);
	 msg = msg + $format("pm[%2d] : ",a) + disassemble(inst) + $format("\n");
/*	 case(i) matches
	    tagged Normal { op: .op, func: .func, shift: .shift, skip: .skip, rw: .rw, ra: .ra, rb: .rb}:
	       msg = msg + $format("prog[%2d] : %s-%s-%s-%s r%1d <- r%1d, %1d\n",a,
				   opcode2string(op),
				   func2string(func),
				   shift2string(shift),
				   skip2string(skip),
				   rw, ra, rb);
	    tagged Immediate { rw: .rw, imm: .imm }:
	       msg = msg + $format("prog[%2d] : r%1d = %1d\n",a,rw,imm);
	 endcase
*/
      end
   return msg;
endfunction
   
											    
// assemble "the_program" (function with list of assembler) and create a ROM
module mkInstructionROM#(function List#(AsmLineT) the_program(function ImmT findaddr(String label)))
   (Server#(PCT, InstructionT)); 
   
   InstructionROM_T rom = assembler(the_program);
   
   FIFO#(InstructionT) out_fifo <- mkLFIFO;
   
   interface Put request;
      method Action put(addr);
	 out_fifo.enq(word2instruction(rom[addr]));
      endmethod
   endinterface
   interface response = toGet(out_fifo);
endmodule
   


// simple test									       
module mkTestAssembler(Empty);
   
   /********** the program we wish to assemble **********/
   function List#(AsmLineT) my_program(function ImmT findaddr(String label)) =
      cons(asmi("",    0, 0), // put 0 in r0
      cons(asmi("",    1, 10), // put 10 in r1
      cons(asmi("",    2, findaddr("loop")), // loop address in r2
      cons(asm("loop", OpOut, FDECb, ShiftNone, SkipNever, 1, 0, 1), // r1-- and output
      cons(asm("",     OpJump, FaORb, ShiftNone, SkipZero, 3, 2, 0), // jump r2 if not zero
      cons(asm("",     OpReserved, Freserved, ShiftNone, SkipNever, 0, 0, 0), // stop processor
      tagged Nil))))));
				  
   InstructionROM_T rom = assembler(my_program);

   // check assembly worked   
   Reg#(Bool) report_rom_state <- mkReg(True);
   rule disassemble (report_rom_state);
      report_rom_state <= False;
      // check for duplicate labels
      let fd = find_duplicate_labels(my_program);
      if(tpl_1(fd))
	 begin
	    $display("Assembler error - duplicate labels found:");
	    $write(tpl_2(fd)); // report any errors
	 end
      // produce disassembly of the program
      $write(disassembleROM(rom));
   endrule
   
endmodule


endpackage: TinyAsm
