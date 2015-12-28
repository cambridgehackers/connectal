
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
   AvalonBfmWrapper.bsv
   avlm_avls_1x1.v
*/

import Clocks::*;
import DefaultValue::*;
import XilinxCells::*;
import GetPut::*;
import AvalonBits::*;

(* always_ready, always_enabled *)
interface AvalonBfmWrapper#(numeric type addrWidth, numeric type dataWidth);
    //interface AvalonMMasterBits#(addrWidth, dataWidth) master_0;
    interface AvalonMSlaveBits#(addrWidth, dataWidth)  slave_0;
endinterface
import "BVI" avlm_avls_1x1 =
module mkAvalonBfmWrapper(AvalonBfmWrapper#(addrWidth, dataWidth));
    default_clock clk();
    default_reset rst();
        input_clock (clk_clk) <- exposeCurrentClock;
        input_reset (reset_reset_n) <- exposeCurrentReset;
//    interface AvalonMMasterBits     master_0;
//        method master_0_m0_address address();
//        method master_0_m0_burstcount burstcount();
//        method master_0_m0_byteenable byteenable();
//        method master_0_m0_read read();
//        method readdata(master_0_m0_readdata) enable((*inhigh*) EN_master_0_m0_readdata);
//        method readdatavalid(master_0_m0_readdatavalid) enable((*inhigh*) EN_master_0_m0_readdatavalid);
//        method waitrequest(master_0_m0_waitrequest) enable((*inhigh*) EN_master_0_m0_waitrequest);
//        method master_0_m0_write write();
//        method master_0_m0_writedata writedata();
//    endinterface
    interface AvalonMSlaveBits     slave_0;
        method address(slave_0_s0_address) enable((*inhigh*) EN_slave_0_s0_address);
        method burstcount(slave_0_s0_burstcount) enable((*inhigh*) EN_slave_0_s0_burstcount);
        method byteenable(slave_0_s0_byteenable) enable((*inhigh*) EN_slave_0_s0_byteenable);
        method read(slave_0_s0_read) enable((*inhigh*) EN_slave_0_s0_read);
        method slave_0_s0_readdata readdata();
        method slave_0_s0_readdatavalid readdatavalid();
        method slave_0_s0_waitrequest waitrequest();
        method write(slave_0_s0_write) enable((*inhigh*) EN_slave_0_s0_write);
        method writedata(slave_0_s0_writedata) enable((*inhigh*) EN_slave_0_s0_writedata);
    endinterface
    //schedule (master_0.address, master_0.burstcount, master_0.byteenable, master_0.read, master_0.readdata, master_0.readdatavalid, master_0.waitrequest, master_0.write, master_0.writedata, slave_0.address, slave_0.burstcount, slave_0.byteenable, slave_0.read, slave_0.readdata, slave_0.readdatavalid, slave_0.waitrequest, slave_0.write, slave_0.writedata) CF (master_0.address, master_0.burstcount, master_0.byteenable, master_0.read, master_0.readdata, master_0.readdatavalid, master_0.waitrequest, master_0.write, master_0.writedata, slave_0.address, slave_0.burstcount, slave_0.byteenable, slave_0.read, slave_0.readdata, slave_0.readdatavalid, slave_0.waitrequest, slave_0.write, slave_0.writedata);
    schedule (slave_0.address, slave_0.burstcount, slave_0.byteenable, slave_0.read, slave_0.readdata, slave_0.readdatavalid, slave_0.waitrequest, slave_0.write, slave_0.writedata) CF (slave_0.address, slave_0.burstcount, slave_0.byteenable, slave_0.read, slave_0.readdata, slave_0.readdatavalid, slave_0.waitrequest, slave_0.write, slave_0.writedata);
endmodule
