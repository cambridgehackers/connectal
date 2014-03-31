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


module mkAxiDmaSlave#(PhysicalDmaSlave#(addrWidth,dsz) slave) (Axi3Slave#(addrWidth,dsz,12));
   interface Put req_ar;
      method Action put((Axi3ReadRequest#(addrWidth, 12)) req);
	 slave.read_server.readReq.put(PhysicalRequest{paddr:req.address, burstLen:extend(req.len+1),  tag:truncate(req.id)});
      endmethod
   endinterface
   interface Get resp_read;
      method ActionValue#(Axi3ReadResponse#(dsz, 12)) get;
	 let resp <- slave.read_server.readData.get;
	 return Axi3ReadResponse{data:resp.data, resp:0, last:1, id:extend(resp.tag)};
      endmethod
   endinterface
   interface Put req_aw;
      method Action put(Axi3WriteRequest#(addrWidth, 12) req);
	 slave.write_server.writeReq.put(PhysicalRequest{paddr:req.address, burstLen:extend(req.len+1), tag:truncate(req.id)});
      endmethod
   endinterface
   interface Put resp_write;
      method Action put(Axi3WriteData#(dsz, 12) resp);
	 slave.write_server.writeData.put(DmaData{data:resp.data, tag:truncate(resp.id)});
      endmethod
   endinterface
   interface Get resp_b;
      method ActionValue#(Axi3WriteResponse#(12)) get;
	 let rv <- slave.write_server.writeDone.get;
	 return Axi3WriteResponse{resp:0, id:extend(rv)};
      endmethod
   endinterface
endmodule

module mkAxiDmaMaster#(PhysicalDmaMaster#(addrWidth,dsz) master) (Axi3Master#(addrWidth,dsz,6));
   
   Reg#(Bit#(8))  burstReg <- mkReg(0);
   FIFO#(Bit#(8)) reqs <- mkSizedFIFO(32);

   interface Get req_aw;
      method ActionValue#(Axi3WriteRequest#(addrWidth,6)) get();
	 let req <- master.write_client.writeReq.get;
	 reqs.enq(req.burstLen);
	 return Axi3WriteRequest{address:req.paddr, len:truncate(req.burstLen-1), id:req.tag, size: axiBusSize(valueOf(dsz)), burst: 1, prot: 0, cache: 3, lock:0, qos:0};
      endmethod
   endinterface
   interface Get resp_write;
      method ActionValue#(Axi3WriteData#(dsz,6)) get();
	 let tagdata <- master.write_client.writeData.get();
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
	 master.write_client.writeDone.put(resp.id);
      endmethod
   endinterface
   interface Get req_ar;
      method ActionValue#(Axi3ReadRequest#(addrWidth,6)) get();
	 let req <- master.read_client.readReq.get;
	 return Axi3ReadRequest{address:req.paddr, len:truncate(req.burstLen-1), id:req.tag, size: axiBusSize(valueOf(dsz)), burst: 1, prot: 0, cache: 3, lock:0, qos:0};
      endmethod
   endinterface
   interface Put resp_read;
      method Action put(Axi3ReadResponse#(dsz,6) response);
	 master.read_client.readData.put(DmaData { data: response.data, tag: response.id});
      endmethod
   endinterface

endmodule

