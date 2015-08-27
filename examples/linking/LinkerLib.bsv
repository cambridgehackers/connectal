// Generic definitions that should go in a shared library.
typeclass InverseIFC#(type a, type b)
  dependencies (a determines b,
                b determines a);
endtypeclass


interface Inverter#(interface ifcType, interface invifcType);
  interface ifcType mod;
  interface invifcType inverse;
endinterface
    
interface SynthInverter0IFC#(interface ifcType);
  interface ifcType mod;
endinterface
  
interface SynthInverter1IFC#(interface param1, interface ifcType);
  interface param1  arg1;
  interface ifcType mod;
endinterface  
  
interface SynthInverter2IFC#(interface param1, interface param2, interface ifcType);
  interface param1 arg1;
  interface param2 arg2;
  interface ifcType mod;
endinterface    
  
interface SynthInverter3IFC#(interface param1, interface param2, interface param3, interface ifcType);
  interface param1 arg1;
  interface param2 arg2;
  interface param3 arg3;
  interface ifcType mod;
endinterface      
