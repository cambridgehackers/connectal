interface Cache;
   interface Put#(CacheRequest) request;
   interface Get#(CacheResponse) response;
endinterface   

// we want to be able to synthesize this, but it has interface parameters
module mkProcessor#(Cache cache, Peripherals peripherals)(Processor);
   rule foo;
      cache.request.put(req);
   endrule
   rule bar;
      let response <- cache.response.get();
   endrule
endmodule

// original top level
module mkTopLevel(Pins);
   Memory memory <- mkMemory();
   Cache  cache  <- mkCache(memory); // standard parameter use example

   Vector#(NumProcessors,Processor) processors <- replicateM(mkProcessor(cache)); // 
   
   Vector#(NumCaches, Memory) mems <- replicateM(mkMemory);
   Vector#(NumCaches, Cache)  caches <- mapM(mkCache, mems);
  
   interface pins = memory.pins;
endmodule
