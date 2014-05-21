
// Copyright (c) 2008- 2009 Bluespec, Inc.  All rights reserved.
// $Revision$
// $Date$
// Copyright (c) 2013 Quanta Research Cambridge, Inc.

// PCI-Express for Xilinx 7
// FPGAs.

import Vector          :: *;
import GetPut          :: *;
import PCIE            :: *;
import Clocks          :: *;
import DefaultValue    :: *;
import TieOff          :: *;
import XilinxCells     :: *;
import XbsvXilinx7Pcie :: *;
import TlpConnect      :: *;
import PCIEWRAPPER     :: *;
import AxiCsr          :: *;

import Connectable     ::*;
import Reserved        ::*;
import DReg            ::*;
import Gearbox         ::*;
import FIFO            ::*;
import FIFOF           ::*;
import SpecialFIFOs    ::*;

// Interface wrapper for PCIE
interface PcieGearbox#(numeric type lanes);
   //method Bool isCalibrated();
endinterface

// This module builds the transactor hierarchy, the clock
// generation logic and the PCIE-to-port logic.
(* no_default_clock, no_default_reset *)
//, synthesize *)
module mkPcieGearbox#(Clock epClock250, Reset epReset250, Clock epClock125, Reset epReset125
, XbsvXilinx7Pcie::PCIExpressX7#(lanes) _ep, TlpConnect#(16) pci) (PcieGearbox#(lanes))
   provisos(Add#(1,_,lanes));
   FIFO#(TLPData#(8))          inFifo              <- mkFIFO(clocked_by epClock250, reset_by epReset250);
   // Connections between TLPData#(16) and a PCIE endpoint, using a gearbox
   // to match data rates between the endpoint and design clocks.
   Gearbox#(1, 2, TLPData#(8)) fifoRxData          <- mk1toNGearbox(epClock250, epReset250, epClock125, epReset125);
   Reg#(Bool)                  rOddBeat            <- mkRegA(False, clocked_by epClock250, reset_by epReset250);
   Reg#(Bool)                  rSendInvalid        <- mkRegA(False, clocked_by epClock250, reset_by epReset250);
   FIFO#(TLPData#(8))          outFifo             <- mkFIFO(clocked_by epClock250, reset_by epReset250);
   Gearbox#(2, 1, TLPData#(8)) fifoTxData          <- mkNto1Gearbox(epClock125, epReset125, epClock250, epReset250);

   rule accept_data1;
      let data <- _ep.tlp.outTo.get();
      inFifo.enq(data);
   endrule

   rule process_incoming_packets1(!rSendInvalid);
      let data = inFifo.first; inFifo.deq;
      rOddBeat     <= !rOddBeat;
      rSendInvalid <= !rOddBeat && data.eof;
      Vector#(1, TLPData#(8)) v = defaultValue;
      v[0] = data;
      fifoRxData.enq(v);
   endrule

   rule send_invalid_packets1(rSendInvalid);
      rOddBeat     <= !rOddBeat;
      rSendInvalid <= False;
      Vector#(1, TLPData#(8)) v = defaultValue;
      v[0].eof = True;
      v[0].be  = 0;
      fifoRxData.enq(v);
   endrule

   rule send_data1;
      function TLPData#(16) combine(Vector#(2, TLPData#(8)) in);
         return TLPData {sof:   in[0].sof, eof:   in[1].eof, hit:   in[0].hit,
                         be:    { in[0].be,   in[1].be },
                         data:  { in[0].data, in[1].data } };
      endfunction
      fifoRxData.deq;
      pci.inFrom.put(combine(fifoRxData.first));
   endrule

   rule get_data;
      function Vector#(2, TLPData#(8)) split(TLPData#(16) in);
         Vector#(2, TLPData#(8)) v = defaultValue;
         v[0].sof  = in.sof;
         v[0].eof  = (in.be[7:0] == 0) ? in.eof : False;
         v[0].hit  = in.hit;
         v[0].be   = in.be[15:8];
         v[0].data = in.data[127:64];
         v[1].sof  = False;
         v[1].eof  = in.eof;
         v[1].hit  = in.hit;
         v[1].be   = in.be[7:0];
         v[1].data = in.data[63:0];
         return v;
      endfunction

      let data <- pci.outTo.get();
      fifoTxData.enq(split(data));
   endrule

   rule process_outgoing_packets;
      let data = fifoTxData.first; fifoTxData.deq;
      outFifo.enq(head(data));
   endrule

   rule send_data;
      let data = outFifo.first; outFifo.deq;
      // filter out TLPs with 00 byte enable
      if (data.be != 0)
         _ep.tlp.inFrom.put(data);
   endrule
endmodule: mkPcieGearbox
