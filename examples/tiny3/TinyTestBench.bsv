package TinyTestBench;

import FIFO::*;
import GetPut::*;
import StmtFSM::*;
import TinyTypes::*;
import TinyAsm::*;
import Tiny3::*;
import BRAM::*;


module mkTestBenchA(Empty);

   /********** the program we wish to assemble **********/
   function List#(AsmLineT) my_program(function ImmT findaddr(String label)) =
      cons(asmi("",    0, 0), // put 0 in r0
      cons(asmi("",    1, 10), // put 10 in r1
      cons(asmi("",    2, findaddr("loop")), // loop address in r2
      cons(asm("loop", OpOut, FDECb, ShiftNone, SkipNever, 1, 0, 1), // r1-- and output
      cons(asm("",     OpJump, FaORb, ShiftNone, SkipZero, 3, 2, 0), // jump r2 if not zero
      cons(asm("",     OpReserved, Freserved, ShiftNone, SkipNever, 0, 0, 0), // stop processor
      tagged Nil))))));

   InstructionROM_T irom = assembler(my_program);
   
   TinyCompIfc tiny <- mkTinyComp(irom);

   rule handle_output;
      let out <- tiny.out.get();
      $display("%05t: output = %d\n",$time,out);
   endrule

endmodule



endpackage: TinyTestBench

