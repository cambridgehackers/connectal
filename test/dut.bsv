
// Device Under Test
interface DUT;
    method Action put(Bit#(32) a, Bit#(32) b);
    method ActionValue#(Bit#(32)) get();
endinterface
