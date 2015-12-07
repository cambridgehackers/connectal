
/*
   ./importbvi.py
   -o
   ALTERA_DDR3_WRAPPER.bsv
   -I
   AvalonDdr3
   -P
   AvalonDdr3
   -c
   pll_ref_clk
   -r
   global_reset_n
   -r
   soft_reset_n
   -c
   afi_clk
   -c
   afi_half_clk
   -r
   afi_reset_n
   -r
   afi_reset_export_n
   -f
   mem
   -f
   avl
   -f
   status
   -f
   oct
   -f
   pll
   /home/hwang/dev/connectal/out/de5/synthesis/altera_mem_if_ddr3_emif_wrapper/altera_mem_if_ddr3_emif_wrapper.v
*/

import Clocks::*;
import DefaultValue::*;
import XilinxCells::*;
import GetPut::*;
import AxiBits::*;
import Vector::*;

(* always_ready, always_enabled *)
interface Avalonddr3Afi;
    interface Clock     clk;
    interface Clock     half_clk;
    method Reset     reset_export_n();
    method Reset     reset_n();
endinterface
(* always_ready, always_enabled *)
interface Avalonddr3Avl;
    method Action      addr(Bit#(25) v);
    method Action      be(Bit#(64) v);
    method Action      burstbegin(Bit#(1) v);
    method Bit#(512)     rdata();
    method Bit#(1)     rdata_valid();
    method Action      read_req(Bit#(1) v);
    method Bit#(1)     wait_request();
    method Action      size(Bit#(3) v);
    method Action      wdata(Bit#(512) v);
    method Action      write_req(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface Avalonddr3status;
    method Bit#(1)     cal_fail();
    method Bit#(1)     cal_success();
    method Bit#(1)     init_done();
endinterface
(* always_ready, always_enabled *)
interface Avalonddr3Mem;
    method Bit#(15)     a();
    method Bit#(3)     ba();
    method Bit#(1)     cas_n();
    method Vector#(1, Bit#(1))     ck();
    method Bit#(1)     ck_n();
    method Bit#(1)     cke();
    method Bit#(1)     cs_n();
    method Bit#(8)     dm();
    interface Inout#(Bit#(64))     dq;
    interface Inout#(Bit#(8))     dqs;
    interface Inout#(Bit#(8))     dqs_n;
    method Bit#(1)     odt();
    method Bit#(1)     ras_n();
    method Bit#(1)     reset_n();
    method Bit#(1)     we_n();
endinterface
(* always_ready, always_enabled *)
interface Avalonddr3Oct;
    (* prefix="" *)
    method Action      rzqin( (* port="rzq_4" *) Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface Avalonddr3Pll;
    method Bit#(1)     addr_cmd_clk();
    method Bit#(1)     avl_clk();
    method Bit#(1)     c2p_write_clk();
    method Bit#(1)     config_clk();
    method Bit#(1)     hr_clk();
    method Bit#(1)     locked();
    method Bit#(1)     mem_clk();
    method Bit#(1)     p2c_read_clk();
    method Bit#(1)     write_clk();
    method Bit#(1)     write_clk_pre_phy_clk();
endinterface
(* always_ready, always_enabled *)
interface AvalonDdr3;
    interface Avalonddr3Afi     afi;
    interface Avalonddr3Avl     avl;
    interface Avalonddr3status  status;
    interface Avalonddr3Mem     mem;
    interface Avalonddr3Oct     oct;
    interface Avalonddr3Pll     pll;
endinterface
import "BVI" altera_mem_if_ddr3_emif_wrapper =
module mkAvalonDdr3#(Clock pll_ref_clk, Reset global_reset_n, Reset soft_reset_n)(AvalonDdr3);
    default_clock clk();
    default_reset rst();
        input_reset global_reset_n(global_reset_n) = global_reset_n;
        input_clock pll_ref_clk(pll_ref_clk) = pll_ref_clk;
        input_reset soft_reset_n(soft_reset_n) = soft_reset_n;
    interface Avalonddr3Afi     afi;
        output_clock clk(afi_clk);
        output_clock half_clk(afi_half_clk);
        output_reset reset_export_n(afi_reset_export_n);
        output_reset reset_n(afi_reset_n);
    endinterface
    interface Avalonddr3Avl     avl;
        method addr(avl_addr) enable((*inhigh*) EN_avl_addr);
        method be(avl_be) enable((*inhigh*) EN_avl_be);
        method burstbegin(avl_burstbegin) enable((*inhigh*) EN_avl_burstbegin);
        method avl_rdata rdata();
        method avl_rdata_valid rdata_valid();
        method read_req(avl_read_req) enable((*inhigh*) EN_avl_read_req);
        method avl_ready wait_request();
        method size(avl_size) enable((*inhigh*) EN_avl_size);
        method wdata(avl_wdata) enable((*inhigh*) EN_avl_wdata);
        method write_req(avl_write_req) enable((*inhigh*) EN_avl_write_req);
    endinterface
    interface Avalonddr3status     status;
        method status_cal_fail cal_fail();
        method status_cal_success cal_success();
        method status_init_done init_done();
    endinterface
    interface Avalonddr3Mem     mem;
        method mem_a a();
        method mem_ba ba();
        method mem_cas_n cas_n();
        method mem_ck ck();
        method mem_ck_n ck_n();
        method mem_cke cke();
        method mem_cs_n cs_n();
        method mem_dm dm();
        ifc_inout dq(mem_dq);
        ifc_inout dqs(mem_dqs);
        ifc_inout dqs_n(mem_dqs_n);
        method mem_odt odt();
        method mem_ras_n ras_n();
        method mem_reset_n reset_n();
        method mem_we_n we_n();
    endinterface
    interface Avalonddr3Oct     oct;
        method rzqin(oct_rzqin) enable((*inhigh*) EN_oct_rzqin);
    endinterface
    interface Avalonddr3Pll     pll;
        method pll_addr_cmd_clk addr_cmd_clk() clocked_by (pll_ref_clk);
        method pll_avl_clk avl_clk() clocked_by (pll_ref_clk);
        method pll_c2p_write_clk c2p_write_clk() clocked_by (pll_ref_clk);
        method pll_config_clk config_clk() clocked_by (pll_ref_clk);
        method pll_hr_clk hr_clk() clocked_by (pll_ref_clk);
        method pll_locked locked() clocked_by (pll_ref_clk);
        method pll_mem_clk mem_clk() clocked_by (pll_ref_clk);
        method pll_p2c_read_clk p2c_read_clk() clocked_by (pll_ref_clk);
        method pll_write_clk write_clk() clocked_by (pll_ref_clk);
        method pll_write_clk_pre_phy_clk write_clk_pre_phy_clk() clocked_by (pll_ref_clk);
    endinterface
    schedule (avl.addr, avl.be, avl.burstbegin, avl.rdata, avl.rdata_valid, avl.read_req, avl.wait_request, avl.size, avl.wdata, avl.write_req, status.cal_fail, status.cal_success, status.init_done, mem.a, mem.ba, mem.cas_n, mem.ck, mem.ck_n, mem.cke, mem.cs_n, mem.dm, mem.odt, mem.ras_n, mem.reset_n, mem.we_n, oct.rzqin, pll.addr_cmd_clk, pll.avl_clk, pll.c2p_write_clk, pll.config_clk, pll.hr_clk, pll.locked, pll.mem_clk, pll.p2c_read_clk, pll.write_clk, pll.write_clk_pre_phy_clk) CF (avl.addr, avl.be, avl.burstbegin, avl.rdata, avl.rdata_valid, avl.read_req, avl.wait_request, avl.size, avl.wdata, avl.write_req, status.cal_fail, status.cal_success, status.init_done, mem.a, mem.ba, mem.cas_n, mem.ck, mem.ck_n, mem.cke, mem.cs_n, mem.dm, mem.odt, mem.ras_n, mem.reset_n, mem.we_n, oct.rzqin, pll.addr_cmd_clk, pll.avl_clk, pll.c2p_write_clk, pll.config_clk, pll.hr_clk, pll.locked, pll.mem_clk, pll.p2c_read_clk, pll.write_clk, pll.write_clk_pre_phy_clk);
endmodule
