
/*
   /home/hwang/dev/connectal/generated/scripts/importbvi.py
   -I
   AvalonMM
   -P
   AvalonMM
   -c
   clk_clk
   -r
   reset_reset_n
   -f
   master_0
   -f
   slave_0
   -o
   AvalonBFM.bsv
   avlm_avls_1x1.v
*/

import Clocks::*;
import DefaultValue::*;
import XilinxCells::*;
import GetPut::*;
import AxiBits::*;

(* always_ready, always_enabled *)
interface AvalonmmMaster_0;
    method Bit#(12)     m0_address();
    method Bit#(4)     m0_burstcount();
    method Bit#(4)     m0_byteenable();
    method Bit#(1)     m0_read();
    method Action      m0_readdata(Bit#(32) v);
    method Action      m0_readdatavalid(Bit#(1) v);
    method Action      m0_waitrequest(Bit#(1) v);
    method Bit#(1)     m0_write();
    method Bit#(32)     m0_writedata();
endinterface
(* always_ready, always_enabled *)
interface AvalonmmSlave_0;
    method Action      s0_address(Bit#(30) v);
    method Action      s0_burstcount(Bit#(3) v);
    method Action      s0_byteenable(Bit#(4) v);
    method Action      s0_read(Bit#(1) v);
    method Bit#(32)     s0_readdata();
    method Bit#(1)     s0_readdatavalid();
    method Bit#(1)     s0_waitrequest();
    method Action      s0_write(Bit#(1) v);
    method Action      s0_writedata(Bit#(32) v);
endinterface
(* always_ready, always_enabled *)
interface AvalonMM;
    interface AvalonmmMaster_0     master_0;
    interface AvalonmmSlave_0     slave_0;
endinterface
import "BVI" avlm_avls_1x1 =
module mkAvalonMM(AvalonMM);
    default_clock clk();
    default_reset rst();
        input_clock (clk_clk) <- exposeCurrentClock;
        input_reset (reset_reset_n) <- exposeCurrentReset;
    interface AvalonmmMaster_0     master_0;
        method master_0_m0_address m0_address();
        method master_0_m0_burstcount m0_burstcount();
        method master_0_m0_byteenable m0_byteenable();
        method master_0_m0_read m0_read();
        method m0_readdata(master_0_m0_readdata) enable((*inhigh*) EN_master_0_m0_readdata);
        method m0_readdatavalid(master_0_m0_readdatavalid) enable((*inhigh*) EN_master_0_m0_readdatavalid);
        method m0_waitrequest(master_0_m0_waitrequest) enable((*inhigh*) EN_master_0_m0_waitrequest);
        method master_0_m0_write m0_write();
        method master_0_m0_writedata m0_writedata();
    endinterface
    interface AvalonmmSlave_0     slave_0;
        method s0_address(slave_0_s0_address) enable((*inhigh*) EN_slave_0_s0_address);
        method s0_burstcount(slave_0_s0_burstcount) enable((*inhigh*) EN_slave_0_s0_burstcount);
        method s0_byteenable(slave_0_s0_byteenable) enable((*inhigh*) EN_slave_0_s0_byteenable);
        method s0_read(slave_0_s0_read) enable((*inhigh*) EN_slave_0_s0_read);
        method slave_0_s0_readdata s0_readdata();
        method slave_0_s0_readdatavalid s0_readdatavalid();
        method slave_0_s0_waitrequest s0_waitrequest();
        method s0_write(slave_0_s0_write) enable((*inhigh*) EN_slave_0_s0_write);
        method s0_writedata(slave_0_s0_writedata) enable((*inhigh*) EN_slave_0_s0_writedata);
    endinterface
    schedule (master_0.m0_address, master_0.m0_burstcount, master_0.m0_byteenable, master_0.m0_read, master_0.m0_readdata, master_0.m0_readdatavalid, master_0.m0_waitrequest, master_0.m0_write, master_0.m0_writedata, slave_0.s0_address, slave_0.s0_burstcount, slave_0.s0_byteenable, slave_0.s0_read, slave_0.s0_readdata, slave_0.s0_readdatavalid, slave_0.s0_waitrequest, slave_0.s0_write, slave_0.s0_writedata) CF (master_0.m0_address, master_0.m0_burstcount, master_0.m0_byteenable, master_0.m0_read, master_0.m0_readdata, master_0.m0_readdatavalid, master_0.m0_waitrequest, master_0.m0_write, master_0.m0_writedata, slave_0.s0_address, slave_0.s0_burstcount, slave_0.s0_byteenable, slave_0.s0_read, slave_0.s0_readdata, slave_0.s0_readdatavalid, slave_0.s0_waitrequest, slave_0.s0_write, slave_0.s0_writedata);
endmodule
