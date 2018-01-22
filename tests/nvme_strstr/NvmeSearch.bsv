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
import StringSearchIfc::*;

interface NvmeSearch;
   interface NvmeRequest request;
   interface NvmeDriverRequest driverRequest;
   interface MemServerPortalRequest bramRequest;
   interface StringSearchRequest searchRequest;
   interface NvmeTrace trace;
   interface NvmePins pins;
   interface Vector#(2, MemReadClient#(DataBusWidth)) dmaReadClient;
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


(* synthesize *)
module mkSearchAcceleratorClient(NvmeAcceleratorClient);
   Reg#(Bit#(32))                       dataCounter <- mkReg(0);
   FIFOF#(Bit#(32))                  dataLengthFifo <- mkFIFOF();
   Reg#(Bit#(24))                      needleLenReg <- mkReg(0);
   MPStreamEngine#(PcieDataBusWidth,DataBusWidth)    mpEngine <- mkMPStreamEngine();

   FIFOF#(MemData#(32)) msgFromSoftwareFifo <- mkFIFOF();
   FIFOF#(MemData#(32)) msgToSoftwareFifo <- mkFIFOF();
   FIFOF#(MemDataF#(PcieDataBusWidth)) dataFromNvmeFifo <- mkFIFOF();
   FIFOF#(MemDataF#(PcieDataBusWidth)) dataToNvmeFifo <- mkFIFOF();
   FIFOF#(Bit#(SizeOf#(NvmeIoCommand))) requestFifo <- mkFIFOF();
   FIFOF#(Bit#(SizeOf#(NvmeIoResponse))) responseFifo <- mkFIFOF();

   mkConnection(toPipeOut(dataFromNvmeFifo), mpEngine.haystack);

   Reg#(Bit#(8)) opcode <- mkReg(extend(pack(NvmeRead)));
   Reg#(Bit#(32)) startBlock <- mkReg(0);
   Reg#(Bit#(32))  numBlocks <- mkReg(0);
   Reg#(Bit#(16)) requestId <- mkReg(0);

   let inmsgTagProbe <- mkProbe();
   let inmsgDataProbe <- mkProbe();
   let outmsgTagProbe <- mkProbe();
   let outmsgDataProbe <- mkProbe();
   let responseProbe <- mkProbe();
   rule rl_msg_from_software;
      let md <- toGet(msgFromSoftwareFifo).get();
      MsgFromSoftware msg = unpack(truncate(md.data));
      inmsgTagProbe <= msg.tag;
      inmsgDataProbe <= msg.data;
      case (msg.tag) matches
	 Loopback: begin
		      MsgToSoftware outmsg = MsgToSoftware { tag: Loopback, data: msg.data };
		      outmsgTagProbe <= outmsg.tag;
		      outmsgDataProbe <= outmsg.data;
		      msgToSoftwareFifo.enq(MemData { data: extend(pack(outmsg)), last: md.last });
		   end
	 Needle: mpEngine.needle.enq(MemDataF { data: extend(msg.data), first: False, last: md.last, tag: 0 });
	 MpNext: mpEngine.mpNext.enq(MemDataF { data: extend(msg.data), first: False, last: md.last, tag: 0 });
	 Clear:  mpEngine.clear();
	 Opcode:         opcode <= truncate(msg.data);
	 StartBlock: startBlock <= extend(msg.data);
	 NumBlocks:   numBlocks <= extend(msg.data);
	 Start: begin
		   mpEngine.start(extend(msg.data));
		   needleLenReg <= msg.data;
		   requestFifo.enq(pack(NvmeIoCommand {
		      opcode: opcode,
		      flags: 0,
		      requestId: requestId,
		      startBlock: extend(startBlock),
		      numBlocks: numBlocks,
		      dsm: 'h71 // FIXME copied value from nvme.cpp, but where did this come from?
		      }));
		   requestId <= requestId + 1;
		end
      endcase
   endrule
   rule rl_response;
      let r <- toGet(responseFifo).get();
      NvmeIoResponse response = unpack(r);
      Bit#(8) sct = truncate(response.statusCodeType);
      responseProbe <= response.statusCode;
      
      MsgToSoftware outmsg = MsgToSoftware { tag: TransferDone, data: { sct, response.statusCode }};
      outmsgTagProbe <= outmsg.tag;
      outmsgDataProbe <= outmsg.data;
      msgToSoftwareFifo.enq(MemData { data: extend(pack(outmsg)), last: True });
   endrule
   rule rl_match;
      let loc <- toGet(mpEngine.locdone).get();
      MsgToSoftware outmsg = MsgToSoftware { tag: LocDone, data: truncate(pack(loc)) };
      outmsgTagProbe <= outmsg.tag;
      outmsgDataProbe <= outmsg.data;
      msgToSoftwareFifo.enq(MemData { data: extend(pack(outmsg)), last: (loc == -1) });
   endrule

   AxiStreamSlave#(32) msgFromSoftwareStream <- mkAxiStream(msgFromSoftwareFifo);
   AxiStreamMaster#(32) msgToSoftwareStream <- mkAxiStream(msgToSoftwareFifo);
   AxiStreamSlave#(PcieDataBusWidth) dataFromNvmeStream <- mkAxiStream(dataFromNvmeFifo);
   AxiStreamMaster#(PcieDataBusWidth) dataToNvmeStream <- mkAxiStream(dataToNvmeFifo);
   AxiStreamMaster#(SizeOf#(NvmeIoCommand)) requestStream <- mkAxiStream(requestFifo);
   AxiStreamSlave#(SizeOf#(NvmeIoResponse)) responseStream <- mkAxiStream(responseFifo);

   interface AxiStreamSlave msgFromSoftware = msgFromSoftwareStream;
   interface AxiStreamMaster msgToSoftware = msgToSoftwareStream;
   interface AxiStreamSlave dataFromNvme = dataFromNvmeStream;
   interface AxiStreamMaster dataToNvme = dataToNvmeStream;
   interface AxiStreamMaster request = requestStream;
   interface AxiStreamSlave response = responseStream;

endmodule

module mkNvmeSearch#(NvmeIndication ind, NvmeDriverIndication driverInd, NvmeTrace trace, MemServerPortalIndication bramIndication,
	       StringSearchResponse searchIndication)(NvmeSearch);

   let nvme <- mkNvme(ind, driverInd, trace, bramIndication);

   MemReadEngine#(DataBusWidth,DataBusWidth,2,3) re <- mkMemReadEngine();

`ifndef NVME_ACCELERATOR_INTERFACE
   Reg#(Bit#(32))                       dataCounter <- mkReg(0);
   FIFOF#(Bit#(32))                  dataLengthFifo <- mkFIFOF();
   FIFOF#(MemDataF#(PcieDataBusWidth))     fifoToMp <- mkFIFOF();
   let                                 needleLenReg <- mkReg(0);
   MPStreamEngine#(PcieDataBusWidth,DataBusWidth)    mpEngine <- mkMPStreamEngine();
   mkConnection(re.readServers[0].data, mpEngine.needle);
   mkConnection(re.readServers[1].data, mpEngine.mpNext);
   mkConnection(toPipeOut(fifoToMp), mpEngine.haystack);

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
	 
   rule rl_locdone;
      let loc <- toGet(mpEngine.locdone).get();
      searchIndication.strstrLoc(pack(loc));
   endrule
`endif

   interface NvmeRequest                request = nvme.request;
   interface NvmeDriverRequest    driverRequest = nvme.driverRequest;
   interface MemServerPortalRequest bramRequest = nvme.bramRequest;
   interface NvmeTrace                    trace = nvme.trace;
   interface NvmePins                      pins = nvme.pins;
   interface StringSearchRequest searchRequest;
      method Action setSearchString(Bit#(32) needleSglId, Bit#(32) mpNextSglId, Bit#(32) needleLen);
`ifndef NVME_ACCELERATOR_INTERFACE
	 mpEngine.clear();
	 needleLenReg <= needleLen;
   
	 let burstLen = fromInteger(valueOf(DataBusWidth)/8);
	 let mask = burstLen - 1;
	 needleLen = (needleLen + mask) & ~mask;
	 re.readServers[0].request.put(MemengineCmd {sglId: needleSglId, base: 0, burstLen: burstLen, len: needleLen, tag: 0});
	 re.readServers[1].request.put(MemengineCmd {sglId: mpNextSglId, base: 0, burstLen: burstLen, len: needleLen*4, tag: 0});
`endif
      endmethod
      method Action startSearch(Bit#(32) haystackLen);
`ifndef NVME_ACCELERATOR_INTERFACE
	 mpEngine.start(needleLenReg);
	 dataLengthFifo.enq(haystackLen);
`endif
      endmethod
   endinterface
`ifdef TOP_SOURCES_PORTAL_CLOCK
   interface Clock portalClockSource = nvme.portalClockSource;
`endif
   interface Vector dmaReadClient = append(nvme.dmaReadClient, vec(re.dmaClient));
   interface Vector dmaWriteClient = nvme.dmaWriteClient;
endmodule
