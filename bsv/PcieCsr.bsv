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
endinterface: PcieControlAndStatusRegs

// This module encapsulates all of the logic for instantiating and
// accessing the control and status registers. It defines the
// registers, the address map, and how the registers respond to reads
// and writes.
module mkPcieControlAndStatusRegs#(TlpTraceData tlpdata)(PcieControlAndStatusRegs);

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
   //Reg#(Bit#(TAdd#(TlpTraceAddrSize,1))) bramMuxRdAddrReg <- mkReg(0);

   // Function to return a one-word slice of the tlpTraceBramResponse
   function Bit#(32) tlpTraceBramResponseSlice(Reg#(TimestampedTlpData) data, Bit#(3) i);
       Bit#(8) i8 = zeroExtend(i);
       begin
           Bit#(192) v = extend(pack(data));
           return v[31 + (i8*32) : 0 + (i8*32)];
       end
   endfunction

   // State used to actually service read and write requests
   rule brmMuxResponse;
       let v <- tlpdata.bramServer.response.get();
       pcieTraceBramResponse <= v;
   endrule

   AddressGenerator#(16,32)           csrRag <- mkAddressGenerator;
   AddressGenerator#(16,32)           csrWag <- mkAddressGenerator;
   FIFOF#(MemData#(32))     readResponseFifo <- mkFIFOF();
   FIFOF#(MemData#(32))        writeDataFifo <- mkFIFOF();
   FIFOF#(Bit#(MemTagSize)) writeDoneFifo <- mkFIFOF();

   FIFOF#(AddrBeat#(16)) csrRagBeatFifo <- mkFIFOF();
   FIFOF#(Bool)       csrIsMsixAddrFifo <- mkFIFOF();
   FIFOF#(Vector#(1024,Bool)) csrOneHotFifo <- mkFIFOF();

   FIFOF#(AddrBeat#(16)) csrWagBeatFifo <- mkFIFOF();
   FIFOF#(Bool)       csrWagIsMsixAddrFifo <- mkFIFOF();
   FIFOF#(Vector#(1024,Bool)) csrWagOneHotFifo <- mkFIFOF();

   rule readDataRule;
      let beat <- csrRag.addrBeat.get();
      let addr = beat.addr >> 2; // word address
      Bit#(32) data = 0;
      let modaddr = (addr % 8192);
      let msixaddr = modaddr - `msix_base;

      csrRagBeatFifo.enq(beat);
      csrIsMsixAddrFifo.enq(msixaddr >= 0 && msixaddr <= 63);
      function Bool addrDecode(Integer i); return addr[9:0] == fromInteger(i); endfunction
      csrOneHotFifo.enq(genWith(addrDecode));
   endrule
   rule readDataRule2;
      let beat       <- toGet(csrRagBeatFifo).get();
      let isMsixAddr <- toGet(csrIsMsixAddrFifo).get();
      let addr = beat.addr >> 2; // word address
      Bit#(32) data = 32'hbad0add0;
      let modaddr = (addr % 8192);
      let msix_base = `msix_base;
      let msixaddr = modaddr - msix_base;
      let oneHotDecode <- toGet(csrOneHotFifo).get();

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
	  if (oneHotDecode[0]) data = 32'h65756c42; // Blue
	  if (oneHotDecode[1]) data = 32'h63657073; // spec

	  //if (oneHotDecode[768]) data = extend(bramMuxRdAddrReg);
	  if (oneHotDecode[774]) data = fromInteger(2**valueOf(TAdd#(TlpTraceAddrSize,1)));
	  if (oneHotDecode[775]) data = (tlpdata.tlpTracing ? 1 : 0);
	  if (oneHotDecode[776]) data = tlpTraceBramResponseSlice(pcieTraceBramResponse, 0);
	  if (oneHotDecode[777]) data = tlpTraceBramResponseSlice(pcieTraceBramResponse, 1);
	  if (oneHotDecode[778]) data = tlpTraceBramResponseSlice(pcieTraceBramResponse, 2);
	  if (oneHotDecode[779]) data = tlpTraceBramResponseSlice(pcieTraceBramResponse, 3);
	  if (oneHotDecode[780]) data = tlpTraceBramResponseSlice(pcieTraceBramResponse, 4);
	  if (oneHotDecode[781]) data = tlpTraceBramResponseSlice(pcieTraceBramResponse, 5);
	  if (oneHotDecode[792]) data = extend(tlpdata.pcieTraceBramWrAddr);
	  if (oneHotDecode[794]) data = extend(tlpdata.tlpTraceLimit);

         //******************************** msix_base has to match CONFIG.MXIx_PBA_Offset in scripts/connectal-synth-pcie.tcl
	  // 4-bit MSIx pending bit field
	  if (oneHotDecode[992]) data = '0;                               // PBA structure (low)
	  if (oneHotDecode[993]) data = '0;                               // PBA structure (high)
	  //******************************** end of PBA Table
      end
      readResponseFifo.enq(MemData { data: data, tag: beat.tag, last: beat.last });
   endrule

   FIFOF#(BRAMRequest#(Bit#(TAdd#(TlpTraceAddrSize,1)),TimestampedTlpData)) bramRequestFifo <- mkFIFOF();
   mkConnection(toGet(bramRequestFifo), tlpdata.bramServer.request);

   rule writeDataRule;
      let beat <- csrWag.addrBeat.get();
      let addr = beat.addr >> 2; // word address

      let modaddr = (addr % 8192);
      let msixaddr = modaddr - `msix_base;

      csrWagBeatFifo.enq(beat);
      csrWagIsMsixAddrFifo.enq(msixaddr >= 0 && msixaddr <= 63);
      function Bool addrDecode(Integer i); return addr[9:0] == fromInteger(i); endfunction
      csrWagOneHotFifo.enq(genWith(addrDecode));
   endrule

   rule writeDataRule2;
      let memData <- toGet(writeDataFifo).get();
      let dword = memData.data;

      let beat       <- toGet(csrWagBeatFifo).get();
      let isMsixAddr <- toGet(csrWagIsMsixAddrFifo).get();
      let addr = beat.addr >> 2; // word address
      let modaddr = (addr % 8192);
      let msix_base = `msix_base;
      let msixaddr = modaddr - msix_base;
      let oneHotDecode <- toGet(csrWagOneHotFifo).get();

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
	 if (oneHotDecode[775]) tlpdata.tlpTracing <= (dword != 0) ? True : False;

	 if (oneHotDecode[768]) begin
		    bramRequestFifo.enq(BRAMRequest{ write: False, responseOnWrite: False, address: truncate(dword), datain: ?});
		    //bramMuxRdAddrReg <= bramMuxRdAddrReg + 1;
		 end
	 if (oneHotDecode[792]) tlpdata.pcieTraceBramWrAddr <= truncate(dword);
	 if (oneHotDecode[794]) tlpdata.tlpTraceLimit <= truncate(dword);
      end
      if (beat.last)
	 writeDoneFifo.enq(beat.tag);
   endrule

   interface PhysMemSlave memSlave;
      interface PhysMemReadServer read_server;
	 interface Put readReq;
	    method Action put(PhysMemRequest#(32) req);
	       csrRag.request.put(PhysMemRequest { addr: truncate(req.addr), burstLen: req.burstLen, tag: req.tag});
	    endmethod
	 endinterface
	 interface Get readData = toGet(readResponseFifo);
   endinterface: read_server

  interface PhysMemWriteServer write_server; 
	 interface Put writeReq;
	    method Action put(PhysMemRequest#(32) req);
	       csrWag.request.put(PhysMemRequest { addr: truncate(req.addr), burstLen: req.burstLen, tag: req.tag});
	    endmethod
	 endinterface
     interface Put writeData = toPut(writeDataFifo);
     interface Get writeDone = toGet(writeDoneFifo);
   endinterface: write_server
   endinterface
   interface Vector msixEntry = map(toReadOnlyMsixEntry, msix_entry);
endmodule: mkPcieControlAndStatusRegs
