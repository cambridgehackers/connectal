
// Copyright (c) 2013,2014 Quanta Research Cambridge, Inc.

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

import GetPut :: *;
import ClientServer :: *;
import Clocks :: *;

////////////////////////////////////////////////////////////////////////////////
/// Typeclass Definition
////////////////////////////////////////////////////////////////////////////////
typeclass ConnectableWithClocks#(type a, type b);
   module mkConnectionWithClocks#(a x1, b x2, Clock fastClock, Reset fastReset, Clock slowClock, Reset slowReset)(Empty);
endtypeclass

instance ConnectableWithClocks#(Get#(a), Put#(a)) provisos (Bits#(a, awidth));
   module mkConnectionWithClocks#(Get#(a) in, Put#(a) out,
                                  Clock inClock, Reset inReset,
                                  Clock outClock, Reset outReset)(Empty) provisos (Bits#(a, awidth));
       SyncFIFOIfc#(a) synchronizer <- mkSyncFIFO(1, inClock, inReset, outClock);
       rule doGet;
           let v <- in.get();
	   synchronizer.enq(v);
       endrule
       rule doPut;
           let v = synchronizer.first;
	   synchronizer.deq;
	   out.put(v);
       endrule
   endmodule: mkConnectionWithClocks
endinstance: ConnectableWithClocks

instance ConnectableWithClocks#(Client#(a,b), Server#(a,b)) provisos (Bits#(a, awidth), Bits#(b, bwidth));
   module mkConnectionWithClocks#(Client#(a,b) client, Server#(a,b) server,
                                  Clock sourceClock, Reset sourceReset,
                                  Clock destClock, Reset destReset)(Empty)
      provisos (ConnectableWithClocks#(Get#(a), Put#(a)),
		ConnectableWithClocks#(Get#(b), Put#(b)),
		Bits#(a, awidth),
		Bits#(b, bwidth));
      mkConnectionWithClocks(client.request, server.request, sourceClock, sourceReset, destClock, destReset);
      mkConnectionWithClocks(server.response, client.response, destClock, destReset, sourceClock, sourceReset);
   endmodule
endinstance

module mkClockBinder#(a ifc) (a);
   return ifc;
endmodule
