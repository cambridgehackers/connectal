
`include "ConnectalProjectConfig.bsv"
import Connectable::*;
import GetPut::*;
import FIFOF::*;
import BRAM::*;
import Probe::*;
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
   method Action setParameters(Bit#(16) cycles, Bool stallOnWaitIn);
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
   Reg#(Bit#(16)) delayReg <- mkReg(10);
   Reg#(Bool)     stallOnWaitReg  <- mkReg(False);
   Reg#(BRAMRequest#(Bit#(25),Bit#(16))) reqReg <- mkReg(unpack(0));
   FIFOF#(BRAMRequest#(Bit#(25),Bit#(16))) reqFifo <- mkFIFOF();
   FIFOF#(Bit#(16)) dataFifo <- mkFIFOF();
   FIFOF#(Bool)     doneFifo <- mkFIFOF();

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

   let readFsm <- mkFSM(seq
			   $dumpfile("bpiflash.vcd");
			   $dumpvars();
			   $dumpoff();
			while (True) seq
			   action
			      $dumpon();

			      reqFifo.deq();
			      let req = reqFifo.first();
			      reqReg <= req;
			      addr_o <= req.address >> 1;
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
			   if (reqReg.write)
			      doneFifo.enq(True);
			   else
			      dataFifo.enq(dataIn);
			   delay(delayReg);
			   ce <= 1;
			   oe <= 1;
			   delay(delayReg);
			   endseq
      $dumpoff();
      $dumpflush();
			endseq);
   
   let resetFsm <- mkFSM(seq
			 rst_o <= 0;
			 delay(20);
			 rst_o <= 1;
			 ind.resetDone();
			 readFsm.start();
			 endseq);

   rule rl_readDone;
      let v <- toGet(dataFifo).get();
      ind.readDone(v);
   endrule
   rule rl_writeDone;
      let v <- toGet(doneFifo).get();
      ind.writeDone();
   endrule

   let probe_addr <- mkProbe();
   let probe_adv <- mkProbe();
   let probe_ce <- mkProbe();
   let probe_oe <- mkProbe();
   let probe_we <- mkProbe();
   let probe_data_in <- mkProbe();
   let probe_data_out <- mkProbe();
   let probe_wait_in <- mkProbe();
   rule rl_probe;
      probe_addr <= addr_o;
      probe_adv <= adv;
      probe_ce <= ce;
      probe_oe <= oe;
      probe_we <= we;
      probe_data_in <= dataIn;
      probe_data_out <= data_o;
      probe_wait_in <= wait_in_b;
   endrule

   interface BpiFlashTestRequest request;
      method Action reset();
	 resetFsm.start();
      endmethod
      method Action read(Bit#(25) addr);
	 reqFifo.enq(BRAMRequest {address: addr, write: False, responseOnWrite: False, datain: 0});
      endmethod
      method Action write(Bit#(25) addr, Bit#(16) data);
	 reqFifo.enq(BRAMRequest {address: addr, write: True, responseOnWrite: False, datain: data});
      endmethod
      method Action setParameters(Bit#(16) cycles, Bool stallOnWaitIn);
	 delayReg <= cycles;
	 stallOnWaitReg <= stallOnWaitIn;
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
