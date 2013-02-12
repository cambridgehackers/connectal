

interface Get#(type a);
    method ActionValue#(a) get();
endinterface

interface Put#(type a);
    method Action put(a v);
endinterface
