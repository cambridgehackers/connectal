



interface Cache;
   interface Put#(CacheRequest) request;
   interface Get#(CacheResponse) response;
endinterface   

// we want to be able to synthesize this, but it has interface parameters
module mkProcessor(Cache cache, Peripherals peripherals)(Processor);
   rule foo;
      cache.request.put(req);
   endrule
   rule bar;
      let response <- cache.response.get();
   endrule
endmodule


// turn the Cache interface inside out
interface CacheInverse;
   interface Get#(CacheRequest) request;
   interface Put#(CacheResponse) response;
endinterface

// provides Cache and CacheInverse
interface CacheLinker;
   interface Cache mod;
   interface CacheInverse inverse;
endinterface

// connects Cache to CacheInverse
module mkCacheLinker;
   FIFO#(CacheRequest) requestFifo <- mkFIFO();
   FIFO#(CacheResponse) responseFifo <- mkFIFO();
   interface mod;
      interface request = toPut(requestFifo);
      interface response = toGet(responseFifo);
   endinterface
   interface inverse;
      interface request = toGet(requestFifo);
      interface response = toPut(responseFifo);
   endinterface
endmodule

// interface used by the linker
interface ProcessorLinkage;
   interface CacheInverse cache;
   interface PeripheralsInverse peripherals;
endinterface
// top level interface of synthesizeable "mkProcessor"
interface ProcessorModule;
   interface Processor mod;
   interface ProcessorLinkage linkage;
endinterface

(* synthesize *)
module mkProcessorModule(ProcessorModule);
   let cacheLinker <- mkCacheLinker;
   let peripheralsLinker <- mkPeripheralsLinker;
   let processor <- mkProcessor(cacheLinker.mod, peripheralsLinker.mod);
   interface mod = processor;
   interface linkage;
      interface cache = cacheLinker.inverse;
      interface peripherals = peripheralsLinker.inverse;
   endinterface
endmodule

// original top level
module mkTopLevel(Pins);
   
   Memory memory <- mkMemory();
   Cache cache <- mkCache(memory);
   Vector#(NumProcessors,Processor) processors <- mkProcessor(cache);
   
   interface pins = memory.pins;
endmodule

// as modified by linker
module mkLinkedTopLevel(Pins);
   
   Peripherals peripherals <- mkPeripherals(); // no interface parameters
   Memory memory <- mkMemory();                // had no interface parameters
   CacheModule cacheModule <- mkCacheModule(); // had interface parameters
   mkConnection(cacheModule.linkage.memory, memory); // connected interface parameters
   
   ProcessorModule processors <- mkProcessorModule(); // had interface parameters
   mkConnection(processor.linkage.cache, cache.mod);  // connect cache parameter
   mkConnection(processor.linkage.peripherals, peripherals); // connect peripherals parameter

   interface pins = memory.pins;
endmodule
