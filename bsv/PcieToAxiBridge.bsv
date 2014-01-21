package PcieToAxiBridge;

// This is a package which acts as a bridge between a TLP-based PCIe
// interface on one side and an AXI slave (portal) and AXI Master on
// the other.

import GetPut       :: *;
import Connectable  :: *;
import Vector       :: *;
import FIFO         :: *;
import FIFOF        :: *;
import MIMO         :: *;
import Counter      :: *;
import DefaultValue :: *;
import XilinxPCIE   :: *;
import BRAM         :: *;
import BRAMFIFO     :: *;
import ConfigReg    :: *;
import DReg         :: *;

import ByteBuffer    :: *;
import ByteCompactor :: *;

import AxiClientServer:: *;

typedef struct {
    Bit#(32) timestamp;
    Bit#(7) unused;
    TLPData#(16) tlp;
} TimestampedTlpData deriving (Bits);
typedef SizeOf#(TimestampedTlpData) TimestampedTlpDataSize;
typedef SizeOf#(TLPData#(16)) TlpData16Size;
typedef SizeOf#(TLPCompletionHeader) TLPCompletionHeaderSize;
interface TlpTrace;
   interface Get#(TimestampedTlpData) tlp;
endinterface

// The top-level interface of the PCIe-to-AXI bridge
interface PcieToAxiBridge#(numeric type bpb);

   interface GetPut#(TLPData#(16)) tlps; // to the PCIe bus
   interface Axi3Client#(32,32,12) portal0; // to the portal control
   interface GetPut#(TLPData#(16)) slave;

   // status for FPGA LEDs
   (* always_ready *)
   method Bool rx_activity();
   (* always_ready *)
   method Bool tx_activity();

   method Action interrupt();

   interface Put#(TimestampedTlpData) trace;
   interface Reg#(Bit#(4)) numPortals;

endinterface: PcieToAxiBridge

// When TLP packets come in from the PCIe bus, they are dispatched to
// either the configuration register block, the portal (AXI slave) or
// the AXI master.
interface TLPDispatcher;

   // TLPs in from PCIe
   interface Put#(TLPData#(16)) tlp_in_from_bus;

   // TLPs out to the bridge implementation
   interface Get#(TLPData#(16)) tlp_out_to_config;
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
   FIFOF#(TLPData#(16)) tlp_in_portal_fifo <- mkGFIFOF(True,False); // unguarded enq
   FIFOF#(TLPData#(16)) tlp_in_axi_fifo <- mkGFIFOF(True,False); // unguarded enq

   Reg#(Bool) route_to_cfg <- mkReg(False);
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
      Bool is_config_read    =  tlp.sof
                             && (tlp.hit == 7'h01)
                             && (hdr_3dw.format == MEM_READ_3DW_NO_DATA)
                             ;
      Bool is_config_write   =  tlp.sof
                             && (tlp.hit == 7'h01)
                             && (hdr_3dw.format == MEM_WRITE_3DW_DATA)
                             && (hdr_3dw.pkttype != COMPLETION)
                             ;
      Bool is_axi_read       =  tlp.sof
                             && (tlp.hit == 7'h04)
                             && (hdr_3dw.format == MEM_READ_3DW_NO_DATA)
                             ;
      Bool is_axi_write      =  tlp.sof
                             && (tlp.hit == 7'h04)
                             && (hdr_3dw.format == MEM_WRITE_3DW_DATA)
                             && (hdr_3dw.pkttype != COMPLETION)
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
         else begin
            // unknown packet type -- just discard it
            tlp_in_fifo.deq();
         end
         // indicate activity type
         if (is_config_read)                     is_read.send();
         if (is_config_write)                    is_write.send();
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
         else begin
            // unknown packet type -- just discard it
            tlp_in_fifo.deq();
         end
      end
   endrule: dispatch_incoming_TLP

   interface Put tlp_in_from_bus    = toPut(tlp_in_fifo);
   interface Get tlp_out_to_config  = toGet(tlp_in_cfg_fifo);
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
   FIFOF#(TLPData#(16)) tlp_out_portal_fifo <- mkGFIFOF(False,True); // unguarded deq
   FIFOF#(TLPData#(16)) tlp_out_axi_fifo <- mkGFIFOF(False,True); // unguarded deq

   Reg#(Bool) route_from_cfg <- mkReg(False);
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
      else if (tlp_out_cfg_fifo.notEmpty()) begin
         // prioritize config read completions over portal traffic
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
         // prioritize portal read completions over AXI master traffic
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
         TLPData#(16) tlp = tlp_out_axi_fifo.first();
         tlp_out_axi_fifo.deq();
         if (tlp.sof) begin
            tlp_out_fifo.enq(tlp);
            if (!tlp.eof)
               route_from_axi <= True;
            is_completion.send();
         end
      end
   endrule: arbitrate_outgoing_TLP

   interface Get tlp_out_to_bus     = toGet(tlp_out_fifo);
   interface Put tlp_in_from_config = toPut(tlp_out_cfg_fifo);
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
    interface Axi3Client#(32,32,12) portal;
    interface Reg#(Bool)           byteSwap;
    interface Reg#(Bool)           interruptRequested;
    interface Reg#(Bit#(64))       interruptAddr;
    interface Reg#(Bit#(32))       interruptData;
endinterface

module mkPortalEngine#(PciId my_id)(PortalEngine);
    Reg#(Bool) byteSwapReg <- mkReg(True);
    Reg#(Bool) interruptRequestedReg <- mkReg(False);
    Reg#(Bool) interruptSecondHalf <- mkReg(False);
    Reg#(Bit#(7)) hitReg <- mkReg(0);
    Reg#(Bit#(4)) timerReg <- mkReg(0);
    Reg#(Bit#(64)) interruptAddrReg <- mkReg(0);
    Reg#(Bit#(32)) interruptDataReg <- mkReg(0);
    FIFOF#(TLPMemoryIO3DWHeader) readHeaderFifo <- mkFIFOF;
    FIFOF#(TLPMemoryIO3DWHeader) readDataFifo <- mkFIFOF;
    FIFOF#(TLPMemoryIO3DWHeader) writeHeaderFifo <- mkFIFOF;
    FIFOF#(TLPMemoryIO3DWHeader) writeDataFifo <- mkFIFOF;
    FIFOF#(TLPData#(16)) tlpOutFifo <- mkFIFOF;
    Reg#(TLPTag) tlpTag <- mkReg(0);

    rule txnTimer if (timerReg > 0);
        timerReg <= timerReg - 1;
    endrule

    rule interruptTlpOut if (interruptRequestedReg && !interruptSecondHalf);
       TLPData#(16) tlp = defaultValue;
       tlp.sof = True;
       tlp.eof = False;
       tlp.hit = 7'h00;
       tlp.be = 16'hffff;

       let sendInterrupt = False;
       let interruptRequested = interruptRequestedReg;

       if (interruptAddrReg == '0) begin
	  // do not write to 0 -- it wedges the host
	  interruptRequested = False;
       end
       else if (interruptAddrReg[63:32] == '0) begin
          TLPMemoryIO3DWHeader hdr_3dw = defaultValue();
          hdr_3dw.format = MEM_WRITE_3DW_DATA;
	  //hdr_3dw.pkttype = MEM_READ_WRITE;
          hdr_3dw.tag = tlpTag;
          hdr_3dw.reqid = my_id;
          hdr_3dw.length = 1;
          hdr_3dw.firstbe = '1;
          hdr_3dw.lastbe = '0;
          hdr_3dw.addr = interruptAddrReg[31:2];
	  hdr_3dw.data = byteSwap(interruptDataReg);
	  tlp.data = pack(hdr_3dw);
	  tlp.eof = True;
	  sendInterrupt = True;
	  interruptRequested = False;
       end
       else begin
	  TLPMemory4DWHeader hdr_4dw = defaultValue;
	  hdr_4dw.format = MEM_WRITE_4DW_DATA;
	  //hdr_4dw.pkttype = MEM_READ_WRITE;
	  hdr_4dw.tag = tlpTag;
	  hdr_4dw.reqid = my_id;
	  hdr_4dw.nosnoop = SNOOPING_REQD;
	  hdr_4dw.addr = interruptAddrReg[40-1:2];
	  hdr_4dw.length = 1;
	  hdr_4dw.firstbe = 4'hf;
	  hdr_4dw.lastbe = 0;
	  tlp.data = pack(hdr_4dw);

	  sendInterrupt = True;
	  interruptSecondHalf <= True;
       end

       if (!interruptRequested)
	  interruptRequestedReg <= False;
       if (sendInterrupt)
	  tlpOutFifo.enq(tlp);
    endrule

    rule interruptTlpDataOut if (interruptSecondHalf);
       TLPData#(16) tlp = defaultValue;
       tlp.sof = False;
       tlp.eof = True;
       tlp.hit = 7'h00;
       tlp.be = 16'hf000;
       tlp.data[7+8*15:8*12] = byteSwap(interruptDataReg);
       tlpOutFifo.enq(tlp);
       interruptSecondHalf <= False;
       interruptRequestedReg <= False;
    endrule

    interface Put tlp_in;
        method Action put(TLPData#(16) tlp);
	    //$display("PortalEngine.put tlp=%h", tlp);
	    TLPMemoryIO3DWHeader h = unpack(tlp.data);
	    hitReg <= tlp.hit;
	    TLPMemoryIO3DWHeader hdr_3dw = unpack(tlp.data);
	    if (hdr_3dw.format == MEM_READ_3DW_NO_DATA) begin
	       if (readHeaderFifo.notFull())
	          readHeaderFifo.enq(hdr_3dw);
	       else begin
		  // FIXME: should generate a response or host will lock up
	       end
	    end
	    else begin
	       if (writeHeaderFifo.notFull())
		  writeHeaderFifo.enq(hdr_3dw);
	    end
            timerReg <= truncate(32'hFFFFFFFF);
	endmethod
    endinterface: tlp_in
    interface Get tlp_out = toGet(tlpOutFifo);
    interface Axi3Client portal;
       interface Get req_aw;
	  method ActionValue#(Axi3WriteRequest#(32,12)) get() if (!interruptSecondHalf);
	     let hdr = writeHeaderFifo.first;
	     writeHeaderFifo.deq;
	     writeDataFifo.enq(hdr);
	     return Axi3WriteRequest { address: extend(writeHeaderFifo.first.addr) << 2, len: 0, id: extend(writeHeaderFifo.first.tag),
				       size: axiBusSize(32), burst: 1, prot: 0, cache: 'b011, lock:0, qos: 0 };
	  endmethod
       endinterface: req_aw
       interface Get resp_write;
	  method ActionValue#(Axi3WriteData#(32,12)) get();
	     writeDataFifo.deq;
	     let data = writeDataFifo.first.data;
	     if (byteSwapReg)
		data = byteSwap(data);
	     return Axi3WriteData { data: data, id: extend(writeDataFifo.first.tag), byteEnable: writeDataFifo.first.firstbe, last: 1 };
	  endmethod
       endinterface: resp_write
       interface Put resp_b;
	  method Action put(Axi3WriteResponse#(12) resp);
	  endmethod
       endinterface: resp_b
       interface Get req_ar;
	  method ActionValue#(Axi3ReadRequest#(32,12)) get();
	     let hdr = readHeaderFifo.first;
	     readHeaderFifo.deq;
	     readDataFifo.enq(hdr);
	     return Axi3ReadRequest { address: extend(readHeaderFifo.first.addr) << 2, len: 0, id: extend(readHeaderFifo.first.tag),
				     size: axiBusSize(32), burst: 1, prot: 0, cache: 'b011, lock:0, qos: 0 };
	    endmethod
       endinterface: req_ar
       interface Put resp_read;
	  method Action put(Axi3ReadResponse#(32,12) resp) if (!interruptSecondHalf);
	        let hdr = readDataFifo.first;
		//FIXME: assumes only 1 word read per request
		readDataFifo.deq;

	        TLPCompletionHeader completion = defaultValue;
		completion.format = MEM_WRITE_3DW_DATA;
		completion.pkttype = COMPLETION;
		completion.relaxed = hdr.relaxed;
		completion.nosnoop = hdr.nosnoop;
		completion.length = 1;
		completion.tclass = hdr.tclass;
		completion.cmplid = my_id;
		completion.tag = truncate(resp.id);
		completion.bytecount = 4;
		completion.reqid = hdr.reqid;
		completion.loweraddr = getLowerAddr(hdr.addr, hdr.firstbe);
		if (byteSwapReg)
		    completion.data = byteSwap(resp.data);
		else
		    completion.data = resp.data;
	        TLPData#(16) tlp = defaultValue;
		tlp.data = pack(completion);
		tlp.sof = True;
		tlp.eof = True;
		tlp.be = 16'hFFFF;
		tlp.hit = hitReg;
		tlpOutFifo.enq(tlp);
	    endmethod
	endinterface: resp_read
    endinterface: portal
    interface Reg byteSwap           = byteSwapReg;
    interface Reg interruptRequested = interruptRequestedReg;
    interface Reg interruptAddr      = interruptAddrReg;
    interface Reg interruptData      = interruptDataReg;
endmodule: mkPortalEngine

interface AxiSlaveEngine#(type buswidth);
    interface GetPut#(TLPData#(16))   tlps;
    interface Axi3Server#(40,buswidth,6)  slave3;
    interface Axi4Server#(40,buswidth,6)  slave4;
    method Bool tlpOutFifoNotEmpty();
    interface Reg#(Bool) use4dw;
endinterface: AxiSlaveEngine

module mkAxiSlaveEngine#(PciId my_id)(AxiSlaveEngine#(buswidth))
   provisos (Div#(buswidth, 8, busWidthBytes),
	     Div#(buswidth, 32, busWidthWords),
	     Bits#(Vector#(busWidthWords, Bit#(32)), buswidth),
	     Add#(aaa, 32, buswidth),
	     Add#(bbb, buswidth, 256),
	     Add#(ccc, TMul#(8, busWidthWords), 64),
	     Add#(ddd, TMul#(32, busWidthWords), 256),
	     Add#(eee, busWidthWords, 8));

    FIFOF#(TLPData#(16)) tlpOutFifo <- mkFIFOF;
    FIFOF#(TLPData#(16)) tlpInFifo <- mkFIFOF;
    FIFOF#(TLPData#(16)) tlpWriteHeaderFifo <- mkFIFOF;

    Reg#(Bit#(7)) hitReg <- mkReg(0);
    Reg#(Bool) use4dwReg <- mkReg(True);

    // default configuration for MIMO is for guarded enq() and deq().
    // However, the implicit guard only checks for space for 1 element for enq(), and availability of 1 element for deq().
    MIMOConfiguration mimoCfg = defaultValue;
    MIMO#(4,busWidthWords,8,Bit#(32)) completionMimo <- mkMIMO(mimoCfg);
    MIMO#(4,busWidthWords,8,TLPTag) completionTagMimo <- mkMIMO(mimoCfg);
    MIMO#(busWidthWords,4,8,Bit#(32)) writeDataMimo <- mkMIMO(mimoCfg);
    Reg#(TLPTag) lastTag <- mkReg(0);
    Reg#(Bit#(9)) writeBurstCount <- mkReg(0);
    Reg#(TLPLength)  writeDwCount <- mkReg(0);
    Reg#(TLPTag) writeTag <- mkReg(0);
    FIFOF#(TLPTag) doneTag <- mkFIFOF();

    function Integer tlpWordCount(TLPData#(16) tlp);
       if (tlp.be == 16'h0000)
	  return 0;
       else if (tlp.be == 16'h000f || tlp.be == 16'hf000)
	  return 1;
       else if (tlp.be == 16'h00ff || tlp.be == 16'hff00)
	  return 2;
       else if (tlp.be == 16'h0fff || tlp.be == 16'hfff0)
	  return 3;
       else if (tlp.be == 16'hffff)
	  return 4;
       else
	  return 0;
    endfunction

   rule writeHeaderTlp if (writeDwCount == 0);
      let tlp = tlpWriteHeaderFifo.first;

      TLPMemory4DWHeader hdr_4dw = unpack(tlp.data);
      TLPLength dwCount = hdr_4dw.length;

      TLPMemoryIO3DWHeader hdr_3dw = unpack(tlp.data);
      Bool sendit = False;
      if (hdr_3dw.format == MEM_WRITE_3DW_DATA && writeDataMimo.deqReadyN(1)) begin
	 dwCount = hdr_3dw.length;
	 Vector#(4, Bit#(32)) v = writeDataMimo.first();
	 writeDataMimo.deq(1);
	 hdr_3dw.data = byteSwap(v[0]);
	 tlp.be = 16'hffff;
	 if (dwCount == 1)
	    tlp.eof = True;
	 dwCount = dwCount - 1;
	 tlp.data = pack(hdr_3dw);
	 sendit = True;
      end
      else if (hdr_3dw.format == MEM_WRITE_3DW_DATA) begin
	 // retry until the data is available in writeDataMimo
      end
      else begin
	 sendit = True;
      end
      if (sendit) begin
	 tlpWriteHeaderFifo.deq();
	 tlpOutFifo.enq(tlp);
	 $display("writeHeaderTlp dwCount=%d", dwCount);
	 writeDwCount <= dwCount;
      end
   endrule

   rule writeTlps if (writeDwCount > 0);
      TLPData#(16) tlp = defaultValue;
      tlp.sof = False;
      Vector#(4, Bit#(32)) v = unpack(0);
      Bool sendit = False;
      // The MIMO implicit guard only checks for availability of 1 element
      // so we explicitly check for the number of elements required
      if (writeDwCount > 4 && writeDataMimo.deqReadyN(4)) begin
	 v = writeDataMimo.first();

	 writeDataMimo.deq(4);
	 writeDwCount <= writeDwCount - 4;
	 tlp.eof = False;
	 tlp.be = 16'hffff;
	 sendit = True;
      end
      else if (writeDwCount <= 4 && writeDataMimo.deqReadyN(unpack(truncate(writeDwCount)))) begin
	 v = writeDataMimo.first();
	 writeDataMimo.deq(unpack(truncate(writeDwCount)));
	 writeDwCount <= 0;
	 doneTag.enq(writeTag);
	 $display("writeDwCount=%d will be zero", writeDwCount);
	 tlp.eof = True;
	 if (writeDwCount == 4)
	    tlp.be = 16'hffff;
	 else if (writeDwCount == 3)
	    tlp.be = 16'hfff0;
	 else if (writeDwCount == 2)
	    tlp.be = 16'hff00;
	 else if (writeDwCount == 1)
	    tlp.be = 16'hf000;
	 sendit = True;
      end
      else begin
	 // wait for more data in writeDataMimo
	 $display("waiting for more data dwCount=%d count=%d writeBurstCount=%d enqReady=%d",
	    writeDwCount, writeDataMimo.count(), writeBurstCount, writeDataMimo.enqReadyN(fromInteger(valueOf(busWidthWords))));
      end
      if (sendit) begin
	 for (Integer i = 0; i < 4; i = i + 1)
	    tlp.data[(i+1)*32-1:i*32] = byteSwap(v[3-i]);
	 tlpOutFifo.enq(tlp);
      end
   endrule

   rule handleTlpIn;
      let tlp = tlpInFifo.first;
      Bool handled = False;
      TLPMemoryIO3DWHeader h = unpack(tlp.data);
      hitReg <= tlp.hit;
      TLPMemoryIO3DWHeader hdr_3dw = unpack(tlp.data);
      Vector#(4, Bit#(32)) vec = unpack(0);
      Vector#(4, Bit#(32)) tlpvec = unpack(tlp.data);

      if (!tlp.sof) begin
	 let count = tlpWordCount(tlp);
	 // if sof is false, then count will be at least 1
	 function Bit#(32) f(Integer i);
	    begin
	       if (i < count)
		  return tlpvec[3-i];
	       else
		  return 32'hbad0beef;
	    end
	 endfunction
	 vec = genWith(f);
	 // The MIMO implicit guard only checks for space to enqueue 1 element
	 // so we explicitly check for the number of elements required
	 // otherwise elements in the queue will be overwritten.
	 if (completionMimo.enqReadyN(fromInteger(count))
	    && completionTagMimo.enqReadyN(fromInteger(count)))
	    begin
	       completionMimo.enq(fromInteger(count), vec);
	       completionTagMimo.enq(fromInteger(count), replicate(lastTag));
	       handled = True;
	    end
      end
      else if (hdr_3dw.format == MEM_WRITE_3DW_DATA
	       && hdr_3dw.pkttype == COMPLETION
	       && completionMimo.enqReadyN(1)
	       && completionTagMimo.enqReadyN(1)) begin
	    vec[0] = hdr_3dw.data;
	    completionMimo.enq(1, vec);
	    lastTag <= hdr_3dw.tag;
	    completionTagMimo.enq(1, replicate(hdr_3dw.tag));
	    handled = True;
      end
      //$display("tlpIn handled=%d tlp=%h\n", handled, tlp);
      if (handled)
	 tlpInFifo.deq();
   endrule

    interface GetPut tlps = tuple2(toGet(tlpOutFifo),toPut(tlpInFifo));
    interface Axi3Server slave3;
	interface Put req_aw;
	   method Action put(Axi3WriteRequest#(40, 6) req)
	      if (writeBurstCount == 0);

	      let burstLen = req.len;
	      let addr = req.address;
	      let awid = req.id;

	      TLPLength tlplen = fromInteger(valueOf(busWidthWords))*(extend(burstLen) + 1);
	      TLPData#(16) tlp = defaultValue;
	      tlp.sof = True;
	      tlp.eof = False;
	      tlp.hit = 7'h00;
	      tlp.be = 16'hffff;

	      $display("slave3.writeAddr tlplen=%d burstLen=%d", tlplen, burstLen);
	      if ((addr >> 32) != 0) begin
		 TLPMemory4DWHeader hdr_4dw = defaultValue;
		 hdr_4dw.format = MEM_WRITE_4DW_DATA;
		 hdr_4dw.tag = extend(awid);
		 hdr_4dw.reqid = my_id;
		 hdr_4dw.nosnoop = SNOOPING_REQD;
		 hdr_4dw.addr = addr[40-1:2];
		 hdr_4dw.length = tlplen;
		 hdr_4dw.firstbe = 4'hf;
		 hdr_4dw.lastbe = 4'hf;
		 tlp.data = pack(hdr_4dw);
	      end
	      else begin
		 TLPMemoryIO3DWHeader hdr_3dw = defaultValue;
		 hdr_3dw.format = MEM_WRITE_3DW_DATA;
		 hdr_3dw.tag = extend(awid);
		 hdr_3dw.reqid = my_id;
		 hdr_3dw.nosnoop = SNOOPING_REQD;
		 hdr_3dw.addr = addr[32-1:2];
		 hdr_3dw.length = tlplen;
		 hdr_3dw.firstbe = 4'hf;
		 hdr_3dw.lastbe = 4'hf;

		 tlp.be = 16'hfff0; // no data word in this TLP

		 tlp.data = pack(hdr_3dw);
	      end
	      tlpWriteHeaderFifo.enq(tlp);
	      writeBurstCount <= zeroExtend(burstLen)+1;
	      writeTag <= extend(awid);
           endmethod
	endinterface : req_aw
       interface Put resp_write;
	   method Action put(Axi3WriteData#(busWidth,6) wdata)
	      provisos (Bits#(Vector#(busWidthWords, Bit#(32)), busWidth)) if (writeBurstCount > 0 && writeDataMimo.enqReadyN(fromInteger(valueOf(busWidthWords))));

	      writeBurstCount <= writeBurstCount - 1;
	      Vector#(busWidthWords, Bit#(32)) v = unpack(wdata.data);
	      writeDataMimo.enq(fromInteger(valueOf(busWidthWords)), v);
           endmethod
       endinterface : resp_write
       interface Get resp_b;
	   method ActionValue#(Axi3WriteResponse#(6)) get();
	      let tag = doneTag.first();
	      doneTag.deq();
	      return Axi3WriteResponse { resp: 0, id: truncate(tag)};
           endmethod
	endinterface: resp_b
       interface Put req_ar;
	   method Action put(Axi3ReadRequest#(40,6) req) if (writeDwCount == 0);
	      let burstLen = req.len;
	      let addr = req.address;
	      let arid = req.id;

	       TLPData#(16) tlp = defaultValue;
	       tlp.sof = True;
	       tlp.eof = True;
	       tlp.hit = 7'h00;
	       TLPLength tlplen = fromInteger(valueOf(busWidthWords))*(extend(burstLen) + 1);
	       if (addr[39:32] != 0) begin
		   TLPMemory4DWHeader hdr_4dw = defaultValue;
		   hdr_4dw.format = MEM_READ_4DW_NO_DATA;
		   hdr_4dw.tag = extend(arid);
		   hdr_4dw.reqid = my_id;
		   hdr_4dw.nosnoop = SNOOPING_REQD;
		   hdr_4dw.addr = addr[40-1:2];
		   hdr_4dw.length = tlplen;
		   hdr_4dw.firstbe = 4'hf;
		   hdr_4dw.lastbe = 4'hf;
		   tlp.data = pack(hdr_4dw);
		   tlp.be = 16'hffff;
	       end
	       else begin
		   TLPMemoryIO3DWHeader hdr_3dw = defaultValue;
		   hdr_3dw.format = MEM_READ_3DW_NO_DATA;
		   hdr_3dw.tag = extend(arid);
		   hdr_3dw.reqid = my_id;
		   hdr_3dw.nosnoop = SNOOPING_REQD;
		   hdr_3dw.addr = addr[32-1:2];
		   hdr_3dw.length = tlplen;
		   hdr_3dw.firstbe = 4'hf;
		   hdr_3dw.lastbe = 4'hf;
		   tlp.data = pack(hdr_3dw);
		   tlp.be = 16'hfff0;
	       end
	       tlpOutFifo.enq(tlp);
           endmethod
       endinterface : req_ar
       interface Get resp_read;
	   method ActionValue#(Axi3ReadResponse#(buswidth,6)) get() if (completionMimo.deqReadyN(fromInteger(valueOf(busWidthWords))));
	      let data_v = completionMimo.first;
	      completionMimo.deq(fromInteger(valueOf(busWidthWords)));
	      completionTagMimo.deq(fromInteger(valueOf(busWidthWords)));
              Bit#(buswidth) v = 0;
	      for (Integer i = 0; i < valueOf(busWidthWords); i = i+1)
		 v[(i+1)*32-1:i*32] = byteSwap(data_v[i]);
	      return Axi3ReadResponse { data: v, last: 0, id: truncate(completionTagMimo.first[0]), resp: 0 };
           endmethod
	endinterface: resp_read
    endinterface: slave3
    interface Axi4Server slave4;
       interface Put req_aw;
	   method Action put(Axi4WriteRequest#(40,6) req)
	      if (writeBurstCount == 0);

	      let burstLen = req.len;
	      let addr = req.address;
	      let awid = req.id;

	      TLPLength tlplen = fromInteger(valueOf(busWidthWords))*(extend(burstLen) + 1);
	      TLPData#(16) tlp = defaultValue;
	      tlp.sof = True;
	      tlp.eof = False;
	      tlp.hit = 7'h00;
	      tlp.be = 16'hffff;

	      Bit#(9) dwCount = zeroExtend(burstLen)*fromInteger(valueOf(busWidthWords)) + fromInteger(valueOf(busWidthWords));
	      if ((addr >> 32) != 0) begin
		 TLPMemory4DWHeader hdr_4dw = defaultValue;
		 hdr_4dw.format = MEM_WRITE_4DW_DATA;
		 hdr_4dw.tag = extend(awid);
		 hdr_4dw.reqid = my_id;
		 hdr_4dw.nosnoop = SNOOPING_REQD;
		 hdr_4dw.addr = addr[40-1:2];
		 hdr_4dw.length = tlplen;
		 hdr_4dw.firstbe = 4'hf;
		 hdr_4dw.lastbe = 4'hf;
		 tlp.data = pack(hdr_4dw);
	      end
	      else begin
		 TLPMemoryIO3DWHeader hdr_3dw = defaultValue;
		 hdr_3dw.format = MEM_WRITE_3DW_DATA;
		 hdr_3dw.tag = extend(awid);
		 hdr_3dw.reqid = my_id;
		 hdr_3dw.nosnoop = SNOOPING_REQD;
		 hdr_3dw.addr = addr[32-1:2];
		 hdr_3dw.length = tlplen;
		 hdr_3dw.firstbe = 4'hf;
		 hdr_3dw.lastbe = 4'hf;
		 
		 // this would cause a deadlock
		 //Vector#(busWidthWords, Bit#(32)) v = writeDataMimo.deq(1);
		 //hdr_3dw.data = v[0];
		 //dwCount = dwCount - 1;

		 tlp.be = 16'hfff0; // no data word in this TLP

		 tlp.data = pack(hdr_3dw);
	      end
	      tlpWriteHeaderFifo.enq(tlp);
	      writeBurstCount <= zeroExtend(burstLen)+1;
	      writeTag <= extend(awid);
           endmethod
       endinterface: req_aw
       interface Put resp_write;
	   method Action put(Axi4WriteData#(buswidth,6) wdata)
	      provisos (Bits#(Vector#(busWidthWords, Bit#(32)), busWidth)) if (writeBurstCount > 0 && writeDataMimo.enqReadyN(fromInteger(valueOf(busWidthWords))));

	      writeBurstCount <= writeBurstCount - 1;
	      Vector#(busWidthWords, Bit#(32)) v = unpack(wdata.data);
	      writeDataMimo.enq(fromInteger(valueOf(busWidthWords)), v);
           endmethod
       endinterface
       interface Get resp_b;
	   method ActionValue#(Axi4WriteResponse#(6)) get();
	      let tag = doneTag.first();
	      doneTag.deq();
	      return Axi4WriteResponse { resp: 0, id: truncate(tag)};
           endmethod
	endinterface: resp_b
        interface Put req_ar;
	   method Action put(Axi4ReadRequest#(40,6) req) if (writeDwCount == 0);
	      let burstLen = req.len;
	      let addr = req.address;
	      let arid = req.id;

	       TLPData#(16) tlp = defaultValue;
	       tlp.sof = True;
	       tlp.eof = True;
	       tlp.hit = 7'h00;
	       TLPLength tlplen = fromInteger(valueOf(busWidthWords))*(extend(burstLen) + 1);
	       if (addr[39:32] != 0) begin
		   TLPMemory4DWHeader hdr_4dw = defaultValue;
		   hdr_4dw.format = MEM_READ_4DW_NO_DATA;
		   hdr_4dw.tag = extend(arid);
		   hdr_4dw.reqid = my_id;
		   hdr_4dw.nosnoop = SNOOPING_REQD;
		   hdr_4dw.addr = addr[40-1:2];
		   hdr_4dw.length = tlplen;
		   hdr_4dw.firstbe = 4'hf;
		   hdr_4dw.lastbe = 4'hf;
		   tlp.data = pack(hdr_4dw);
		   tlp.be = 16'hffff;
	       end
	       else begin
		   TLPMemoryIO3DWHeader hdr_3dw = defaultValue;
		   hdr_3dw.format = MEM_READ_3DW_NO_DATA;
		   hdr_3dw.tag = extend(arid);
		   hdr_3dw.reqid = my_id;
		   hdr_3dw.nosnoop = SNOOPING_REQD;
		   hdr_3dw.addr = addr[32-1:2];
		   hdr_3dw.length = tlplen;
		   hdr_3dw.firstbe = 4'hf;
		   hdr_3dw.lastbe = 4'hf;
		   tlp.data = pack(hdr_3dw);
		   tlp.be = 16'hfff0;
	       end
	       tlpOutFifo.enq(tlp);
           endmethod
       endinterface: req_ar
       interface Get resp_read;
	   method ActionValue#(Axi4ReadResponse#(buswidth,6)) get() if (completionMimo.deqReadyN(fromInteger(valueOf(busWidthWords))));
	      let data_v = completionMimo.first;
	      completionMimo.deq(fromInteger(valueOf(busWidthWords)));
	      completionTagMimo.deq(fromInteger(valueOf(busWidthWords)));
              Bit#(buswidth) v = 0;
	      for (Integer i = 0; i < valueOf(busWidthWords); i = i+1)
		 v[(i+1)*32-1:i*32] = byteSwap(data_v[i]);
	      return Axi4ReadResponse { data: v, last: 0, id: truncate(completionTagMimo.first[0]), resp: 0 };
           endmethod
	endinterface: resp_read
    endinterface: slave4
   method Bool tlpOutFifoNotEmpty() = tlpOutFifo.notEmpty;
   interface Reg use4dw = use4dwReg;
endmodule: mkAxiSlaveEngine

// The control and status registers which are accessible from the PCIe
// bus.
interface ControlAndStatusRegs;

   // PCIe-facing interfaces
   interface Put#(TLPData#(16)) csr_read_and_write_tlps;
   interface Get#(TLPData#(16)) csr_read_completion_tlps;

   interface ReadOnly#(Bit#(64)) interruptAddr;
   interface ReadOnly#(Bit#(32)) interruptData;

   interface Reg#(Bool) tlpTracing;
   interface Reg#(Bool) axiEnabled;
   interface Reg#(Bool) byteSwap;
   interface Reg#(Bool) use4dw;
   interface Reg#(Bit#(4)) numPortals;
   interface Reg#(Bit#(32)) tlpDataBramWrAddr;
   interface Reg#(Bit#(32)) tlpSeqno;
   interface Reg#(Bit#(32)) tlpOutCount;
   interface BRAMServer#(Bit#(11), TimestampedTlpData) tlpDataBram;
endinterface: ControlAndStatusRegs

// This module encapsulates all of the logic for instantiating and
// accessing the control and status registers. It defines the
// registers, the address map, and how the registers respond to reads
// and writes.
module mkControlAndStatusRegs#( Bit#(64)  board_content_id
			       , PciId     my_id
			       , Integer   bytes_per_beat
			       , UInt#(13) max_read_req_bytes
			       , UInt#(13) max_payload_bytes
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
   Vector#(4,MSIX_Entry) msix_entry               <- replicateM(mkMSIXEntry);

   Reg#(Bool) tlpTracingReg <- mkReg(False);
   Reg#(Bool) axiEnabledReg <- mkReg(False);
   Reg#(Bool) byteSwapReg <- mkReg(False);
   Reg#(Bool) use4dwReg <- mkReg(True);
   Reg#(Bit#(4)) numPortalsReg <- mkReg(1);
   Reg#(Bit#(32)) tlpSeqnoReg <- mkReg(0);
   Reg#(Bit#(32)) tlpDataBramRdAddrReg <- mkReg(0);
   Reg#(Bit#(32)) tlpDataBramWrAddrReg <- mkReg(0);
   BRAM_Configure bramCfg = defaultValue;
   bramCfg.memorySize = 2048;
   BRAM1Port#(Bit#(11), TimestampedTlpData) tlpDataBram1Port <- mkBRAM1Server(bramCfg);
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
         64: return 0;
         512: return 0;
         513: return 0;
         514: return 0;
         515: return 0;
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
	 782: return zeroExtend(rcb_mask);
	 783: return zeroExtend(pack(max_read_req_bytes));
	 784: return zeroExtend(pack(max_payload_bytes));
	 785: return 0;
	 786: return 0;
	 787: return 0;
	 788: return axiEnabledReg ? 1 : 0;
	 789: return tlpDataBramRdAddrReg;
	 790: return msix_enabled ? 1 : 0;
	 791: return msix_mask_all_intr ? 1 : 0;
	 792: return tlpDataBramWrAddrReg;
	 793: return msi_enabled ? 1 : 0;
	 794: return byteSwapReg ? 1 : 0;
	 795: return 0;
	 796: return extend(numPortalsReg);

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
         5120: return '0;                               // PBA structure (low)
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
	    774: tlpSeqnoReg <= dword;
	    775: tlpTracingReg <= (dword != 0) ? True : False;
	    776: tlpDataScratchpad[0] <= dword;
	    777: tlpDataScratchpad[1] <= dword;
	    778: tlpDataScratchpad[2] <= dword;
	    779: tlpDataScratchpad[3] <= dword;
	    780: tlpDataScratchpad[4] <= dword;
	    781: tlpDataScratchpad[5] <= dword;

	    788: axiEnabledReg <= (dword != 0) ? True : False;
	    789: tlpDataBramRdAddrReg <= dword;
	    792: tlpDataBramWrAddrReg <= dword;
	    794: byteSwapReg <= (dword != 0) ? True : False;
	    796: numPortalsReg <= truncate(dword);

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

   interface ReadOnly interruptAddr;
      method Bit#(64) _read();
	 return { msix_entry[0].addr_hi, msix_entry[0].addr_lo };
      endmethod
   endinterface
   interface ReadOnly interruptData = regToReadOnly(msix_entry[0].msg_data);

   interface Reg tlpTracing = tlpTracingReg;
   interface Reg axiEnabled = axiEnabledReg;
   interface Reg byteSwap = byteSwapReg;
   interface Reg use4dw = use4dwReg;
   interface Reg numPortals = numPortalsReg;
   interface Reg tlpDataBramWrAddr = tlpDataBramWrAddrReg;
   interface Reg tlpSeqno = tlpSeqnoReg;
   interface Reg tlpOutCount = tlpOutCountReg;
   interface BRAMServer tlpDataBram = tlpDataBram1Port.portA;
endmodule: mkControlAndStatusRegs

// The PCIe-to-AXI bridge puts all of the elements together
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

   // instantiate sub-components
   PortalEngine            portalEngine <- mkPortalEngine( my_id );

   TLPDispatcher        dispatcher <- mkTLPDispatcher();
   TLPArbiter           arbiter    <- mkTLPArbiter();
   ControlAndStatusRegs csr        <- mkControlAndStatusRegs( board_content_id
                                                            , my_id
                                                            , bytes_per_beat
							    , max_read_req_bytes
							    , max_payload_bytes
                                                            , rcb_mask
                                                            , msix_enabled
                                                            , msix_mask_all_intr
                                                            , msi_enabled
							    , portalEngine
                                                            );
   Reg#(Bit#(32)) timestamp <- mkReg(0);
   rule incTimestamp;
       timestamp <= timestamp + 1;
   endrule
   rule endTrace if (csr.tlpTracing && csr.tlpDataBramWrAddr > 2047);
       csr.tlpTracing <= False;
   endrule
   rule connectEnables;
      dispatcher.axiEnabled <= csr.axiEnabled;
      portalEngine.byteSwap <= csr.byteSwap;
   endrule

   // connect the sub-components to each other

   rule interruptConfig;
      portalEngine.interruptAddr <= csr.interruptAddr;
      portalEngine.interruptData <= csr.interruptData;
   endrule

   mkConnection(dispatcher.tlp_out_to_config,    csr.csr_read_and_write_tlps);
   mkConnection(dispatcher.tlp_out_to_portal,    portalEngine.tlp_in);

   mkConnection(csr.csr_read_completion_tlps,    arbiter.tlp_in_from_config);
   mkConnection(portalEngine.tlp_out,            arbiter.tlp_in_from_portal);

   FIFO#(TLPData#(16)) tlpFromBusFifo <- mkFIFO();
   Reg#(Bool) skippingIncomingTlps <- mkReg(False);
   rule traceTlpFromBus;
       let tlp = tlpFromBusFifo.first;
       tlpFromBusFifo.deq();
       dispatcher.tlp_in_from_bus.put(tlp);
       $display("tlp in: %h\n", tlp);
       if (csr.tlpTracing) begin
           TLPMemoryIO3DWHeader hdr_3dw = unpack(tlp.data);
           // skip root_broadcast_messages sent to tlp.hit 0                                                                                                  
           if (tlp.sof && tlp.hit == 0 && hdr_3dw.pkttype != COMPLETION) begin
 	      skippingIncomingTlps <= True;
	   end
	   else if (skippingIncomingTlps && !tlp.sof) begin
	      // do nothing
	   end
	   else begin
	       TimestampedTlpData ttd = TimestampedTlpData { timestamp: timestamp, unused: 7'h04, tlp: tlp };
	       csr.tlpDataBram.request.put(BRAMRequest{ write: True, responseOnWrite: False, address: truncate(csr.tlpDataBramWrAddr), datain: ttd });
	       csr.tlpDataBramWrAddr <= csr.tlpDataBramWrAddr + 1;
	       csr.tlpSeqno <= csr.tlpSeqno + 1;
	       skippingIncomingTlps <= False;
	   end
       end
   endrule: traceTlpFromBus

   FIFO#(TLPData#(16)) tlpToBusFifo <- mkFIFO();
   rule traceTlpToBus;
       let tlp <- arbiter.tlp_out_to_bus.get();
       tlpToBusFifo.enq(tlp);
       if (csr.tlpTracing) begin
	   TimestampedTlpData ttd = TimestampedTlpData { timestamp: timestamp, unused: 7'h08, tlp: tlp };
	   csr.tlpDataBram.request.put(BRAMRequest{ write: True, responseOnWrite: False, address: truncate(csr.tlpDataBramWrAddr), datain: ttd });
	   csr.tlpDataBramWrAddr <= csr.tlpDataBramWrAddr + 1;
	   csr.tlpSeqno <= csr.tlpSeqno + 1;
       end
   endrule: traceTlpToBus

   // route the interfaces to the sub-components

   //interface GetPut tlps = tuple2(arbiter.tlp_out_to_bus,dispatcher.tlp_in_from_bus);
   interface GetPut tlps = tuple2(toGet(tlpToBusFifo),toPut(tlpFromBusFifo));

   interface Axi3Server portal0 = portalEngine.portal;
   interface GetPut slave = tuple2(dispatcher.tlp_out_to_axi, arbiter.tlp_in_from_axi);
   interface Reg numPortals = csr.numPortals;

   method Bool rx_activity  = dispatcher.read_tlp() || dispatcher.write_tlp() || arbiter.completion_tlp();
   method Bool tx_activity  = arbiter.read_tlp()    || arbiter.write_tlp()    || dispatcher.completion_tlp();

   method Action interrupt();
       portalEngine.interruptRequested <= True;
   endmethod

   interface Put trace;
       method Action put(TimestampedTlpData ttd);
	   if (csr.tlpTracing) begin
	       ttd.timestamp = timestamp;
	       csr.tlpDataBram.request.put(BRAMRequest{ write: True, responseOnWrite: False, address: truncate(csr.tlpDataBramWrAddr), datain: ttd });
	       csr.tlpDataBramWrAddr <= csr.tlpDataBramWrAddr + 1;
	   end
       endmethod
   endinterface: trace

endmodule: mkPcieToAxiBridge

endpackage: PcieToAxiBridge

