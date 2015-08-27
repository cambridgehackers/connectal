// To be auto generated from Linking.bsv

import LinkerLib::*;
import Linking::*;
  
//================================================================================
// Parts corresponding to Cache interface

interface CacheInverse;
   interface GetInverse#(CacheRequest)   request;
   interface PutInverse#(CacheResponse) response;
endinterface

instance InverseIFC#(Cache, CacheInverse);

//define how to connect Cache and it's inverse
instance Connectable#(Cache, CacheInverse);
   module mkConnection#(Cache x, CacheInverse y)(Empty);
     mkConnection( x.request,  y.request);
     mkConnection(x.response, y.response);
   endmodule
endinstance  
    
// module to allow Cache Parameter. This needs to have the same schedulign restrictions as the
// initial parameter
module mkCacheParam(Param#(Cache, CacheInverse));
  GetLinked  requestlink <- mkGetParam(); // one for each sub component in Cache interface
  PutLinked responselink <- mkPutParam();
  
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
module mkCacheSynth(SynthParam1IFC#(MemoryInverse, Cache));
  // parameter setup
  let memoryParam <- mkMemoryParam()
  // build base module (use linked version)
  let cache <- mkCacheLink(memoryParam.mod);
  // hook up interface
  interface arg1 = memoryParam.inverse;
  interface mod  = cache;
endmodule

module mkCacheLink#(Memory arg1)(Cache);
  let x <- mkCacheSynth; // It would be great if we could check schedule here. 
  mkConnection(x.arg1, arg1);
  return x.mod;
endmodule
  
  
//=============================================================================================================
// Parts Corresponding to mkProcessor
  
// This is the module we can synthesize
module mkProcessorSynth(SynthParam2IFC#(CacheInverse, PeripheralsInverse, Processor));
   //instantiate param versions of modules
   let cacheparam       <- mkCacheParam();
   let cache = cacheparam.mod;
   let peripheralsparam  <- mkPeripheralsParam();
   let peripherals = peripheralsparam.mod;  
   //instantiate actual module
   let processor <- mkProcessor(cache, peripherals);
   //hook params and return ifc
   interface mod        = processor;
   interface arg1       = cacheparam.inverse;
   interface arg2       = peripheralsparam.inverse;
endmodule
   
module mkProcessorLink(Cache arg1, Peripherals arg2)(Processor);
   let x <- mkProcessorSynth();
   mkConnection(cache, x.arg1);
   mkConnection(peripherals, x.arg2);  
   return x.mod;
endmodule  
    
//====================================================================================================================

module mkTopLevelSynth(SynthParam0IFC#(Pins));
   Memory memory <- mkMemoryLink();
   Cache  cache  <- mkCacheLink(memory); // standard parameter use example

   Vector#(NumProcessors,Processor) processors <- replicateM(mkProcessorLink(cache)); // 
   
   Vector#(NumCaches, Memory) mems <- replicateM(mkMemoryLink);
   Vector#(NumCaches, Cache)  caches <- mapM(mkCacheLink, mems);
  
   interface mod;
     interface pins = memory.pins;  
   endinterface
endmodule
 
module mkTopLevelLink(Pins);
  let x <- mkTopLevelSynth();
  return x.mod;
endmodule
