// bsv libraries
import SpecialFIFOs::*;
import Vector::*;
import StmtFSM::*;
import FIFO::*;
import Connectable::*;
import FloatingPoint::*;
import ClientServer::*;
import GetPut::*;
import DefaultValue::*;

// portz libraries
import RbmTypes::*;
import FpMac::*;
import FloatOps::*;

interface FpMacRequest;
   method Action mac(Bit#(32) x, Bit#(32) y);
endinterface

interface FpMacIndication;
   method Action res(Bit#(32) v, Bit#(32) e);
endinterface

module mkFpMacRequest#(FpMacIndication indication) (FpMacRequest);
   
   let fpmac <- mkFloatMac(Rnd_Nearest_Even); //defaultValue
   Reg#(Float) accum <- mkReg(0);
   
   rule res;
      let resp <- fpmac.response.get;
      accum <= tpl_1(resp);
      indication.res(pack(tpl_1(resp)), extend(pack(tpl_2(resp))));
   endrule
   
   method Action mac(Bit#(32) x, Bit#(32) y);
      fpmac.request.put(tuple3(tagged Valid accum, unpack(x), unpack(y)));
   endmethod

endmodule

