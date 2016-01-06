
import Connectable::*;
import GetPut::*;
import FIFOF::*;
import StmtFSM::*;
import TriState::*;
import Vector::*;
import ConnectalXilinxCells::*;
import BpiFlash::*;
`ifdef SIMULATION
import I28F512P33::*;
`endif

interface BpiFlashTestRequest;
   method Action reset();
   method Action read(Bit#(25) addr);
   method Action write(Bit#(25) addr, Bit#(16) data);
endinterface

interface BpiFlashTestIndication;
   method Action resetDone();
   method Action readDone(Bit#(16) data);
   method Action writeDone();
endinterface

interface BpiFlashTest;
   interface BpiFlashTestRequest request;
   interface BpiPins pins;
endinterface

module mkBpiFlashTest#(BpiFlashTestIndication ind)(BpiFlashTest);

   let defaultClock <- exposeCurrentClock();
   let defaultReset <- exposeCurrentReset();

   Reg#(Bit#(1)) rst_o <- mkReg(0);
   Reg#(Bit#(1)) ce <- mkReg(1);
   Reg#(Bit#(1)) we <- mkReg(1);
   Reg#(Bit#(1)) oe <- mkReg(1);
   Reg#(Bit#(1)) adv <- mkReg(1);
   Reg#(Bit#(16)) data_o <- mkReg(0);
   Reg#(Bit#(25)) addr_o <- mkReg(0);
   FIFOF#(Bit#(25)) addrFifo <- mkFIFOF();
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

   let readFsm <- mkFSM(seq
			while (True) seq
			   action
			      addrFifo.deq();
			      addr_o <= addrFifo.first() >> 1;
			      adv <= 0;
			      ce <= 0;
			   endaction
			   adv <= 1;
			   oe <= 0;
      $display("addr_o=%x\n", addr_o);
      $display("wait_in_b=%d dataIn=%x", wait_in_b, dataIn);
			   await (wait_in_b == 0);
      $display("wait_in_b=%d dataIn=%x", wait_in_b, dataIn);
			   dataFifo.enq(dataIn);
			   ce <= 1;
			   oe <= 1;
			   endseq
			endseq);
   
   let resetFsm <- mkFSM(seq
			 rst_o <= 0;
			 rst_o <= 1;
			 ind.resetDone();
			 readFsm.start();
			 endseq);

   rule rl_readDone;
      let v <- toGet(dataFifo).get();
      ind.readDone(v);
   endrule

   interface BpiFlashTestRequest request;
      method Action reset();
	 resetFsm.start();
      endmethod
      method Action read(Bit#(25) addr);
	 addrFifo.enq(addr);   
      endmethod
      method Action write(Bit#(25) addr, Bit#(16) data);
      endmethod
   endinterface
`ifndef SIMULATION
   interface BpiPins pins;
       interface BpiFlashPins flash;
	  interface deleteme_unused_clock = defaultClock;
//          interface rst = defaultReset;
	  interface data = map(iobuf_io, iobuf);
	  method Bit#(25) addr = addr_o;
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
   endinterface
`endif
endmodule
