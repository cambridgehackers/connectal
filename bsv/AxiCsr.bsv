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
import Connectable    :: *;
import AxiMasterSlave :: *;
import Bscan          :: *;
import BramMux        :: *;
import Clocks         :: *;

typedef 11 TlpTraceAddrSize;
typedef TAdd#(TlpTraceAddrSize,1) TlpTraceAddrSize1;

typedef struct {
    Bit#(32) timestamp;
    Bit#(7) source;   // 4==frombus 8=tobus
    TLPData#(16) tlp; // 153 bits
} TimestampedTlpData deriving (Bits);
typedef SizeOf#(TimestampedTlpData) TimestampedTlpDataSize;
typedef SizeOf#(TLPData#(16)) TlpData16Size;
typedef SizeOf#(TLPCompletionHeader) TLPCompletionHeaderSize;
interface TlpTrace;
   interface Get#(TimestampedTlpData) tlp;
endinterface

`define msix_base 4096

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

   interface Reg#(Bool)     tlpTracing;
   interface Reg#(Bit#(TlpTraceAddrSize)) tlpTraceLimit;
   interface Reg#(Bit#(TlpTraceAddrSize)) fromPcieTraceBramWrAddr;
   interface Reg#(Bit#(TlpTraceAddrSize))   toPcieTraceBramWrAddr;
   interface BRAMServer#(Bit#(TlpTraceAddrSize), TimestampedTlpData) fromPcieTraceBramPort;
   interface BRAMServer#(Bit#(TlpTraceAddrSize), TimestampedTlpData)   toPcieTraceBramPort;
endinterface: AxiControlAndStatusRegs

// This module encapsulates all of the logic for instantiating and
// accessing the control and status registers. It defines the
// registers, the address map, and how the registers respond to reads
// and writes.
module mkAxiControlAndStatusRegs#(MakeResetIfc portalResetIfc)
   (AxiControlAndStatusRegs);

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

   // Clocks and Resets
   Clock defaultClock <- exposeCurrentClock();
   Reset defaultReset <- exposeCurrentReset();
   
   // Trace Support
   Reg#(Bool) tlpTracingReg        <- mkReg(False);
   Reg#(Bit#(TlpTraceAddrSize)) tlpTraceLimitReg <- mkReg(0);
   Reg#(Bit#(TAdd#(TlpTraceAddrSize,1))) bramMuxRdAddrReg <- mkReg(0);
   Reg#(Bit#(TlpTraceAddrSize)) fromPcieTraceBramWrAddrReg <- mkReg(0);
   Reg#(Bit#(TlpTraceAddrSize))   toPcieTraceBramWrAddrReg <- mkReg(0);
   Integer memorySize = 2**valueOf(TlpTraceAddrSize);
   // TODO: lift BscanBram to *Top.bsv
`ifdef BSIM
   Clock jtagClock = defaultClock;
   Reset jtagReset = defaultReset;
`else
   Reg#(Bit#(TAdd#(TlpTraceAddrSize,1))) bscanPcieTraceBramWrAddrReg <- mkReg(0);
   BscanBram#(Bit#(TAdd#(TlpTraceAddrSize,1)), TimestampedTlpData) pcieBscanBram <- mkBscanBram(1, bscanPcieTraceBramWrAddrReg);
   Clock jtagClock = pcieBscanBram.jtagClock;
   Reset jtagReset = pcieBscanBram.jtagReset;
`endif

   BRAM_Configure bramCfg = defaultValue;
   bramCfg.memorySize = memorySize;
   bramCfg.latency = 1;
   BRAM2Port#(Bit#(TlpTraceAddrSize), TimestampedTlpData) fromPcieTraceBram <- mkSyncBRAM2Server(bramCfg, defaultClock, defaultReset,
												 jtagClock, jtagReset);
   BRAM2Port#(Bit#(TlpTraceAddrSize), TimestampedTlpData) toPcieTraceBram <- mkSyncBRAM2Server(bramCfg, defaultClock, defaultReset,
											       jtagClock, jtagReset);
   Vector#(2, BRAMServer#(Bit#(TlpTraceAddrSize), TimestampedTlpData)) bramServers;
   bramServers[0] = fromPcieTraceBram.portA;
   bramServers[1] =   toPcieTraceBram.portA;
   BramServerMux#(TAdd#(TlpTraceAddrSize,1), TimestampedTlpData) bramMux <- mkBramServerMux(bramServers);

`ifndef BSIM
   Vector#(2, BRAMServer#(Bit#(TlpTraceAddrSize), TimestampedTlpData)) bscanBramServers;
   bscanBramServers[0] = fromPcieTraceBram.portB;
   bscanBramServers[1] =   toPcieTraceBram.portB;
   BramServerMux#(TAdd#(TlpTraceAddrSize,1), TimestampedTlpData) bscanBramMux <- mkBramServerMux(bscanBramServers, clocked_by jtagClock, reset_by jtagReset);
   mkConnection(pcieBscanBram.bramClient, bscanBramMux.bramServer, clocked_by jtagClock, reset_by jtagReset);
`endif
   
   Reg#(TimestampedTlpData) pcieTraceBramResponse <- mkReg(unpack(0));

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
      case (addr % 8192)
         // board identification
         0: return 32'h65756c42; // Blue
         1: return 32'h63657073; // spec
	 
	 768: return extend(bramMuxRdAddrReg);
	 774: return fromInteger(2**valueOf(TAdd#(TlpTraceAddrSize,1)));
	 775: return (tlpTracingReg ? 1 : 0);
	 776: return tlpTraceBramResponseSlice(pcieTraceBramResponse, 0);
	 777: return tlpTraceBramResponseSlice(pcieTraceBramResponse, 1);
	 778: return tlpTraceBramResponseSlice(pcieTraceBramResponse, 2);
	 779: return tlpTraceBramResponseSlice(pcieTraceBramResponse, 3);
	 780: return tlpTraceBramResponseSlice(pcieTraceBramResponse, 4);
	 781: return tlpTraceBramResponseSlice(pcieTraceBramResponse, 5);
	 792: return extend(fromPcieTraceBramWrAddrReg);
	 793: return extend(  toPcieTraceBramWrAddrReg);
	 794: return extend(tlpTraceLimitReg);
	 795: return portalResetIfc.isAsserted() ? 1 : 0;

         //******************************** start of area referenced from xilinx_x7_pcie_wrapper.v
         // 4-entry MSIx table
         `msix_base: return msix_entry[0].addr_lo;            // entry 0 lower address
         (`msix_base+1): return msix_entry[0].addr_hi;            // entry 0 upper address
         (`msix_base+2): return msix_entry[0].msg_data;           // entry 0 msg data
         (`msix_base+3): return {'0, pack(msix_entry[0].masked)}; // entry 0 vector control
         (`msix_base+4): return msix_entry[1].addr_lo;            // entry 1 lower address
         (`msix_base+5): return msix_entry[1].addr_hi;            // entry 1 upper address
         (`msix_base+6): return msix_entry[1].msg_data;           // entry 1 msg data
         (`msix_base+7): return {'0, pack(msix_entry[1].masked)}; // entry 1 vector control
         (`msix_base+8): return msix_entry[2].addr_lo;            // entry 2 lower address
         (`msix_base+9): return msix_entry[2].addr_hi;            // entry 2 upper address
         (`msix_base+10): return msix_entry[2].msg_data;           // entry 2 msg data
         (`msix_base+11): return {'0, pack(msix_entry[2].masked)}; // entry 2 vector control
         (`msix_base+12): return msix_entry[3].addr_lo;            // entry 3 lower address
         (`msix_base+13): return msix_entry[3].addr_hi;            // entry 3 upper address
         (`msix_base+14): return msix_entry[3].msg_data;           // entry 3 msg data
         (`msix_base+15): return {'0, pack(msix_entry[3].masked)}; // entry 3 vector control
         (`msix_base+16): return msix_entry[4].addr_lo;            // entry 0 lower address
         (`msix_base+17): return msix_entry[4].addr_hi;            // entry 0 upper address
         (`msix_base+18): return msix_entry[4].msg_data;           // entry 0 msg data
         (`msix_base+19): return {'0, pack(msix_entry[4].masked)}; // entry 0 vector control
         (`msix_base+20): return msix_entry[5].addr_lo;            // entry 1 lower address
         (`msix_base+21): return msix_entry[5].addr_hi;            // entry 1 upper address
         (`msix_base+22): return msix_entry[5].msg_data;           // entry 1 msg data
         (`msix_base+23): return {'0, pack(msix_entry[5].masked)}; // entry 1 vector control
         (`msix_base+24): return msix_entry[6].addr_lo;            // entry 2 lower address
         (`msix_base+25): return msix_entry[6].addr_hi;            // entry 2 upper address
         (`msix_base+26): return msix_entry[6].msg_data;           // entry 2 msg data
         (`msix_base+27): return {'0, pack(msix_entry[6].masked)}; // entry 2 vector control
         (`msix_base+28): return msix_entry[7].addr_lo;            // entry 3 lower address
         (`msix_base+29): return msix_entry[7].addr_hi;            // entry 3 upper address
         (`msix_base+30): return msix_entry[7].msg_data;           // entry 3 msg data
         (`msix_base+31): return {'0, pack(msix_entry[7].masked)}; // entry 3 vector control
         (`msix_base+32): return msix_entry[8].addr_lo;            // entry 0 lower address
         (`msix_base+33): return msix_entry[8].addr_hi;            // entry 0 upper address
         (`msix_base+34): return msix_entry[8].msg_data;           // entry 0 msg data
         (`msix_base+35): return {'0, pack(msix_entry[8].masked)}; // entry 0 vector control
         (`msix_base+36): return msix_entry[9].addr_lo;            // entry 1 lower address
         (`msix_base+37): return msix_entry[9].addr_hi;            // entry 1 upper address
         (`msix_base+38): return msix_entry[9].msg_data;           // entry 1 msg data
         (`msix_base+39): return {'0, pack(msix_entry[9].masked)}; // entry 1 vector control
         (`msix_base+40): return msix_entry[10].addr_lo;            // entry 2 lower address
         (`msix_base+41): return msix_entry[10].addr_hi;            // entry 2 upper address
         (`msix_base+42): return msix_entry[10].msg_data;           // entry 2 msg data
         (`msix_base+43): return {'0, pack(msix_entry[10].masked)}; // entry 2 vector control
         (`msix_base+44): return msix_entry[11].addr_lo;            // entry 3 lower address
         (`msix_base+45): return msix_entry[11].addr_hi;            // entry 3 upper address
         (`msix_base+46): return msix_entry[11].msg_data;           // entry 3 msg data
         (`msix_base+47): return {'0, pack(msix_entry[11].masked)}; // entry 3 vector control
         (`msix_base+48): return msix_entry[12].addr_lo;            // entry 0 lower address
         (`msix_base+49): return msix_entry[12].addr_hi;            // entry 0 upper address
         (`msix_base+50): return msix_entry[12].msg_data;           // entry 0 msg data
         (`msix_base+51): return {'0, pack(msix_entry[12].masked)}; // entry 0 vector control
         (`msix_base+52): return msix_entry[13].addr_lo;            // entry 1 lower address
         (`msix_base+53): return msix_entry[13].addr_hi;            // entry 1 upper address
         (`msix_base+54): return msix_entry[13].msg_data;           // entry 1 msg data
         (`msix_base+55): return {'0, pack(msix_entry[13].masked)}; // entry 1 vector control
         (`msix_base+56): return msix_entry[14].addr_lo;            // entry 2 lower address
         (`msix_base+57): return msix_entry[14].addr_hi;            // entry 2 upper address
         (`msix_base+58): return msix_entry[14].msg_data;           // entry 2 msg data
         (`msix_base+59): return {'0, pack(msix_entry[14].masked)}; // entry 2 vector control
         (`msix_base+60): return msix_entry[15].addr_lo;            // entry 3 lower address
         (`msix_base+61): return msix_entry[15].addr_hi;            // entry 3 upper address
         (`msix_base+62): return msix_entry[15].msg_data;           // entry 3 msg data
         (`msix_base+63): return {'0, pack(msix_entry[15].masked)}; // entry 3 vector control
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
         case (addr % 8192)
	    775: tlpTracingReg <= (dword != 0) ? True : False;

	    768: begin
		    bramMux.bramServer.request.put(BRAMRequest{ write: False, responseOnWrite: False, address: bramMuxRdAddrReg, datain: unpack(0)});
		    bramMuxRdAddrReg <= bramMuxRdAddrReg + 1;
		    end

	    792: fromPcieTraceBramWrAddrReg <= truncate(dword);
	    793:   toPcieTraceBramWrAddrReg <= truncate(dword);
	    794: tlpTraceLimitReg <= truncate(dword);
	    795: portalResetIfc.assertReset();

            //******************************** start of area referenced from xilinx_x7_pcie_wrapper.v
            // MSIx table entries
            (`msix_base): msix_entry[0].addr_lo  <= update_dword(msix_entry[0].addr_lo, be, (dword & 32'hfffffffc));
            (`msix_base+1): msix_entry[0].addr_hi  <= update_dword(msix_entry[0].addr_hi, be, dword);
            (`msix_base+2): msix_entry[0].msg_data <= update_dword(msix_entry[0].msg_data, be, dword);
            (`msix_base+3): if (be[0] == 1) msix_entry[0].masked <= unpack(dword[0]);
            (`msix_base+4): msix_entry[1].addr_lo  <= update_dword(msix_entry[1].addr_lo, be, (dword & 32'hfffffffc));
            (`msix_base+5): msix_entry[1].addr_hi  <= update_dword(msix_entry[1].addr_hi, be, dword);
            (`msix_base+6): msix_entry[1].msg_data <= update_dword(msix_entry[1].msg_data, be, dword);
            (`msix_base+7): if (be[0] == 1) msix_entry[1].masked <= unpack(dword[0]);
            (`msix_base+8): msix_entry[2].addr_lo  <= update_dword(msix_entry[2].addr_lo, be, (dword & 32'hfffffffc));
            (`msix_base+9): msix_entry[2].addr_hi  <= update_dword(msix_entry[2].addr_hi, be, dword);
            (`msix_base+10): msix_entry[2].msg_data <= update_dword(msix_entry[2].msg_data, be, dword);
            (`msix_base+11): if (be[0] == 1) msix_entry[2].masked <= unpack(dword[0]);
            (`msix_base+12): msix_entry[3].addr_lo  <= update_dword(msix_entry[3].addr_lo, be, (dword & 32'hfffffffc));
            (`msix_base+13): msix_entry[3].addr_hi  <= update_dword(msix_entry[3].addr_hi, be, dword);
            (`msix_base+14): msix_entry[3].msg_data <= update_dword(msix_entry[3].msg_data, be, dword);
            (`msix_base+15): if (be[0] == 1) msix_entry[3].masked <= unpack(dword[0]);
            (`msix_base+16): msix_entry[4].addr_lo  <= update_dword(msix_entry[4].addr_lo, be, (dword & 32'hfffffffc));
            (`msix_base+17): msix_entry[4].addr_hi  <= update_dword(msix_entry[4].addr_hi, be, dword);
            (`msix_base+18): msix_entry[4].msg_data <= update_dword(msix_entry[4].msg_data, be, dword);
            (`msix_base+19): if (be[0] == 1) msix_entry[4].masked <= unpack(dword[0]);
            (`msix_base+20): msix_entry[5].addr_lo  <= update_dword(msix_entry[5].addr_lo, be, (dword & 32'hfffffffc));
            (`msix_base+21): msix_entry[5].addr_hi  <= update_dword(msix_entry[5].addr_hi, be, dword);
            (`msix_base+22): msix_entry[5].msg_data <= update_dword(msix_entry[5].msg_data, be, dword);
            (`msix_base+23): if (be[0] == 1) msix_entry[5].masked <= unpack(dword[0]);
            (`msix_base+24): msix_entry[6].addr_lo  <= update_dword(msix_entry[6].addr_lo, be, (dword & 32'hfffffffc));
            (`msix_base+25): msix_entry[6].addr_hi  <= update_dword(msix_entry[6].addr_hi, be, dword);
            (`msix_base+26): msix_entry[6].msg_data <= update_dword(msix_entry[6].msg_data, be, dword);
            (`msix_base+27): if (be[0] == 1) msix_entry[6].masked <= unpack(dword[0]);
            (`msix_base+28): msix_entry[7].addr_lo  <= update_dword(msix_entry[7].addr_lo, be, (dword & 32'hfffffffc));
            (`msix_base+29): msix_entry[7].addr_hi  <= update_dword(msix_entry[7].addr_hi, be, dword);
            (`msix_base+30): msix_entry[7].msg_data <= update_dword(msix_entry[7].msg_data, be, dword);
            (`msix_base+31): if (be[0] == 1) msix_entry[7].masked <= unpack(dword[0]);
            (`msix_base+32): msix_entry[8].addr_lo  <= update_dword(msix_entry[8].addr_lo, be, (dword & 32'hfffffffc));
            (`msix_base+33): msix_entry[8].addr_hi  <= update_dword(msix_entry[8].addr_hi, be, dword);
            (`msix_base+34): msix_entry[8].msg_data <= update_dword(msix_entry[8].msg_data, be, dword);
            (`msix_base+35): if (be[0] == 1) msix_entry[8].masked <= unpack(dword[0]);
            (`msix_base+36): msix_entry[9].addr_lo  <= update_dword(msix_entry[9].addr_lo, be, (dword & 32'hfffffffc));
            (`msix_base+37): msix_entry[9].addr_hi  <= update_dword(msix_entry[9].addr_hi, be, dword);
            (`msix_base+38): msix_entry[9].msg_data <= update_dword(msix_entry[9].msg_data, be, dword);
            (`msix_base+39): if (be[0] == 1) msix_entry[9].masked <= unpack(dword[0]);
            (`msix_base+40): msix_entry[10].addr_lo  <= update_dword(msix_entry[10].addr_lo, be, (dword & 32'hfffffffc));
            (`msix_base+41): msix_entry[10].addr_hi  <= update_dword(msix_entry[10].addr_hi, be, dword);
            (`msix_base+42): msix_entry[10].msg_data <= update_dword(msix_entry[10].msg_data, be, dword);
            (`msix_base+43): if (be[0] == 1) msix_entry[10].masked <= unpack(dword[0]);
            (`msix_base+44): msix_entry[11].addr_lo  <= update_dword(msix_entry[11].addr_lo, be, (dword & 32'hfffffffc));
            (`msix_base+45): msix_entry[11].addr_hi  <= update_dword(msix_entry[11].addr_hi, be, dword);
            (`msix_base+46): msix_entry[11].msg_data <= update_dword(msix_entry[11].msg_data, be, dword);
            (`msix_base+47): if (be[0] == 1) msix_entry[11].masked <= unpack(dword[0]);
            (`msix_base+48): msix_entry[12].addr_lo  <= update_dword(msix_entry[12].addr_lo, be, (dword & 32'hfffffffc));
            (`msix_base+49): msix_entry[12].addr_hi  <= update_dword(msix_entry[12].addr_hi, be, dword);
            (`msix_base+50): msix_entry[12].msg_data <= update_dword(msix_entry[12].msg_data, be, dword);
            (`msix_base+51): if (be[0] == 1) msix_entry[12].masked <= unpack(dword[0]);
            (`msix_base+52): msix_entry[13].addr_lo  <= update_dword(msix_entry[13].addr_lo, be, (dword & 32'hfffffffc));
            (`msix_base+53): msix_entry[13].addr_hi  <= update_dword(msix_entry[13].addr_hi, be, dword);
            (`msix_base+54): msix_entry[13].msg_data <= update_dword(msix_entry[13].msg_data, be, dword);
            (`msix_base+55): if (be[0] == 1) msix_entry[13].masked <= unpack(dword[0]);
            (`msix_base+56): msix_entry[14].addr_lo  <= update_dword(msix_entry[14].addr_lo, be, (dword & 32'hfffffffc));
            (`msix_base+57): msix_entry[14].addr_hi  <= update_dword(msix_entry[14].addr_hi, be, dword);
            (`msix_base+58): msix_entry[14].msg_data <= update_dword(msix_entry[14].msg_data, be, dword);
            (`msix_base+59): if (be[0] == 1) msix_entry[14].masked <= unpack(dword[0]);
            (`msix_base+60): msix_entry[15].addr_lo  <= update_dword(msix_entry[15].addr_lo, be, (dword & 32'hfffffffc));
            (`msix_base+61): msix_entry[15].addr_hi  <= update_dword(msix_entry[15].addr_hi, be, dword);
            (`msix_base+62): msix_entry[15].msg_data <= update_dword(msix_entry[15].msg_data, be, dword);
            (`msix_base+63): if (be[0] == 1) msix_entry[15].masked <= unpack(dword[0]);
            //******************************** end of area referenced from xilinx_x7_pcie_wrapper.v
         endcase
      endaction
   endfunction: wr_csr

   // State used to actually service read and write requests

   rule brmMuxResponse;
       let v <- bramMux.bramServer.response.get();
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

   interface Reg tlpTracing    = tlpTracingReg;
   interface Reg tlpTraceLimit = tlpTraceLimitReg;
   interface Reg fromPcieTraceBramWrAddr = fromPcieTraceBramWrAddrReg;
   interface Reg   toPcieTraceBramWrAddr =   toPcieTraceBramWrAddrReg;
   interface BRAMServer fromPcieTraceBramPort = fromPcieTraceBram.portA;
   interface BRAMServer   toPcieTraceBramPort =   toPcieTraceBram.portA;
endmodule: mkAxiControlAndStatusRegs
