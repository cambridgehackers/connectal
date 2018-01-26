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
`include "ConnectalProjectConfig.bsv"
import Clocks            :: *;
import Connectable       :: *;
import DefaultValue      :: *;
import FIFO              :: *;
import GetPut            :: *;
import FIFOF             :: *;
import Vector            :: *;
import AxiCsr            :: *;
import PCIE              :: *;
import AxiSlaveEngine    :: *;
import Portal            :: *;
import MemServer         :: *;
import SGList::*;
import MemReadEngine     :: *;
import AxiDma            :: *;
import ConnectalMemTypes          :: *;
import AxiMasterSlave    :: *;
import DmaUtils          :: *;

import MemServerRequestWrapper::*;
import SGListConfigRequestWrapper::*;
import MemServerIndicationProxy::*;
import SGListConfigIndicationProxy::*;

// copied from PCIE.bsv because connectalgen cannot handle TMul#()
typedef struct {
   Bit#(32)              data0;
   Bit#(32)              data1;
   Bit#(32)              data2;
   Bit#(32)              data3;
   Bit#(32)              data4;
   Bit#(32)              data5;
} TsTLPData16 deriving (Bits, Eq);

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
   method Action tlpout(TsTLPData16 tlp);
   method Action started(Bit#(32) numWords);
   method Action finished(Bit#(32) v);
endinterface

interface PcieTestBenchRequest;
   method Action tlpin(TsTLPData16 tlp);
   method Action startRead(Bit#(32) pointer, Bit#(32) numWords, Bit#(32) burstLen);
endinterface

interface PcieTestBench#(numeric type addrWidth, numeric type dataWidth);
   interface PcieTestBenchRequest request;
   interface StdPortal dmaConfig;
   interface StdPortal dmaIndication;
   interface Vector#(1,MemMaster#(addrWidth,dataWidth)) masters;
endinterface

typedef enum {TestBenchIndication, TestBenchRequest, HostmemMemServerIndication, HostmemMemServerRequest, HostmemSGListConfigRequest, HostmemSGListConfigIndication} IfcNames deriving (Eq,Bits);

//`define SANITY

module mkPcieTestBench#(PcieTestBenchIndication indication)(PcieTestBench#(40,64));
   
   // memread state
   Reg#(SGLId)     rdPointer <- mkReg(0);
   Reg#(Bit#(8))            burstLen <- mkReg(0);
   Reg#(Bit#(32))             reqLen <- mkReg(0);

   Reg#(Bit#(3))               rdTag <- mkReg(0);
   Reg#(Bit#(32))            respCnt <- mkReg(0);
   Reg#(Bit#(32))              rdOff <- mkReg(0);
   DmaReadBuffer#(64, 32) rb <- mkDmaReadBuffer();
   
   // dma state
   SGListConfigIndicationProxy hostmemSGListConfigIndicationProxy <- mkSGListConfigIndicationProxy(HostmemSGListConfigIndication);
   SGListMMU#(PhysAddrWidth) hostmemSGList <- mkSGListMMU(0, True, hostmemSGListConfigIndicationProxy.ifc);
   SGListConfigRequestWrapper hostmemSGListConfigRequestWrapper <- mkSGListConfigRequestWrapper(HostmemSGListConfigRequest, hostmemSGList.request);

   MemServerIndicationProxy hostmemMemServerIndicationProxy <- mkMemServerIndicationProxy(HostmemMemServerIndication);
   MemServer#(PhysAddrWidth,64,1) dma <- mkMemServerOOR(hostmemMemServerIndicationProxy.ifc, cons(rb.dmaClient,nil), hostmemSGList);
   MemServerRequestWrapper hostmemMemServerRequestWrapper <- mkMemServerRequestWrapper(HostmemMemServerRequest, dma.request);
`ifdef SANITY
   Axi3Master#(40,64,6) m_axi = ?;
`else   
   Axi3Master#(40,64,6)  m_axi <- mkAxiDmaMaster(dma.masters[0]);
`endif
   
   // tlp state
   PciId my_id = PciId { bus: 1, dev: 1, func: 0};
   Bit#(64) board_content_id = 'hdeadbeefd00df00d;
   Reg#(Bit#(32)) tlp_portal_drop_count <- mkReg(0);
   Reg#(Bit#(32)) tlp_axi_drop_count <- mkReg(0);
   AxiSlaveEngine#(64) axiSlaveEngine <- mkAxiSlaveEngine(my_id);
   Reg#(Bit#(32)) timestamp <- mkReg(0);
   mkConnection(m_axi, axiSlaveEngine.slave);
   FIFO#(TimestampedTlpData) tlpin_fifo <- mkSizedFIFO(20);
   
   // tlp rules
   rule timebase;
      timestamp <= timestamp + 1;
   endrule
   
   rule tlp_out;
      let tlp <- tpl_1(axiSlaveEngine.tlps).get();
      TimestampedTlpData ttd = TimestampedTlpData { timestamp: timestamp, source: 4, tlp: tlp };
      indication.tlpout(unpack(pack(ttd)));
      //$display("%h",ttd);
   endrule

   rule tlp_in;
      let ttd = tlpin_fifo.first;
      tlpin_fifo.deq;
      tpl_2(axiSlaveEngine.tlps).put(unpack(pack(ttd.tlp)));
   endrule
   
   // memread rules
   rule rdReq if (rdOff < reqLen);
      rdOff <= rdOff + extend(burstLen);
      rb.dmaServer.readReq.put(MemRequest { sglId: rdPointer, offset: extend(rdOff), burstLen: burstLen, tag: extend(rdTag) });
      rdTag <= rdTag+1;
   endrule
   
   rule rdData;
      MemData#(64) d <- rb.dmaServer.readData.get;
      let new_respCnt = respCnt+(64/8);
      respCnt <= new_respCnt;
      if (new_respCnt >= reqLen)
	 indication.finished(0);
   endrule
   
   interface PcieTestBenchRequest request;
      method Action startRead(Bit#(32) rp, Bit#(32) nw, Bit#(32) bl);
	 $display("startRead rdPointer=%d numWords=%h burstLen=%d", rp, nw, bl);
	 indication.started(nw);
	 rdPointer <= rp;
	 burstLen  <= truncate(bl*4);
	 reqLen    <= nw*4;
	 respCnt   <= 0;
	 rdOff     <= 0;
      endmethod
      method Action tlpin(TsTLPData16 tstlp);
	 TimestampedTlpData ttd = unpack(pack(tstlp));
	 tlpin_fifo.enq(ttd);
      endmethod
   endinterface
   interface StdPortal dmaConfig = hostmemMemServerRequestWrapper.portalIfc;
   interface StdPortal dmaIndication = hostmemMemServerIndicationProxy.portalIfc;
   //portals[z] = hostmemSGListConfigRequestWrapper.portalIfc;
   //portals[z] = hostmemSGListConfigIndicationProxy.portalIfc;

`ifdef SANITY
   interface masters = dma.masters;
`else
   interface masters = ?;
`endif
endmodule
