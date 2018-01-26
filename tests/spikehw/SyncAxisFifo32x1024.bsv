
/*
   ../../generated/scripts/importbvi.py
   -I
   SyncAxisFifo32x1024
   -P
   SyncAxisFifo32x1024
   -c
   m_aclk
   -c
   s_aclk
   -r
   s_aresetn
   -o
   SyncAxisFifo32x1024.bsv
   cores/nfsume/dual_clock_axis_fifo_32x1024/dual_clock_axis_fifo_32x1024_stub.v
*/

import Clocks::*;
import ConnectalFIFO::*;
import DefaultValue::*;
import FIFOF::*;
import XilinxCells::*;
import GetPut::*;
import AxiBits::*;
import AxiStream::*;

(* always_ready, always_enabled *)
(* always_ready, always_enabled *)
interface Syncaxisfifo32x1024M_axis;
    method Bit#(32)     tdata();
    method Bit#(4)     tkeep();
    method Bit#(1)     tlast();
    method Action      tready(Bit#(1) v);
    method Bit#(1)     tvalid();
endinterface
(* always_ready, always_enabled *)
(* always_ready, always_enabled *)
interface Syncaxisfifo32x1024S_axis;
    method Action      tdata(Bit#(32) v);
    method Action      tkeep(Bit#(4) v);
    method Action      tlast(Bit#(1) v);
    method Bit#(1)     tready();
    method Action      tvalid(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface SyncAxisFifo32x1024;
    interface AxiStreamMaster#(32) m_axis;
    interface AxiStreamSlave#(32)  s_axis;
endinterface
import "BVI" dual_clock_axis_fifo_32x1024 =
module mkSyncAxisFifo32x1024#(Clock s_aclk, Reset s_aresetn, Clock m_aclk, Reset m_aresetn)(SyncAxisFifo32x1024);
    default_clock clk();
    default_reset rst();
        input_clock m_aclk(m_aclk) = m_aclk;
        input_clock s_aclk(s_aclk) = s_aclk;
        input_reset s_aresetn(s_aresetn) clocked_by (s_aclk) = s_aresetn;
        input_reset m_aresetn_foo() clocked_by (m_aclk) = m_aresetn;
    interface AxiStreamMaster     m_axis;
        method m_axis_tdata tdata() clocked_by (m_aclk) reset_by (m_aresetn_foo);
        method m_axis_tkeep tkeep() clocked_by (m_aclk) reset_by (m_aresetn_foo);
        method m_axis_tlast tlast() clocked_by (m_aclk) reset_by (m_aresetn_foo);
        method tready(m_axis_tready) enable((*inhigh*) EN_m_axis_tready) clocked_by (m_aclk) reset_by (m_aresetn_foo);
        method m_axis_tvalid tvalid() clocked_by (m_aclk) reset_by (m_aresetn_foo);
    endinterface
    interface AxiStreamSlave     s_axis;
        method tdata(s_axis_tdata) enable((*inhigh*) EN_s_axis_tdata) clocked_by (s_aclk) reset_by (s_aresetn);
        method tkeep(s_axis_tkeep) enable((*inhigh*) EN_s_axis_tkeep) clocked_by (s_aclk) reset_by (s_aresetn);
        method tlast(s_axis_tlast) enable((*inhigh*) EN_s_axis_tlast) clocked_by (s_aclk) reset_by (s_aresetn);
        method s_axis_tready tready() clocked_by (s_aclk) reset_by (s_aresetn);
        method tvalid(s_axis_tvalid) enable((*inhigh*) EN_s_axis_tvalid) clocked_by (s_aclk) reset_by (s_aresetn);
    endinterface
    schedule (m_axis.tdata, m_axis.tkeep, m_axis.tlast, m_axis.tready, m_axis.tvalid, s_axis.tdata, s_axis.tkeep, s_axis.tlast, s_axis.tready, s_axis.tvalid) CF (m_axis.tdata, m_axis.tkeep, m_axis.tlast, m_axis.tready, m_axis.tvalid, s_axis.tdata, s_axis.tkeep, s_axis.tlast, s_axis.tready, s_axis.tvalid);
endmodule

module mkSyncAxisFifo32x1024FIFOF#(Clock fromClock, Reset fromReset, Clock toClock, Reset toReset)(FIFOF#(a)) provisos (Bits#(a, asz), Add#(asz, a__, 32));
   let fromFIFOF <- mkCFFIFOF(clocked_by fromClock, reset_by fromReset);
   let syncFIFOF <- mkSyncAxisFifo32x1024(fromClock, fromReset, toClock, toReset);
   let   toFIFOF <- mkCFFIFOF(clocked_by toClock, reset_by toReset);

   rule rl_from if (syncFIFOF.s_axis.tready() == 1);
      syncFIFOF.s_axis.tdata(extend(pack(fromFIFOF.first())));
      fromFIFOF.deq();
   endrule
   rule rl_from_handshake;
      syncFIFOF.s_axis.tvalid(pack(fromFIFOF.notEmpty()));
      syncFIFOF.s_axis.tkeep(maxBound);
      syncFIFOF.s_axis.tlast(1);
   endrule

   rule rl_to if (syncFIFOF.m_axis.tvalid() == 1);
      toFIFOF.enq(unpack(truncate(syncFIFOF.m_axis.tdata)));
   endrule
   rule rl_to_handshake;
      syncFIFOF.m_axis.tready(pack(toFIFOF.notFull()));
   endrule

   method notEmpty = toFIFOF.notEmpty;
   method first    = toFIFOF.first;
   method deq      = toFIFOF.deq;
   method enq      = fromFIFOF.enq;
   method notFull  = fromFIFOF.notFull;
endmodule
   
