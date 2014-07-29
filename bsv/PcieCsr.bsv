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
   interface MemSlave#(32,32) memSlave;
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
   Reg#(Bit#(TAdd#(TlpTraceAddrSize,1))) bramMuxRdAddrReg <- mkReg(0);

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

   AddressGenerator#(16)              csrRag <- mkAddressGenerator;
   AddressGenerator#(16)              csrWag <- mkAddressGenerator;
   FIFOF#(MemData#(32))     readResponseFifo <- mkFIFOF();
   FIFOF#(MemData#(32))        writeDataFifo <- mkFIFOF();
   FIFOF#(Bit#(ObjectTagSize)) writeDoneFifo <- mkFIFOF();

   rule readDataRule;
      let beat <- csrRag.addrBeat.get();
      let addr = beat.addr;
      Bit#(32) data = 0;
      let modaddr = (addr % 8192);
      let msixaddr = modaddr - `msix_base;
      if (msixaddr >= 0 && msixaddr <= 63)
         begin
            let groupaddr = (msixaddr / 4);
            //******************************** area referenced from xilinx_x7_pcie_wrapper.v
            case (msixaddr % 4)
               0: data = msix_entry[groupaddr].addr_lo;
               1: data = msix_entry[groupaddr].addr_hi;
               2: data = msix_entry[groupaddr].msg_data;
               3: data = {'0, pack(msix_entry[groupaddr].masked)}; // vector control
               default: data = 32'hbad0add0;
            endcase
         end
      else
	 case (modaddr)
            // board identification
            0: data = 32'h65756c42; // Blue
            1: data = 32'h63657073; // spec
	    
	    768: data = extend(bramMuxRdAddrReg);
	    774: data = fromInteger(2**valueOf(TAdd#(TlpTraceAddrSize,1)));
	    775: data = (tlpdata.tlpTracing ? 1 : 0);
	    776: data = tlpTraceBramResponseSlice(pcieTraceBramResponse, 0);
	    777: data = tlpTraceBramResponseSlice(pcieTraceBramResponse, 1);
	    778: data = tlpTraceBramResponseSlice(pcieTraceBramResponse, 2);
	    779: data = tlpTraceBramResponseSlice(pcieTraceBramResponse, 3);
	    780: data = tlpTraceBramResponseSlice(pcieTraceBramResponse, 4);
	    781: data = tlpTraceBramResponseSlice(pcieTraceBramResponse, 5);
	    792: data = extend(tlpdata.pcieTraceBramWrAddr);
	    794: data = extend(tlpdata.tlpTraceLimit);

            //******************************** start of area referenced from xilinx_x7_pcie_wrapper.v
            // 4-bit MSIx pending bit field
            992: data = '0;                               // PBA structure (low)
            993: data = '0;                               // PBA structure (high)
            //******************************** end of area referenced from xilinx_x7_pcie_wrapper.v
            // unused addresses
            default: data = 32'hbad0add0;
	 endcase
      readResponseFifo.enq(MemData { data: data, tag: beat.tag, last: beat.last });
   endrule

   FIFOF#(BRAMRequest#(Bit#(TAdd#(TlpTraceAddrSize,1)),TimestampedTlpData)) bramRequestFifo <- mkFIFOF();
   mkConnection(toGet(bramRequestFifo), tlpdata.bramServer.request);

   rule writeDataRule;
      let beat <- csrWag.addrBeat.get();
      let addr = beat.addr;
      let memData <- toGet(writeDataFifo).get();
      let dword = memData.data;

      let modaddr = (addr % 8192);
      let msixaddr = modaddr - `msix_base;
      if (msixaddr >= 0 && msixaddr <= 63)
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
      else
         case (modaddr)
	    775: tlpdata.tlpTracing <= (dword != 0) ? True : False;

	    768: begin
		    bramRequestFifo.enq(BRAMRequest{ write: False, responseOnWrite: False, address: bramMuxRdAddrReg, datain: ?});
		    bramMuxRdAddrReg <= bramMuxRdAddrReg + 1;
		 end
	    792: tlpdata.pcieTraceBramWrAddr <= truncate(dword);
	    794: tlpdata.tlpTraceLimit <= truncate(dword);
         endcase
      if (beat.last)
	 writeDoneFifo.enq(beat.tag);
   endrule

   interface MemSlave memSlave;
      interface MemReadServer read_server;
	 interface Put readReq;
	    method Action put(MemRequest#(32) req);
	       csrRag.request.put(MemRequest { addr: truncate(req.addr), burstLen: req.burstLen, tag: req.tag});
	    endmethod
	 endinterface
	 interface Get readData = toGet(readResponseFifo);
   endinterface: read_server

  interface MemWriteServer write_server; 
	 interface Put writeReq;
	    method Action put(MemRequest#(32) req);
	       csrWag.request.put(MemRequest { addr: truncate(req.addr), burstLen: req.burstLen, tag: req.tag});
	    endmethod
	 endinterface
     interface Put writeData = toPut(writeDataFifo);
     interface Get writeDone = toGet(writeDoneFifo);
   endinterface: write_server
   endinterface
   interface Vector msixEntry = map(toReadOnlyMsixEntry, msix_entry);
endmodule: mkPcieControlAndStatusRegs
