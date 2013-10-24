
import Connectable :: *;
import FIFO        :: *;
import GetPut      :: *;
import PCIE        :: *;
import TieOff      :: *;
import Cntrs       :: *;
import StmtFSM     :: *;
import Assert      :: *;
import GetPutWithClocks :: *;


import AxiMasterSlave  :: *;
import PcieToAxiBridge :: *;
import EchoWrapper     :: *;

instance FShow#(TLPMemoryIO3DWHeader);
   function Fmt fshow (TLPMemoryIO3DWHeader hdr_3dw);
      return ($format("{3dwHeader fmt:%d", hdr_3dw.format)
	 + $format(" pkttype:%h", hdr_3dw.pkttype)
	 + $format(" tag:%h", hdr_3dw.tag)
	 + $format(" address:%h", hdr_3dw.addr)
	 + (hdr_3dw.format == MEM_WRITE_3DW_DATA ? $format("data:%h", pack(hdr_3dw.data)) : $format(""))
	 + $format(" }"));
   endfunction
endinstance

instance FShow#(TLPCompletionHeader);
   function Fmt fshow (TLPCompletionHeader completion);
      return ($format("{TlpCompletion fmt:%d", completion.format)
	 + $format(" pkttype:%h", completion.pkttype)
	 + $format(" tag:%h", completion.tag)
	 + $format(" data:%h", completion.data)
	 + $format(" }"));
   endfunction
endinstance


module mkEchoTestBench(Empty);
   EchoWrapper echoWrapper <- mkEchoWrapper();
   Axi3Slave#(32,32,4,12) ctrl = echoWrapper.ctrl;
   PciId my_id = PciId { bus: 3, dev: 7, func: 1 };
//    PcieToAxiBridge#(4) pcieBridge <- mkPcieToAxiBridge_4(64'h05ce_0006_ecc0_2604,
// 							 my_id,
// 							 1024,
// 							 1024,
// 							 0,
// 							 True,
// 							 False,
// 							 False
//       );
//    mkTieOff(pcieBridge.noc);
//    mkConnection(pcieBridge.portal0, ctrl);

   PortalEngine portalEngine <- mkPortalEngine(my_id);
   mkConnection(portalEngine.portal, ctrl);

   Put#(TLPData#(16)) tlps_in = portalEngine.tlp_in;
   Get#(TLPData#(16)) tlps_out = portalEngine.tlp_out;

   function Action displayTlp(String prefix, TLPData#(16) tlp);
      begin
	 TLPMemoryIO3DWHeader hdr_3dw = unpack(tlp.data);
	 if (hdr_3dw.pkttype == COMPLETION) begin
	    TLPCompletionHeader hdr_completion = unpack(tlp.data);
	    $display($format(prefix) + fshow(hdr_completion));
	 end
	 else if (hdr_3dw.format == MEM_WRITE_3DW_DATA || hdr_3dw.format == MEM_READ_3DW_NO_DATA) begin
	    $display($format(prefix) + fshow(hdr_3dw));
	 end
	 else begin
	    $display(fshow(prefix) + fshow(tlp.data) 
	       + fshow(" pkttype:") + fshow(pack(hdr_3dw.pkttype))
	       + fshow(" format:") + fshow(pack(hdr_3dw.format)));
	 end
      end
   endfunction

   rule displayTlpOut;
      TLPData#(16) tlp <- tlps_out.get();
      displayTlp("tlp out:", tlp);
   endrule

   FIFO#(TLPData#(16)) tlpInFifo <- mkFIFO;
   rule displayAndPutTlp;
      let tlp = tlpInFifo.first;
      tlpInFifo.deq;
      displayTlp("tlp in: ", tlp);
      tlps_in.put(tlp);
   endrule

   function TLPData#(16) axiTlpData(Bit#(128) data);
      TLPData#(16) tlp = TLPData {
	     sof: True,
	     eof: True,
	     hit: 4,
	     be: 16'hffff,
	     data: data
	 };
      return tlp;
   endfunction

   Count#(TLPTag) tag <- mkCount(0);

   Reg#(Bit#(15)) timer <- mkReg(0);
   rule timeout;
      timer <= timer + 1;
      dynamicAssert(timer < 100, "Timeout");
   endrule

   FSM test_fsm <- mkFSM(
      seq
      tlpInFifo.enq(axiTlpData(pack(TLPMemoryIO3DWHeader {
	 format:  MEM_WRITE_3DW_DATA,
	 pkttype: MEMORY_READ_WRITE,
	 length: 4,
	 reqid: my_id,
	 tag: tag,
	 firstbe: 15,
	 addr: (0<<14)+(0*256),
	 data: 42
	 })));
      tag.incr(1);

      tlpInFifo.enq(axiTlpData(pack(TLPMemoryIO3DWHeader {
	 format:  MEM_WRITE_3DW_DATA,
	 pkttype: MEMORY_READ_WRITE,
	 length: 4,
	 reqid: my_id,
	 tag: tag,
	 firstbe: 15,
	 addr: (0<<14)+(2*256),
	 data: 9
	 })));
      tag.incr(1);

      tlpInFifo.enq(axiTlpData(pack(TLPMemoryIO3DWHeader {
	 format:  MEM_READ_3DW_NO_DATA,
	 pkttype: MEMORY_READ_WRITE,
	 length: 4,
	 reqid: my_id,
	 tag: tag,
	 firstbe: 15,
	 addr: ((3<<14)+0) >> 2,
	 data: 0
	 })));
      tag.incr(1);

      tlpInFifo.enq(axiTlpData(pack(TLPMemoryIO3DWHeader {
	 format:  MEM_READ_3DW_NO_DATA,
	 pkttype: MEMORY_READ_WRITE,
	 length: 4,
	 reqid: my_id,
	 tag: tag,
	 firstbe: 15,
	 addr: ((3<<14)+4) >> 2,
	 data: 0
	 })));
      tag.incr(1);

      tlpInFifo.enq(axiTlpData(pack(TLPMemoryIO3DWHeader {
	 format:  MEM_READ_3DW_NO_DATA,
	 pkttype: MEMORY_READ_WRITE,
	 length: 4,
	 reqid: my_id,
	 tag: tag,
	 firstbe: 15,
	 addr: ((3<<14)+8) >> 2,
	 data: 0
	 })));
      tag.incr(1);

      tlpInFifo.enq(axiTlpData(pack(TLPMemoryIO3DWHeader {
	 format:  MEM_READ_3DW_NO_DATA,
	 pkttype: MEMORY_READ_WRITE,
	 length: 4,
	 reqid: my_id,
	 tag: tag,
	 firstbe: 15,
	 addr: ((2<<14)+0) >> 2,
	 data: 0
	 })));
      tag.incr(1);

      tlpInFifo.enq(axiTlpData(pack(TLPMemoryIO3DWHeader {
	 format:  MEM_READ_3DW_NO_DATA,
	 pkttype: MEMORY_READ_WRITE,
	 length: 4,
	 reqid: my_id,
	 tag: tag,
	 firstbe: 15,
	 addr: ((1<<14)+0) >> 2,
	 data: 0
	 })));
      tag.incr(1);

      tlpInFifo.enq(axiTlpData(pack(TLPMemoryIO3DWHeader {
	 format:  MEM_READ_3DW_NO_DATA,
	 pkttype: MEMORY_READ_WRITE,
	 length: 4,
	 reqid: my_id,
	 tag: tag,
	 firstbe: 15,
	 addr: ((0<<14)+0) >> 2,
	 data: 0
	 })));
      tag.incr(1);


      $display("read interrupt status");
      tlpInFifo.enq(axiTlpData(pack(TLPMemoryIO3DWHeader {
	 format:  MEM_READ_3DW_NO_DATA,
	 pkttype: MEMORY_READ_WRITE,
	 length: 4,
	 reqid: my_id,
	 tag: tag,
	 firstbe: 15,
	 addr: ((1<<15)+(1<<14)+0) >> 2,
	 data: 0
	 })));
      tag.incr(1);

      $display("read put failed fifo");
      tlpInFifo.enq(axiTlpData(pack(TLPMemoryIO3DWHeader {
	 format:  MEM_READ_3DW_NO_DATA,
	 pkttype: MEMORY_READ_WRITE,
	 length: 4,
	 reqid: my_id,
	 tag: tag,
	 firstbe: 15,
	 addr: ((1<<15)+(0<<14)+(2 << 8)) >> 2,
	 data: 0
	 })));
      tag.incr(1);

      $display("read heard fifo");
      tlpInFifo.enq(axiTlpData(pack(TLPMemoryIO3DWHeader {
	 format:  MEM_READ_3DW_NO_DATA,
	 pkttype: MEMORY_READ_WRITE,
	 length: 4,
	 reqid: my_id,
	 tag: tag,
	 firstbe: 15,
	 addr: ((0<<15)+(0<<14)+(0 << 8)) >> 2,
	 data: 0
	 })));
      tag.incr(1);

      $display("read interrupt status");
      tlpInFifo.enq(axiTlpData(pack(TLPMemoryIO3DWHeader {
	 format:  MEM_READ_3DW_NO_DATA,
	 pkttype: MEMORY_READ_WRITE,
	 length: 4,
	 reqid: my_id,
	 tag: tag,
	 firstbe: 15,
	 addr: ((1<<15)+(1<<14)+0) >> 2,
	 data: 0
	 })));
      tag.incr(1);

      $display("read put failed fifo");
      tlpInFifo.enq(axiTlpData(pack(TLPMemoryIO3DWHeader {
	 format:  MEM_READ_3DW_NO_DATA,
	 pkttype: MEMORY_READ_WRITE,
	 length: 4,
	 reqid: my_id,
	 tag: tag,
	 firstbe: 15,
	 addr: ((1<<15)+(0<<14)+(2 << 8)) >> 2,
	 data: 0
	 })));
      tag.incr(1);

      $display("ind underflow count");
      tlpInFifo.enq(axiTlpData(pack(TLPMemoryIO3DWHeader {
	 format:  MEM_READ_3DW_NO_DATA,
	 pkttype: MEMORY_READ_WRITE,
	 length: 4,
	 reqid: my_id,
	 tag: tag,
	 firstbe: 15,
	 addr: ((1<<15)+(1<<14)+30'h38) >> 2,
	 data: 0
	 })));
      tag.incr(1);

      $display("req underflow count");
      tlpInFifo.enq(axiTlpData(pack(TLPMemoryIO3DWHeader {
	 format:  MEM_READ_3DW_NO_DATA,
	 pkttype: MEMORY_READ_WRITE,
	 length: 4,
	 reqid: my_id,
	 tag: tag,
	 firstbe: 15,
	 addr: ((0<<15)+(1<<14)+30'h38) >> 2,
	 data: 0
	 })));
      tag.incr(1);

      endseq
      );
   Reg#(Bool) started <- mkReg(False);
   rule startIt if (!started);
      test_fsm.start();
      started <= True;
   endrule

endmodule:mkEchoTestBench
