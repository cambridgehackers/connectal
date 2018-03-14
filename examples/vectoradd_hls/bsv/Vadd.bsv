
import GetPut::*;
import FIFOF::*;
import VaddBvi::*;

interface VaddRequest;
   method Action data(Bit#(32) in0, Bit#(32) in1);
endinterface
interface VaddResponse;
   method Action data(Bit#(32) out);
endinterface

interface Vadd64;
   interface Put#(Bit#(32)) in0;
   interface Put#(Bit#(32)) in1;
   interface Get#(Bit#(32)) out;
endinterface

module mkVadd64(Vadd64);
   VaddBvi vadd <- mkVaddBvi();
   
   FIFOF#(Bit#(32)) in0Fifo <- mkSizedFIFOF(64);
   FIFOF#(Bit#(32)) in1Fifo <- mkSizedFIFOF(64);
   FIFOF#(Bit#(32)) outFifo <- mkSizedFIFOF(64);

   Reg#(Bool) started <- mkReg(False);

   rule rl_start if (!in0Fifo.notFull() && !in1Fifo.notFull() && vadd.ap_ready == 1 && !started);
      vadd.ap_start(1);
      $display("starting");
      started <= True;
   endrule

   rule rl_done if (vadd.ap_done == 1);
      $display("done");
   endrule

   rule rl_in0_data;
      $display("in0 %d", in0Fifo.first);
      vadd.in0(in0Fifo.first);
   endrule
   rule rl_in0_hs;
      vadd.in0_ap_vld(pack(in0Fifo.notEmpty()));
      if (vadd.in0_ap_ack() == 1)
	 in0Fifo.deq();
   endrule
   rule rl_in1_data;
      $display("in1 %d", in1Fifo.first);
      vadd.in1(in1Fifo.first);
   endrule
   rule rl_in1_hs;
      vadd.in1_ap_vld(pack(in1Fifo.notEmpty()));
      if (vadd.in1_ap_ack() == 1)
	 in1Fifo.deq();
   endrule
   rule rl_out_data;
      if (vadd.out_r_ap_vld() == 1) begin
	 outFifo.enq(vadd.out_r());
	 $display("out %d", vadd.out_r());
      end
   endrule
   rule rl_out_hs;
      vadd.out_r_ap_ack(pack(vadd.out_r_ap_vld() == 1 && outFifo.notFull()));
   endrule

   interface Put in0 = toPut(in0Fifo);
   interface Put in1 = toPut(in1Fifo);
   interface Get out = toGet(outFifo);

endmodule

interface Vadd;
   interface VaddRequest request;
endinterface

module mkVadd#(VaddResponse response)(Vadd);
   Vadd64 vadd64 <- mkVadd64();

   rule rl_response;
      let v <- vadd64.out.get();
      response.data(v);
   endrule

   interface VaddRequest request;
      method Action data(Bit#(32) in0, Bit#(32) in1);
	 vadd64.in0.put(in0);
	 vadd64.in1.put(in1);
      endmethod
   endinterface
endmodule
