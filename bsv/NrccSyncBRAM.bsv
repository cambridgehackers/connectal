// Copyright (c) 2013 Nokia, Inc.

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

import RegFile::*;
import FIFO::*;

interface BRAM#(type idx_type, type data_type);
  method Action readAddr(idx_type idx);
  method ActionValue#(data_type) readData();
  method Action	write(idx_type idx, data_type data);
endinterface

interface SyncBRAMBVI#(type idx_type, type data_type);
  method Action	portAReq(Bit#(1) we, idx_type idx, data_type data);
  method data_type portAReadData();

  method Action	portBReq(Bit#(1) we, idx_type idx, data_type data);
  method data_type portBReadData();
endinterface

interface SyncBRAM#(type idx_type, type data_type);
    interface BRAM#(idx_type, data_type) portA;
    interface BRAM#(idx_type, data_type) portB;
endinterface

import "BVI" NRCCBRAM2 = module mkSyncBRAMBVI#(Integer memsize, Clock clkA, Reset rstA, Clock clkB, Reset rstB) 
  //interface:
              (SyncBRAMBVI#(idx_type, data_type))
  provisos
          (Bits#(idx_type, idx), 
	   Bits#(data_type, data),
	   Literal#(idx_type));

  parameter ADDR_WIDTH = valueof(idx);
  parameter DATA_WIDTH = valueof(data);
  parameter MEMSIZE = memsize;
  parameter PIPELINED = 0;

  input_clock (CLKA, (*inhigh*)GATE) = clkA;
  input_clock (CLKB, (*inhigh*)GATE) = clkB;
  default_clock clkA;
  input_reset (RSTA_N) clocked_by (clkA) = rstA;
  input_reset (RSTB_N) clocked_by (clkB) = rstB;
  default_reset rstA;

  method DOA portAReadData() ready (DRA) clocked_by(clkA) reset_by (rstA);
  method portAReq(WEA, ADDRA, DIA) enable(ENA) clocked_by(clkA) reset_by (rstA);

  method portBReq(WEB, ADDRB, DIB) enable(ENB) clocked_by(clkB) reset_by (rstB);
  method DOB portBReadData() ready (DRB) clocked_by(clkB) reset_by (rstB);

  schedule portAReadData  CF (portAReadData, portAReq);
  schedule portAReq      CF (portAReadData);
  
  schedule portAReq     C portAReq;

  schedule portBReadData  CF (portBReadData, portBReq);
  schedule portBReq     CF (portBReadData);

  schedule portBReq     C portBReq;

endmodule

module mkSyncBRAM#(Integer memsize, Clock clkA, Reset resetA, Clock clkB, Reset resetB)
                  (SyncBRAM#(idx_type, data_type))
                  provisos(Bits#(idx_type, idxbits),
                           Literal#(idx_type),
                           Bits#(data_type, databits),
                           Add#(1, z, databits));
    SyncBRAMBVI#(idx_type, data_type) syncBRAMBVI <- mkSyncBRAMBVI(memsize, clkA, resetA, clkB, resetB);

    interface BRAM portA;
        method Action readAddr(idx_type idx);
            syncBRAMBVI.portAReq(0, idx, unpack(0));
        endmethod
        method ActionValue#(data_type) readData();
            return syncBRAMBVI.portAReadData();
        endmethod
        method Action write(idx_type idx, data_type data);
            syncBRAMBVI.portAReq(1, idx, data);
        endmethod
    endinterface
    interface BRAM portB;
        method Action readAddr(idx_type idx);
            syncBRAMBVI.portBReq(0, idx, unpack(0));
        endmethod
        method ActionValue#(data_type) readData();
            return syncBRAMBVI.portBReadData();
        endmethod
        method Action write(idx_type idx, data_type data);
            syncBRAMBVI.portBReq(1, idx, data);
        endmethod
    endinterface
endmodule

typedef enum {
        Idle, Read, Write
} Op deriving (Bits);

module mkSimSyncBRAM#(Integer memsize, Clock clkA, Reset resetA, Clock clkB, Reset resetB)
                  (SyncBRAM#(idx_type, data_type))
                  provisos(Bits#(idx_type, idxbits),
                           Bounded#(idx_type),
                           Literal#(idx_type),
                           Bits#(data_type, databits),
                           Literal#(data_type),
                           Add#(1, z, databits));
    RegFile#(idx_type, data_type) rf <- mkRegFileFull;

    FIFO#(idx_type) aAddr <- mkFIFO(clocked_by clkA, reset_by resetA);
    Reg#(Op) aOp <- mkReg(Idle, clocked_by clkA, reset_by resetA);
    FIFO#(idx_type) bAddr <- mkFIFO(clocked_by clkA, reset_by resetA);
    Reg#(Op) bOp <- mkReg(Idle, clocked_by clkA, reset_by resetA);

    interface BRAM portA;
        method Action readAddr(idx_type idx);
            aAddr.enq(idx);
            aOp <= Read;
        endmethod
        method ActionValue#(data_type) readData() if (aOp matches Read);
            aAddr.deq;
            return rf.sub(aAddr.first);
        endmethod
        method Action write(idx_type idx, data_type data);
            rf.upd(idx, data);
        endmethod
    endinterface
    interface BRAM portB;
        method Action readAddr(idx_type idx);
            bAddr.enq(idx);
            bOp <= Read;
        endmethod
        method ActionValue#(data_type) readData() if (bOp matches Read);
            bAddr.deq;
            return rf.sub(bAddr.first);
        endmethod
        method Action write(idx_type idx, data_type data);
            rf.upd(idx, data);
        endmethod
    endinterface
endmodule
