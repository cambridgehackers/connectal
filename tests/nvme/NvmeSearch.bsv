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
import MemTypes::*;
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

module mkNvmeSearch#(NvmeIndication ind, NvmeDriverIndication driverInd, NvmeTrace trace, MemServerPortalIndication bramIndication,
	       StringSearchResponse searchIndication)(NvmeSearch);

   let nvme <- mkNvme(ind, driverInd, trace, bramIndication);

   Reg#(Bit#(32))                       dataCounter <- mkReg(0);
   FIFOF#(Bit#(32))                  dataLengthFifo <- mkFIFOF();
   let                                     fifoToMp <- mkFIFOF();
   let                                 needleLenReg <- mkReg(0);
   MemReadEngine#(DataBusWidth,DataBusWidth,2,3) re <- mkMemReadEngine();
   MPStreamEngine#(PcieDataBusWidth,DataBusWidth)    mpEngine <- mkMPStreamEngine();
   mkConnection(re.readServers[0].data, mpEngine.needle);
   mkConnection(re.readServers[1].data, mpEngine.mpNext);
   mkConnection(toPipeOut(fifoToMp), mpEngine.haystack);

   rule rl_count_data_to_mp;
      let data <- toGet(nvme.dataOut).get();
      if (dataLengthFifo.notEmpty()) begin
	 data.last = (dataCounter+fromInteger(valueOf(PcieDataBusWidth)/8)) >= dataLengthFifo.first;
	 let md = MemDataF {data: data.data, last: data.last};
	 fifoToMp.enq(md);
      end
      dataCounter <= dataCounter + 1;
   endrule

   rule rl_locdone;
      let loc <- toGet(mpEngine.locdone).get();
      searchIndication.strstrLoc(pack(loc));
   endrule

   interface MemServerPortalRequest bramRequest = nvme.bramRequest;
   interface NvmeDriverRequest      driverRequest = nvme.driverRequest;
   interface StringSearchRequest searchRequest;
      method Action setSearchString(Bit#(32) needleSglId, Bit#(32) mpNextSglId, Bit#(32) needleLen);
	 mpEngine.clear();
	 needleLenReg <= needleLen;
   
	 let burstLen = fromInteger(valueOf(DataBusWidth)/8);
	 let mask = burstLen - 1;
	 needleLen = (needleLen + mask) & ~mask;
	 re.readServers[0].request.put(MemengineCmd {sglId: needleSglId, base: 0, burstLen: burstLen, len: needleLen, tag: 0});
	 re.readServers[1].request.put(MemengineCmd {sglId: mpNextSglId, base: 0, burstLen: burstLen, len: needleLen*4, tag: 0});
      endmethod
      method Action startSearch(Bit#(32) haystackLen);
	 mpEngine.start(needleLenReg);
	 dataLengthFifo.enq(haystackLen);
      endmethod
   endinterface
   interface Clock portalClockSource = nvme.portalClockSource;
   interface NvmePins           pins = nvme.pins;
   interface Vector dmaReadClient = append(nvme.dmaReadClient, vec(re.dmaClient));
   interface Vector dmaWriteClient = nvme.dmaWriteClient;
endmodule
