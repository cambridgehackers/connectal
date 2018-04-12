// To be auto generated from Linking.bsv

import LinkerLib::*;
import Processor::*;
  
//================================================================================
// Parts corresponding to Cache interface

interface CacheInverse;
   interface GetInverse#(CacheRequest)   request;
   interface PutInverse#(CacheResponse) response;
endinterface

instance InverseIFC#(Cache, CacheInverse);
endinstance

//define how to connect Cache and it's inverse
instance Connectable#(Cache, CacheInverse);
   module mkConnection#(Cache x, CacheInverse y)(Empty);
     mkConnection( x.request,  y.request);
     mkConnection(x.response, y.response);
   endmodule
endinstance  
    
// module to create Cache Inverter. This needs to have the same schedulign restrictions as the
// initial parameter
module mkCacheInverter(Inverter#(Cache, CacheInverse));
  GetInverse  requestlink <- mkGetInverter(); // one for each sub component in Cache interface
  PutInverse responselink <- mkPutInverter();
  
  interface Cache mod;
    interface Get  request = requestlink.mod;
    interface Put response = responselink.mod;  
  endinterface
  
  interface CacheInverse inverse;
    interface GetInverse  request = requestlink.inverse;
    interface PutInverse response = responselink.inverse;  
  endinterface  
endmodule  
    
//================================================================================
// Parts corresponding to mkCache    

//linked version of mkCache. Hooks ups missing memory module
module mkCacheSynth(SynthInverter1IFC#(MemoryInverse, Cache));
  // parameter setup
  let memoryInverter <- mkMemoryInverter();
  // build base module (use original version)
  let cache <- Cache::mkCache(memoryInverter.mod);
  // hook up interface
  interface arg1 = memoryInverter.inverse;
  interface mod  = cache;
endmodule

import "BVI" mkCacheSynth =
module mkCacheBVI(Cache);
//...
endmodule

module mkCache#(Memory arg1)(Cache);
  let x <- mkCacheBVI; // It would be great if we could check schedule here. 
  mkConnection(x.arg1, arg1);
  return x.mod;
endmodule
  
  
//=============================================================================================================
// Parts Corresponding to mkProcessor
  
// This is the module we can synthesize
module mkProcessorSynth(SynthInverter2IFC#(CacheInverse, PeripheralsInverse, Processor));
   //instantiate param versions of modules
   let cacheparam       <- mkCacheInverter();
   let cache = cacheparam.mod;
   let peripheralsparam  <- mkPeripheralsInverter();
   let peripherals = peripheralsparam.mod;  
   //instantiate actual module
   let processor <- Processor::mkProcessor(cache, peripherals);
   //hook params and return ifc
   interface mod        = processor;
   interface arg1       = cacheparam.inverse;
   interface arg2       = peripheralsparam.inverse;
endmodule
   
// to enable separate compilation
import "BVI" mkProcessorSynth =
module mkProcessorBVI(ProcessorBvi);
endmodule

module mkProcessor#(Cache arg1, Peripherals arg2)(Processor);
   let x <- mkProcessorBVI();
   mkConnection(cache, x.arg1);
   mkConnection(peripherals, x.arg2);  
   return x.mod;
endmodule  
    
