interface Say;
    method Action say(Bit#(32) v);
    method Action say2(Bit#(16) a, Bit#(16) b);
endinterface

module mkSay#(Say indication)(Say);
   
   method Action say(Bit#(32) v);
      //$display("mkSay::say(%h)", v);
      indication.say(v);
   endmethod
   
   method Action say2(Bit#(16) a, Bit#(16) b);
      //$display("mkSay::say(%h,%h)", a,b);
      indication.say2(a,b);
   endmethod

endmodule