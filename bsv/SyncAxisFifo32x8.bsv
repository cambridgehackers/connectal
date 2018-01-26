
/*
   ../../generated/scripts/importbvi.py
   -I
   SyncAxisFifo32x8
   -P
   SyncAxisFifo32x8
   -c
   m_aclk
   -c
   s_aclk
   -r
   s_aresetn
   -o
   SyncAxisFifo32x8.bsv
   cores/nfsume/dual_clock_axis_fifo_32x8/dual_clock_axis_fifo_32x8_stub.v
*/

import Clocks::*;
import ConnectalFIFO::*;
import DefaultValue::*;
import FIFOF::*;
import XilinxCells::*;
import GetPut::*;
import Connectable::*;
import AxiBits::*;
import AxiStream::*;
import Vector::*;

(* always_ready, always_enabled *)
interface SyncAxisFifo8#(numeric type dwidth);
    interface AxiStreamMaster#(dwidth) m_axis;
    interface AxiStreamSlave#(dwidth)  s_axis;
endinterface
import "BVI" dual_clock_axis_fifo_32x8 =
module mkSyncAxisFifo32x8#(Clock s_aclk, Reset s_aresetn, Clock m_aclk, Reset m_aresetn)(SyncAxisFifo8#(32));
    default_clock no_clock;
    default_reset no_reset;
        input_clock m_aclk(m_aclk, (* unused *) GATE) = m_aclk;
        input_clock s_aclk(s_aclk, (* unused *) GATE) = s_aclk;
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

(* no_default_clock, no_default_reset *)
module mkSyncAxisFifo8#(Clock sclk, Reset srst, Clock dclk, Reset drst)(SyncAxisFifo8#(dwidth))
   provisos (Div#(dwidth, 32, numFifos),
	     Mul#(numFifos, 32, numBits),
	     Add#(a__, dwidth, numBits),
	     Bits#(Vector#(numFifos, Bit#(4)), TDiv#(numBits, 8)),
	     Add#(b__, TDiv#(dwidth, 8), TDiv#(numBits, 8))
      );
   Vector#(numFifos,SyncAxisFifo8#(32)) fifos <- replicateM(mkSyncAxisFifo32x8(sclk, srst, dclk, drst));
   Integer numFifos = valueOf(numFifos);
   interface AxiStreamSlave s_axis;
       method tready = fifos[0].s_axis.tready;
       method Action tdata(Bit#(dwidth) v);
	  Vector#(numFifos,Bit#(32)) data = unpack(extend(v));
	  for (Integer i = 0; i < numFifos; i = i + 1)
	     fifos[i].s_axis.tdata(data[i]);
       endmethod
       method Action tkeep(Bit#(TDiv#(dwidth,8)) v);
	  Vector#(numFifos,Bit#(4)) keep = unpack(extend(v));
	  for (Integer i = 0; i < numFifos; i = i + 1)
	     fifos[i].s_axis.tkeep(keep[i]);
       endmethod
       method Action tlast(Bit#(1) v);
	  for (Integer i = 0; i < numFifos; i = i + 1)
	     fifos[i].s_axis.tlast(v);
       endmethod
       method Action tvalid(Bit#(1) v);
          function Action fifo_tvalid(SyncAxisFifo8#(32) f); action f.s_axis.tvalid(v); endaction endfunction
	 mapM_(fifo_tvalid, fifos);
       endmethod
   endinterface
   interface AxiStreamMaster m_axis;
      method Bit#(dwidth)              tdata();
	 function Bit#(32) fifo_tdata(SyncAxisFifo8#(32) f); return f.m_axis.tdata(); endfunction
	 Vector#(numFifos,Bit#(32)) datavec = map(fifo_tdata, fifos);
	 Bit#(numBits) data = pack(datavec);
	 return truncate(data);
      endmethod
      method Bit#(TDiv#(dwidth,8))     tkeep();
	 function Bit#(4) fifo_tkeep(SyncAxisFifo8#(32) f); return f.m_axis.tkeep(); endfunction
	 Vector#(numFifos,Bit#(4)) keepvec = map(fifo_tkeep, fifos);
	 Bit#(TDiv#(dwidth,8)) keep = truncate(pack(keepvec));
	 return truncate(keep);
      endmethod
      method Bit#(1)                tlast();
	 return fifos[0].m_axis.tlast();
      endmethod
      method Action                 tready(Bit#(1) v);
	 function Action fifo_tready(SyncAxisFifo8#(32) f); action f.m_axis.tready(v); endaction endfunction
	 mapM_(fifo_tready, fifos);
      endmethod
      method Bit#(1)                tvalid();
	 return fifos[0].m_axis.tvalid();
      endmethod
   endinterface
endmodule

(* no_default_clock, no_default_reset *)
module mkSyncFifo8#(Clock fromClock, Reset fromReset, Clock toClock, Reset toReset)(FIFOF#(a))
   provisos (Bits#(a, asz),
	     Div#(asz,32,afifos),
	     Mul#(afifos,32,fsz),
	     Div#(fsz, 32, afifos),
	     Mul#(TDiv#(fsz, 32), 4, TDiv#(fsz, 8)),
	     Add#(a__, asz, fsz)
      );
   FIFOF#(a)   fromFIFOF <- mkCFFIFOF(clocked_by fromClock, reset_by fromReset);
   SyncAxisFifo8#(fsz) syncFIFOF <- mkSyncAxisFifo8(fromClock, fromReset, toClock, toReset);
   FIFOF#(a)     toFIFOF <- mkCFFIFOF(clocked_by toClock, reset_by toReset);

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
   
