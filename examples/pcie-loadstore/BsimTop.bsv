
import StmtFSM::*;
import AxiMasterSlave::*;
import FIFO::*;
import SpecialFIFOs::*;
import MemcpyWrapper::*;


import "BDPI" function Action      initPortal(Bit#(32) d);

import "BDPI" function Bool                    writeReq();
import "BDPI" function ActionValue#(Bit#(32)) writeAddr();
import "BDPI" function ActionValue#(Bit#(32)) writeData();

import "BDPI" function Bool                     readReq();
import "BDPI" function ActionValue#(Bit#(32))  readAddr();
import "BDPI" function Action        readData(Bit#(32) d);


module mkBsimTop();
    MemcpyWrapper dut <- mkMemcpyWrapper;
    let wf <- mkPipelineFIFO;
    let init_seq = (action 
                        initPortal(0);
                        initPortal(1);
                        initPortal(2);
                    endaction);
    let init_fsm <- mkOnce(init_seq);
    rule init_rule;
        init_fsm.start;
    endrule
    rule wrReq (writeReq());
        let wa <- writeAddr;
        let wd <- writeData;
        dut.ctrl.write.writeAddr(wa,0,0,0,0,0,0);
        wf.enq(wd);
    endrule
    rule wrData;
        wf.deq;
        dut.ctrl.write.writeData(wf.first,0,0);
    endrule
    rule rdReq (readReq());
        let ra <- readAddr;
        dut.ctrl.read.readAddr(ra,0,0,0,0,0,0);
    endrule
    rule rdResp;
        let rd <- dut.ctrl.read.readData;
        readData(rd);
    endrule
endmodule
