
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
import ClientServer    :: *;
`ifdef XILINX
import PCIEWRAPPER     :: *;
`endif
import Connectable     ::*;
import Reserved        ::*;
import DReg            ::*;
import Gearbox         ::*;
import FIFO            ::*;
import FIFOF           ::*;
import SpecialFIFOs    ::*;

// Interface wrapper for PCIE
interface PcieGearbox;
   interface Client#(TLPData#(8), TLPData#(8)) tlp;
   interface Server#(TLPData#(16), TLPData#(16)) pci;
endinterface

// This module builds the transactor hierarchy, the clock
// generation logic and the PCIE-to-port logic.
(* no_default_clock, no_default_reset, synthesize *)
module mkPcieGearbox#(Clock epClock250, Reset epReset250, Clock epClock125, Reset epReset125)(PcieGearbox);
   // Connections between TLPData#(16) and a PCIE endpoint, using a gearbox
   // to match data rates between the endpoint and design clocks.
   Gearbox#(1, 2, TLPData#(8)) fifoRxData   <- mk1toNGearbox(epClock250, epReset250, epClock125, epReset125);
   Reg#(Bool)                  rOddBeat     <- mkRegA(False, clocked_by epClock250, reset_by epReset250);
   Reg#(Bool)                  rSendInvalid <- mkRegA(False, clocked_by epClock250, reset_by epReset250);
   FIFO#(TLPData#(8))          inFifo       <- mkFIFO(clocked_by epClock250, reset_by epReset250);
   FIFO#(TLPData#(8))          outFifo      <- mkFIFO(clocked_by epClock250, reset_by epReset250);
   Gearbox#(2, 1, TLPData#(8)) fifoTxData   <- mkNto1Gearbox(epClock125, epReset125, epClock250, epReset250);

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

   rule process_outgoing_packets;
      let data = fifoTxData.first; fifoTxData.deq;
      let temp = head(data);
      // filter out TLPs with 00 byte enable
      if (temp.be != 0)
          outFifo.enq(temp);
   endrule

   interface Server pci;
      interface Get response;
         method ActionValue#(TLPData#(16)) get();
            function TLPData#(16) combine(Vector#(2, TLPData#(8)) in);
               return TLPData {sof:   in[0].sof, eof: in[1].eof, hit: in[0].hit,
                   be: { in[0].be, in[1].be }, data: { in[0].data, in[1].data } };
            endfunction
            fifoRxData.deq;
            return combine(fifoRxData.first);
         endmethod
      endinterface
      interface Put request;
         method Action put(TLPData#(16) data);
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
            fifoTxData.enq(split(data));
         endmethod
      endinterface
   endinterface
   interface Client tlp;
      interface request = toGet(outFifo);
      interface response = toPut(inFifo);
   endinterface
endmodule: mkPcieGearbox
