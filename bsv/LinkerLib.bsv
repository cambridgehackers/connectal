// Copyright (c) 2015 The Connectal Project

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
import GetPut::*;
// Generic definitions that should go in a shared library.
//typeclass InverseIFC#(type a, type b)
  //dependencies (a determines b,
                //b determines a);
//endtypeclass

interface GetInverter#(type a);
   interface Get#(a) mod;
   interface Put#(a) inverse;
endinterface

interface PutInverter#(type a);
   interface Put#(a) mod;
   interface Get#(a) inverse;
endinterface
interface LinkInverter#(type a);
   interface Put#(a) mod;
   interface Get#(a) inverse;
   method Bool modReady();
   method Bool inverseReady();
endinterface

import "BVI" GetInverter =
module mkGetInverterBvi(GetInverter#(Bit#(asz)));
   let asz = valueOf(asz);
   parameter DATA_WIDTH = asz;
   default_clock (CLK);
   default_reset (RST);
   interface Get mod;
      method get get() enable(EN_get) ready (RDY_get);
   endinterface
   interface Put inverse;
      method put(put) enable (EN_put) ready (RDY_put);
   endinterface
   schedule (mod.get, inverse.put) CF (mod.get, inverse.put);
endmodule
module mkGetInverter(GetInverter#(a)) provisos (Bits#(a, asz));
   let inverter <- mkGetInverterBvi();
   interface Get mod;
      method ActionValue#(a) get();
	 let v <- inverter.mod.get();
	 return unpack(v);
      endmethod
   endinterface
   interface Put inverse;
      method Action put(a v);
	 inverter.inverse.put(pack(v));
      endmethod
   endinterface
endmodule

import "BVI" PutInverter =
module mkPutInverterBvi(PutInverter#(Bit#(asz)));
   let asz = valueOf(asz);
   parameter DATA_WIDTH = asz;
   default_clock (CLK);
   default_reset (RST);
   interface Put mod;
      method put(put) enable(EN_put) ready (RDY_put);
   endinterface
   interface Get inverse;
      method get get() enable (EN_get) ready (RDY_get);
   endinterface
   schedule (mod.put, inverse.get) CF (mod.put, inverse.get);
endmodule
module mkPutInverter(PutInverter#(a)) provisos (Bits#(a, asz));
   let inverter <- mkPutInverterBvi();
   interface Put mod;
      method Action put(a v);
	 inverter.mod.put(pack(v));
      endmethod
   endinterface
   interface Get inverse;
      method ActionValue#(a) get();
	 let v <- inverter.inverse.get();
	 return unpack(v);
      endmethod
   endinterface
endmodule

import "BVI" LinkInverter =
module mkLinkInverterBvi(LinkInverter#(Bit#(asz)));
   let asz = valueOf(asz);
   parameter DATA_WIDTH = asz;
   default_clock (CLK);
   default_reset (RST);
   interface Put mod;
      method put(put) enable(EN_put) ready (RDY_put);
   endinterface
   interface Get inverse;
      method get get() enable (EN_get) ready (RDY_get);
   endinterface
   method modReady modReady();
   method inverseReady inverseReady();
   schedule (mod.put, inverse.get, modReady, inverseReady) CF (mod.put, inverse.get, modReady, inverseReady);
endmodule
module mkLinkInverter(LinkInverter#(a)) provisos (Bits#(a, asz));
   let inverter <- mkLinkInverterBvi();
   interface Put mod;
      method Action put(a v);
	 inverter.mod.put(pack(v));
      endmethod
   endinterface
   interface Get inverse;
      method ActionValue#(a) get();
	 let v <- inverter.inverse.get();
	 return unpack(v);
      endmethod
   endinterface
   method Bool modReady();
      return inverter.modReady();
   endmethod
   method Bool inverseReady();
      return inverter.inverseReady();
   endmethod
endmodule
