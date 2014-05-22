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
//import Connectable    :: *;
import AxiMasterSlave :: *;
import Bscan          :: *;
import BramMux        :: *;
import Clocks         :: *;
import PcieTracer     :: *;

`define msix_base 1024

// An MSIX table entry, as defined in the PCIe spec
interface MSIX_Entry;
   interface Reg#(Bit#(32)) addr_lo;
   interface Reg#(Bit#(32)) addr_hi;
   interface Reg#(Bit#(32)) msg_data;
   interface Reg#(Bool)     masked;
endinterface

// The control and status registers which are accessible from the PCIe
// bus.
interface AxiControlAndStatusRegs;
   interface Axi3Slave#(32,32,12)  slave;
   interface Vector#(16,MSIX_Entry) msixEntry;
endinterface: AxiControlAndStatusRegs

// This module encapsulates all of the logic for instantiating and
// accessing the control and status registers. It defines the
// registers, the address map, and how the registers respond to reads
// and writes.
module mkAxiControlAndStatusRegs#(MakeResetIfc portalResetIfc, TlpTraceData tlp)(AxiControlAndStatusRegs);

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

   // Function to read from the CSR address space (using DW address)
   function Bit#(32) rd_csr(UInt#(30) addr);
      let modaddr = (addr % 8192);
      if (modaddr >= `msix_base && modaddr <= (`msix_base+63))
         begin
         let groupaddr = (modaddr / 4);
         //******************************** area referenced from xilinx_x7_pcie_wrapper.v
         case (modaddr % 4)
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
	 775: return (tlp.tlpTracing ? 1 : 0);
	 776: return tlpTraceBramResponseSlice(pcieTraceBramResponse, 0);
	 777: return tlpTraceBramResponseSlice(pcieTraceBramResponse, 1);
	 778: return tlpTraceBramResponseSlice(pcieTraceBramResponse, 2);
	 779: return tlpTraceBramResponseSlice(pcieTraceBramResponse, 3);
	 780: return tlpTraceBramResponseSlice(pcieTraceBramResponse, 4);
	 781: return tlpTraceBramResponseSlice(pcieTraceBramResponse, 5);
	 792: return extend(tlp.fromPcieTraceBramWrAddr);
	 793: return extend(  tlp.toPcieTraceBramWrAddr);
	 794: return extend(tlp.tlpTraceLimit);
	 795: return portalResetIfc.isAsserted() ? 1 : 0;

         //******************************** start of area referenced from xilinx_x7_pcie_wrapper.v
         // 4-bit MSIx pending bit field
         (`msix_base+1024): return '0;                               // PBA structure (low)
         (`msix_base+1025): return '0;                               // PBA structure (high)
         //******************************** end of area referenced from xilinx_x7_pcie_wrapper.v
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
         let modaddr = (addr % 8192);
         if (modaddr >= `msix_base && modaddr <= (`msix_base+63))
            begin
            let groupaddr = (modaddr / 4);
            //******************************** area referenced from xilinx_x7_pcie_wrapper.v
            case (modaddr % 4)
            0: msix_entry[groupaddr].addr_lo  <= update_dword(msix_entry[groupaddr].addr_lo, be, (dword & 32'hfffffffc));
            1: msix_entry[groupaddr].addr_hi  <= update_dword(msix_entry[groupaddr].addr_hi, be, dword);
            2: msix_entry[groupaddr].msg_data <= update_dword(msix_entry[groupaddr].msg_data, be, dword);
            3: if (be[0] == 1) msix_entry[groupaddr].masked <= unpack(dword[0]);
            endcase
            end
         else
         case (modaddr)
	    775: tlp.tlpTracing <= (dword != 0) ? True : False;

	    768: begin
		    tlp.bramMux.bramServer.request.put(BRAMRequest{ write: False, responseOnWrite: False, address: bramMuxRdAddrReg, datain: unpack(0)});
		    bramMuxRdAddrReg <= bramMuxRdAddrReg + 1;
		    end
	    792: tlp.fromPcieTraceBramWrAddr <= truncate(dword);
	    793:   tlp.toPcieTraceBramWrAddr <= truncate(dword);
	    794: tlp.tlpTraceLimit <= truncate(dword);
	    795: portalResetIfc.assertReset();
         endcase
      endaction
   endfunction: wr_csr

   // State used to actually service read and write requests

   rule brmMuxResponse;
       let v <- tlp.bramMux.bramServer.response.get();
       pcieTraceBramResponse <= v;
   endrule

   FIFOF#(Axi3ReadRequest#(32,12)) req_ar_fifo <- mkFIFOF();
   FIFOF#(Axi3ReadResponse#(32,12)) resp_read_fifo <- mkSizedFIFOF(8);
   FIFOF#(Axi3WriteRequest#(32,12)) req_aw_fifo <- mkFIFOF();
   FIFOF#(Axi3WriteData#(32,12)) resp_write_fifo <- mkSizedFIFOF(8);
   FIFOF#(Axi3WriteResponse#(12)) resp_b_fifo <- mkFIFOF();

   Reg#(Bit#(5)) readBurstCount <- mkReg(0);
   Reg#(Bit#(30)) readAddr <- mkReg(0);
   rule do_read if (req_ar_fifo.notEmpty());
      Bit#(5) bc = readBurstCount;
      Bit#(30) addr = readAddr;
      let req = req_ar_fifo.first();
      if (bc == 0) begin
	 bc = extend(req.len)+1;
	 addr = truncate(req.address);
      end

      let v = rd_csr(unpack(addr >> 2));
      $display("AxiCsr do_read addr=%h len=%d v=%h", addr, bc, v);
      resp_read_fifo.enq(Axi3ReadResponse { data: v, resp: 0, last: pack(bc == 1), id: req.id });

      addr = addr + 4;
      bc = bc - 1;

      readBurstCount <= bc;
      readAddr <= addr;
      if (bc == 0)
	 req_ar_fifo.deq();
   endrule

   Reg#(Bit#(5)) writeBurstCount <- mkReg(0);
   Reg#(Bit#(30)) writeAddr <- mkReg(0);
   rule do_write if (req_aw_fifo.notEmpty());
      Bit#(5) bc = writeBurstCount;
      Bit#(30) addr = writeAddr;
      let req = req_aw_fifo.first();
      if (bc == 0) begin
	 bc = extend(req.len)+1;
	 addr = truncate(req.address);
      end

      let resp_write = resp_write_fifo.first();
      resp_write_fifo.deq();

      wr_csr(unpack(addr >> 2), 'hf, resp_write.data);

      addr = addr + 4;
      bc = bc - 1;

      writeBurstCount <= bc;
      writeAddr <= addr;
      if (bc == 0) begin
	 req_aw_fifo.deq();
	 resp_b_fifo.enq(Axi3WriteResponse { resp: 0, id: req.id});
      end
   endrule

   interface Axi3Slave slave;
	interface Put req_ar;
	   method Action put(Axi3ReadRequest#(32,12) req);
	      req_ar_fifo.enq(req);
	   endmethod
	endinterface: req_ar
	interface Get resp_read;
	   method ActionValue#(Axi3ReadResponse#(32,12)) get();
	      let resp = resp_read_fifo.first();
	      resp_read_fifo.deq();
	      return resp;
	   endmethod
	endinterface: resp_read
	interface Put req_aw;
	   method Action put(Axi3WriteRequest#(32,12) req);
	      req_aw_fifo.enq(req);
	   endmethod
	endinterface: req_aw
	interface Put resp_write;
	   method Action put(Axi3WriteData#(32,12) resp);
	      resp_write_fifo.enq(resp);
	   endmethod
	endinterface: resp_write
	interface Get resp_b;
	   method ActionValue#(Axi3WriteResponse#(12)) get();
	      let b = resp_b_fifo.first();
	      resp_b_fifo.deq();
	      return b;
	   endmethod
	endinterface: resp_b
   endinterface: slave

   interface Vector msixEntry = msix_entry;
endmodule: mkAxiControlAndStatusRegs
