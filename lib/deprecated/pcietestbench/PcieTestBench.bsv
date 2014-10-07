
// Copyright (c) 2014 Quanta Research Cambridge, Inc.

// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use, copy,
// modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
// BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
// ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Clocks            :: *;
import Connectable       :: *;
import DefaultValue      :: *;
import FIFO              :: *;
import GetPut            :: *;
import PCIE              :: *;

import AxiCsr            :: *;
import AxiSlaveEngine    :: *;
import AxiMasterEngine   :: *;
import PcieSplitter      :: *;

// copied from PCIE.bsv because connectalgen cannot handle TMul#()
typedef struct {
   Bit#(1)               sof;
   Bit#(1)               eof;
   Bit#(7)               hit;
   Bit#(16)              be;
   Bit#(32)              data0;
   Bit#(32)              data1;
   Bit#(32)              data2;
   Bit#(32)              data3;
} TLPData16 deriving (Bits, Eq);

// copied from PCIE.bsv because connectalgen cannot parse the file
typedef enum {
   MEM_READ_3DW_NO_DATA = 0,
   MEM_READ_4DW_NO_DATA = 1,
   MEM_WRITE_3DW_DATA   = 2,
   MEM_WRITE_4DW_DATA   = 3
   } TLPPacketFormat deriving (Bits, Eq);

// copied from PCIE.bsv because connectalgen cannot parse the file
typedef enum {
   MEMORY_READ_WRITE   = 0,
   MEMORY_READ_LOCKED  = 1,
   IO_REQUEST          = 2,
   UNKNOWN_TYPE_3      = 3,
   CONFIG_0_READ_WRITE = 4,
   CONFIG_1_READ_WRITE = 5,
   UNKNOWN_TYPE_6      = 6,
   UNKNOWN_TYPE_7      = 7,
   UNKNOWN_TYPE_8      = 8,
   UNKNOWN_TYPE_9      = 9,
   COMPLETION          = 10,
   COMPLETION_LOCKED   = 11,
   UNKNOWN_TYPE_12     = 12,
   UNKNOWN_TYPE_13     = 13,
   UNKNOWN_TYPE_14     = 14,
   UNKNOWN_TYPE_15     = 15,
   MSG_ROUTED_TO_ROOT  = 16,
   MSG_ROUTED_BY_ADDR  = 17,
   MSG_ROUTED_BY_ID    = 18,
   MSG_ROOT_BROADCAST  = 19,
   MSG_LOCAL           = 20,
   MSG_GATHER          = 21,
   UNKNOWN_TYPE_22     = 22,
   UNKNOWN_TYPE_23     = 23,
   UNKNOWN_TYPE_24     = 24,
   UNKNOWN_TYPE_25     = 25,
   UNKNOWN_TYPE_26     = 26,
   UNKNOWN_TYPE_27     = 27,
   UNKNOWN_TYPE_28     = 28,
   UNKNOWN_TYPE_29     = 29,
   UNKNOWN_TYPE_30     = 30,
   UNKNOWN_TYPE_31     = 31
   } TLPPacketType deriving (Bits, Eq);

// copied from PCIE.bsv because connectalgen cannot parse the file
typedef struct {Bit#(8) hit;
		Bit#(8) sof;
		Bit#(8) eof;
		Bit#(16) tlpbe;
		Bit#(16) tag;
		Bit#(16) length;
		TLPPacketType pkttype;
		TLPPacketFormat format;
		Bit#(8) firstbe;
		Bit#(8) lastbe;
		Bit#(32) addr;
   Bit#(32) data;
   } Pcie3dwHeader deriving (Bits);

interface PcieTestBenchIndication;
   method Action tlpout(TLPData16 tlp);
endinterface

interface PcieTestBenchRequest;
   method Action sendReadRequest(Bit#(8) hit, Bit#(32) addr, Bit#(8) length, Bit#(8) tag);
endinterface


module mkPcieTestBenchRequest#(PcieTestBenchIndication indication)(PcieTestBenchRequest);

   Clock defaultClock <- exposeCurrentClock();
   Reset defaultReset <- exposeCurrentReset();
   MakeResetIfc portalResetIfc <- mkReset(10, False, defaultClock);
   PciId my_id = PciId { bus: 1, dev: 1, func: 0};
   Bit#(64) board_content_id = 'hdeadbeefd00df00d;
   Reg#(Bit#(32)) tlp_portal_drop_count <- mkReg(0);
   Reg#(Bit#(32)) tlp_axi_drop_count <- mkReg(0);


   AxiMasterEngine axiMasterEngine <- mkAxiMasterEngine(my_id);
   AxiControlAndStatusRegs axiCsr  <- mkAxiControlAndStatusRegs( board_content_id,
								my_id,
								0,
								0,
								tlp_portal_drop_count,
								tlp_axi_drop_count,
								portalResetIfc);
   Reg#(Bit#(32)) timestamp <- mkReg(0);
   rule timebase;
      timestamp <= timestamp + 1;
   endrule
   mkConnection(axiMasterEngine.master, axiCsr.slave);
   rule tlp_out;
      let tlp <- axiMasterEngine.tlp_out.get();
      TimestampedTlpData ttd = TimestampedTlpData { timestamp: timestamp, source: 4, tlp: tlp };
      $display("%h", ttd);
      indication.tlpout(unpack(pack(tlp)));
   endrule
   
   method Action sendReadRequest(Bit#(8) hit, Bit#(32) addr, Bit#(8) length, Bit#(8) tag);
      $display("send3dwRequest hit=%d addr=%h length=%h tag=%d", hit, addr, length, tag);
      TLPMemoryIO3DWHeader hdr = defaultValue;
      hdr.tag = truncate(tag);
      hdr.length = extend(length);
      hdr.format = PCIE::MEM_READ_3DW_NO_DATA;
      hdr.pkttype = PCIE::MEMORY_READ_WRITE;
      hdr.firstbe = 4'hf;
      hdr.lastbe = (length == 1) ? 0 : 4'hf;
      hdr.addr = truncate(addr >> 2);
      hdr.data = 0;
      TLPData#(16) tlp;
      tlp.be = 16'hfff0;
      tlp.sof = True;
      tlp.eof = True;
      tlp.hit = truncate(hit);
      tlp.data = pack(hdr);
      $display("tlp_in=%h", tlp);
      axiMasterEngine.tlp_in.put(tlp);
   endmethod
endmodule