package PcieToAxiBridge;

// This is a package which acts as a bridge between a TLP-based PCIe
// interface on one side and message-based NoC interface on the other.

import GetPut       :: *;
import Connectable  :: *;
import Vector       :: *;
import FIFO         :: *;
import FIFOF        :: *;
import Counter      :: *;
import DefaultValue :: *;
import XilinxPCIE   :: *;
import BRAM         :: *;
import BRAMFIFO     :: *;
import ConfigReg    :: *;
import DReg         :: *;

import MsgFormat     :: *;
import ByteBuffer    :: *;
import ByteCompactor :: *;

import AxiMasterSlave :: *;

typedef struct {
    Bit#(32) seqno;
    Bit#(7) unused;
    TLPData#(16) tlp;
} TimestampedTlpData deriving (Bits);
typedef SizeOf#(TimestampedTlpData) TimestampedTlpDataSize;
typedef SizeOf#(TLPData#(16)) TlpData16Size;
typedef SizeOf#(TLPCompletionHeader) TLPCompletionHeaderSize;

// The top-level interface of the PCIe-to-NoC bridge
interface PcieToAxiBridge#(numeric type bpb);

   interface GetPut#(TLPData#(16)) tlps; // to the PCIe bus
   interface MsgPort#(bpb)         noc;  // to the NoC
   interface Axi3Master#(32,32,4,12) portal0; // to the portal control

   // global network activation status
   (* always_ready *)
   method Bool is_activated();

   // status for FPGA LEDs
   (* always_ready *)
   method Bool rx_activity();
   (* always_ready *)
   method Bool tx_activity();

   (* always_ready *)
   method Action interrupt();
   // methods for MSI interrupts
   (* always_ready *)
   method Bool msi_interrupt_req();
   (* always_ready *)
   method Action msi_interrupt_clear();

   interface Put#(TimestampedTlpData) trace;

endinterface: PcieToAxiBridge

// When TLP packets come in from the PCIe bus, they are dispatched to
// either the configuration register block or the DMA controller
// block. The DMA controller and driver need to observe a protocol
// that prevents requests from backing up on the DMA side and thereby
// preventing reads and writes of the control and status registers.
// For example, the DMA controller can tell the driver how many
// open slots it has to receive write and read commands, and the
// driver must respect those limits.

interface TLPDispatcher;

   // TLPs in from PCIe
   interface Put#(TLPData#(16)) tlp_in_from_bus;

   // TLPs out to the bridge implementation
   interface Get#(TLPData#(16)) tlp_out_to_config;
   interface Get#(TLPData#(16)) tlp_out_to_dma;
   interface Get#(TLPData#(16)) tlp_out_to_portal;
   interface Get#(TLPData#(16)) tlp_out_to_axi;

   // activity indicators
   (* always_ready *)
   method Bool read_tlp();
   (* always_ready *)
   method Bool write_tlp();
   (* always_ready *)
   method Bool completion_tlp();

   interface Reg#(Bool) axiEnabled;

endinterface: TLPDispatcher

(* synthesize *)
module mkTLPDispatcher(TLPDispatcher);

   FIFO#(TLPData#(16))  tlp_in_fifo     <- mkFIFO();
   FIFOF#(TLPData#(16)) tlp_in_cfg_fifo <- mkGFIFOF(True,False); // unguarded enq
   FIFOF#(TLPData#(16)) tlp_in_dma_fifo <- mkGFIFOF(True,False); // unguarded enq
   FIFOF#(TLPData#(16)) tlp_in_portal_fifo <- mkGFIFOF(True,False); // unguarded enq
   FIFOF#(TLPData#(16)) tlp_in_axi_fifo <- mkGFIFOF(True,False); // unguarded enq

   Reg#(Bool) route_to_cfg <- mkReg(False);
   Reg#(Bool) route_to_dma <- mkReg(False);
   Reg#(Bool) route_to_portal <- mkReg(False);
   Reg#(Bool) route_to_axi <- mkReg(False);

   Reg#(Bool) axiEnabledReg <- mkReg(False);

   PulseWire is_read       <- mkPulseWire();
   PulseWire is_write      <- mkPulseWire();
   PulseWire is_completion <- mkPulseWire();

   (* fire_when_enabled *)
   rule dispatch_incoming_TLP;
      TLPData#(16) tlp = tlp_in_fifo.first();
      TLPMemoryIO3DWHeader hdr_3dw = unpack(tlp.data);
      Bool in_dma_command_addr_range =  ((hdr_3dw.addr % 8192) == 1024)
                                     || ((hdr_3dw.addr % 8192) == 1025)
                                     || ((hdr_3dw.addr % 8192) == 1026)
                                     || ((hdr_3dw.addr % 8192) == 1027)
                                     ;
      Bool is_config_read    =  tlp.sof
                             && (tlp.hit == 7'h01)
                             && (hdr_3dw.format == MEM_READ_3DW_NO_DATA)
                             ;
      Bool is_config_write   =  tlp.sof
                             && (tlp.hit == 7'h01)
                             && (hdr_3dw.format == MEM_WRITE_3DW_DATA)
                             && (hdr_3dw.pkttype != COMPLETION)
                             && !in_dma_command_addr_range
                             ;
      Bool is_axi_read       =  tlp.sof
                             && (tlp.hit != 7'h01)
                             && (hdr_3dw.format == MEM_READ_3DW_NO_DATA)
                             ;
      Bool is_axi_write      =  tlp.sof
                             && (tlp.hit != 7'h01)
                             && (hdr_3dw.format == MEM_WRITE_3DW_DATA)
                             && (hdr_3dw.pkttype != COMPLETION)
                             ;
      Bool is_dma_command    =  tlp.sof
                             && (tlp.hit == 7'h01)
                             && (hdr_3dw.format == MEM_WRITE_3DW_DATA)
                             && (hdr_3dw.pkttype != COMPLETION)
                             && in_dma_command_addr_range
                             ;
      Bool is_dma_completion =  tlp.sof
                             && (hdr_3dw.format == MEM_WRITE_3DW_DATA)
                             && (hdr_3dw.pkttype == COMPLETION)
                             ;
      Bool is_axi_completion =  tlp.sof
                             && (hdr_3dw.format == MEM_WRITE_3DW_DATA)
                             && (hdr_3dw.pkttype == COMPLETION)
                             ;
      if (tlp.sof) begin
         // route the packet based on this header
         if (is_config_read || is_config_write) begin
            // send to config interface if it will accept
            if (tlp_in_cfg_fifo.notFull()) begin
               tlp_in_fifo.deq();
               tlp_in_cfg_fifo.enq(tlp);
               if (!tlp.eof)
                  route_to_cfg <= True;
            end
         end
         else if (is_axi_read || is_axi_write) begin
            // send to portal interface if it will accept
            if (tlp_in_portal_fifo.notFull()) begin
               tlp_in_fifo.deq();
               tlp_in_portal_fifo.enq(tlp);
               if (!tlp.eof)
                  route_to_portal <= True;
            end
         end
	 else if (is_axi_completion) begin
            // send to AXI interface if it will accept
            if (tlp_in_axi_fifo.notFull()) begin
               tlp_in_fifo.deq();
               tlp_in_axi_fifo.enq(tlp);
               if (!tlp.eof)
                  route_to_axi <= True;
            end
	 end
         else if (is_dma_command || is_dma_completion) begin
            // send to DMA interface if it will accept
            if (tlp_in_dma_fifo.notFull()) begin
               tlp_in_fifo.deq();
               tlp_in_dma_fifo.enq(tlp);
               if (!tlp.eof)
                  route_to_dma <= True;
            end
         end
         else begin
            // unknown packet type -- just discard it
            tlp_in_fifo.deq();
         end
         // indicate activity type
         if (is_config_read)                     is_read.send();
         if (is_config_write || is_dma_command)  is_write.send();
         if (is_dma_completion)                  is_completion.send();
      end
      else begin
         // this is a continuation of a previous TLP packet, so route
         // based on the last header
         if (route_to_cfg) begin
            // send to config interface if it will accept
            if (tlp_in_cfg_fifo.notFull()) begin
               tlp_in_fifo.deq();
               tlp_in_cfg_fifo.enq(tlp);
               if (tlp.eof)
                  route_to_cfg <= False;
            end
         end
         else if (route_to_portal) begin
            // send to portal interface if it will accept
            if (tlp_in_portal_fifo.notFull()) begin
               tlp_in_fifo.deq();
               tlp_in_portal_fifo.enq(tlp);
               if (tlp.eof)
                  route_to_portal <= False;
            end
         end
         else if (route_to_axi) begin
            // send to AXI interface if it will accept
            if (tlp_in_axi_fifo.notFull()) begin
               tlp_in_fifo.deq();
               tlp_in_axi_fifo.enq(tlp);
               if (tlp.eof)
                  route_to_axi <= False;
            end
         end
         else if (route_to_dma) begin
            // send to DMA interface if it will accept
            if (tlp_in_dma_fifo.notFull()) begin
               tlp_in_fifo.deq();
               tlp_in_dma_fifo.enq(tlp);
               if (tlp.eof)
                  route_to_dma <= False;
            end
         end
         else begin
            // unknown packet type -- just discard it
            tlp_in_fifo.deq();
         end
      end
   endrule: dispatch_incoming_TLP

   interface Put tlp_in_from_bus    = toPut(tlp_in_fifo);
   interface Get tlp_out_to_config  = toGet(tlp_in_cfg_fifo);
   interface Get tlp_out_to_dma     = toGet(tlp_in_dma_fifo);
   interface Get tlp_out_to_portal  = toGet(tlp_in_portal_fifo);
   interface Get tlp_out_to_axi     = toGet(tlp_in_axi_fifo);

   method Bool read_tlp       = is_read;
   method Bool write_tlp      = is_write;
   method Bool completion_tlp = is_completion;
   interface Reg axiEnabled = axiEnabledReg;
endmodule: mkTLPDispatcher

// Multiple sources of TLP packets must all share the PCIe bus. There
// is an arbiter which controls which source gets access to the PCIe
// endpoint.

interface TLPArbiter;

   // TLPs out to PCIe
   interface Get#(TLPData#(16)) tlp_out_to_bus;

   // TLPs in from the bridge implementation
   interface Put#(TLPData#(16)) tlp_in_from_config; // read completions
   interface Put#(TLPData#(16)) tlp_in_from_dma;    // read and write requests, interrupts
   interface Put#(TLPData#(16)) tlp_in_from_portal; // read completions
   interface Put#(TLPData#(16)) tlp_in_from_axi;    // read and write requests

   // activity indicators
   (* always_ready *)
   method Bool read_tlp();
   (* always_ready *)
   method Bool write_tlp();
   (* always_ready *)
   method Bool completion_tlp();

endinterface: TLPArbiter

(* synthesize *)
module mkTLPArbiter(TLPArbiter);

   FIFO#(TLPData#(16))  tlp_out_fifo     <- mkFIFO();
   FIFOF#(TLPData#(16)) tlp_out_cfg_fifo <- mkGFIFOF(False,True); // unguarded deq
   FIFOF#(TLPData#(16)) tlp_out_dma_fifo <- mkGFIFOF(False,True); // unguarded deq
   FIFOF#(TLPData#(16)) tlp_out_portal_fifo <- mkGFIFOF(False,True); // unguarded deq
   FIFOF#(TLPData#(16)) tlp_out_axi_fifo <- mkGFIFOF(False,True); // unguarded deq

   Reg#(Bool) route_from_cfg <- mkReg(False);
   Reg#(Bool) route_from_dma <- mkReg(False);
   Reg#(Bool) route_from_portal <- mkReg(False);
   Reg#(Bool) route_from_axi <- mkReg(False);

   PulseWire is_read       <- mkPulseWire();
   PulseWire is_write      <- mkPulseWire();
   PulseWire is_completion <- mkPulseWire();

   (* fire_when_enabled *)
   rule arbitrate_outgoing_TLP;
      if (route_from_cfg) begin
         // continue taking from the config FIFO until end-of-frame
         if (tlp_out_cfg_fifo.notEmpty()) begin
            TLPData#(16) tlp = tlp_out_cfg_fifo.first();
            tlp_out_cfg_fifo.deq();
            tlp_out_fifo.enq(tlp);
            if (tlp.eof)
               route_from_cfg <= False;
         end
      end
      else if (route_from_portal) begin
         // continue taking from the portal FIFO until end-of-frame
         if (tlp_out_portal_fifo.notEmpty()) begin
            TLPData#(16) tlp = tlp_out_portal_fifo.first();
            tlp_out_portal_fifo.deq();
            tlp_out_fifo.enq(tlp);
            if (tlp.eof)
               route_from_portal <= False;
         end
      end
      else if (route_from_axi) begin
         // continue taking from the axi FIFO until end-of-frame
         if (tlp_out_axi_fifo.notEmpty()) begin
            TLPData#(16) tlp = tlp_out_axi_fifo.first();
            tlp_out_axi_fifo.deq();
            tlp_out_fifo.enq(tlp);
            if (tlp.eof)
               route_from_axi <= False;
         end
      end
      else if (route_from_dma) begin
         // continue taking from the DMA FIFO until end-of-frame
         if (tlp_out_dma_fifo.notEmpty()) begin
            TLPData#(16) tlp = tlp_out_dma_fifo.first();
            tlp_out_dma_fifo.deq();
            tlp_out_fifo.enq(tlp);
            if (tlp.eof)
               route_from_dma <= False;
         end
      end
      else if (tlp_out_cfg_fifo.notEmpty()) begin
         // prioritize config read completions over DMA traffic
         TLPData#(16) tlp = tlp_out_cfg_fifo.first();
         tlp_out_cfg_fifo.deq();
         if (tlp.sof) begin
            tlp_out_fifo.enq(tlp);
            if (!tlp.eof)
               route_from_cfg <= True;
            is_completion.send();
         end
      end
      else if (tlp_out_portal_fifo.notEmpty()) begin
         // prioritize portal read completions over DMA traffic
         TLPData#(16) tlp = tlp_out_portal_fifo.first();
         tlp_out_portal_fifo.deq();
         if (tlp.sof) begin
            tlp_out_fifo.enq(tlp);
            if (!tlp.eof)
               route_from_portal <= True;
            is_completion.send();
         end
      end
      else if (tlp_out_axi_fifo.notEmpty()) begin
         // prioritize axi read completions over DMA traffic
         TLPData#(16) tlp = tlp_out_axi_fifo.first();
         tlp_out_axi_fifo.deq();
         if (tlp.sof) begin
            tlp_out_fifo.enq(tlp);
            if (!tlp.eof)
               route_from_axi <= True;
            is_completion.send();
         end
      end
      else if (tlp_out_dma_fifo.notEmpty()) begin
         // take DMA traffic
         TLPData#(16) tlp = tlp_out_dma_fifo.first();
         tlp_out_dma_fifo.deq();
         if (tlp.sof) begin
            tlp_out_fifo.enq(tlp);
            if (!tlp.eof)
               route_from_dma <= True;
            TLPMemory4DWHeader hdr_4dw = unpack(tlp.data);
            if (hdr_4dw.format == MEM_READ_4DW_NO_DATA)
               is_read.send();
            else
               is_write.send();
         end
      end
   endrule: arbitrate_outgoing_TLP

   interface Get tlp_out_to_bus     = toGet(tlp_out_fifo);
   interface Put tlp_in_from_config = toPut(tlp_out_cfg_fifo);
   interface Put tlp_in_from_dma    = toPut(tlp_out_dma_fifo);
   interface Put tlp_in_from_portal = toPut(tlp_out_portal_fifo);
   interface Put tlp_in_from_axi    = toPut(tlp_out_axi_fifo);

   method Bool read_tlp       = is_read;
   method Bool write_tlp      = is_write;
   method Bool completion_tlp = is_completion;

endmodule

// An MSIX table entry, as defined in the PCIe spec
interface MSIX_Entry;
   interface Reg#(Bit#(32)) addr_lo;
   interface Reg#(Bit#(32)) addr_hi;
   interface Reg#(Bit#(32)) msg_data;
   interface Reg#(Bool)     masked;
endinterface

interface PortalEngine;
    interface Put#(TLPData#(16))   tlp_in;
    interface Get#(TLPData#(16))   tlp_out;
    interface Axi3Master#(32,32,4,12) portal;
    interface Reg#(Bool)           pipeliningEnabled;
endinterface

(* synthesize *)
module mkPortalEngine#(PciId my_id)(PortalEngine);
    Reg#(Bool) pipeliningEnabledReg <- mkReg(False);
    Reg#(Bool) busyReg <- mkReg(False);
    Reg#(Bit#(7)) hitReg <- mkReg(0);
    Reg#(Bit#(4)) timerReg <- mkReg(0);
    FIFO#(TLPMemoryIO3DWHeader) readHeaderFifo <- mkFIFO;
    FIFO#(TLPMemoryIO3DWHeader) readDataFifo <- mkFIFO;
    FIFO#(TLPMemoryIO3DWHeader) writeHeaderFifo <- mkFIFO;
    FIFO#(TLPMemoryIO3DWHeader) writeDataFifo <- mkFIFO;
    FIFO#(TLPData#(16)) tlpOutFifo <- mkFIFO;

    rule txnTimer if (timerReg > 0);
        timerReg <= timerReg - 1;
    endrule

//     rule txnTimeout if (busyReg && timerReg == 0);
// 	let hdr = readDataFifo.first;
// 	//FIXME: assumes only 1 word read per request
// 	readDataFifo.deq;

// 	TLPCompletionHeader completion = defaultValue;
// 	completion.format = MEM_WRITE_3DW_DATA;
// 	completion.pkttype = COMPLETION;
// 	completion.nosnoop = SNOOPING_REQD;
// 	completion.length = 1;
// 	completion.cmplid = my_id;
// 	completion.tag = truncate(hdr.tag);
// 	completion.bytecount = 4;
// 	completion.reqid = hdr.reqid;
// 	completion.loweraddr = getLowerAddr(hdr.addr, hdr.firstbe);
// 	completion.data = byteSwap(32'h0badfeed);
// 	TLPData#(16) tlp = defaultValue;
// 	tlp.data = pack(completion);
// 	tlp.sof = True;
// 	tlp.eof = True;
// 	tlp.be = 16'hFFFF;
// 	tlp.hit = hitReg;
// 	tlpOutFifo.enq(tlp);
// 	busyReg <= False;
//     endrule

    interface Put tlp_in;
        method Action put(TLPData#(16) tlp) if (!busyReg);
	    //$display("PortalEngine.put tlp=%h", tlp);
	    TLPMemoryIO3DWHeader h = unpack(tlp.data);
	    hitReg <= tlp.hit;
	    TLPMemoryIO3DWHeader hdr_3dw = unpack(tlp.data);
	    if (hdr_3dw.format == MEM_READ_3DW_NO_DATA)
	        readHeaderFifo.enq(hdr_3dw);
	    else
	        writeHeaderFifo.enq(hdr_3dw);
            if (!pipeliningEnabledReg)
	        busyReg <= True;
            timerReg <= truncate(32'hFFFFFFFF);
	endmethod
    endinterface: tlp_in
    interface Get tlp_out = toGet(tlpOutFifo);
    interface Axi3Master portal;
	interface Axi3MasterWrite write;
	    method ActionValue#(Bit#(32)) writeAddr();
	        let hdr = writeHeaderFifo.first;
	        writeHeaderFifo.deq;
		writeDataFifo.enq(hdr);
		return (extend(writeHeaderFifo.first.addr) << 2);
	    endmethod
	    method Bit#(4) writeBurstLen();
		return 0;
	    endmethod
	    method Bit#(3) writeBurstWidth();
		return 3'b010; // 3'b010: 32bit, 3'b011: 64bit, 3'b100: 128bit
	    endmethod
	    method Bit#(2) writeBurstType();  // drive with 2'b01 increment address
		return 2'b01; // increment address
	    endmethod
	    method Bit#(3) writeBurstProt(); // drive with 3'b000
		return 3'b000;
	    endmethod
	    method Bit#(4) writeBurstCache(); // drive with 4'b0011
		return 4'b0011;
	    endmethod
	    method Bit#(12) writeId();
		return extend(writeHeaderFifo.first.tag);
	    endmethod

	    method ActionValue#(Bit#(32)) writeData();
	        busyReg <= False;
	        writeDataFifo.deq;
		return byteSwap(writeDataFifo.first.data);
	    endmethod
	    method Bit#(12) writeWid();
		return extend(writeDataFifo.first.tag);
	    endmethod
	    method Bit#(4) writeDataByteEnable();
		return writeDataFifo.first.firstbe;
	    endmethod
	    method Bit#(1) writeLastDataBeat(); // last data beat
		return 0;
	    endmethod

	    method Action writeResponse(Bit#(2) responseCode, Bit#(12) id);
	    endmethod
	endinterface: write

	interface Axi3MasterRead read;
	    method ActionValue#(Bit#(32)) readAddr();
	        let hdr = readHeaderFifo.first;
	        readHeaderFifo.deq;
		readDataFifo.enq(hdr);
		return (extend(readHeaderFifo.first.addr) << 2);
	    endmethod
	    method Bit#(4) readBurstLen();
		return 0;
	    endmethod
	    method Bit#(3) readBurstWidth();
		return 3'b010; // 3'b010: 32bit, 3'b011: 64bit, 3'b100: 128bit
	    endmethod
	    method Bit#(2) readBurstType();  // drive with 2'b01
		return 2'b01;
	    endmethod
	    method Bit#(3) readBurstProt(); // drive with 3'b000
		return 3'b000;
	    endmethod
	    method Bit#(4) readBurstCache(); // drive with 4'b0011
		return 4'b0011;
	    endmethod
	    method Bit#(12) readId();
		return extend(readHeaderFifo.first.tag);
	    endmethod
	    method Action readData(Bit#(32) data, Bit#(2) resp, Bit#(1) last, Bit#(12) id);
	        let hdr = readDataFifo.first;
		//FIXME: assumes only 1 word read per request
		readDataFifo.deq;

	        TLPCompletionHeader completion = defaultValue;
		completion.format = MEM_WRITE_3DW_DATA;
		completion.pkttype = COMPLETION;
		completion.nosnoop = SNOOPING_REQD;
		completion.length = 1;
		completion.cmplid = my_id;
		completion.tag = truncate(id);
		completion.bytecount = 4;
		completion.reqid = hdr.reqid;
		completion.loweraddr = getLowerAddr(hdr.addr, hdr.firstbe);
		completion.data = data;
	        TLPData#(16) tlp = defaultValue;
		tlp.data = pack(completion);
		tlp.sof = True;
		tlp.eof = True;
		tlp.be = 16'hFFFF;
		tlp.hit = hitReg;
		tlpOutFifo.enq(tlp);
		busyReg <= False;
	    endmethod
	endinterface: read
    endinterface: portal
    interface Reg pipeliningEnabled = pipeliningEnabledReg;
endmodule: mkPortalEngine

interface AxiSlaveEngine;
    interface Put#(TLPData#(16))   tlp_in;
    interface Get#(TLPData#(16))   tlp_out;
    interface Axi3Slave#(40,32,4,12)  slave;
endinterface: AxiSlaveEngine

module mkAxiSlaveEngine#(PciId my_id)(AxiSlaveEngine);
    FIFO#(TLPData#(16)) tlpOutFifo <- mkFIFO;

    Reg#(Bit#(7)) hitReg <- mkReg(0);
    FIFO#(TLPMemoryIO3DWHeader) completionFifo <- mkFIFO;
    interface Put tlp_in;
        method Action put(TLPData#(16) tlp);
	    $display("AxiSlaveEngine.put tlp=%h", tlp);
	    TLPMemoryIO3DWHeader h = unpack(tlp.data);
	    hitReg <= tlp.hit;
	    TLPMemoryIO3DWHeader hdr_3dw = unpack(tlp.data);
	    if (hdr_3dw.format == MEM_WRITE_3DW_DATA)
	        completionFifo.enq(hdr_3dw);
	endmethod
    endinterface: tlp_in
    interface Get tlp_out = toGet(tlpOutFifo);
    interface Axi3Slave slave;
	interface Axi3SlaveWrite write;
	   method Action writeAddr(Bit#(addrWidth) addr, Bit#(4) burstLen, Bit#(3) burstWidth,
				   Bit#(2) burstType, Bit#(3) burstProt, Bit#(4) burstCache, Bit#(12) awid);
           endmethod: writeAddr
	   method Action writeData(Bit#(busWidth) data, Bit#(busWidthBytes) byteEnable, Bit#(1) last);
           endmethod: writeData
	   method ActionValue#(Bit#(2)) writeResponse();
	       return 0;
           endmethod: writeResponse
	   method ActionValue#(Bit#(12)) bid();
	       return 0;
           endmethod: bid
	endinterface
	interface Axi3SlaveRead read;
	   method Action readAddr(Bit#(40) addr, Bit#(4) burstLen, Bit#(3) burstWidth,
				  Bit#(2) burstType, Bit#(3) burstProt, Bit#(4) burstCache, Bit#(12) arid);
               TLPMemory4DWHeader hdr_4dw = defaultValue;
	       hdr_4dw.format = MEM_READ_4DW_NO_DATA;
	       hdr_4dw.tag = truncate(arid);
	       hdr_4dw.reqid = my_id;
	       hdr_4dw.nosnoop = SNOOPING_REQD;
	       hdr_4dw.addr = addr[40-1:2];
	       hdr_4dw.length = 1;
	       hdr_4dw.firstbe = 4'hf;
	       hdr_4dw.lastbe = 0;
	       TLPData#(16) tlp = defaultValue;
	       tlp.data = pack(hdr_4dw);
	       tlp.sof = True;
	       tlp.eof = True;
	       tlp.hit = 7'h00;
	       tlp.be = 16'hffff;
	       tlpOutFifo.enq(tlp);
           endmethod: readAddr
	   method ActionValue#(Bit#(32)) readData();
	       let hdr = completionFifo.first;
	       completionFifo.deq;
	       return hdr.data;
           endmethod: readData
	   method Bit#(1) last();
	       return 1;
           endmethod: last
	   method Bit#(12) rid();
	       return zeroExtend(completionFifo.first.tag);
           endmethod: rid
	   // method Action readResponse(Bit#(2) responseCode);
	endinterface: read
    endinterface: slave
endmodule: mkAxiSlaveEngine

typedef enum {
    Idle,
    SendAddress,
    WaitingForData,
    Done
} AxiSlaveTestState deriving (Bits,Eq);

interface AxiSlaveTest;
    interface Axi3Master#(40,32,4,12) master;
    interface Reg#(Bit#(40)) addr;
    interface Reg#(Bit#(32)) result;
    interface Reg#(AxiSlaveTestState) state;
    method Action start();
    method ActionValue#(Bit#(32)) done();
endinterface: AxiSlaveTest

module mkAxiSlaveTest(AxiSlaveTest);
    Reg#(Bit#(40)) addrReg <- mkReg(0);
    Reg#(Bit#(32)) resultReg <- mkReg(0);
    Reg#(AxiSlaveTestState) stateReg <- mkReg(Idle);

    interface Axi3Master master;
	interface Axi3MasterRead read;
	   method ActionValue#(Bit#(40)) readAddr() if (stateReg == SendAddress);
	       stateReg <= WaitingForData;
	       return addrReg;
	   endmethod
	   method Bit#(4) readBurstLen();
	       return 0;
	   endmethod
	   method Bit#(3) readBurstWidth();
	       return pack(ReadBurstWidth32);
	   endmethod
	   method Bit#(2) readBurstType();  // drive with 2'b01
	       return 2'b01;
	   endmethod
	   method Bit#(3) readBurstProt(); // drive with 3'b000
	       return 3'b000;
	   endmethod
	   method Bit#(4) readBurstCache(); // drive with 4'b0011
	       return 4'b0011;
	   endmethod
	   method Bit#(idWidth) readId();
	       return 22;
	   endmethod
	   method Action readData(Bit#(32) data, Bit#(2) resp, Bit#(1) last, Bit#(12) id) if (stateReg == WaitingForData);
	       resultReg <= data;
	       stateReg <= Done;
	   endmethod
	endinterface
    endinterface
    interface Reg addr = addrReg;
    interface Reg result = resultReg;
    interface Reg state = stateReg;
    method Action start() if (stateReg == Idle);
        stateReg <= SendAddress;
    endmethod
    method ActionValue#(Bit#(32)) done() if (stateReg == Done);
        stateReg <= Idle;
	return resultReg;
    endmethod
endmodule: mkAxiSlaveTest


// The control and status registers which are accessible from the PCIe
// bus.
interface ControlAndStatusRegs;

   // PCIe-facing interfaces
   interface Put#(TLPData#(16)) csr_read_and_write_tlps;
   interface Get#(TLPData#(16)) csr_read_completion_tlps;

   // DMA-facing interfaces
   (* always_ready *)
   method Bool is_activated();
   (* always_ready *)
   method Action set_write_buffers_level(UInt#(5) n);
   (* always_ready *)
   method Action set_read_buffers_level(UInt#(5) n);
   (* always_ready *)
   method Action incr_rd_xfer_count(UInt#(5) bytes);
   (* always_ready *)
   method Action incr_wr_xfer_count(UInt#(5) bytes);
   (* always_ready *)
   method Action finished_write();
   (* always_ready *)
   method Action finished_read(Bool short);
   (* always_ready, always_enabled *)
   method Action has_space_to_receive_data(Bool b);
   (* always_ready, always_enabled *)
   method Action has_data_to_send(Bool b);
   (* always_ready *)
   method Action interrupt();
   interface Get#(Tuple2#(Bit#(64),Bit#(32))) intr_to_send;

   // Used to generate MSI interrupts through the PCIe endpoint
   (* always_ready *)
   method Bool msi_interrupt_req();
   (* always_ready *)
   method Action msi_interrupt_clear();

   interface Reg#(Bool) tlpTracing;
   interface Reg#(Bool) axiEnabled;
   interface Reg#(Bool) pipeliningEnabled;
   interface Reg#(Bool) axiTestEnabled;
   interface Reg#(Bit#(32)) addrLowerWord;
   interface Reg#(Bit#(32)) addrUpperWord;
   interface Reg#(Bit#(32)) testResult;
   interface Reg#(Bit#(32)) testState;
   interface Reg#(Bit#(32)) tlpDataBramWrAddr;
   interface Reg#(Bit#(32)) tlpSeqno;
   interface Reg#(Bit#(32)) tlpOutCount;
   interface BRAMServer#(Bit#(7), TimestampedTlpData) tlpDataBram;
endinterface: ControlAndStatusRegs

// This module encapsulates all of the logic for instantiating and
// accessing the control and status registers. It defines the
// registers, the address map, and how the registers respond to reads
// and writes.
module mkControlAndStatusRegs#( Bit#(64)  board_content_id
                              , PciId     my_id
                              , Integer   bytes_per_beat
                              , Bit#(7)   rcb_mask
                              , Bool      msix_enabled
                              , Bool      msix_mask_all_intr
                              , Bool      msi_enabled
			      , PortalEngine portalEngine
                              )
                              (ControlAndStatusRegs);

   // Utility for module creating all of the storage for a single MSIX
   // table entry
   module mkMSIXEntry(MSIX_Entry);
      Reg#(Bit#(32)) _addr_lo  <- mkConfigReg(0);
      Reg#(Bit#(32)) _addr_hi  <- mkConfigReg(0);
      Reg#(Bit#(32)) _msg_data <- mkConfigReg(0);
      Reg#(Bool)     _masked   <- mkConfigReg(True);

      interface addr_lo  = _addr_lo;
      interface addr_hi  = _addr_hi;
      interface msg_data = _msg_data;
      interface masked   = _masked;
   endmodule: mkMSIXEntry

   // Revision information for this implementation
   Integer major_rev = 1;
   Integer minor_rev = 0;

   // Registers and their default values
   Reg#(Bool)            is_board_number_assigned <- mkReg(False);
   Reg#(UInt#(4))        board_number             <- mkReg(15);
   Reg#(Bool)            is_network_active        <- mkConfigReg(False);
   Reg#(NodeID)          host_nodeid              <- mkReg(unpack(0));
   Vector#(4,MSIX_Entry) msix_entry               <- replicateM(mkMSIXEntry);
   Reg#(Bool)            end_of_read_list         <- mkReg(False);
   Reg#(Bool)            flushed                  <- mkReg(False);
   Reg#(Bool)            end_of_write_list        <- mkReg(False);
   Reg#(UInt#(32))       rd_xfer_count            <- mkReg(0);
   Reg#(UInt#(32))       wr_xfer_count            <- mkReg(0);

   // Wires used to manage concurrent actions
   PulseWire         reset_read_status  <- mkPulseWireOR();
   PulseWire         reset_write_status <- mkPulseWireOR();
   RWire#(UInt#(5))  rd_xfer_incr       <- mkRWire();
   RWire#(UInt#(5))  wr_xfer_incr       <- mkRWire();
   PulseWire         finished_read_pw   <- mkPulseWire();
   PulseWire         finished_write_pw  <- mkPulseWire();
   PulseWire         flushed_pw         <- mkPulseWire();
   Wire#(Bool)       space_for_read     <- mkBypassWire();
   Wire#(Bool)       data_to_write      <- mkBypassWire();

   // A FIFO used for managing MSI-X interrupt requests
   FIFOF#(Tuple2#(Bit#(64),Bit#(32))) intr_info <- mkGFIFOF(True,False); // unguarded enq
   PulseWire                          intr_read <- mkPulseWire();

   // A register used for MSI interrupt requests
   Reg#(Bool) msi_intr_needed <- mkReg(False);

   // External values available in the CSR address space
   Wire#(UInt#(5)) write_buffers_level <- mkBypassWire();
   Wire#(UInt#(5)) read_buffers_level  <- mkBypassWire();

   // We want to notify the user when space becomes
   // available for writing (via DMA read) and when data
   // becomes available for reading (via DMA write).
   Reg#(Bool) read_operation_in_progress <- mkReg(False);
   Reg#(Bool) write_operation_in_progress <- mkReg(False);
   Bool read_allowed  = !read_operation_in_progress && data_to_write;
   Bool write_allowed = !write_operation_in_progress && space_for_read;

   Reg#(Bool) tlpTracingReg <- mkReg(False);
   Reg#(Bool) axiEnabledReg <- mkReg(False);
   Reg#(Bool) pipeliningEnabledReg <- mkReg(False);
   Reg#(Bool) axiTestEnabledReg <- mkReg(False);
   Reg#(Bit#(32)) addrLowerWordReg <- mkReg(0);
   Reg#(Bit#(32)) addrUpperWordReg <- mkReg(0);
   Reg#(Bit#(32)) testResultReg <- mkReg(0);
   Reg#(Bit#(32)) testStateReg <- mkReg(0);
   Reg#(Bit#(32)) tlpSeqnoReg <- mkReg(0);
   Reg#(Bit#(32)) tlpDataBramRdAddrReg <- mkReg(0);
   Reg#(Bit#(32)) tlpDataBramWrAddrReg <- mkReg(0);
   BRAM_Configure bramCfg = defaultValue;
   bramCfg.memorySize = 128;
   BRAM1Port#(Bit#(7), TimestampedTlpData) tlpDataBram1Port <- mkBRAM1Server(bramCfg);
   Reg#(TimestampedTlpData) tlpDataBramResponse <- mkReg(unpack(0));
   Vector#(6, Reg#(Bit#(32))) tlpDataScratchpad <- replicateM(mkReg(0));
   Reg#(Bit#(32)) tlpOutCountReg <- mkReg(0);

   // Function to return a one-word slice of the tlpDataBramResponse
   function Bit#(32) tlpDataBramResponseSlice(Bit#(3) i);
       Bit#(8) i8 = zeroExtend(i);
       begin
           Bit#(192) v = extend(pack(tlpDataBramResponse));
           return v[31 + (i8*32) : 0 + (i8*32)];
       end
   endfunction

   // Function to read from the CSR address space (using DW address)
   function Bit#(32) rd_csr(UInt#(30) addr);
      case (addr % 8192)
         // board identification
         0: return 32'h65756c42; // Blue
         1: return 32'h63657073; // spec
         2: return fromInteger(minor_rev);
         3: return fromInteger(major_rev);
         4: return pack(buildVersion);
         5: return pack(epochTime);
         6: return {23'd0,pack(is_board_number_assigned),4'd0,pack(board_number)};
         7: return {24'd0,fromInteger(bytes_per_beat)};
         8: return board_content_id[31:0];
         9: return board_content_id[63:32];
         // network configuration
         64: return zeroExtend({pack(is_network_active),pack(host_nodeid)});
         // DMA status
         512: return {23'd0,pack(read_allowed),pack(read_buffers_level == 16),pack(end_of_read_list),pack(flushed),pack(read_buffers_level)};
         513: return {23'd0,pack(write_allowed),pack(write_buffers_level == 16),pack(end_of_write_list),1'b0,pack(write_buffers_level)};
         514: return pack(rd_xfer_count);
         515: return pack(wr_xfer_count);
	 768: return 0;
	 769: return 0;
	 770: return 0;
	 771: return 0;
	 772: return 0;
	 773: return 0;
	 774: return tlpSeqnoReg;
	 775: return (tlpTracingReg ? 1 : 0);
	 776: return tlpDataBramResponseSlice(0);
	 777: return tlpDataBramResponseSlice(1);
	 778: return tlpDataBramResponseSlice(2);
	 779: return tlpDataBramResponseSlice(3);
	 780: return tlpDataBramResponseSlice(4);
	 781: return tlpDataBramResponseSlice(5);
	 782: return axiTestEnabledReg ? 1 : 0;
	 783: return addrLowerWordReg;
	 784: return addrUpperWordReg;
	 785: return testResultReg;
	 786: return testStateReg;
	 787: return pipeliningEnabledReg ? 1 : 0;
	 788: return axiEnabledReg ? 1 : 0;
	 789: return tlpDataBramRdAddrReg;
	 790: return msix_enabled ? 1 : 0;
	 791: return msix_mask_all_intr ? 1 : 0;
	 792: return tlpDataBramWrAddrReg;
	 793: return msi_enabled ? 1 : 0;

         // 4-entry MSIx table
         4096: return msix_entry[0].addr_lo;            // entry 0 lower address
         4097: return msix_entry[0].addr_hi;            // entry 0 upper address
         4098: return msix_entry[0].msg_data;           // entry 0 msg data
         4099: return {'0, pack(msix_entry[0].masked)}; // entry 0 vector control
         4100: return msix_entry[1].addr_lo;            // entry 1 lower address
         4101: return msix_entry[1].addr_hi;            // entry 1 upper address
         4102: return msix_entry[1].msg_data;           // entry 1 msg data
         4103: return {'0, pack(msix_entry[1].masked)}; // entry 1 vector control
         4104: return msix_entry[2].addr_lo;            // entry 2 lower address
         4105: return msix_entry[2].addr_hi;            // entry 2 upper address
         4106: return msix_entry[2].msg_data;           // entry 2 msg data
         4107: return {'0, pack(msix_entry[2].masked)}; // entry 2 vector control
         4108: return msix_entry[3].addr_lo;            // entry 3 lower address
         4109: return msix_entry[3].addr_hi;            // entry 3 upper address
         4110: return msix_entry[3].msg_data;           // entry 3 msg data
         4111: return {'0, pack(msix_entry[3].masked)}; // entry 3 vector control
         // 4-bit MSIx pending bit field
         5120: return {'0, pack(intr_info.notEmpty())}; // PBA structure (low)
         5121: return '0;                               // PBA structure (high)
         // unused addresses
         default: return 32'hbad0add0;
      endcase
   endfunction: rd_csr

   // Utility function for managing partial writes
   function t update_dword(t dword_orig, Bit#(4) be, Bit#(32) dword_in) provisos(Bits#(t,32));
      Vector#(4,Bit#(8)) result = unpack(pack(dword_orig));
      Vector#(4,Bit#(8)) vin    = unpack(dword_in);
      for (Integer i = 0; i < 4; i = i + 1)
         if (be[i] != 0) result[i] = vin[i];
      return unpack(pack(result));
   endfunction: update_dword

   // Function to write to the CSR address space (using DW address)
   function Action wr_csr(UInt#(30) addr, Bit#(4) be, Bit#(32) dword);
      action
         case (addr % 8192)
            // board identification
            6:  begin
                   if (be[0] == 1) board_number             <= unpack(dword[3:0]);
                   if (be[1] == 1) is_board_number_assigned <= unpack(dword[8]);
                end
            // network configuration
            64: begin
                   if (be[0] == 1) host_nodeid       <= unpack(dword[7:0]);
                   if (be[1] == 1) is_network_active <= unpack(dword[8]);
                end
            // DMA status
            512: if (be[0] == 1) reset_read_status.send();
            513: if (be[0] == 1) reset_write_status.send();
	    774: tlpSeqnoReg <= dword;
	    775: tlpTracingReg <= (dword != 0) ? True : False;
	    776: tlpDataScratchpad[0] <= dword;
	    777: tlpDataScratchpad[1] <= dword;
	    778: tlpDataScratchpad[2] <= dword;
	    779: tlpDataScratchpad[3] <= dword;
	    780: tlpDataScratchpad[4] <= dword;
	    781: tlpDataScratchpad[5] <= dword;
	    782: axiTestEnabledReg <= (dword != 0) ? True : False;
	    783: addrLowerWordReg <= dword;
	    784: addrUpperWordReg <= dword;
	    785: testResultReg <= dword;
	    786: testStateReg <= dword;

	    787: pipeliningEnabledReg <= (dword != 0) ? True : False;
	    788: axiEnabledReg <= (dword != 0) ? True : False;
	    789: tlpDataBramRdAddrReg <= dword;
	    792: tlpDataBramWrAddrReg <= dword;

            // MSIx table entries
            4096: msix_entry[0].addr_lo  <= update_dword(msix_entry[0].addr_lo, be, (dword & 32'hfffffffc));
            4097: msix_entry[0].addr_hi  <= update_dword(msix_entry[0].addr_hi, be, dword);
            4098: msix_entry[0].msg_data <= update_dword(msix_entry[0].msg_data, be, dword);
            4099: if (be[0] == 1) msix_entry[0].masked <= unpack(dword[0]);
            4100: msix_entry[1].addr_lo  <= update_dword(msix_entry[1].addr_lo, be, (dword & 32'hfffffffc));
            4101: msix_entry[1].addr_hi  <= update_dword(msix_entry[1].addr_hi, be, dword);
            4102: msix_entry[1].msg_data <= update_dword(msix_entry[1].msg_data, be, dword);
            4103: if (be[0] == 1) msix_entry[1].masked <= unpack(dword[0]);
            4104: msix_entry[2].addr_lo  <= update_dword(msix_entry[2].addr_lo, be, (dword & 32'hfffffffc));
            4105: msix_entry[2].addr_hi  <= update_dword(msix_entry[2].addr_hi, be, dword);
            4106: msix_entry[2].msg_data <= update_dword(msix_entry[2].msg_data, be, dword);
            4107: if (be[0] == 1) msix_entry[2].masked <= unpack(dword[0]);
            4108: msix_entry[3].addr_lo  <= update_dword(msix_entry[3].addr_lo, be, (dword & 32'hfffffffc));
            4109: msix_entry[3].addr_hi  <= update_dword(msix_entry[3].addr_hi, be, dword);
            4110: msix_entry[3].msg_data <= update_dword(msix_entry[3].msg_data, be, dword);
            4111: if (be[0] == 1) msix_entry[3].masked <= unpack(dword[0]);
         endcase
      endaction
   endfunction: wr_csr

   // Interrupts can be requested externally, or generated internally

   PulseWire external_intr <- mkPulseWire();
   PulseWire internal_intr <- mkPulseWire();

   (* fire_when_enabled, no_implicit_conditions *)
   rule trigger_interrupt if (is_network_active && (external_intr || internal_intr));
      if (msix_enabled && !intr_info.notEmpty())
         intr_info.enq(tuple2({msix_entry[0].addr_hi,msix_entry[0].addr_lo},msix_entry[0].msg_data));
      else if (msi_enabled)
         msi_intr_needed <= True;
   endrule

   // State used to actually service read and write requests

   Reg#(Bool)       read_in_progress <- mkReg(False);
   Reg#(Bool)       need_rd_bytes    <- mkReg(False);
   Reg#(Bool)       header_sent      <- mkReg(False);
   Reg#(UInt#(13))  bytes_to_send    <- mkRegU();
   Reg#(UInt#(32))  curr_rd_addr     <- mkRegU();
   Reg#(UInt#(6))   dws_left_in_tlp  <- mkReg(0);
   FIFO#(UInt#(30)) rd_addr_queue    <- mkFIFO();

   Reg#(TLPTrafficClass)        saved_tc       <- mkRegU();
   Reg#(TLPAttrRelaxedOrdering) saved_attr_ro  <- mkRegU();
   Reg#(TLPAttrNoSnoop)         saved_attr_ns  <- mkRegU();
   Reg#(TLPTag)                 saved_tag      <- mkRegU();
   Reg#(PciId)                  saved_reqid    <- mkRegU();
   Reg#(Bit#(7))                saved_bar      <- mkRegU();
   Reg#(UInt#(30))              saved_addr     <- mkRegU();
   Reg#(UInt#(10))              saved_length   <- mkRegU();
   Reg#(TLPFirstDWBE)           saved_firstbe  <- mkRegU();
   Reg#(TLPLastDWBE)            saved_lastbe   <- mkRegU();

   ByteBuffer#(16) completion_tlp <- mkByteBuffer();

   // Read byte_count bytes starting at byte address addr (handles unaligned byte address issues)
   function ActionValue#(UInt#(13)) do_read(Bit#(7) hit, UInt#(13) byte_count, UInt#(32) addr);
      actionvalue
         UInt#(13) bytes_covered = byte_count;
         if (hit == 7'h01) begin
            UInt#(3) bytes_in_dword = 4 - truncate(addr % 4);
            UInt#(3) bytes_to_read = (byte_count < zeroExtend(bytes_in_dword)) ? truncate(byte_count) : bytes_in_dword;
            rd_addr_queue.enq(truncate(addr/4));
            bytes_covered = zeroExtend(bytes_to_read);
         end
         return bytes_covered;
      endactionvalue
   endfunction: do_read

   rule bramResponse;
       let v <- tlpDataBram1Port.portA.response.get();
       tlpDataBramResponse <= v;
   endrule

   // Supply data (with dword granularity and byte enables) to be
   // written.
   function Action do_write(UInt#(30) addr, Vector#(4,Tuple2#(Bit#(4),Bit#(32))) value);
      action
         if ((addr % 8192) == 768) begin
	     tlpDataBram1Port.portA.request.put(BRAMRequest{ write: False, responseOnWrite: False, address: truncate(tlpDataBramRdAddrReg), datain: unpack(0)});
	     tlpDataBramRdAddrReg <= tlpDataBramRdAddrReg + 1;
	 end else if ((addr % 8192) == 792) begin
	     // update tplDataBramWrAddrReg and write back scratchpad
	     Bit#(TimestampedTlpDataSize) ttd = 0;
	     ttd[31+(0*32):0+(0*32)] = tlpDataScratchpad[0];
	     ttd[31+(1*32):0+(1*32)] = tlpDataScratchpad[1];
	     ttd[31+(2*32):0+(2*32)] = tlpDataScratchpad[2];
	     ttd[31+(3*32):0+(3*32)] = tlpDataScratchpad[3];
	     ttd[31+(4*32):0+(4*32)] = tlpDataScratchpad[4];
	     ttd[24+(5*32):0+(5*32)] = tlpDataScratchpad[5][24:0];
	     tlpDataBram1Port.portA.request.put(BRAMRequest{ write: True, responseOnWrite: False, address: truncate(tpl_2(value[0])),
	                                                     datain: unpack(ttd)});
         end
         wr_csr(addr,  tpl_1(value[0]),tpl_2(value[0]));
         wr_csr(addr+1,tpl_1(value[1]),tpl_2(value[1]));
         wr_csr(addr+2,tpl_1(value[2]),tpl_2(value[2]));
         wr_csr(addr+3,tpl_1(value[3]),tpl_2(value[3]));
      endaction
   endfunction: do_write

   // The number of bytes sent in a completion is determined by the
   // the starting address, the number of bytes requested and the
   // PCIe read completion boundary

   function UInt#(8) bytes_to_next_completion_boundary(DWAddress addr);
      UInt#(8)  rcb_offset  = unpack({1'b0,truncate({pack(addr),2'b00}) & rcb_mask});
      UInt#(8)  bytes_to_next_rcb = unpack(~pack(rcb_offset - 1) & {1'b0,rcb_mask});
      return (rcb_offset == 0) ? unpack(zeroExtend(rcb_mask) + 1) : bytes_to_next_rcb;
   endfunction

   function UInt#(6) dws_in_completion(TLPLength dws_remaining, DWAddress starting_addr);
      UInt#(12) num_bytes = 4 * zeroExtend(unpack(dws_remaining));
      UInt#(8)  bytes_to_next_rcb = bytes_to_next_completion_boundary(starting_addr);
      UInt#(6)  dws_in_next_completion = truncate(min(num_bytes,zeroExtend(bytes_to_next_rcb)) / 4);
      return dws_in_next_completion;
   endfunction

   // The initiate_read rule fires when need_rd_bytes is set (by the
   // put method), and it fills the rd_addr_queue FIFO with the next
   // dword address to fill in the read completion data.
   (* fire_when_enabled *)
   rule initiate_read if (read_in_progress && need_rd_bytes);
      UInt#(13) bytes_covered_by_request <- do_read(saved_bar, bytes_to_send, curr_rd_addr);
      if (bytes_covered_by_request == bytes_to_send)
         need_rd_bytes <= False;
      else begin
         bytes_to_send <= bytes_to_send - bytes_covered_by_request;
         curr_rd_addr  <= curr_rd_addr + zeroExtend(bytes_covered_by_request);
      end
   endrule: initiate_read

   // This rule is used to set up the 3DW of completion header
   // when a new completion is started.
   (* fire_when_enabled *)
   rule write_completion_header if (read_in_progress && !header_sent && (completion_tlp.valid_mask() == replicate(False)));
      // Write first 3 DWs of header into completion TLP buffer
      TLPCompletionHeader rc_hdr = defaultValue();
      rc_hdr.tclass    = saved_tc;
      rc_hdr.relaxed   = saved_attr_ro;
      rc_hdr.nosnoop   = saved_attr_ns;
      rc_hdr.length    = pack(saved_length);
      rc_hdr.cmplid    = my_id;
      rc_hdr.tag       = saved_tag;
      rc_hdr.bytecount = computeByteCount(pack(saved_length),saved_firstbe,saved_lastbe);
      rc_hdr.reqid     = saved_reqid;
      rc_hdr.loweraddr = getLowerAddr(pack(saved_addr),saved_firstbe);
      Vector#(16,Bit#(8)) rc_hdr_dws = unpack(pack(rc_hdr));
      completion_tlp.clear();
      for (Integer i = 4; i < 16; i = i + 1)
         completion_tlp.bytes[i] <= rc_hdr_dws[i];
      // Add padding for unused bytes in first word
      for (Integer i = 0; i < 4; i = i + 1)
         if (saved_firstbe[i] == 0) completion_tlp.bytes[3-i] <= ?;
   endrule: write_completion_header

   // The do_csr_read rule fills in the data area of the completion
   // header set up by the put method.  It is less urgent than:
   //   - write_completion_header (conflict happens at start of a
   //     new completion)
   //   - pad_completion_TLP (conflict happens at read completion
   //     boundaries)
   (* descending_urgency = "write_completion_header, do_csr_read" *)
   rule do_csr_read if (read_in_progress && (completion_tlp.valid_mask() != replicate(True)));
      UInt#(30) addr = rd_addr_queue.first();
      rd_addr_queue.deq();
      // FIXME
      Vector#(4,Bit#(8)) result = unpack(byteSwap(rd_csr(addr)));
      Bit#(16) mask = pack(completion_tlp.valid_mask());
      // Note firstbe is already handled when the header is set up
      if (mask[15:12] != '1) begin
         for (Integer i = 0; i < 4; i = i + 1)
            if (mask[12+i] == 0) completion_tlp.bytes[12+i] <= result[i];
      end
      else if (mask[11:8] != '1) begin
         for (Integer i = 0; i < 4; i = i + 1)
            if (mask[8+i] == 0) completion_tlp.bytes[8+i] <= result[i];
      end
      else if (mask[7:4] != '1) begin
         for (Integer i = 0; i < 4; i = i + 1)
            if (mask[4+i] == 0) completion_tlp.bytes[4+i] <= result[i];
      end
      else
         for (Integer i = 0; i < 4; i = i + 1)
            if (mask[i] == 0) completion_tlp.bytes[i] <= result[i];
   endrule: do_csr_read

   // Compute how many dwords have been filled up in the completion
   // TLP
   function UInt#(6) dws_in_buffer(Bit#(16) mask);
      if (mask[3:0] != '0)
         return 4;
      else if (mask[7:4] != '0)
         return 3;
      else if (mask[11:8] != '0)
         return 2;
      else if (mask[15:12] != 0)
         return 1;
      else return 0;
   endfunction

   UInt#(6) dws_in_completion_tlp_buffer = dws_in_buffer(pack(completion_tlp.valid_mask()));
   Bool need_to_pad = (dws_in_completion_tlp_buffer != 4) && (dws_left_in_tlp == dws_in_completion_tlp_buffer);

   // Add padding in the final TLP of a read completion, if not all 4 DWs are occupied
   (* fire_when_enabled *)
   (* descending_urgency="pad_completion_TLP,do_csr_read" *) // why: pause read data at read completion boundary
   rule pad_completion_TLP if (read_in_progress && need_to_pad && (completion_tlp.valid_mask() != replicate(False)));
      for (Integer i = 0; i < 16; i = i + 1) begin
         if (!completion_tlp.valid_mask()[i])
            completion_tlp.bytes[i] <= ?;
      end
   endrule: pad_completion_TLP

   (* fire_when_enabled, no_implicit_conditions *)
   rule reset_csr_dma_state if (!is_network_active);
      end_of_read_list            <= False;
      flushed                     <= False;
      rd_xfer_count               <= 0;
      read_operation_in_progress  <= False;
      end_of_write_list           <= False;
      wr_xfer_count               <= 0;
      write_operation_in_progress <= False;
      msi_intr_needed             <= False;
   endrule

   (* fire_when_enabled, no_implicit_conditions *)
   rule clear_csr_dma_intr if (!is_network_active);
      intr_info.clear();
   endrule

   (* fire_when_enabled *)
   rule deq_csr_dma_intr if (is_network_active && intr_read);
      intr_info.deq();
   endrule

   (* fire_when_enabled, no_implicit_conditions *)
   rule update_csr_dma_state if (is_network_active);
      if (reset_read_status) begin
         end_of_read_list           <= False;
         flushed                    <= False;
         rd_xfer_count              <= 0;
         read_operation_in_progress <= True;
      end
      else begin
         if (rd_xfer_incr.wget() matches tagged Valid .n)
            rd_xfer_count <= rd_xfer_count + zeroExtend(n);
         if (finished_read_pw)
            end_of_read_list <= True;
         if (flushed_pw)
            flushed <= True;
         if (finished_read_pw || flushed_pw)
            read_operation_in_progress <= False;
      end
      if (reset_write_status) begin
         end_of_write_list           <= False;
         wr_xfer_count               <= 0;
         write_operation_in_progress <= True;
      end
      else begin
         if (wr_xfer_incr.wget() matches tagged Valid .n)
            wr_xfer_count <= wr_xfer_count + zeroExtend(n);
         if (finished_write_pw) begin
            end_of_write_list           <= True;
            write_operation_in_progress <= False;
         end
      end
   endrule

   // generate interrupts when a read or write becomes allowed
   // and the SW side needs to know this

   Reg#(Bool) prev_read_allowed  <- mkReg(False);
   Reg#(Bool) prev_write_allowed <- mkReg(False);

   (* fire_when_enabled, no_implicit_conditions *)
   rule generate_internal_interrupts if (is_network_active);
      Bool do_internal_intr = False;
      if (!prev_read_allowed && read_allowed)
         do_internal_intr = True;
      if (!prev_write_allowed && write_allowed)
         do_internal_intr = True;
      prev_read_allowed  <= read_allowed;
      prev_write_allowed <= write_allowed;
      if (do_internal_intr)
         internal_intr.send();
   endrule


   // PCIE-facing interfaces

   interface Put csr_read_and_write_tlps;
      method Action put(TLPData#(16) tlp) if (!read_in_progress);
         Bool is_read = False;
         TLPMemoryIO3DWHeader hdr_3dw = unpack(tlp.data);
         if (tlp.sof) begin
            if (hdr_3dw.format == MEM_READ_3DW_NO_DATA)
               is_read = True;
         end
         if (is_read) begin
            // To handle a read request, we set up so that
            // write_completion_header can fill in the header
            // and let the do_csr_read rule fill in the data
            read_in_progress <= True;
            need_rd_bytes    <= True;
            header_sent      <= False;
            DWAddress addr = hdr_3dw.addr;
            TLPLength len  = hdr_3dw.length;
            Bit#(12) _byte_count = computeByteCount(len,hdr_3dw.firstbe,hdr_3dw.lastbe);
            TLPLowerAddr _lower_addr = getLowerAddr(addr,hdr_3dw.firstbe);
            saved_tc         <= hdr_3dw.tclass;
            saved_attr_ro    <= hdr_3dw.relaxed;
            saved_attr_ns    <= hdr_3dw.nosnoop;
            saved_tag        <= hdr_3dw.tag;
            saved_reqid      <= hdr_3dw.reqid;
            saved_bar        <= tlp.hit;
            saved_addr       <= unpack(addr);
            saved_length     <= unpack(len);
            saved_firstbe    <= hdr_3dw.firstbe;
            saved_lastbe     <= (len == 1) ? '0 : hdr_3dw.lastbe;
            bytes_to_send    <= unpack({pack(_byte_count == '0),_byte_count});
            curr_rd_addr     <= unpack({addr[29:5],_lower_addr});
            dws_left_in_tlp  <= dws_in_completion(len,addr);
         end
         else begin
            // Write requests are handle directly in the put method,
            // using up to 4DWs from the TLP buffer.
            Vector#(4,Tuple2#(Bit#(4),Bit#(32))) vec = replicate(tuple2(4'h0,?));
            if (tlp.sof) begin
               saved_addr    <= unpack(hdr_3dw.addr) + 1;
               saved_length  <= unpack(hdr_3dw.length) - 1;
               saved_lastbe  <= (hdr_3dw.length == 1) ? '0 : hdr_3dw.lastbe;
               vec[0] = tuple2(hdr_3dw.firstbe, byteSwap(hdr_3dw.data));
               do_write(unpack(hdr_3dw.addr),vec);
            end
            else begin
               vec[0] = tuple2((saved_length == 1) ? saved_lastbe : 4'hf, byteSwap(tlp.data[127:96]));
               vec[1] = tuple2((saved_length == 2) ? saved_lastbe : ((saved_length < 2) ? 4'h0 : 4'hf), byteSwap(tlp.data[95:64]));
               vec[2] = tuple2((saved_length == 3) ? saved_lastbe : ((saved_length < 3) ? 4'h0 : 4'hf), byteSwap(tlp.data[63:32]));
               vec[3] = tuple2((saved_length == 4) ? saved_lastbe : ((saved_length < 4) ? 4'h0 : 4'hf), byteSwap(tlp.data[31:0]));
               do_write(saved_addr,vec);
               saved_addr   <= saved_addr + 4;
               saved_length <= saved_length - 4;
            end
         end
      endmethod
   endinterface

   interface Get csr_read_completion_tlps;
      method ActionValue#(TLPData#(16)) get() if (read_in_progress && (completion_tlp.valid_mask() == replicate(True)));
         TLPData#(16) tlp;
         UInt#(8) bytes_in_next_completion = 4 * zeroExtend(dws_left_in_tlp);
         if (!header_sent) begin
            tlp.sof = True;
            tlp.eof = (bytes_in_next_completion <= 4);
            tlp.be  = { 12'hfff, saved_firstbe};
         end
         else begin
            Bit#(4) be0 = '1;
            Bit#(4) be1 = (dws_left_in_tlp > 1) ? '1 : '0;
            Bit#(4) be2 = (dws_left_in_tlp > 2) ? '1 : '0;
            Bit#(4) be3 = (dws_left_in_tlp > 3) ? '1 : '0;
            tlp.sof = False;
            tlp.eof = (bytes_in_next_completion <= 16);
            tlp.be  = {be0,be1,be2,be3};
         end
         tlp.hit = saved_bar;
         tlp.data = pack(readVReg(completion_tlp.bytes));
         completion_tlp.clear();
         UInt#(3) dws_sent = header_sent ? truncate(min(4,dws_left_in_tlp)) : 1;
         if (saved_length <= zeroExtend(dws_sent)) begin
            read_in_progress <= False;
            header_sent      <= False;
         end
         else begin
            saved_firstbe <= '1;
            UInt#(30) new_saved_addr   = saved_addr   + zeroExtend(dws_sent);
            UInt#(10) new_saved_length = saved_length - zeroExtend(dws_sent);
            saved_addr    <= new_saved_addr;
            saved_length  <= new_saved_length;
            UInt#(8) bytes_to_next_rcb = bytes_to_next_completion_boundary(pack(saved_addr));
            if (bytes_to_next_rcb > 4 * zeroExtend(dws_sent)) begin
               header_sent     <= True;
               dws_left_in_tlp <= dws_left_in_tlp - zeroExtend(dws_sent);
            end
            else begin
               // set up for a new read completion header
               header_sent <= False;
               UInt#(6) dws_in_next_completion = dws_in_completion(pack(new_saved_length),pack(new_saved_addr));
               dws_left_in_tlp <= dws_in_next_completion;
            end
         end
         return tlp;
      endmethod
   endinterface

   // DMA-facing interfaces

   method is_activated = is_network_active;

   method set_write_buffers_level = write_buffers_level._write;
   method set_read_buffers_level  = read_buffers_level._write;

   method Action incr_rd_xfer_count(UInt#(5) bytes);
      rd_xfer_incr.wset(bytes);
   endmethod

   method Action incr_wr_xfer_count(UInt#(5) bytes);
      wr_xfer_incr.wset(bytes);
   endmethod

   method Action finished_write();
      finished_write_pw.send();
   endmethod

   method Action finished_read(Bool short);
      if (short)
         flushed_pw.send();
      else
         finished_read_pw.send();
   endmethod

   method Action has_space_to_receive_data(Bool b);
      space_for_read <= b;
   endmethod

   method Action has_data_to_send(Bool b);
      data_to_write <= b;
   endmethod

   method Action interrupt();
      external_intr.send();
   endmethod

   interface Get intr_to_send;
      method ActionValue#(Tuple2#(Bit#(64),Bit#(32))) get() if (!msix_mask_all_intr && !msix_entry[0].masked);
         intr_read.send();
         return intr_info.first();
      endmethod
   endinterface

   method Bool msi_interrupt_req = msi_intr_needed;

   method Action msi_interrupt_clear();
      msi_intr_needed <= False;
   endmethod

   interface Reg tlpTracing = tlpTracingReg;
   interface Reg axiEnabled = axiEnabledReg;
   interface Reg pipeliningEnabled = pipeliningEnabledReg;
   interface Reg axiTestEnabled = axiTestEnabledReg;
   interface Reg addrLowerWord = addrLowerWordReg;
   interface Reg addrUpperWord = addrUpperWordReg;
   interface Reg testResult = testResultReg;
   interface Reg testState = testStateReg;
   interface Reg tlpDataBramWrAddr = tlpDataBramWrAddrReg;
   interface Reg tlpSeqno = tlpSeqnoReg;
   interface Reg tlpOutCount = tlpOutCountReg;
   interface BRAMServer tlpDataBram = tlpDataBram1Port.portA;
endmodule: mkControlAndStatusRegs

// The DMA engine receives DMA commands from the PCIe bus in the form
// of scatter-gather list entries. Based on the commands it receives
// the DMA engine will initiate read and write transactions across the
// PCIe bus to move data to and from the host memory. The DMA engine
// also coordinates with the control and status register module to
// communicate status and interrupts to the host. The other side of
// the DMA engine consists of a connection to the NoC, where DMA data
// is converted to/from NoC messages.

// This is one entry of a DMA scatter-gather list.
typedef struct {
   Bool      last;       // last entry in the list
   Bool      intr_req;   // interrupt when this entry is processed
   UInt#(32) len;        // number of bytes to transfer
   UInt#(64) addr;       // starting address
} DMAListEntry deriving (Bits);

interface DMAEngine#(numeric type bpb);

   // PCIe-facing interfaces
   interface Put#(TLPData#(16)) dma_commands_and_completions;
   interface Get#(TLPData#(16)) dma_read_and_write_requests;

   // NoC-facing interface
   interface MsgPort#(bpb) noc;

   // Methods for coordination with control and status registers
   (* always_ready *)
   method Action clear();
   (* always_ready *)
   method UInt#(5) num_write_commands();
   (* always_ready *)
   method UInt#(5) num_read_commands();
   method UInt#(5) bytes_received();
   method UInt#(5) bytes_sent();
   (* always_ready *)
   method Bool write_operation_completed();
   (* always_ready *)
   method Bool read_operation_completed();
   (* always_ready *)
   method Bool read_flushed();
   (* always_ready *)
   method Bool has_space_to_receive_data();
   (* always_ready *)
   method Bool has_data_to_send();
   (* always_ready *)
   method Bool request_interrupt();
   interface Put#(Tuple2#(Bit#(64),Bit#(32))) next_interrupt;

endinterface: DMAEngine

module mkDMAEngine#( PciId my_id
                   , UInt#(13) max_read_req_bytes
                   , UInt#(13) max_payload_bytes
                   )
                   (DMAEngine#(bpb))
   provisos( Add#(1, __1, TDiv#(bpb,4))
           // the compiler should be able to figure these out ...
           , Log#(TAdd#(1,bpb), TLog#(TAdd#(bpb,1)))
           , Add#(TAdd#(bpb,20), __2, TMul#(TDiv#(TMul#(TAdd#(bpb,20),9),36),4))
           );

   Integer bytes_per_beat = valueOf(bpb);

   // Reset functionality for the DMA engine
   PulseWire      reset_engine  <- mkPulseWire();
   Reg#(Bool)     in_reset  <- mkReg(True);

   (* fire_when_enabled, no_implicit_conditions *)
   rule manage_reset;
      if (reset_engine)
	 in_reset <= True;
      else if (in_reset)
         in_reset <= False;
   endrule

   // Buffers of DMA commands for read and write requests

   FIFO#(DMAListEntry) rd_buffer_queue     <- mkSizedBRAMFIFO(16);
   FIFO#(DMAListEntry) wr_buffer_queue     <- mkSizedBRAMFIFO(16);
   Reg#(UInt#(5))      read_buffers_level  <- mkReg(0);
   Reg#(UInt#(5))      write_buffers_level <- mkReg(0);
   Wire#(DMAListEntry) new_rd_command      <- mkWire();
   Wire#(DMAListEntry) new_wr_command      <- mkWire();
   PulseWire           rd_command_incr     <- mkPulseWire();
   PulseWire           rd_command_decr     <- mkPulseWire();
   PulseWire           wr_command_incr     <- mkPulseWire();
   PulseWire           wr_command_decr     <- mkPulseWire();
   RWire#(UInt#(5))    byte_sent_count     <- mkRWire();
   RWire#(UInt#(5))    byte_recv_count     <- mkRWire();

   // Scatter-gather list entries (DMA commands) are added to their
   // queues using these rules. The purpose of the wires is to stop
   // propagation of the implicit conditions. The method that receives
   // these commands also processes read completion data and we do not
   // want processing of read completions to stop if one of the
   // command queues is full. The driver is responsible for ensuring
   // that it doesn't attempt to add a command to a queue that is
   // already full, and the buffer level values are provided to the
   // driver for that purpose.

   (* fire_when_enabled *)
   rule add_rd_command if (!in_reset);
      rd_buffer_queue.enq(new_rd_command);
      rd_command_incr.send();
   endrule

   (* fire_when_enabled *)
   rule add_wr_command if (!in_reset);
      wr_buffer_queue.enq(new_wr_command);
      wr_command_incr.send();
   endrule

   // As scatter-gather list entries are added and removed, we track
   // the number of entries in each queue.

   (* fire_when_enabled, no_implicit_conditions *)
   rule track_rd_buffer_level if ((rd_command_incr || rd_command_decr) && !in_reset);
      if (rd_command_incr && !rd_command_decr)
         read_buffers_level <= read_buffers_level + 1;
      else if (!rd_command_incr && rd_command_decr)
         read_buffers_level <= read_buffers_level - 1;
   endrule

   (* fire_when_enabled, no_implicit_conditions *)
   rule track_wr_buffer_level if ((wr_command_incr || wr_command_decr) && !in_reset);
      if (wr_command_incr && !wr_command_decr)
         write_buffers_level <= write_buffers_level + 1;
      else if (!wr_command_incr && wr_command_decr)
         write_buffers_level <= write_buffers_level - 1;
   endrule

   (* fire_when_enabled, no_implicit_conditions *)
   rule reset_buffer_queues if (in_reset);
      wr_buffer_queue.clear();
      rd_buffer_queue.clear();
      write_buffers_level <= 0;
      read_buffers_level  <= 0;
   endrule

   // Process incoming commands and completions (see the put method)

   Reg#(Bit#(32))  lo_command_data      <- mkRegU();
   Reg#(Bool)      do_rd_command        <- mkReg(False);
   Reg#(Bool)      do_wr_command        <- mkReg(False);
   Reg#(Bool)      pass_completion_data <- mkReg(False);
   Reg#(TLPTag)    saved_tag            <- mkRegU();
   Reg#(UInt#(10)) saved_length         <- mkRegU();
   Reg#(Bit#(4))   saved_lastbe         <- mkRegU();

   ByteCompactor#(16,bpb,TAdd#(bpb,20)) wr_data <- mkByteCompactor();

   function Maybe#(t) mkMaybe(Bool valid, t x);
      return valid ? tagged Valid x : tagged Invalid;
   endfunction

   function Action wr_dma(Vector#(4,Tuple2#(Bit#(4),Bit#(32))) dwords);
      action
         Vector#(16,Bool)    mask  = unpack(pack(map(tpl_1,dwords)));
         Vector#(16,Bit#(8)) bytes = unpack(pack(map(tpl_2,dwords)));
         Vector#(16,Maybe#(Bit#(8))) vec = zipWith(mkMaybe,mask,bytes);
         wr_data.enq(vec);
      endaction
   endfunction

   (* fire_when_enabled, no_implicit_conditions *)
   rule reset_incoming_tlp_status if (in_reset);
      do_rd_command        <= False;
      do_wr_command        <= False;
      pass_completion_data <= False;
      wr_data.clear();
   endrule

   // When there is a DMA request in the write queue, we need to
   // initiate a sequence of one or more read request TLPs to transfer
   // the full memory range requested.

   Reg#(Bool)      dma_to_device_in_progress      <- mkReg(False);
   Reg#(UInt#(52)) dma_td_block_page              <- mkRegU();
   Reg#(UInt#(12)) dma_td_block_offset            <- mkRegU();
   Reg#(UInt#(32)) dma_td_block_bytes_remaining   <- mkReg(0);
   Reg#(Bool)      dma_td_block_is_last           <- mkRegU();
   Reg#(Bool)      dma_td_intr_req                <- mkRegU();
   PulseWire       intr_req_during_xfer_to_device <- mkPulseWire();
   PulseWire       finished_xfer_to_device        <- mkPulseWire();

   Reg#(Bool)      end_of_completion              <- mkDReg(False);
   Reg#(Bool)      is_last_completion_for_req     <- mkReg(False);
   FIFO#(UInt#(5)) last_tag_queue                 <- mkSizedFIFO(32);
   Reg#(UInt#(5))  next_read_req_tag              <- mkReg(0);
   Reg#(UInt#(5))  last_completion_tag            <- mkReg(unpack('1));
   // For now, only allow one outstanding request at a time
   // Bool ok_to_send_read_req = (next_read_req_tag != last_completion_tag);
   Bool ok_to_send_read_req = (next_read_req_tag == (last_completion_tag + 1));

   ByteBuffer#(16) dma_read_req_tlp <- mkByteBuffer();

   // These values are redundant with dma_td_block_offset, but keeping
   // them in registers allows for shorter circuit paths.
   Reg#(UInt#(13)) dma_td_bytes_to_end_of_page <- mkRegU();
   Reg#(UInt#(13)) dma_td_bytes_to_size_limit  <- mkRegU();
   UInt#(13) dma_td_req_size_limit = min(dma_td_bytes_to_end_of_page,dma_td_bytes_to_size_limit);

   (* fire_when_enabled *)
   rule initiate_dma_buffer_read if (!dma_to_device_in_progress && ok_to_send_read_req && !in_reset);
      DMAListEntry entry = wr_buffer_queue.first();
      dma_to_device_in_progress    <= True;
      dma_td_block_page            <= truncate(entry.addr / 4096);
      UInt#(12) _offset = truncate(entry.addr % 4096);
      dma_td_block_offset          <= _offset;
      dma_td_block_bytes_remaining <= entry.len;
      dma_td_block_is_last         <= entry.last;
      dma_td_intr_req              <= entry.intr_req;
      UInt#(2) addr_idx_in_dw = truncate(_offset);
      dma_td_bytes_to_size_limit   <= max_read_req_bytes - zeroExtend(addr_idx_in_dw);
      dma_td_bytes_to_end_of_page  <= 4096 - zeroExtend(_offset);
   endrule

   (* fire_when_enabled *)
   rule make_dma_block_read_request if (  dma_to_device_in_progress
                                       && (dma_td_block_bytes_remaining != 0)
                                       && (dma_read_req_tlp.valid_mask() == replicate(False))
                                       && ok_to_send_read_req
                                       && !in_reset
                                       );
      TLPData#(16) tlp;
      tlp.sof = True;
      tlp.eof = True;
      tlp.be  = '1;
      tlp.hit = 7'h01;
      TLPMemory4DWHeader hdr_4dw = defaultValue();
      hdr_4dw.format = MEM_READ_4DW_NO_DATA;
      hdr_4dw.tag = unpack(zeroExtend(pack(next_read_req_tag)));
      next_read_req_tag <= next_read_req_tag + 1;
      hdr_4dw.reqid = my_id;
      hdr_4dw.nosnoop = SNOOPING_REQD;
      hdr_4dw.addr = ({pack(dma_td_block_page),pack(dma_td_block_offset)})[63:2];
      UInt#(2) addr_idx_in_dw  = truncate(dma_td_block_offset);
      if (dma_td_block_bytes_remaining <= (4 - zeroExtend(addr_idx_in_dw))) begin
         // entire transfer fits in one DW
         hdr_4dw.length  = 1;
         hdr_4dw.firstbe = (~('1 << dma_td_block_bytes_remaining)) << addr_idx_in_dw;
         hdr_4dw.lastbe  = '0;
         dma_td_block_bytes_remaining <= 0;
         dma_to_device_in_progress <= False;
             wr_buffer_queue.deq();
         wr_command_decr.send();
         if (dma_td_intr_req) intr_req_during_xfer_to_device.send();
         if (dma_td_block_is_last) last_tag_queue.enq(next_read_req_tag);
      end
      else if (dma_td_block_bytes_remaining > zeroExtend(dma_td_req_size_limit)) begin
         // transfer crosses a 4K boundary or exceedss maximum request size
         hdr_4dw.length  = pack(truncate((dma_td_req_size_limit + 3)/4));
         hdr_4dw.firstbe = '1 << addr_idx_in_dw;
         hdr_4dw.lastbe  = '1;
         dma_td_block_bytes_remaining <= dma_td_block_bytes_remaining - zeroExtend(dma_td_req_size_limit);
         if (dma_td_req_size_limit == dma_td_bytes_to_end_of_page) begin
            dma_td_block_offset         <= 0;
            dma_td_block_page           <= dma_td_block_page + 1;
            dma_td_bytes_to_size_limit  <= max_read_req_bytes;
            dma_td_bytes_to_end_of_page <= 4096;
         end
         else begin
            dma_td_block_offset         <= dma_td_block_offset + truncate(dma_td_bytes_to_size_limit);
            dma_td_bytes_to_size_limit  <= max_read_req_bytes;
            dma_td_bytes_to_end_of_page <= dma_td_bytes_to_end_of_page - dma_td_bytes_to_size_limit;
         end
      end
      else begin
         // transfer can be done with one request of more than 1 DW
         UInt#(2) end_idx_in_dw       = addr_idx_in_dw + truncate(dma_td_block_bytes_remaining);
         UInt#(2) space_in_last_dw    = truncate(3'd4 - zeroExtend(end_idx_in_dw));
         UInt#(32) bytes_plus_padding = dma_td_block_bytes_remaining + zeroExtend(addr_idx_in_dw) + zeroExtend(space_in_last_dw);
         hdr_4dw.length  = pack(truncate(bytes_plus_padding/4));
         hdr_4dw.firstbe = '1 << addr_idx_in_dw;
         hdr_4dw.lastbe  = '1 >> space_in_last_dw;
         dma_td_block_bytes_remaining <= 0;
         dma_to_device_in_progress <= False;
         wr_buffer_queue.deq();
         wr_command_decr.send();
         if (dma_td_intr_req) intr_req_during_xfer_to_device.send();
         if (dma_td_block_is_last) last_tag_queue.enq(next_read_req_tag);
      end
      for (Integer i = 0; i < 16; i = i + 1)
         dma_read_req_tlp.bytes[i] <= pack(hdr_4dw)[8*i+7:8*i];
   endrule

   (* fire_when_enabled, no_implicit_conditions *)
   rule move_to_next_request if (end_of_completion && is_last_completion_for_req && !in_reset);
      last_completion_tag        <= unpack(truncate(pack(saved_tag)));
      is_last_completion_for_req <= False;
   endrule

   (* fire_when_enabled *)
   rule request_completed if (  end_of_completion
                             && is_last_completion_for_req
                             && (saved_tag == unpack(zeroExtend(pack(last_tag_queue.first()))))
                             && !in_reset
                             );
      last_tag_queue.deq();
      finished_xfer_to_device.send();
   endrule

   (* fire_when_enabled, no_implicit_conditions *)
   rule reset_dma_to_device if (in_reset);
      dma_to_device_in_progress    <= False;
      dma_td_block_bytes_remaining <= 0;
      is_last_completion_for_req   <= False;
      last_tag_queue.clear();
      next_read_req_tag            <= 0;
      last_completion_tag          <= unpack('1);
      dma_read_req_tlp.clear();
   endrule

   // convert incoming NoC messages to DMA transfers from the device

   PulseWire                            incoming_beat <- mkUnsafePulseWire();
   MsgRoute#(bpb)                       msg_parse     <- mkMsgRoute();
   ByteCompactor#(bpb,16,TAdd#(bpb,20)) rd_data       <- mkByteCompactor();
   Wire#(MsgBeat#(bpb))                 current_beat  <- mkWire();
   PulseWire                            beat_moving   <- mkPulseWire();
   FIFOF#(Bool)                         dont_wait_out <- mkFIFOF();
   FIFOF#(UInt#(9))                     msg_len_out   <- mkFIFOF();

   // parse the incoming beats
   rule advance_to_next_beat if (incoming_beat && !in_reset);
      Vector#(bpb,Maybe#(Bit#(8))) vec = zipWith(mkMaybe,replicate(True),unpack(current_beat));
      rd_data.enq(vec);
      msg_parse.advance();
      beat_moving.send();
   endrule

   // extract the sequence of message lengths from the incoming beat stream
   (* fire_when_enabled *)
   rule capture_msg_len if (beat_moving && !in_reset);
      UInt#(8) len = msg_parse.length();
      msg_len_out.enq(zeroExtend(len) + 4);
   endrule

   // extract the sequence of "don't wait" flags from the incoming beat stream
   (* fire_when_enabled *)
   rule capture_dont_wait if (beat_moving && !in_reset);
      Bool dw = msg_parse.dont_wait();
      dont_wait_out.enq(dw);
   endrule

   (* fire_when_enabled, no_implicit_conditions *)
   rule reset_incoming_noc_ifc if (in_reset);
      msg_parse.clear();
      rd_data.clear();
      dont_wait_out.clear();
      msg_len_out.clear();
   endrule

   // generate the DMA write requests to transfer the messages

   ByteBuffer#(16) dma_write_req_tlp <- mkByteBuffer();
   Reg#(Bool)      header_sent_out   <- mkReg(False);
   Reg#(UInt#(9))  bytes_left_in_tlp <- mkReg(0);

   Reg#(Bool)      dma_from_device_in_progress  <- mkReg(False);
   Reg#(UInt#(52)) dma_fd_block_page            <- mkRegU();
   Reg#(UInt#(12)) dma_fd_block_offset          <- mkRegU();
   Reg#(UInt#(32)) dma_fd_block_bytes_remaining <- mkReg(0);
   Reg#(Bool)      dma_fd_block_is_last         <- mkRegU();
   Reg#(Bool)      dma_fd_intr_req              <- mkRegU();
   PulseWire       intr_from_xfer_from_device   <- mkPulseWire();
   PulseWire       finished_xfer_from_device    <- mkPulseWire();
   PulseWire       flushed_xfer_from_device     <- mkPulseWire();
   Reg#(UInt#(9))  bytes_left_in_msg            <- mkReg(0);
   Reg#(Bool)      flush_after_msg              <- mkReg(False);
   Reg#(Bool)      flush_unused_dma_blocks      <- mkReg(False);
   PulseWire       flush_dma_from_device        <- mkPulseWire();

   // These values are redundant with dma_fd_block_offset, but keeping
   // them in registers allows for shorter circuit paths.
   Reg#(UInt#(13)) dma_fd_bytes_to_end_of_page <- mkRegU();
   Reg#(UInt#(13)) dma_fd_bytes_to_size_limit  <- mkRegU();
   UInt#(13) dma_fd_req_size_limit = min(dma_fd_bytes_to_end_of_page,dma_fd_bytes_to_size_limit);

   (* fire_when_enabled *)
   rule prepare_for_dma_buffer_write if (!dma_from_device_in_progress && !flush_unused_dma_blocks && !in_reset);
      DMAListEntry entry = rd_buffer_queue.first();
      dma_from_device_in_progress  <= True;
      dma_fd_block_page            <= truncate(entry.addr / 4096);
      UInt#(12) _offset = truncate(entry.addr % 4096);
      dma_fd_block_offset          <= _offset;
      dma_fd_block_bytes_remaining <= entry.len;
      dma_fd_block_is_last         <= entry.last;
      dma_fd_intr_req              <= entry.intr_req;
      UInt#(2) addr_idx_in_dw  = truncate(_offset);
      dma_fd_bytes_to_size_limit   <= max_payload_bytes - zeroExtend(addr_idx_in_dw);
      dma_fd_bytes_to_end_of_page  <= 4096 - zeroExtend(_offset);
   endrule

   (* fire_when_enabled *)
   rule setup_next_msg_dma if ((bytes_left_in_msg == 0) && !in_reset);
      UInt#(9) msg_bytes = msg_len_out.first();
      Bool needs_padding = (msg_bytes % fromInteger(bytes_per_beat)) != 0;
      UInt#(9) msg_beats = (msg_bytes / fromInteger(bytes_per_beat)) + (needs_padding ? 1 : 0);
      bytes_left_in_msg <= fromInteger(bytes_per_beat) * msg_beats;
      msg_len_out.deq();
      flush_after_msg <= dont_wait_out.first();
      dont_wait_out.deq();
   endrule

   (* fire_when_enabled, no_implicit_conditions *)
   rule send_dma_write_request_header if (  !header_sent_out
                                         && (dma_write_req_tlp.valid_mask == replicate(False))
                                         && dma_from_device_in_progress
                                         && (dma_fd_block_bytes_remaining != 0)
                                         && (bytes_left_in_msg != 0)
                                         && !in_reset
                                         );
      TLPMemory4DWHeader hdr_4dw = defaultValue();
      hdr_4dw.format  = MEM_WRITE_4DW_DATA;
      hdr_4dw.tag     = 0;
      hdr_4dw.reqid   = my_id;
      hdr_4dw.nosnoop = SNOOPING_REQD;
      hdr_4dw.addr    = ({pack(dma_fd_block_page),pack(dma_fd_block_offset)})[63:2];
      UInt#(9) bytes_to_xfer = 0;
      if (zeroExtend(bytes_left_in_msg) <= dma_fd_block_bytes_remaining) begin
         // the entire message fits within the current DMA block
         bytes_to_xfer = bytes_left_in_msg;
      end
      else begin
         // we can only fit a portion of the message in the current DMA block
         bytes_to_xfer = truncate(dma_fd_block_bytes_remaining);
      end
      UInt#(2) addr_idx_in_dw  = truncate(dma_fd_block_offset);
      if (bytes_to_xfer <= (4 - zeroExtend(addr_idx_in_dw))) begin
         // entire transfer fits in one DW
         hdr_4dw.length  = 1;
         hdr_4dw.firstbe = (~('1 << bytes_to_xfer)) << addr_idx_in_dw;
         hdr_4dw.lastbe  = '0;
         bytes_left_in_tlp <= bytes_to_xfer;
      end
      else if (zeroExtend(bytes_to_xfer) > dma_fd_req_size_limit) begin
         // transfer crosses a 4K boundary or exceeds maximum payload size
         hdr_4dw.length  = pack(truncate((dma_fd_req_size_limit + 3)/4));
         hdr_4dw.firstbe = '1 << addr_idx_in_dw;
         hdr_4dw.lastbe  = '1;
         bytes_left_in_tlp <= truncate(dma_fd_req_size_limit);
      end
      else begin
         // transfer can be done with one request of more than 1 DW
         UInt#(2) end_idx_in_dw  = addr_idx_in_dw + truncate(bytes_to_xfer);
         UInt#(2) space_in_last_dw = truncate(3'd4 - zeroExtend(end_idx_in_dw));
         UInt#(9) bytes_plus_padding = bytes_to_xfer + zeroExtend(addr_idx_in_dw) + zeroExtend(space_in_last_dw);
         hdr_4dw.length  = pack(zeroExtend(bytes_plus_padding/4));
         hdr_4dw.firstbe = '1 << addr_idx_in_dw;
         hdr_4dw.lastbe  = '1 >> space_in_last_dw;
         bytes_left_in_tlp <= bytes_to_xfer;
      end
      for (Integer i = 0; i < 16; i = i + 1)
         dma_write_req_tlp.bytes[i] <= pack(hdr_4dw)[8*i+7:8*i];
      header_sent_out <= True;
   endrule

   (* fire_when_enabled *)
   rule send_dma_write_data if (  header_sent_out
                               && (dma_write_req_tlp.valid_mask() == replicate(False))
                               && dma_from_device_in_progress
                               && (bytes_left_in_msg != 0)
                               && !flush_unused_dma_blocks
                               && !in_reset
                               );
      // we need to supply up to 4DWs of data, but possibly less
      Bit#(16) mask = pack(map(isValid,rd_data.first()));
      UInt#(9) bytes_to_take = min(bytes_left_in_tlp,16);
      Bit#(16) required_mask = ~('1 << bytes_to_take);
      if ((mask & required_mask) == required_mask) begin
         for (Integer i = 0; i < 16; i = i + 1) begin
            Integer dw  = 3 - (i / 4);
            Integer idx = 3 - (i % 4);
            if (required_mask[i] != 0)
               dma_write_req_tlp.bytes[4*dw+idx] <= validValue(rd_data.first()[i]);
            else
               dma_write_req_tlp.bytes[4*dw+idx] <= '0; // padding
         end
         rd_data.deq(truncate(bytes_to_take));
         bytes_left_in_tlp <= bytes_left_in_tlp - bytes_to_take;
         if (bytes_left_in_tlp == bytes_to_take)
            header_sent_out <= False;
         if ((bytes_left_in_msg == bytes_to_take) && flush_after_msg) begin
            flush_dma_from_device.send();
            if (dma_fd_block_bytes_remaining != zeroExtend(bytes_to_take) || !dma_fd_block_is_last) begin
               flush_unused_dma_blocks <= True;
               flushed_xfer_from_device.send();
            end
         end
         bytes_left_in_msg <= bytes_left_in_msg - bytes_to_take;
         if (dma_fd_block_bytes_remaining == zeroExtend(bytes_to_take)) begin
            rd_buffer_queue.deq();
            rd_command_decr.send();
            if (dma_fd_block_is_last || dma_fd_intr_req)
               intr_from_xfer_from_device.send();
            if (dma_fd_block_is_last)
               finished_xfer_from_device.send();
         end
         if (  (dma_fd_block_bytes_remaining == zeroExtend(bytes_to_take))
            || ((bytes_left_in_msg == bytes_to_take) && flush_after_msg)
            )
            dma_from_device_in_progress <= False;
         dma_fd_block_bytes_remaining <= dma_fd_block_bytes_remaining - zeroExtend(bytes_to_take);
         if ((dma_fd_block_offset + zeroExtend(bytes_to_take)) == 0) begin
            dma_fd_block_offset         <= 0;
            dma_fd_block_page           <= dma_fd_block_page + 1;
            dma_fd_bytes_to_size_limit  <= max_payload_bytes;
            dma_fd_bytes_to_end_of_page <= 4096;
         end
         else begin
            UInt#(12) _new_offset = dma_fd_block_offset + zeroExtend(bytes_to_take);
            UInt#(2) _new_addr_idx_in_dw  = truncate(_new_offset);
            dma_fd_block_offset         <= _new_offset;
            dma_fd_bytes_to_size_limit  <= max_payload_bytes - zeroExtend(_new_addr_idx_in_dw);
            dma_fd_bytes_to_end_of_page <= 4096 - zeroExtend(_new_offset);
         end
         byte_sent_count.wset(truncate(bytes_to_take));
      end
   endrule

   (* fire_when_enabled *)
   rule discard_unused_blocks if (flush_unused_dma_blocks);
      DMAListEntry entry = rd_buffer_queue.first();
      rd_buffer_queue.deq();
      rd_command_decr.send();
      if (entry.last)
         flush_unused_dma_blocks <= False;
   endrule

   (* fire_when_enabled *)
   rule reset_dma_from_device if (in_reset);
      dma_write_req_tlp.clear();
      header_sent_out              <= False;
      bytes_left_in_tlp            <= 0;
      dma_from_device_in_progress  <= False;
      dma_fd_block_bytes_remaining <= 0;
      bytes_left_in_msg            <= 0;
      flush_after_msg              <= False;
      flush_unused_dma_blocks      <= False;
   endrule

   // generate MSIx interrupts

   // There are five reasons we will send an interrupt:
   //
   //   1. When DMA to the device completes
   //
   //      An interrupt is sent when the final completion
   //      associated with the last DMA block in the write
   //      buffer list is handled. It allows the host to
   //      know that the transfer is complete.
   //
   //   2. When the write buffer queue needs to be refilled
   //
   //      An interrupt is sent when an entry with the intr_req
   //      field set is removed from the write buffer queue.
   //      It allows the host to supply additional DMA blocks.
   //
   //   3. When DMA from the device completes
   //
   //      An interrupt is sent after the final write request
   //      associated with the last DMA block in the read
   //      buffer list is generated. It allows the host to
   //      know that the transfer is complete.
   //
   //   4. When the read buffer queue needs to be refilled
   //
   //      An interrupt is sent when an entry with the intr_req
   //      field set is removed from the read buffer queue.
   //      It allows the host to supply additional DMA blocks.
   //
   //   5. When a read flush is encountered
   //
   //      An interrupt is generated after transferring
   //      a message that is marked as "don't wait" from the
   //      device to the host. It allows the host to know
   //      that the transfer finished early.

   Wire#(Tuple2#(Bit#(64),Bit#(32)))  add_intr  <- mkWire();
   FIFOF#(Tuple2#(Bit#(64),Bit#(32))) intr_info <- mkFIFOF();

   ByteBuffer#(16) intr_tlp            <- mkByteBuffer();
   Reg#(Bool)      intr_header_done    <- mkReg(False);
   Reg#(Bool)      intr_in_one_tlp     <- mkRegU();
   Reg#(Bool)      second_tlp          <- mkRegU();
   PulseWire       need_intr           <- mkPulseWireOR();

   // case 1
   (* fire_when_enabled, no_implicit_conditions *)
   rule trigger_intr_after_dma_to_device if (finished_xfer_to_device);
      need_intr.send();
   endrule

   // case 2
   (* fire_when_enabled, no_implicit_conditions *)
   rule trigger_intr_during_dma_to_device if (intr_req_during_xfer_to_device);
      need_intr.send();
   endrule

   // cases 3 & 4
   (* fire_when_enabled, no_implicit_conditions *)
   rule trigger_intr_during_dma_from_device if (intr_from_xfer_from_device);
      need_intr.send();
   endrule

   // case 5
   (* fire_when_enabled, no_implicit_conditions *)
   rule trigger_intr_on_flush_dma_from_device if (flush_dma_from_device);
      need_intr.send();
   endrule

   (* fire_when_enabled *)
   rule initiate_intr if (!intr_info.notEmpty());
      intr_info.enq(add_intr);
   endrule

   (* fire_when_enabled *)
   rule write_intr_tlp_header if (!intr_header_done && !in_reset);
      let {addr,data} = intr_info.first();
      if (addr[63:32] == '0) begin
         TLPMemoryIO3DWHeader hdr_3dw = defaultValue();
         hdr_3dw.format = MEM_WRITE_3DW_DATA;
         hdr_3dw.tag = 0;
         hdr_3dw.reqid = my_id;
         hdr_3dw.length = 1;
         hdr_3dw.firstbe = '1;
         hdr_3dw.lastbe = '0;
         hdr_3dw.addr = addr[31:2];
         for (Integer i = 4; i < 16; i = i + 1)
            intr_tlp.bytes[i] <= pack(hdr_3dw)[8*i+7:8*i];
         intr_in_one_tlp <= True;
      end
      else begin
         TLPMemory4DWHeader hdr_4dw = defaultValue();
         hdr_4dw.format = MEM_WRITE_4DW_DATA;
         hdr_4dw.tag = 0;
         hdr_4dw.reqid = my_id;
         hdr_4dw.length = 1;
         hdr_4dw.firstbe = '1;
         hdr_4dw.lastbe = '0;
         hdr_4dw.addr = addr[63:2];
         for (Integer i = 0; i < 16; i = i + 1)
            intr_tlp.bytes[i] <= pack(hdr_4dw)[8*i+7:8*i];
         intr_in_one_tlp <= False;
      end
      intr_header_done <= True;
   endrule

   (* fire_when_enabled *)
   rule write_intr_tlp_data if (intr_header_done && (intr_tlp.valid_mask() != replicate(True)));
      let {addr,data} = intr_info.first();
      intr_info.deq();
      Bit#(32) value = byteSwap(data);
      if (intr_in_one_tlp) begin
         for (Integer i = 0; i < 4; i = i + 1)
            intr_tlp.bytes[i] <= value[8*i+7:8*i];
      end
      else begin
         for (Integer i = 0; i < 4; i = i + 1)
            intr_tlp.bytes[12+i] <= value[8*i+7:8*i];
         for (Integer i = 0; i < 12; i = i + 1)
            intr_tlp.bytes[i] <= ?;
      end
      intr_header_done <= False;
      second_tlp       <= False;
   endrule

   (* fire_when_enabled *)
   rule reset_intr_generation if (in_reset);
      intr_info.clear();
      intr_tlp.clear();
      intr_header_done <= False;
   endrule

   // auto flush

   Reg#(Bit#(7)) rIdleCount <- mkReg(0);

   Bool read_in_progress = ((read_buffers_level != 0) &&
			    (dma_from_device_in_progress) &&
			    (!in_reset));

   Bool read_idle = ((dma_write_req_tlp.valid_mask() == replicate(False)) &&
		     (!flush_unused_dma_blocks) &&
		     (rd_data.bytes_available() == 0) &&
		     (!header_sent_out) &&
		     (bytes_left_in_tlp == 0) &&
		     (bytes_left_in_msg == 0));

   rule auto_flush;

      rule reset(!read_in_progress || !read_idle);
	 rIdleCount <= 0;
      endrule

      rule count(read_in_progress && read_idle && (rIdleCount < maxBound));
	 rIdleCount <= rIdleCount + 1;
      endrule

      rule flush(read_in_progress && read_idle && (rIdleCount == maxBound));
	 rIdleCount <= 0;
	 flush_dma_from_device.send();
	 flush_unused_dma_blocks <= True;
	 flushed_xfer_from_device.send();
         dma_from_device_in_progress <= False;
      endrule

   endrule

   //
   // Interfaces
   //

   Reg#(UInt#(11)) dma_write_req_reserved <- mkReg(0);
   Reg#(Bool)      dma_intr_reserved      <- mkReg(False);

   Bool read_req_ready   = dma_read_req_tlp.valid_mask() == replicate(True);
   Bool write_data_ready = dma_write_req_tlp.valid_mask() == replicate(True);
   Bool intr_ready       = intr_tlp.valid_mask() == replicate(True);
   Bool tlp_ready =  ((dma_write_req_reserved != 0) && write_data_ready)
                  || (dma_intr_reserved && intr_ready)
                  || ((dma_write_req_reserved == 0) && !dma_intr_reserved && (read_req_ready || write_data_ready || intr_ready))
                  ;

   (* fire_when_enabled, no_implicit_conditions *)
   rule reset_tlp_reservation if (in_reset);
      dma_write_req_reserved <= 0;
      dma_intr_reserved      <= False;
   endrule

   // This is the interface which processes incoming DMA commands and
   // completion data from the PCIe bus.

   interface Put dma_commands_and_completions;
      method Action put(TLPData#(16) tlp) if (!in_reset);
         // We expect only writes of 8 bytes to the DMA command addresses,
         // using 32-bit addresses, or else read completion traffic
         if (tlp.sof) begin
            TLPMemoryIO3DWHeader hdr_3dw = unpack(tlp.data);
            if (hdr_3dw.pkttype != COMPLETION) begin
               // This is a write to the command area
               if ((hdr_3dw.addr % 8192) == 1024) begin
                  if (!tlp.eof)
                     do_rd_command <= True;
                  lo_command_data <= byteSwap(tlp.data[31:0]);
               end
               else if ((hdr_3dw.addr % 8192) == 1025) begin
                  Bit#(32) hi_command_data = byteSwap(tlp.data[31:0]);
                  DMAListEntry entry = ?;
                  entry.last     = unpack(hi_command_data[31]);
                  entry.intr_req = unpack(hi_command_data[30]);
                  entry.len      = (hi_command_data[29:16] == '0) ? 16384 : zeroExtend(unpack(hi_command_data[29:16]));
                  entry.addr     = zeroExtend(unpack({hi_command_data[15:0],lo_command_data}));
                  new_rd_command <= entry;
                  do_rd_command  <= False;
               end
               else if ((hdr_3dw.addr % 8192) == 1026) begin
                  if (!tlp.eof)
                     do_wr_command <= True;
                  lo_command_data <= byteSwap(tlp.data[31:0]);
               end
               else if ((hdr_3dw.addr % 8192) == 1027) begin
                  Bit#(32) hi_command_data = byteSwap(tlp.data[31:0]);
                  DMAListEntry entry = ?;
                  entry.last     = unpack(hi_command_data[31]);
                  entry.intr_req = unpack(hi_command_data[30]);
                  entry.len      = (hi_command_data[29:16] == '0) ? 16384 : zeroExtend(unpack(hi_command_data[29:16]));
                  entry.addr     = zeroExtend(unpack({hi_command_data[15:0],lo_command_data}));
                  new_wr_command <= entry;
                  do_wr_command  <= False;
               end
            end
            else begin
               // This is the start of completion data
               TLPCompletionHeader hdr_compl = unpack(tlp.data);
               if (hdr_compl.cstatus == SUCCESSFUL_COMPLETION) begin
                  UInt#(2) unused_in_first_dw = unpack(truncate(hdr_compl.loweraddr));
                  Bit#(4) firstbe = '1 << unused_in_first_dw;
                  UInt#(2) _tmp = truncate(unpack(hdr_compl.loweraddr)) + truncate(unpack(hdr_compl.bytecount));
                  UInt#(2) unused_in_last_dw = truncate(3'd4 - zeroExtend(_tmp));
                  Bit#(4) lastbe = (hdr_compl.length == 1) ? '0 : ('1 >> unused_in_last_dw);
                  Vector#(4,Tuple2#(Bit#(4),Bit#(32))) vec = replicate(tuple2(4'h0,?));
                  vec[0] = tuple2(firstbe, byteSwap(hdr_compl.data));
                  wr_dma(vec);
                  byte_recv_count.wset(countOnes({tpl_1(vec[0]),tpl_1(vec[1]),tpl_1(vec[2]),tpl_1(vec[3])}));
                  is_last_completion_for_req <= hdr_compl.bytecount == computeByteCount(hdr_compl.length,firstbe,lastbe);
                  saved_tag <= hdr_compl.tag;
                  if (tlp.eof)
                     end_of_completion <= True;
                  else begin
                     pass_completion_data <= True;
                     saved_lastbe <= lastbe;
                     saved_length <= unpack(hdr_compl.length) - 1;
                  end
               end
            end
         end
         else if (do_rd_command) begin
            // Second DW of a read command
            Bit#(32) hi_command_data = byteSwap(tlp.data[127:96]);
            DMAListEntry entry = ?;
            entry.last     = unpack(hi_command_data[31]);
            entry.intr_req = unpack(hi_command_data[30]);
            entry.len      = (hi_command_data[29:16] == '0) ? 16384 : zeroExtend(unpack(hi_command_data[29:16]));
            entry.addr     = zeroExtend(unpack({hi_command_data[15:0],lo_command_data}));
            new_rd_command <= entry;
            do_rd_command  <= False;
         end
         else if (do_wr_command) begin
            // Second DW of a write command
            Bit#(32) hi_command_data = byteSwap(tlp.data[127:96]);
            DMAListEntry entry = ?;
            entry.last     = unpack(hi_command_data[31]);
            entry.intr_req = unpack(hi_command_data[30]);
            entry.len      = (hi_command_data[29:16] == '0) ? 16384 : zeroExtend(unpack(hi_command_data[29:16]));
            entry.addr     = zeroExtend(unpack({hi_command_data[15:0],lo_command_data}));
            new_wr_command <= entry;
            do_wr_command  <= False;
         end
         else if (pass_completion_data) begin
            // Continuation of completion data
            Vector#(4,Tuple2#(Bit#(4),Bit#(32))) vec = replicate(tuple2(4'h0,?));
            vec[0] = tuple2((saved_length == 1) ? saved_lastbe : 4'hf, byteSwap(tlp.data[127:96]));
            vec[1] = tuple2((saved_length == 2) ? saved_lastbe : ((saved_length < 2) ? 4'h0 : 4'hf), byteSwap(tlp.data[95:64]));
            vec[2] = tuple2((saved_length == 3) ? saved_lastbe : ((saved_length < 3) ? 4'h0 : 4'hf), byteSwap(tlp.data[63:32]));
            vec[3] = tuple2((saved_length == 4) ? saved_lastbe : ((saved_length < 4) ? 4'h0 : 4'hf), byteSwap(tlp.data[31:0]));
            wr_dma(vec);
            byte_recv_count.wset(countOnes({tpl_1(vec[0]),tpl_1(vec[1]),tpl_1(vec[2]),tpl_1(vec[3])}));
            if (tlp.eof) begin
               end_of_completion <= True;
               pass_completion_data <= False;
            end
            else
               saved_length <= saved_length - 4;
         end
      endmethod
   endinterface

   // This is the interface which selects TLPs to go out to the PCIe
   // bus. It gives priority to read and write TLPs over interrupts,
   // to ensure that interrupts don't accidentally overtake requests.
   // It also must make sure that multi-TLP write and interrupt
   // requests are transmitted without interruption.

   interface Get dma_read_and_write_requests;
      method ActionValue#(TLPData#(16)) get() if (tlp_ready && !in_reset);
         TLPData#(16) tlp = ?;
         if (dma_write_req_reserved != 0) begin
            // we can send only the write data TLPs
            tlp.sof = False;
            tlp.eof = (dma_write_req_reserved <= 4);
            tlp.hit = 7'h00;
            case (dma_write_req_reserved)
               1:       tlp.be = 16'hf000;
               2:       tlp.be = 16'hff00;
               3:       tlp.be = 16'hfff0;
               default: tlp.be = 16'hffff;
            endcase
            tlp.data = pack(readVReg(dma_write_req_tlp.bytes));
            dma_write_req_tlp.clear();
            if (dma_write_req_reserved <= 4)
               dma_write_req_reserved <= 0;
            else
               dma_write_req_reserved <= dma_write_req_reserved - 4;
         end
         else if (dma_intr_reserved) begin
            // we can only send the interrupt data TLP
            tlp.sof  = False;
            tlp.eof  = True;
            tlp.hit  = 7'h00;
            tlp.be   = 16'hf000;
            tlp.data = pack(readVReg(intr_tlp.bytes));
            intr_tlp.clear();
            dma_intr_reserved <= False;
         end
         else if (read_req_ready) begin
            // entire read request
            tlp.sof  = True;
            tlp.eof  = True;
            tlp.hit  = 7'h00;
            tlp.be   = 16'hffff;
            tlp.data = pack(readVReg(dma_read_req_tlp.bytes));
            dma_read_req_tlp.clear();
         end
         else if (write_data_ready) begin
            // first part of write request
            TLPMemory4DWHeader hdr_4dw = unpack(pack(readVReg(dma_write_req_tlp.bytes)));
            tlp.sof  = True;
            tlp.eof  = False;
            tlp.hit  = 7'h00;
            tlp.be   = 16'hffff;
            tlp.data = pack(readVReg(dma_write_req_tlp.bytes));
            dma_write_req_tlp.clear();
            dma_write_req_reserved <= (hdr_4dw.length == '0) ? 11'd1024 : zeroExtend(unpack(hdr_4dw.length));
         end
         else if (intr_ready) begin
            // first part of interrupt
            TLPMemoryIO3DWHeader hdr_3dw = unpack(pack(readVReg(intr_tlp.bytes)));
            tlp.sof  = True;
            tlp.eof  = (hdr_3dw.format == MEM_WRITE_3DW_DATA);
            tlp.hit  = 7'h00;
            tlp.be   = 16'hffff;
            tlp.data = pack(readVReg(intr_tlp.bytes));
            intr_tlp.clear();
            if (hdr_3dw.format != MEM_WRITE_3DW_DATA)
               dma_intr_reserved <= True;
         end
         return tlp;
      endmethod
   endinterface

   // This is the interface which handles NoC traffic

   interface MsgPort noc;

      interface MsgSource out;
         method Action dst_rdy(Bool b);
            if (b && (wr_data.bytes_available() >= fromInteger(bytes_per_beat)))
               wr_data.deq(fromInteger(bytes_per_beat));
         endmethod
         method src_rdy = (wr_data.bytes_available() >= fromInteger(bytes_per_beat));
         method beat = pack(take(map(validValue,wr_data.first())));
      endinterface

      interface MsgSink in;
         method dst_rdy = rd_data.can_enq() && msg_len_out.notFull() && !in_reset;
         method Action src_rdy(Bool b);
            if (b && (rd_data.can_enq() && msg_len_out.notFull()) && !in_reset)
               incoming_beat.send();
         endmethod
         method Action beat(MsgBeat#(bpb) v);
            current_beat <= v;
            if (incoming_beat)
               msg_parse.beat(v);
         endmethod
      endinterface

   endinterface

   // Methods for coordination with control and status registers

   method Action clear();
      reset_engine.send();
   endmethod

   method UInt#(5) num_write_commands = write_buffers_level;
   method UInt#(5) num_read_commands  = read_buffers_level;

   method UInt#(5) bytes_received = fromMaybe(0,byte_recv_count.wget());
   method UInt#(5) bytes_sent     = fromMaybe(0,byte_sent_count.wget());

   method Bool write_operation_completed = finished_xfer_to_device;
   method Bool read_operation_completed  = finished_xfer_from_device || flushed_xfer_from_device;
   method Bool read_flushed              = flushed_xfer_from_device;

   method Bool has_space_to_receive_data = wr_data.can_enq();
   method Bool has_data_to_send          = (bytes_left_in_msg != 0);

   method Bool request_interrupt = need_intr;

   interface Put next_interrupt;
      method Action put(Tuple2#(Bit#(64),Bit#(32)) x);
         add_intr <= x;
      endmethod
   endinterface

endmodule: mkDMAEngine

// The PCIe-to-NoC bridge puts all of the elements together
(* synthesize *)
module mkPcieToAxiBridge_4#( Bit#(64)  board_content_id
			   , PciId     my_id
			   , UInt#(13) max_read_req_bytes
			   , UInt#(13) max_payload_bytes
			   , Bit#(7)   rcb_mask
			   , Bool      msix_enabled
			   , Bool      msix_mask_all_intr
			   , Bool      msi_enabled
			   )
			   (PcieToAxiBridge#(4));

   let pbb <- mkPcieToAxiBridge(board_content_id, my_id, max_read_req_bytes, 
					max_payload_bytes, rcb_mask, msix_enabled, 
					msix_mask_all_intr, msi_enabled);
   return pbb;
endmodule

//(* synthesize *)
module mkPcieToAxiBridge_8#( Bit#(64)  board_content_id
			   , PciId     my_id
			   , UInt#(13) max_read_req_bytes
			   , UInt#(13) max_payload_bytes
			   , Bit#(7)   rcb_mask
			   , Bool      msix_enabled
			   , Bool      msix_mask_all_intr
			   , Bool      msi_enabled
			   )
			   (PcieToAxiBridge#(8));

   let pbb <- mkPcieToAxiBridge(board_content_id, my_id, max_read_req_bytes, 
					max_payload_bytes, rcb_mask, msix_enabled, 
					msix_mask_all_intr, msi_enabled);
   return pbb;
endmodule

//(* synthesize *)
module mkPcieToAxiBridge_16#( Bit#(64)  board_content_id
			   , PciId     my_id
			   , UInt#(13) max_read_req_bytes
			   , UInt#(13) max_payload_bytes
			   , Bit#(7)   rcb_mask
			   , Bool      msix_enabled
			   , Bool      msix_mask_all_intr
			   , Bool      msi_enabled
			   )
			   (PcieToAxiBridge#(16));

   let pbb <- mkPcieToAxiBridge(board_content_id, my_id, max_read_req_bytes, 
					max_payload_bytes, rcb_mask, msix_enabled, 
					msix_mask_all_intr, msi_enabled);
   return pbb;
endmodule

module mkPcieToAxiBridge#( Bit#(64)  board_content_id
			 , PciId     my_id
			 , UInt#(13) max_read_req_bytes
			 , UInt#(13) max_payload_bytes
			 , Bit#(7)   rcb_mask
			 , Bool      msix_enabled
			 , Bool      msix_mask_all_intr
			 , Bool      msi_enabled
			 )
			 (PcieToAxiBridge#(bpb))
   provisos( Add#(1, __1, TDiv#(bpb,4))
           // the compiler should be able to figure these out ...
           , Log#(TAdd#(1,bpb), TLog#(TAdd#(bpb,1)))
           , Add#(TAdd#(bpb,20), __2, TMul#(TDiv#(TMul#(TAdd#(bpb,20),9),36),4))
           );

   Integer bytes_per_beat = valueOf(bpb);

   check_bytes_per_beat("mkPCIEtoBNoC", bytes_per_beat);

   // instantiate sub-components
   PortalEngine            portalEngine <- mkPortalEngine( my_id );
   AxiSlaveEngine          axiSlaveEngine <- mkAxiSlaveEngine( my_id );

   TLPDispatcher        dispatcher <- mkTLPDispatcher();
   TLPArbiter           arbiter    <- mkTLPArbiter();
   ControlAndStatusRegs csr        <- mkControlAndStatusRegs( board_content_id
                                                            , my_id
                                                            , bytes_per_beat
                                                            , rcb_mask
                                                            , msix_enabled
                                                            , msix_mask_all_intr
                                                            , msi_enabled
							    , portalEngine
                                                            );
   DMAEngine#(bpb)      dma        <- mkDMAEngine( my_id
                                                 , max_read_req_bytes
                                                 , max_payload_bytes
                                                 );

   Reg#(Bool) interruptRequested <- mkReg(False);

   rule endTrace if (csr.tlpTracing && csr.tlpDataBramWrAddr > 127);
       csr.tlpTracing <= False;
   endrule
   rule axiEnabledRule;
       dispatcher.axiEnabled <= csr.axiEnabled;
       portalEngine.pipeliningEnabled <= csr.pipeliningEnabled;
   endrule

   // connect the sub-components to each other

   mkConnection(dispatcher.tlp_out_to_config,    csr.csr_read_and_write_tlps);
   mkConnection(dispatcher.tlp_out_to_dma,       dma.dma_commands_and_completions);
   mkConnection(dispatcher.tlp_out_to_portal,    portalEngine.tlp_in);
   mkConnection(dispatcher.tlp_out_to_axi,       axiSlaveEngine.tlp_in);

   mkConnection(csr.csr_read_completion_tlps,    arbiter.tlp_in_from_config);
   mkConnection(dma.dma_read_and_write_requests, arbiter.tlp_in_from_dma);
   mkConnection(portalEngine.tlp_out,            arbiter.tlp_in_from_portal);
   mkConnection(axiSlaveEngine.tlp_out,          arbiter.tlp_in_from_axi);

   mkConnection(dma.bytes_received,              csr.incr_wr_xfer_count);
   mkConnection(dma.bytes_sent,                  csr.incr_rd_xfer_count);
   mkConnection(csr.intr_to_send,                dma.next_interrupt);
   mkConnection(dma.num_write_commands,          csr.set_write_buffers_level);
   mkConnection(dma.num_read_commands,           csr.set_read_buffers_level);

   (* fire_when_enabled, no_implicit_conditions *)
   rule clear_dma_when_inactive if (!csr.is_activated());
      dma.clear();
   endrule

   (* fire_when_enabled, no_implicit_conditions *)
   rule wr_xfer_done if (dma.write_operation_completed() && csr.is_activated());
      csr.finished_write();
   endrule

   (* fire_when_enabled, no_implicit_conditions *)
   rule rd_xfer_done if (dma.read_operation_completed() && csr.is_activated());
      csr.finished_read(dma.read_flushed());
   endrule

   (* fire_when_enabled, no_implicit_conditions *)
   rule pass_ready_indicators;
      csr.has_space_to_receive_data(dma.has_space_to_receive_data());
      csr.has_data_to_send(dma.has_data_to_send());
   endrule

   (* fire_when_enabled, no_implicit_conditions *)
   rule intr_req if (dma.request_interrupt || interruptRequested);
      csr.interrupt();
      if (interruptRequested)
         interruptRequested <= False;
   endrule

   FIFO#(TLPData#(16)) tlpFromBusFifo <- mkFIFO();
   rule traceTlpFromBus;
       let tlp = tlpFromBusFifo.first;
       tlpFromBusFifo.deq();
       dispatcher.tlp_in_from_bus.put(tlp);
       $display("tlp in: %h\n", tlp);
       if (csr.tlpTracing) begin
	   TimestampedTlpData ttd = TimestampedTlpData { seqno: csr.tlpSeqno, unused: 7'h04, tlp: tlp };
	   csr.tlpDataBram.request.put(BRAMRequest{ write: True, responseOnWrite: False, address: truncate(csr.tlpDataBramWrAddr), datain: ttd });
	   csr.tlpDataBramWrAddr <= csr.tlpDataBramWrAddr + 1;
	   csr.tlpSeqno <= csr.tlpSeqno + 1;
       end
   endrule: traceTlpFromBus

   FIFO#(TLPData#(16)) tlpToBusFifo <- mkFIFO();
   rule traceTlpToBus;
       let tlp <- arbiter.tlp_out_to_bus.get();
       tlpToBusFifo.enq(tlp);
       if (csr.tlpTracing) begin
	   TimestampedTlpData ttd = TimestampedTlpData { seqno: csr.tlpSeqno, unused: 7'h08, tlp: tlp };
	   csr.tlpDataBram.request.put(BRAMRequest{ write: True, responseOnWrite: False, address: truncate(csr.tlpDataBramWrAddr), datain: ttd });
	   csr.tlpDataBramWrAddr <= csr.tlpDataBramWrAddr + 1;
	   csr.tlpSeqno <= csr.tlpSeqno + 1;
       end
   endrule: traceTlpToBus

   AxiSlaveTest            axiSlaveTest <- mkAxiSlaveTest();
   mkConnection(axiSlaveTest.master, axiSlaveEngine.slave);
   rule axiSlaveAddrStart;
       Bit#(40) addr = 0;
       addr[31:0] = csr.addrLowerWord;
       addr[39:32] = truncate(csr.addrUpperWord);
       axiSlaveTest.addr <= addr;
       if (csr.axiTestEnabled)
           axiSlaveTest.start();
   endrule
   rule axiSlaveOutput;
       csr.testResult <= axiSlaveTest.result;
       csr.testState <= zeroExtend(pack(axiSlaveTest.state));
   endrule

   // route the interfaces to the sub-components

   //interface GetPut tlps = tuple2(arbiter.tlp_out_to_bus,dispatcher.tlp_in_from_bus);
   interface GetPut tlps = tuple2(toGet(tlpToBusFifo),toPut(tlpFromBusFifo));

   interface MsgPort noc = dma.noc;
   interface Axi3Master portal0 = portalEngine.portal;

   method Bool is_activated = csr.is_activated();
   method Bool rx_activity  = dispatcher.read_tlp() || dispatcher.write_tlp() || arbiter.completion_tlp();
   method Bool tx_activity  = arbiter.read_tlp()    || arbiter.write_tlp()    || dispatcher.completion_tlp();

   method Action interrupt();
       interruptRequested <= True;
   endmethod
   method Bool   msi_interrupt_req   = csr.msi_interrupt_req;
   method Action msi_interrupt_clear = csr.msi_interrupt_clear;

   interface Put trace;
       method Action put(TimestampedTlpData ttd);
	   if (csr.tlpTracing) begin
	       csr.tlpDataBram.request.put(BRAMRequest{ write: True, responseOnWrite: False, address: truncate(csr.tlpDataBramWrAddr), datain: ttd });
	       csr.tlpDataBramWrAddr <= csr.tlpDataBramWrAddr + 1;
	   end
       endmethod
   endinterface: trace

endmodule: mkPcieToAxiBridge

endpackage: PcieToAxiBridge

