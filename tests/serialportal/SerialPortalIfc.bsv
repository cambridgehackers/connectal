import RS232::*;

interface SerialPortalRequest;
   method Action setDivisor(Bit#(16) d);
endinterface

interface SerialPortalIndication;
   method Action rx(Bit#(8) c);
endinterface

interface SerialPortalPins;
   interface RS232 uart;
   interface Clock deleteme_unused_clock;
endinterface
   
export RS232(..);
export SerialPortalRequest(..);
export SerialPortalIndication(..);
export SerialPortalPins(..);
