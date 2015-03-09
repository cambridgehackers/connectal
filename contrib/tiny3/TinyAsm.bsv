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


function Fmt disassembleROM(InstructionROM_T rom);
   Fmt msg = $format("");   
   for(Integer a=0; a<length(rom); a=a+1)
      begin
	 InstructionT inst = word2instruction(rom[a]);
	 msg = msg + $format("pm[%2d] : ",a) + fshow(inst) + $format("\n");
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
   

endpackage: TinyAsm
