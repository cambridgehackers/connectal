// Generic definitions that should go in a shared library.
typeclass InverseIFC#(type a, type b)
  dependencies (a determines b,
                b determines a);
endtypeclass


interface GetInverse#(type a);
   interface Get#(a) mod;
   interface Put#(a) inverse;
endinterface

interface PutInverse#(type a);
   interface Put#(a) mod;
   interface Get#(a) inverse;
endinterface

import "BVI" GetInverse =
module mkGetInverseBvi(GetInverse#(Bits#(asz)));
   parameter DATA_SIZE = asz;
   default_clock (CLK);
   default_reset (RST);
   interface Get mod;
      method get get() enable(EN_get) ready (RDY_get);
   endinterface
   interface Put inverse;
      method put(put) enable (EN_put) ready (RDY_put);
   endinterface
endmodule
module mkGetInverse(GetInverse#(a)) provisos (Bits#(a, asz));
   inverter <- mkGetInverseBvi();
   interface Get mod;
      method a get();
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

import "BVI" PutInverse =
module mkPutInverseBvi(PutInverse#(Bits#(asz)));
   parameter DATA_SIZE = asz;
   default_clock (CLK);
   default_reset (RST);
   interface Put mod;
      method put(put) enable(EN_put) ready (RDY_put);
   endinterface
   interface Get inverse;
      method get get() enable (EN_get) ready (RDY_get);
   endinterface
endmodule
module mkPutInverse(PutInverse#(a)) provisos (Bits#(a, asz));
   inverter <- mkPutInverseBvi();
   interface Put mod;
      method Action put(a v);
	 inverter.mod.put(pack(v));
      endmethod
   endinterface
   interface Get inverse;
      method a get();
	 let v <- inverter.inverse.get();
	 return unpack(v);
      endmethod
   endinterface
endmodule

interface Inverter#(type ifcType, type invifcType);
  interface ifcType mod;
  interface invifcType inverse;
endinterface
    
interface SynthInverter0IFC#(type ifcType);
  interface ifcType mod;
endinterface
  
interface SynthInverter1IFC#(type param1, type ifcType);
  interface param1  arg1;
  interface ifcType mod;
endinterface  
  
interface SynthInverter2IFC#(type param1, type param2, type ifcType);
  interface param1 arg1;
  interface param2 arg2;
  interface ifcType mod;
endinterface    
  
interface SynthInverter3IFC#(type param1, type param2, type param3, type ifcType);
  interface param1 arg1;
  interface param2 arg2;
  interface param3 arg3;
  interface ifcType mod;
endinterface     
