import Processor_Generated::*;

//====================================================================================================================

module mkProcessorTop(Pins);
   Memory memory <- mkMemory();
   Cache  cache  <- mkCache(memory); // actually uses the wrapper from Processor_Generated.bsv

   Vector#(NumProcessors,Processor) processors <- replicateM(mkProcessor(cache)); // same here

   Vector#(NumCaches, Memory) mems <- replicateM(mkMemory);
   Vector#(NumCaches, Cache)  caches <- mapM(mkCache, mems); // and here

   interface mod;
     interface Pins pins = memory.pins;
   endinterface
endmodule
