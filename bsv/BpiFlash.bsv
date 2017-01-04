
`include "ConnectalProjectConfig.bsv"
import Vector::*;
import Clocks::*;
import Connectable::*;
import GetPut::*;
import FIFOF::*;
import BRAM::*;
import Probe::*;
import StmtFSM::*;
import TriState::*;
import Vector::*;
import ConnectalXilinxCells::*;

`ifdef SIMULATION
import I28F512P33::*;
`endif

// interface to BPI Flash (PC28F00AG18FE)

(* always_ready, always_enabled *)
interface BpiFlashPins;
   interface Clock deleteme_unused_clock;
//   interface Reset rst;
   interface Vector#(16,Inout#(Bit#(1))) data;
   method Bit#(26) addr();
   method Bit#(1) adv_b();
   method Bit#(1) ce_b();
   method Bit#(1) oe_b();
   method Bit#(1) we_b();
`ifdef BPI_HAS_WP
   method Bit#(1) wp_b();
`endif
`ifdef BPI_HAS_VPP
   method Bit#(1) vpp();
`endif
   method Action wait_in(Bit#(1) b);
endinterface

interface BpiPins;
   interface BpiFlashPins flash;
endinterface

interface BpiFlash;
   interface BpiFlashPins flash;
   method Action setParameters(Bit#(16) cycles, Bool stallOnWaitIn);
   interface Server#(BRAMRequest#(Bit#(26),Bit#(16)),Bit#(16)) server;
endinterface

module mkBpiFlash(BpiFlash);
   let clock <- exposeCurrentClock();
   let reset <- exposeCurrentReset();

   Reg#(Bit#(1)) rst_o <- mkReg(0);
   Reg#(Bit#(1)) ce <- mkReg(1);
   Reg#(Bit#(1)) we <- mkReg(1);
   Reg#(Bit#(1)) oe <- mkReg(1);
   Reg#(Bit#(1)) adv <- mkReg(1);
   Reg#(Bit#(16)) data_o <- mkReg(0);
   Reg#(Bit#(26)) addr_o <- mkReg(0);
   Reg#(Bit#(16)) delayReg <- mkReg(10);
   Reg#(Bool)     stallOnWaitReg  <- mkReg(False);
   Reg#(BRAMRequest#(Bit#(26),Bit#(16))) reqReg <- mkReg(unpack(0));
   FIFOF#(BRAMRequest#(Bit#(26),Bit#(16))) reqFifo <- mkFIFOF();
   FIFOF#(Bit#(16)) dataFifo <- mkFIFOF();

`ifndef SIMULATION
   Wire#(Bit#(1)) wait_in_b <- mkDWire(0);
   module mkDataIobuf#(Integer i)(IOBUF);
      (* hide *)
      let iobuf <- mkIOBUF(we, data_o[i]);
      return iobuf;
   endmodule
   function Inout#(Bit#(1)) iobuf_io(IOBUF iobuf); return iobuf.io; endfunction
   function Bit#(1) iobuf_o(IOBUF iobuf); return iobuf.o; endfunction
   Vector#(16, IOBUF) iobuf <- genWithM(mkDataIobuf);
   let dataIn = pack(map(iobuf_o, iobuf));
`endif

`ifdef SIMULATION
   let flash <- mkI28f512p33Load("flash.hex");
   let dataTristate <- mkTriState(oe == 1, data_o);
   mkConnection(dataTristate.io, flash.dq);
   let wait_in_b = flash.waitout();
   let dataIn = dataTristate;
   rule rl_flash_inputs;
      flash.addr(addr_o);
      flash.advneg(adv);
      flash.ceneg(ce);
      flash.oeneg(oe);
      flash.weneg(we);
      flash.wpneg(1);
      flash.vpp(0);
   endrule
`endif

   Reg#(Bit#(10)) i <- mkReg(0);

   let readFsm <- mkAutoFSM(seq
			while (True) seq
			   action

			      reqFifo.deq();
			      let req = reqFifo.first();
			      reqReg <= req;
			      addr_o <= req.address;
			      data_o <= req.datain;
			      adv <= 0;
			      ce <= 0;
			   endaction
			   delay(delayReg);
			   adv <= 1;
			   delay(delayReg);
			   action
			      if (reqReg.write)
				 we <= 0;
			      else
				 oe <= 0;
			   endaction
			   delay(delayReg);
      $display("addr_o=%x\n", addr_o);
      $display("wait_in_b=%d dataIn=%x", wait_in_b, dataIn);
			   if (reqReg.write)
			      we <= 1;
			   if (!reqReg.write && stallOnWaitReg) await (wait_in_b == 1);
      $display("wait_in_b=%d dataIn=%x", wait_in_b, dataIn);
			   if (!reqReg.write || reqReg.responseOnWrite)
			      dataFifo.enq(dataIn);
			   delay(delayReg);
			   ce <= 1;
			   oe <= 1;
			   delay(delayReg);
			   endseq
			endseq);

   method Action setParameters(Bit#(16) cycles, Bool stallOnWaitIn);
      delayReg <= cycles;
      stallOnWaitReg <= stallOnWaitIn;
   endmethod
   interface Server server;
      interface request = toPut(reqFifo);
      interface response = toGet(dataFifo);
   endinterface
`ifndef SIMULATION
   interface BpiFlashPins flash;
      interface deleteme_unused_clock = clock;
//          interface rst = defaultReset;
      interface data = map(iobuf_io, iobuf);
      method Bit#(26) addr = addr_o;
      method Bit#(1) adv_b = adv;
      method Bit#(1) ce_b = ce;
      method Bit#(1) oe_b = oe;
      method Bit#(1) we_b = we;
`ifdef BPI_HAS_WP
      method Bit#(1) wp_b = 1;
`endif
`ifdef BPI_HAS_VPP
      method Bit#(1) vpp = 0;
`endif
      method Action wait_in(Bit#(1) b);
	 wait_in_b <= b;
      endmethod
   endinterface
`endif
endmodule
