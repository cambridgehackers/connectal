// Copyright (c) 2013 Quanta Research Cambridge, Inc.

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

// BSV Libraries
import FIFO::*;
import GetPut::*;
import ClientServer::*;

// XBSV Libraries
import AxiMasterSlave::*;
import Dma::*;
import PortalMemory::*;


module mkAxiDmaServer#(PhysicalReadClient#(addrWidth,dsz) readClient,
		       PhysicalWriteClient#(addrWidth,dsz) writeClient) (Axi3Master#(addrWidth,dsz,6));
   
   Reg#(Bit#(8))  burstReg <- mkReg(0);
   FIFO#(Bit#(8)) reqs <- mkSizedFIFO(32);

   interface Get req_aw;
      method ActionValue#(Axi3WriteRequest#(addrWidth,6)) get();
	 let req <- writeClient.writeReq.get;
	 reqs.enq(req.burstLen);
	 return Axi3WriteRequest{address:req.paddr, len:truncate(req.burstLen-1), id:req.tag, size: axiBusSize(valueOf(dsz)), burst: 1, prot: 0, cache: 3, lock:0, qos:0};
      endmethod
   endinterface
   interface Get resp_write;
      method ActionValue#(Axi3WriteData#(dsz,6)) get();
	 let tagdata <- writeClient.writeData.get();
	 let burstLen = burstReg;
	 if (burstLen == 0)
	    burstLen = reqs.first;
	 if (burstLen == 1)
	    reqs.deq;
	 burstReg <= burstLen-1;
	 Bit#(1) last = burstLen == 1 ? 1'b1 : 1'b0;
	 return Axi3WriteData { data: tagdata.data, byteEnable: maxBound, last: last, id: tagdata.tag };
      endmethod
   endinterface
   interface Put resp_b;
      method Action put(Axi3WriteResponse#(6) resp);
	 writeClient.writeDone.put(resp.id);
      endmethod
   endinterface
   interface Get req_ar;
      method ActionValue#(Axi3ReadRequest#(addrWidth,6)) get();
	 let req <- readClient.readReq.get;
	 return Axi3ReadRequest{address:req.paddr, len:truncate(req.burstLen-1), id:req.tag, size: axiBusSize(valueOf(dsz)), burst: 1, prot: 0, cache: 3, lock:0, qos:0};
      endmethod
   endinterface
   interface Put resp_read;
      method Action put(Axi3ReadResponse#(dsz,6) response);
	 readClient.readData.put(DmaData { data: response.data, tag: response.id});
      endmethod
   endinterface

endmodule

