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
import Clocks::*;
import Vector::*;
import BuildVector::*;
import GetPut::*;
import Connectable::*;
import ClientServer::*;
import ConnectalMemory::*;
import ConnectalBramFifo::*;
import FIFOF::*;
import ConnectalMemTypes::*;
import MemReadEngine::*;
import MemWriteEngine::*;
import Pipe::*;
import AxiDdr3Controller::*;
import GetPutWithClocks::*;
import AxiMasterSlave::*;
import Axi4MasterSlave::*;
import AxiDdr3Wrapper  ::*;
import AxiDma::*;
import ConnectalConfig::*;
import HostInterface::*;
import Probe::*;
import Axi4::*;

module mkDdrAws#(Ddr3TestIndication ind)(DdrAws);

   Reg#(Bool) flying <- mkReg(False);

   FIFOF#(Axi4ReadRequest#(DdrAddrWidth, DdrIdWidth)) fifo_req_ar <- mkFIFOF();
   FIFOF#(Axi4ReadResponse#(DdrBusWidth, DdrIdWidth)) fifo_resp_read <- mkFIFOF();
   FIFOF#(Axi4WriteRequest#(DdrAddrWidth, DdrIdWidth)) fifo_req_aw <- mkFIFOF();
   FIFOF#(Axi4WriteData#(DdrBusWidth, DdrIdWidth)) fifo_resp_write <- mkFIFOF();
   FIFOF#(Axi4WriteResponse#(DdrIdWidth)) fifo_resp_b <- mkFIFOF();


   let aximaster = (interface Axi4Master;
       		   	      interface req_ar = toGet(fifo_req_ar);
			      interface resp_read = toPut(fifo_resp_read);
			      interface req_aw = toGet(fifo_req_aw);
			      interface resp_write = toGet(fifo_resp_write);
			      interface resp_b = toPut(fifo_resp_b);
		endinterface);

   Axi4 ddr3bits <- mkAxi4MasterBitsEmpty(aximaster);

   rule gotRead;
   	fifo_resp_read.deq();
	let respread  = fifo_resp_read.first();
	let resp = respread.data;
	let id = respread.id;
	let last = respread.last;
	let error = respread.resp;
	if (error != 0 || last != 1) begin
	   ind.error(zeroExtend(error),zeroExtend(id));
	end
	flying <= False;
	ind.readDone(id,resp[31:0],resp[63:32],resp[95:64],resp[127:96],
		     resp[159:128],resp[191:160],resp[223:192],resp[255:224],
		     resp[287:256],resp[319:288],resp[351:320],resp[383:352],
		     resp[415:384],resp[447:416],resp[479:448],resp[511:480]);
   endrule

   rule gotWrite;
   	fifo_resp_b.deq();
	let resp = fifo_resp_b.first();
	let error = resp.resp;
	let id = resp.id;
	flying <= False;
	if (error != 0) begin
	   ind.error(zeroExtend(error), zeroExtend(id));
	end
	ind.writeDone(zeroExtend(id));
   endrule

// len = nb pack512 -1
// size axiBusSize
// burst: 1
// prot: 0
// cache:3
// lock: 0
// qos: 0
// resp: 0 if no error
// last: 1 for the last burst.

   interface Ddr3TestRequest request;
      method Action startWriteDram(Bit#(16) id, Bit#(64) address,
         	  	 	  Bit#(32) v1, Bit#(32) v2, Bit#(32) v3, Bit#(32) v4,
				  Bit#(32) v5, Bit#(32) v6,Bit#(32) v7, Bit#(32) v8,
			  	  Bit#(32) v9, Bit#(32) v10, Bit#(32) v11, Bit#(32) v12,
 				  Bit#(32) v13, Bit#(32) v14, Bit#(32) v15, Bit#(32) v16) if (!flying);
      	     flying <= True;
	     fifo_req_aw.enq(Axi4WriteRequest{address: address,
	     				      len: 0,
					      size: 6,
					      burst: 1,
					      prot: 0,
					      cache: 3,
					      id: id,
					      lock: 0,
					      qos: 0
					      });
	     fifo_resp_write.enq(Axi4WriteData{data: {v16,v15,v14,v13,v12,v11,v10,v9,v8,v7,v6,v5,v4,v3,v2,v1},
	     				       byteEnable: maxBound,
					       last: 1,
					       id: id});
      endmethod

      method Action startReadDram(Bit#(16) id, Bit#(64) address) if (!flying);
      	     flying <= True;
	     fifo_req_ar.enq(Axi4ReadRequest{address: address,
	     				     len: 0,
					     size: 6,
					     burst: 1,
					     prot: 0,
					     cache: 3,
					     id: id,
					     lock: 0,
					     qos: 0
					     });
      endmethod
   endinterface

   interface ddr3 = ddr3bits;
endmodule
