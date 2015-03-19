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
import Vector::*;
import List::*;
import GetPut::*;
import ClientServer::*;
import Assert::*;
import StmtFSM::*;
import SpecialFIFOs::*;
import Connectable::*;

// CONNECTAL Libraries
import MemServer::*;
import MemTypes::*;
import ConnectalMemory::*;
import MMU::*;

interface MemServerCompat#(numeric type addrWidth, numeric type dataWidth, numeric type nMasters);
   interface MemServerRequest request;
   interface Vector#(nMasters,PhysMemMaster#(addrWidth, dataWidth)) masters;
endinterface		 

module mkMemServerCompat#(Vector#(numReadClients, MemReadClient#(dataWidth)) readClients,
			  Vector#(numWriteClients, MemWriteClient#(dataWidth)) writeClients,
			  Vector#(numMMUs,MMU#(addrWidth)) mmus,
			  MemServerIndication indication) (MemServerCompat#(addrWidth, dataWidth, nMasters))
   provisos(Mul#(a__, nMasters, numWriteClients)
	    ,Mul#(b__, nMasters, numReadClients)
	    ,Add#(TLog#(TDiv#(dataWidth, 8)), c__, 8)
	    ,Add#(d__, addrWidth, 64)
	    );

   MemServer#(addrWidth,dataWidth,nMasters,numReadClients,numWriteClients) memServer <- mkMemServer(indication, mmus);
   zipWithM(mkConnection,readClients,memServer.read_servers);
   zipWithM(mkConnection,writeClients,memServer.write_servers);
   interface request = memServer.request;
   interface masters = memServer.masters;
   
endmodule
   


