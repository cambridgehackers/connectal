import DDS::*;
import FixedPoint::*;
import Pipe::*;

(* synthesize *)
module mkTb(Empty);
   
   DDS dds <- mkDDS();
   
   Reg#(Bit#(1)) started <- mkReg(0);
   Reg#(Bit#(12)) count <- mkReg(0);

   
   rule showoutput;
      DDSOutType y = dds.osc.first();
      $write("%4d ", count);
      $display(fshow(y));
      count <= count + 1;
      dds.osc.deq();
      if (count >= 1032) $finish;
   endrule
   
   rule start (started == 0);
      Int#(10) v = 1;
      FixedPoint#(10,23) pa = fromInt(v);
      dds.setPhaseAdvance(pa);
      started <= 1;
      $display("started");
   endrule
   
 endmodule

