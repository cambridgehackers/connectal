package TinyTestBench;

import FIFO::*;
import GetPut::*;
import StmtFSM::*;
import TinyTypes::*;
import TinyAsm::*;
import Tiny3::*;
import BRAM::*;
import Vector::*;
import BuildVector::*;


// example assembler program - a simple loop with output
function List#(AsmLineT) simple_loop(function ImmT findaddr(String label));
  let program_memory = vec(
     asmi("",    0, 0),                                             // r0 = 0
     asmi("",    1, 10),                                            // r1 = 10
     asmi("",    2, findaddr("loop")),                              // r2 = loop address
     asm("loop", OpOut,      FDECb, ShiftNone, SkipZero,  1, 0, 1), // r1-- and output, skip if zero
     asm("",     OpJump,     FaORb, ShiftNone, SkipNever,32, 2, 0), // jump r2, r32=temporary to dispose of func result
     asm("",     OpReserved, FaORb, ShiftNone, SkipNever, 0, 0, 0)  // stop processor
     );
  return toList(program_memory);
endfunction


// example assembler to do a simple memory test
function List#(AsmLineT) simple_memory_test(function ImmT findaddr(String label));
  let program_memory = vec(
     asmi("",       0, 0),                                              // put 0 in r0
     asmi("",       1, 16),                                             // put 16 in r1 (loop max)
     asmi("",       2, 4),                                              // initial data value
     asmi("",       16, findaddr("memfill")),                           // loop address in r16
     asm("memfill", OpStoreDM, FaORb,  ShiftNone, SkipNever, 32, 2, 0), // store: dmem[r0] = r2
     asm("",        OpNormal,   FaADDb,ShiftNone, SkipNever,  2, 2, 2), // r2=r2+r2
     asm("",        OpNormal,   FINCb, ShiftNone, SkipNever,  0, 0, 0), // r0++
     asm("",        OpNormal,   FDECb, ShiftNone, SkipZero,   1, 0, 1), // r1--, skip if zero
     asm("",        OpJump,     FaORb, ShiftNone, SkipNever, 32,16,16), // jump r2 (skipped if r1 was zero)
     asmi("",       0, 0),                                              // put 0 in r0
     asmi("",       1, 16),                                             // put 16 in r1 (loop max)
     asmi("",       16, findaddr("memread")),                           // loop address in r16
     asm("memread", OpLoadDM,   FaORb, ShiftNone, SkipNever,  2, 0, 0), // r2=dmem[r0]
     asm("",        OpOut,      FaORb, ShiftNone, SkipNever,  2, 2, 2), // output r2
     asm("",        OpNormal,   FINCb, ShiftNone, SkipNever,  0, 0, 0), // r0++
     asm("",        OpNormal,   FDECb, ShiftNone, SkipZero,   1, 0, 1), // r1--, skip if zero
     asm("",        OpJump,     FaORb, ShiftNone, SkipNever, 32,16,16), // jump r2 (skipped if r1 was zero)
     asm("",        OpReserved, FaORb, ShiftNone, SkipNever,  0, 0, 0)  // stop processor
     );
  return toList(program_memory);
endfunction


module mkTinyTestBench(Empty);
  
  let codeToRun = simple_loop;
//  let codeToRun = simple_memory_test;

  InstructionROM_T irom = assembler(codeToRun);
  
  TinyCompIfc tiny <- mkTinyComp(irom);

  // check assembly of ROM worked   
  Reg#(Bool) report_rom_state <- mkReg(True);
  rule disassemble (report_rom_state);
    report_rom_state <= False;
    // check for duplicate labels
    let fd = find_duplicate_labels(codeToRun);
    if(tpl_1(fd))
      begin
	$display("Assembler error - duplicate labels found:");
	$write(tpl_2(fd)); // report any errors
      end
  endrule

  rule handle_output;
      let out <- tiny.out.get();
      $display("%05t: \t\t\t*********************",$time);
      $display("%05t: \t\t\t* output = %8d *",$time,out);
      $display("%05t: \t\t\t*********************",$time);
  endrule

endmodule



endpackage: TinyTestBench

