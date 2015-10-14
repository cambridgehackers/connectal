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

import Vector         :: *;
import BRAM           :: *;
import FIFOF          :: *;
import GetPut         :: *;
import Connectable    :: *;
import PCIE           :: *;
import Clocks         :: *;
import PcieTracer     :: *;
import MemTypes       :: *;
import AddressGenerator::*;

`include "ConnectalProjectConfig.bsv"

`define msix_base 1024

// An MSIX table entry, as defined in the PCIe spec
interface MSIX_Entry;
   interface Reg#(Bit#(32)) addr_lo;
   interface Reg#(Bit#(32)) addr_hi;
   interface Reg#(Bit#(32)) msg_data;
   interface Reg#(Bool)     masked;
endinterface

interface ReadOnly_MSIX_Entry;
   interface ReadOnly#(Bit#(32)) addr_lo;
   interface ReadOnly#(Bit#(32)) addr_hi;
   interface ReadOnly#(Bit#(32)) msg_data;
   interface ReadOnly#(Bool)     masked;
endinterface

function ReadOnly_MSIX_Entry toReadOnlyMsixEntry(MSIX_Entry msix);
   return (interface ReadOnly_MSIX_Entry;
	   interface ReadOnly addr_lo = regToReadOnly(msix.addr_lo);
	   interface ReadOnly addr_hi = regToReadOnly(msix.addr_hi);
	   interface ReadOnly msg_data = regToReadOnly(msix.msg_data);
	   interface ReadOnly masked = regToReadOnly(msix.masked);
	   endinterface);
endfunction

// control and status registers accessed from PCIe
interface PcieControlAndStatusRegs;
   interface PhysMemSlave#(32,32) memSlave;
   interface Vector#(16,ReadOnly_MSIX_Entry) msixEntry;
   interface TlpTraceClient traceClient;
endinterface: PcieControlAndStatusRegs

// This module encapsulates all of the logic for instantiating and
// accessing the control and status registers. It defines the
// registers, the address map, and how the registers respond to reads
// and writes.
(* synthesize *)
module mkPcieControlAndStatusRegs(PcieControlAndStatusRegs);

   // Utility for module creating all of the storage for a single MSIX
   // table entry
   module mkMSIXEntry(MSIX_Entry);
      Reg#(Bit#(32)) _addr_lo  <- mkReg(0);
      Reg#(Bit#(32)) _addr_hi  <- mkReg(0);
      Reg#(Bit#(32)) _msg_data <- mkReg(0);
      Reg#(Bool)     _masked   <- mkReg(True);

      interface addr_lo  = _addr_lo;
      interface addr_hi  = _addr_hi;
      interface msg_data = _msg_data;
      interface masked   = _masked;
   endmodule: mkMSIXEntry

   // Registers and their default values
   Vector#(16,MSIX_Entry) msix_entry              <- replicateM(mkMSIXEntry);
   Reg#(TimestampedTlpData) pcieTraceBramResponse <- mkReg(unpack(0));

   // Function to return a one-word slice of the tlpTraceBramResponse
   function Bit#(32) tlpTraceBramResponseSlice(Reg#(TimestampedTlpData) data, Integer i);
       Bit#(8) i8 = fromInteger(i);
       begin
           Bit#(TMul#(12,32)) v = extend(pack(data));
           return v[31 + (i8*32) : 0 + (i8*32)];
       end
   endfunction

   FIFOF#(BRAMRequest#(Bit#(TAdd#(TlpTraceAddrSize,1)),TimestampedTlpData)) bramRequestFifo <- mkFIFOF();
   FIFOF#(TimestampedTlpData)                                               bramResponseFifo <- mkFIFOF();
   Reg#(Bool)                   tlpTracingReg                <- mkReg(True);
   Reg#(Bit#(TlpTraceAddrSize)) tlpTraceLimitReg             <- mkReg(0);
   Reg#(Bit#(TlpTraceAddrSize)) tlpTraceBramWrAddrReg        <- mkReg(0);

   // State used to actually service read and write requests
   rule brmMuxResponse;
       let v <- toGet(bramResponseFifo).get();
       pcieTraceBramResponse <= v;
   endrule

   AddressGenerator#(16,32)           csrRag <- mkAddressGenerator;
   AddressGenerator#(16,32)           csrWag <- mkAddressGenerator;
   FIFOF#(MemData#(32))     readResponseFifo <- mkFIFOF();
   FIFOF#(MemData#(32))        writeDataFifo <- mkFIFOF();
   FIFOF#(Bit#(MemTagSize)) writeDoneFifo <- mkFIFOF();

   FIFOF#(AddrBeat#(16)) csrRagBeatFifo <- mkFIFOF();
   FIFOF#(Bool)       csrIsMsixAddrFifo <- mkFIFOF();
   FIFOF#(Bit#(2))     csrOneHotFifo000 <- mkFIFOF();
   FIFOF#(Bit#(27))    csrOneHotFifo774 <- mkFIFOF();
   FIFOF#(Bit#(2))     csrOneHotFifo992 <- mkFIFOF();

   FIFOF#(AddrBeat#(16)) csrWagBeatFifo <- mkFIFOF();
   FIFOF#(Bool)       csrWagIsMsixAddrFifo <- mkFIFOF();
   FIFOF#(Bit#(8))     csrWagOneHotFifo768 <- mkFIFOF();
   FIFOF#(Bit#(3))     csrWagOneHotFifo792 <- mkFIFOF();

   rule readDataRule;
      let beat <- csrRag.addrBeat.get();
      let addr = beat.addr >> 2; // word address
      Bit#(32) data = 0;
      let modaddr = (addr % 8192);
      let msixaddr = modaddr - `msix_base;

      csrRagBeatFifo.enq(beat);
      csrIsMsixAddrFifo.enq(msixaddr >= 0 && msixaddr <= 63);
      Bit#(1024) onehot = (1 << addr[9:0]);
      csrOneHotFifo000.enq(onehot[1:0]);
      csrOneHotFifo774.enq(onehot[800:774]);
      csrOneHotFifo992.enq(onehot[993:992]);
   endrule
   rule readDataRule2;
      let beat       <- toGet(csrRagBeatFifo).get();
      let isMsixAddr <- toGet(csrIsMsixAddrFifo).get();
      let addr = beat.addr >> 2; // word address
      Bit#(32) data = 32'hbad0add0;
      let modaddr = (addr % 8192);
      let msix_base = `msix_base;
      let msixaddr = modaddr - msix_base;
      let oneHotDecode000 <- toGet(csrOneHotFifo000).get();
      let oneHotDecode774 <- toGet(csrOneHotFifo774).get();
      let oneHotDecode992 <- toGet(csrOneHotFifo992).get();

      if (isMsixAddr) begin
         begin
            let groupaddr = (msixaddr / 4);
            //******************************** msix_base has to match CONFIG.MXIx_Table_Offset in scripts/connectal-synth-pcie.tcl
            case (msixaddr % 4)
               0: data = msix_entry[groupaddr].addr_lo;
               1: data = msix_entry[groupaddr].addr_hi;
               2: data = msix_entry[groupaddr].msg_data;
               3: data = {'0, pack(msix_entry[groupaddr].masked)}; // vector control
               default: data = 32'hbad0add0;
	  //******************************** end of MSIX Table
            endcase
         end
      end
      else begin
	  // board identification
	  if (oneHotDecode000[0] == 1) data = 32'h65756c42; // Blue
	  if (oneHotDecode000[1] == 1) data = 32'h63657073; // spec

	  if (oneHotDecode774[774-774] == 1) data = fromInteger(2**valueOf(TAdd#(TlpTraceAddrSize,1)));
	  if (oneHotDecode774[775-774] == 1) data = (tlpTracingReg ? 1 : 0);
	  if (oneHotDecode774[776-774] == 1) data = tlpTraceBramResponseSlice(pcieTraceBramResponse, 0);
	  if (oneHotDecode774[777-774] == 1) data = tlpTraceBramResponseSlice(pcieTraceBramResponse, 1);
	  if (oneHotDecode774[778-774] == 1) data = tlpTraceBramResponseSlice(pcieTraceBramResponse, 2);
	  if (oneHotDecode774[779-774] == 1) data = tlpTraceBramResponseSlice(pcieTraceBramResponse, 3);
	  if (oneHotDecode774[780-774] == 1) data = tlpTraceBramResponseSlice(pcieTraceBramResponse, 4);
	  if (oneHotDecode774[781-774] == 1) data = tlpTraceBramResponseSlice(pcieTraceBramResponse, 5);
	  if (oneHotDecode774[792-774] == 1) data = extend(tlpTraceBramWrAddrReg);
	  if (oneHotDecode774[794-774] == 1) data = extend(tlpTraceLimitReg);
	  if (oneHotDecode774[795-774] == 1) data = tlpTraceBramResponseSlice(pcieTraceBramResponse, 6);
	  if (oneHotDecode774[796-774] == 1) data = tlpTraceBramResponseSlice(pcieTraceBramResponse, 7);
	  if (oneHotDecode774[797-774] == 1) data = tlpTraceBramResponseSlice(pcieTraceBramResponse, 8);
	  if (oneHotDecode774[798-774] == 1) data = tlpTraceBramResponseSlice(pcieTraceBramResponse, 9);
	  if (oneHotDecode774[799-774] == 1) data = tlpTraceBramResponseSlice(pcieTraceBramResponse, 10);
	  if (oneHotDecode774[790-774] == 1) data = tlpTraceBramResponseSlice(pcieTraceBramResponse, 11);

         //******************************** msix_base has to match CONFIG.MXIx_PBA_Offset in scripts/connectal-synth-pcie.tcl
	  // 4-bit MSIx pending bit field
	  if (oneHotDecode992[992-992] == 1) data = '0;                               // PBA structure (low)
	  if (oneHotDecode992[993-992] == 1) data = '0;                               // PBA structure (high)
	  //******************************** end of PBA Table
      end
      readResponseFifo.enq(MemData { data: data, tag: beat.tag, last: beat.last });
   endrule

   rule writeDataRule;
      let beat <- csrWag.addrBeat.get();
      let addr = beat.addr >> 2; // word address

      let modaddr = (addr % 8192);
      let msixaddr = modaddr - `msix_base;

      csrWagBeatFifo.enq(beat);
      csrWagIsMsixAddrFifo.enq(msixaddr >= 0 && msixaddr <= 63);
      Bit#(1024) onehot = (1 << addr[9:0]);
      $display("addr: %h", addr);
      csrWagOneHotFifo768.enq(onehot[775:768]);
      csrWagOneHotFifo792.enq(onehot[794:792]);
   endrule

   rule writeDataRule2;
      let memData <- toGet(writeDataFifo).get();
      let dword = memData.data;

      $display("data: %h, last: %h, tag: %h", dword, memData.last, memData.tag);
      let beat       <- toGet(csrWagBeatFifo).get();
      let isMsixAddr <- toGet(csrWagIsMsixAddrFifo).get();
      let addr = beat.addr >> 2; // word address
      let modaddr = (addr % 8192);
      let msix_base = `msix_base;
      let msixaddr = modaddr - msix_base;
      let oneHotDecode768 <- toGet(csrWagOneHotFifo768).get();
      let oneHotDecode792 <- toGet(csrWagOneHotFifo792).get();

      if (isMsixAddr)
         begin
            let groupaddr = (msixaddr / 4);
            //******************************** area referenced from xilinx_x7_pcie_wrapper.v
            case (msixaddr % 4)
               0: msix_entry[groupaddr].addr_lo  <= (dword & 32'hfffffffc);
               1: msix_entry[groupaddr].addr_hi  <= dword;
               2: msix_entry[groupaddr].msg_data <= dword;
               3: msix_entry[groupaddr].masked <= unpack(dword[0]);
            endcase
         end
      else begin
	 if (oneHotDecode768[775-768] == 1) tlpTracingReg <= (dword != 0) ? True : False;
	 if (oneHotDecode768[768-768] == 1)
	     bramRequestFifo.enq(BRAMRequest{ write: False, responseOnWrite: False, address: truncate(dword), datain: ?});
	 if (oneHotDecode792[792-792] == 1) tlpTraceBramWrAddrReg <= truncate(dword);
	 if (oneHotDecode792[794-792] == 1) tlpTraceLimitReg <= truncate(dword);
      end
      if (beat.last)
	 writeDoneFifo.enq(beat.tag);
   endrule

   interface PhysMemSlave memSlave;
      interface PhysMemReadServer read_server;
	 interface Put readReq;
	    method Action put(PhysMemRequest#(32,32) req);
	       csrRag.request.put(PhysMemRequest { addr: truncate(req.addr), burstLen: req.burstLen, tag: req.tag
`ifdef BYTE_ENABLES
						  , firstbe: req.firstbe, lastbe: req.lastbe
`endif
						  });
	    endmethod
	 endinterface
	 interface Get readData = toGet(readResponseFifo);
   endinterface: read_server

  interface PhysMemWriteServer write_server; 
	 interface Put writeReq;
	    method Action put(PhysMemRequest#(32,32) req);
               $display("csrWag Request, addr=%h, burstLen=%h, tag=%h", req.addr, req.burstLen, req.tag);
	       csrWag.request.put(PhysMemRequest { addr: truncate(req.addr), burstLen: req.burstLen, tag: req.tag
`ifdef BYTE_ENABLES
						  , firstbe: req.firstbe, lastbe: req.lastbe
`endif
						  });
	    endmethod
	 endinterface
     interface Put writeData = toPut(writeDataFifo);
     interface Get writeDone = toGet(writeDoneFifo);
   endinterface: write_server
   endinterface
   interface TlpTraceClient traceClient;
      interface Reg tlpTracing = tlpTracingReg;
      interface Reg tlpTraceLimit = tlpTraceLimitReg;
      interface Reg tlpTraceBramWrAddr = tlpTraceBramWrAddrReg;
      interface BRAMClient bramClient;
         interface Get request = toGet(bramRequestFifo);
	 interface Put response = toPut(bramResponseFifo);
      endinterface: bramClient
   endinterface: traceClient
   interface Vector msixEntry = map(toReadOnlyMsixEntry, msix_entry);
endmodule: mkPcieControlAndStatusRegs
