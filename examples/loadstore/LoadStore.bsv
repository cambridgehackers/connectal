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

import FIFO            :: *;
import AxiClientServer :: *;
import PortalMemory    :: *;

interface LoadStoreIndication;
    method Action loadValue(Bit#(64) value);
endinterface

interface LoadStoreRequest;
    method Action load(Bit#(40) addr, Bit#(4) length);
    method Action store(Bit#(40) addr, Bit#(64) value);
endinterface

interface LoadStoreRequestInternal;
   interface LoadStoreRequest ifc;
   interface Axi3Client#(40,64,8,12) m_axi;
endinterface

module mkLoadStoreRequestInternal#(LoadStoreIndication ind)(LoadStoreRequestInternal);

    FIFO#(Bit#(40)) readAddrFifo <- mkFIFO;
    FIFO#(Bit#(4)) readLenFifo <- mkFIFO;
    FIFO#(Bit#(40)) writeAddrFifo <- mkFIFO;
    FIFO#(Bit#(64)) writeDataFifo <- mkFIFO;

    interface LoadStoreRequest ifc;
        method Action load(Bit#(40) addr, Bit#(4) len);
    	    readAddrFifo.enq(addr);
	    readLenFifo.enq(len);
	endmethod
        method Action store(Bit#(40) addr, Bit#(64) value);
	    writeAddrFifo.enq(addr);
	    writeDataFifo.enq(value);
	endmethod
    endinterface

    interface Axi3Client m_axi;
	interface Axi3WriteClient write;
	   method ActionValue#(Axi3WriteRequest#(40, 12)) address();
	       writeAddrFifo.deq;
	       return Axi3WriteRequest { address: writeAddrFifo.first, id: 0 };
	   endmethod
	   method ActionValue#(Axi3WriteData#(64, 8, 12)) data();
	       writeDataFifo.deq;
	       return Axi3WriteData { data: writeDataFifo.first, byteEnable: 8'b11111111, last: 1, id: 0 };
	   endmethod
	   method Action response(Axi3WriteResponse#(12) r);
	   endmethod
	endinterface
	interface Axi3ReadClient read;
	   method ActionValue#(Axi3ReadRequest#(40, 12)) address();
	       readAddrFifo.deq;
	       readLenFifo.deq;
	       return Axi3ReadRequest { address: readAddrFifo.first, burstLen: readLenFifo.first, id: 0};
	   endmethod
	   method Action data(Axi3ReadResponse#(64, 12) response);
	       ind.loadValue(response.data);
	   endmethod
	endinterface
    endinterface
endmodule
