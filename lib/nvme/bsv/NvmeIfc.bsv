// Copyright (c) 2016 Connectal Project

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

import AxiStream::*;
import Vector::*;
import ConnectalConfig::*;
`include "ConnectalProjectConfig.bsv"

typedef `PcieDataBusWidth PcieDataBusWidth;

typedef enum { DMA_RX, DMA_TX, DMA_SG } DmaChannel deriving (Bits,Eq);

interface MemServerPortalRequest;
   method Action read(Bit#(32) addr);
   method Action write(Bit#(32) addr, Bit#(DataBusWidth) data);
endinterface

interface MemServerPortalIndication;
   method Action readDone(Bit#(DataBusWidth) data);
   method Action writeDone();
endinterface

typedef enum {
    NvmeFlush = 0,
    NvmeWrite = 1,
    NvmeRead = 2,
    NvmeWriteUncorrectable = 4,
    NvmeCompare = 5,
    NvmeWriteZeros = 8,
    NvmeManageDataset = 9,
    NvmeRegisterReservation = 13,
    NvmeReportReservation = 14,
    NvmeAcquireReservation = 17,
    NvmeReleaseReservation = 21
   }  NvmeOpcode deriving (Bits,Eq,FShow);

interface NvmeRequest;
   method Action startTransfer(Bit#(8) opcode, Bit#(8) flags, Bit#(16) requestId, Bit#(32) startBlock, Bit#(32) numBlocks, Bit#(32) dsm);
   method Action msgFromSoftware(Bit#(32) value, Bit#(1) last);
endinterface

interface NvmeIndication;
   method Action transferCompleted(Bit#(16) requestId, Bit#(64) sc, Bit#(32) cycles);
   method Action msgToSoftware(Bit#(32) value, Bit#(1) last);
endinterface

// internal interfaces
interface NvmeDriverRequest;
   method Action reset(Bit#(8) count);
   method Action nvmeReset(Bit#(8) count);
   method Action setup();
   method Action read32(Bit#(32) addr);
   method Action write32(Bit#(32) addr, Bit#(32) data);
   method Action read64(Bit#(32) addr);
   method Action write64(Bit#(32) addr, Bit#(64) data);
   method Action read128(Bit#(32) addr);
   method Action write128(Bit#(32) addr, Bit#(64) udata, Bit#(64) ldata);
   method Action read(Bit#(32) addr);
   method Action write(Bit#(32) addr, Bit#(DataBusWidth) data);
   method Action readCtl(Bit#(32) addr);
   method Action writeCtl(Bit#(32) addr, Bit#(DataBusWidth) data);
   method Action status();
   method Action trace(Bool enabled);
endinterface

interface NvmeDriverIndication;
   method Action setupDone();
   method Action readDone(Bit#(DataBusWidth) data);
   method Action writeDone();
   method Action status(Bit#(1) mmcm_lock, Bit#(32) dataCounter);
   method Action setupComplete();
endinterface

interface NvmeTrace;
   method Action traceDmaRequest(DmaChannel channel, Bool write, Bit#(16) objId, Bit#(32) offset, Bit#(16) burstLen, Bit#(8) tag, Bit#(32) timestamp);
   method Action traceDmaData(DmaChannel channel, Bool write, Vector#(TDiv#(PcieDataBusWidth,32),Bit#(32)) data, Bool last, Bit#(8) tag, Bit#(32) timestamp);
   method Action traceDmaDone(DmaChannel channel, Bit#(8) tag, Bit#(32) timestamp);
   method Action traceData(Vector#(TDiv#(PcieDataBusWidth,32),Bit#(32)) data, Bool last, Bit#(8) tag, Bit#(32) timestamp);
endinterface

typedef struct {
   Bit#(8)  opcode;
   Bit#(8)  flags;
   Bit#(16) requestId;
   Bit#(32) startBlock;
   Bit#(32) numBlocks;
   Bit#(32) dsm;
   } NvmeIoCommand deriving (Bits);

typedef struct {
   Bit#(16) requestId;
   Bit#(16) statusCode;
   Bit#(16) statusCodeType;
   } NvmeIoResponse deriving (Bits);

// these ports exposed to a verilog wrapper module
interface NvmeAccelerator;
   interface AxiStreamMaster#(32) msgFromSoftware;
   interface AxiStreamSlave#(32) msgToSoftware;
   interface AxiStreamMaster#(PcieDataBusWidth) dataFromNvme;
   interface AxiStreamSlave#(PcieDataBusWidth) dataToNvme;
   interface AxiStreamSlave#(SizeOf#(NvmeIoCommand)) request;
   interface AxiStreamMaster#(SizeOf#(NvmeIoResponse)) response;
   interface Clock clock;
   interface Reset reset;
endinterface

interface NvmeAcceleratorClient;
   interface AxiStreamSlave#(32) msgFromSoftware;
   interface AxiStreamMaster#(32) msgToSoftware;
   interface AxiStreamSlave#(PcieDataBusWidth) dataFromNvme;
   interface AxiStreamMaster#(PcieDataBusWidth) dataToNvme;
   interface AxiStreamMaster#(SizeOf#(NvmeIoCommand)) request;
   interface AxiStreamSlave#(SizeOf#(NvmeIoResponse)) response;
endinterface
