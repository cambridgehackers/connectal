interface Say;
    method Action say(Bit#(32) v);
    method Action say2(Bit#(16) a, Bit#(16) b);
endinterface

module mkSay#(Say saySW)(Say);
   
   method Action say(Bit#(32) v);
      saySW.say(v);
   endmethod
   
   method Action say2(Bit#(16) a, Bit#(16) b);
      saySW.say2(a,b);
   endmethod

endmodule