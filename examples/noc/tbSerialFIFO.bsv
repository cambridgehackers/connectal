import SerialFIFO::*;

(* synthesize *)
module mkTb(Empty);
   
   SerialFIFO#(Bit#(32)) x <- mkSerialFIFO();
   
   Reg#(Bit#(32)) t <- mkReg(0);
   
   rule doempty;
      $display("x.out.first %x", x.out.first);
      x.out.deq();
   endrule
   
   rule dotest;
      $display("x.in.enq %x", t);
      x.in.enq(t);
   endrule
   
   rule doinc;
      t <= t + 1;
      if (t > 1000) $finish(0);
   endrule
   
 endmodule

