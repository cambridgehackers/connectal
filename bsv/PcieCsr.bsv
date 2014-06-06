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
import PCIE           :: *;
import Bscan          :: *;
import BramMux        :: *;
import Clocks         :: *;
import PcieTracer     :: *;
import MemSlave       :: *;

`define msix_base 1024

// An MSIX table entry, as defined in the PCIe spec
interface MSIX_Entry;
   interface Reg#(Bit#(32)) addr_lo;
   interface Reg#(Bit#(32)) addr_hi;
   interface Reg#(Bit#(32)) msg_data;
   interface Reg#(Bool)     masked;
endinterface

// control and status registers accessed from PCIe
interface PcieControlAndStatusRegs;
   interface MemSlaveClient client;
   interface Vector#(16,MSIX_Entry) msixEntry;
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

   interface MemSlaveClient client;
   // Function to read from the CSR address space (using DW address)
   method Bit#(32) rd(UInt#(30) addr);
      let modaddr = (addr % 8192);
      let msixaddr = modaddr - `msix_base;
      if (msixaddr >= 0 && msixaddr <= 63)
         begin
         let groupaddr = (msixaddr / 4);
         //******************************** area referenced from xilinx_x7_pcie_wrapper.v
         case (msixaddr % 4)
         0: return msix_entry[groupaddr].addr_lo;
         1: return msix_entry[groupaddr].addr_hi;
         2: return msix_entry[groupaddr].msg_data;
         3: return {'0, pack(msix_entry[groupaddr].masked)}; // vector control
         default: return 32'hbad0add0;
         endcase
         end
      else
      case (modaddr)
         // board identification
         0: return 32'h65756c42; // Blue
         1: return 32'h63657073; // spec
	 
	 768: return extend(bramMuxRdAddrReg);
	 774: return fromInteger(2**valueOf(TAdd#(TlpTraceAddrSize,1)));
	 775: return (tlpdata.tlpTracing ? 1 : 0);
	 776: return tlpTraceBramResponseSlice(pcieTraceBramResponse, 0);
	 777: return tlpTraceBramResponseSlice(pcieTraceBramResponse, 1);
	 778: return tlpTraceBramResponseSlice(pcieTraceBramResponse, 2);
	 779: return tlpTraceBramResponseSlice(pcieTraceBramResponse, 3);
	 780: return tlpTraceBramResponseSlice(pcieTraceBramResponse, 4);
	 781: return tlpTraceBramResponseSlice(pcieTraceBramResponse, 5);
	 792: return extend(tlpdata.fromPcieTraceBramWrAddr);
	 793: return extend(  tlpdata.toPcieTraceBramWrAddr);
	 794: return extend(tlpdata.tlpTraceLimit);

         //******************************** start of area referenced from xilinx_x7_pcie_wrapper.v
         // 4-bit MSIx pending bit field
         992: return '0;                               // PBA structure (low)
         993: return '0;                               // PBA structure (high)
         //******************************** end of area referenced from xilinx_x7_pcie_wrapper.v
         // unused addresses
         default: return 32'hbad0add0;
      endcase
   endmethod

   // Function to write to the CSR address space (using DW address)
   method Action wr(UInt#(30) addr, Bit#(32) dword);
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
		    tlpdata.bramServer.request.put(BRAMRequest{ write: False, responseOnWrite: False, address: bramMuxRdAddrReg, datain: unpack(0)});
		    bramMuxRdAddrReg <= bramMuxRdAddrReg + 1;
		    end
	    792: tlpdata.fromPcieTraceBramWrAddr <= truncate(dword);
	    793:   tlpdata.toPcieTraceBramWrAddr <= truncate(dword);
	    794: tlpdata.tlpTraceLimit <= truncate(dword);
         endcase
   endmethod
   endinterface
   interface Vector msixEntry = msix_entry;
endmodule: mkPcieControlAndStatusRegs
