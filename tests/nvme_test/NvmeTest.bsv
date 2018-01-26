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

`include "ConnectalProjectConfig.bsv"
import Arbitrate::*;
import BRAM::*;
import BuildVector::*;
import Clocks::*;
import Connectable::*;
import FIFOF::*;
import Gearbox::*;
import GetPut::*;
import Probe::*;
import StmtFSM::*;
import Vector::*;

import AddressGenerator::*;
import AxiBits::*;
import AxiStream::*;
import ConnectalClocks::*;
import ConnectalConfig::*;
import DefaultValue::*;
import GearboxGetPut::*;
import HostInterface::*;
import MemReadEngine::*;
import ConnectalMemTypes::*;
import PhysMemSlaveFromBram::*;
import Pipe::*;
import TraceMemClient::*;
import XilinxCells::*;
import MPEngine::*;

import Nvme::*;
import NvmeIfc::*;
import NvmePins::*;

interface NvmeTest;
   interface NvmeRequest request;
   interface NvmeDriverRequest driverRequest;
   interface MemServerPortalRequest bramRequest;
   interface NvmeTrace trace;
   interface NvmePins pins;
   interface Vector#(1, MemReadClient#(DataBusWidth)) dmaReadClient;
   interface Vector#(1, MemWriteClient#(DataBusWidth)) dmaWriteClient;
`ifdef TOP_SOURCES_PORTAL_CLOCK
   interface Clock portalClockSource;
`endif
endinterface

typedef enum {
   Loopback,
   Needle,
   MpNext,
   Clear,
   Opcode,
   StartBlock,
   NumBlocks,
   Start
   } MsgFromSoftwareTag deriving (Bits,Eq);

typedef struct {
   MsgFromSoftwareTag tag;
   Bit#(24)  data;
   } MsgFromSoftware deriving (Bits);

typedef enum {
   Loopback=1,
   LocDone=2,
   TransferDone=3
   } MsgToSoftwareTag deriving (Bits,Eq);

typedef struct {
   MsgToSoftwareTag tag;
   Bit#(24)  data;
   } MsgToSoftware deriving (Bits);


module mkNvmeTest#(NvmeIndication ind, NvmeDriverIndication driverInd, NvmeTrace trace, MemServerPortalIndication bramIndication)(NvmeTest);

   let nvme <- mkNvme(ind, driverInd, trace, bramIndication);

`ifndef NVME_ACCELERATOR_INTERFACE
   Reg#(Bit#(32))                       dataCounter <- mkReg(0);
   FIFOF#(Bit#(32))                  dataLengthFifo <- mkFIFOF();
   FIFOF#(MemDataF#(PcieDataBusWidth))     fifoToMp <- mkFIFOF();
   let                                 needleLenReg <- mkReg(0);

   Reg#(Bool) firstReg <- mkReg(True);
   rule rl_count_data_to_mp;
      let data <- toGet(nvme.dataFromNvme).get();
      if (dataLengthFifo.notEmpty()) begin
	 data.last = (dataCounter+fromInteger(valueOf(PcieDataBusWidth)/8)) >= dataLengthFifo.first;
	 let md = MemDataF {data: data.data, last: data.last, first: firstReg, tag: 0};
	 firstReg <= data.last;
	 fifoToMp.enq(md);
      end
      dataCounter <= dataCounter + 1;
   endrule
`endif

   
   interface NvmeRequest                request = nvme.request;
   interface NvmeDriverRequest    driverRequest = nvme.driverRequest;
   interface MemServerPortalRequest bramRequest = nvme.bramRequest;
   interface NvmeTrace                    trace = nvme.trace;
   interface NvmePins                      pins = nvme.pins;
`ifdef TOP_SOURCES_PORTAL_CLOCK
   interface Clock portalClockSource = nvme.portalClockSource;
`endif
   interface Vector dmaReadClient = nvme.dmaReadClient;
   interface Vector dmaWriteClient = nvme.dmaWriteClient;
endmodule
