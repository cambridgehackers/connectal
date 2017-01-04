// Copyright (c) 2016 Connectal Project

// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use, copy,
// modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
// BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
// ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Connectable::*;
import FIFOF::*;
import GetPut::*;
import GetPutM::*;
import Probe::*;
`include "ConnectalProjectConfig.bsv"

(* always_ready, always_enabled *)
interface AxiStreamMaster#(numeric type dsz);
    method Bit#(dsz)              tdata();
    method Bit#(TDiv#(dsz,8))     tkeep();
    method Bit#(1)                tlast();
    (* prefix = "" *)method Action                 tready((* port="tready" *) Bit#(1) v);
    method Bit#(1)                tvalid();
endinterface

(* always_ready, always_enabled *)
interface AxiStreamSlave#(numeric type dsz);
    (* prefix = "" *)
    method Action      tdata((* port = "tdata" *) Bit#(dsz) v);
    (* prefix = "" *)
    method Action      tkeep((* port = "tkeep" *) Bit#(TDiv#(dsz,8)) v);
    (* prefix = "" *)
    method Action      tlast((* port = "tlast" *) Bit#(1) v);
    method Bit#(1)     tready();
    (* prefix = "" *)
    method Action      tvalid((* port = "tvalid" *)Bit#(1) v);
endinterface

instance Connectable#(AxiStreamMaster#(dataWidth), AxiStreamSlave#(dataWidth));
   module mkConnection#(AxiStreamMaster#(dataWidth) from, AxiStreamSlave#(dataWidth) to)(Empty);
`ifdef GET_PUT_WITH_CLOCKS_USE_XILINX_FIFO
      let cnxProbe <- mkProbe;
      rule rl_probe if (from.tvalid() == 1 && to.tready() == 1);
	 cnxProbe <= from.tdata();
      endrule
`endif
      rule rl_axi_stream;
	 to.tdata(from.tdata());
	 to.tkeep(from.tkeep());
	 to.tlast(from.tlast());
	 to.tvalid(from.tvalid());
	 from.tready(to.tready());
      endrule
   endmodule
endinstance

instance Connectable#(AxiStreamMaster#(dataWidth), Put#(dtype))
   provisos (Bits#(dtype, dataWidth));
   module mkConnection#(AxiStreamMaster#(dataWidth) from, Put#(dtype) to)(Empty);
      FIFOF#(Bit#(dataWidth)) asputfifo <- mkFIFOF();
`ifdef GET_PUT_WITH_CLOCKS_USE_XILINX_FIFO
      let getProbe <- mkProbe;
      let putProbe <- mkProbe;
`endif
      rule rl_ready;
	 from.tready(pack(asputfifo.notFull));
      endrule
      rule rl_enq if (from.tvalid == 1);
`ifdef GET_PUT_WITH_CLOCKS_USE_XILINX_FIFO
	 getProbe <= from.tdata;
`endif
	 asputfifo.enq(from.tdata);
      endrule
      rule rl_put;
	 let v <- toGet(asputfifo).get();
`ifdef GET_PUT_WITH_CLOCKS_USE_XILINX_FIFO
	 putProbe <= v;
`endif
	 to.put(unpack(v));
      endrule
   endmodule
endinstance

instance Connectable#(Get#(dtype), AxiStreamSlave#(dataWidth))
   provisos (Bits#(dtype, dataWidth));
   module mkConnection#(Get#(dtype) from, AxiStreamSlave#(dataWidth) to)(Empty);
      FIFOF#(Bit#(dataWidth)) asgetfifo <- mkFIFOF();
`ifdef GET_PUT_WITH_CLOCKS_USE_XILINX_FIFO
      let getProbe <- mkProbe();
      let putProbe <- mkProbe();
`endif
      rule rl_get;
	 let v <- from.get();
`ifdef GET_PUT_WITH_CLOCKS_USE_XILINX_FIFO
	 getProbe <= v;
`endif
	 asgetfifo.enq(pack(v));
      endrule
      rule rl_axi_stream;
	 to.tdata(asgetfifo.first);
	 to.tkeep(maxBound);
	 to.tlast(0);
      endrule
      rule rl_tvalid;
	 to.tvalid(pack(asgetfifo.notEmpty));
      endrule
      rule rl_deq if (to.tready == 1);
`ifdef GET_PUT_WITH_CLOCKS_USE_XILINX_FIFO
	 putProbe <= asgetfifo.first();
`endif
	 asgetfifo.deq();
      endrule
   endmodule
endinstance

////////////////////////////////////////////////////////////

instance ToGetM#(AxiStreamMaster#(asz), Bit#(asz));
   module toGetM#(AxiStreamMaster#(asz) m)(Get#(Bit#(asz)));
      FIFOF#(Bit#(asz)) tmpfifo <- mkFIFOF();

      rule handshake;
         m.tready(pack(tmpfifo.notFull));
      endrule
      rule enq if (unpack(m.tvalid));
	 tmpfifo.enq(m.tdata());
      endrule

      return toGet(tmpfifo);
   endmodule
endinstance

instance ToPutM#(AxiStreamSlave#(asz), Bit#(asz));
   module toPutM#(AxiStreamSlave#(asz) m)(Put#(Bit#(asz)));
      FIFOF#(Bit#(asz)) tmpfifo <- mkFIFOF();

      rule handshake;
	 m.tvalid(pack(tmpfifo.notEmpty()));
      endrule
      rule deq if (unpack(m.tready()));
	 m.tdata(tmpfifo.first());
	 m.tkeep(maxBound);
	 m.tlast(1);
	 tmpfifo.deq();
      endrule

      return toPut(tmpfifo);
   endmodule
endinstance

////////////////////////////////////////////////////////////
typeclass ToAxiStream#(type atype, type btype);
   function atype toAxiStream(btype b);
endtypeclass
typeclass MkAxiStream#(type atype, type btype);
   module mkAxiStream#(btype b)(atype);
endtypeclass

instance MkAxiStream#(AxiStreamMaster#(dsize), FIFOF#(Bit#(dsize)));
   module mkAxiStream#(FIFOF#(Bit#(dsize)) f)(AxiStreamMaster#(dsize));
      Wire#(Bool) readyWire <- mkDWire(False);
      Wire#(Bit#(dsize)) dataWire <- mkDWire(0);
      rule rl_data if (f.notEmpty());
	 dataWire <= f.first();
      endrule
      rule rl_deq if (readyWire && f.notEmpty);
	 f.deq();
      endrule
     method Bit#(dsize)              tdata();
	return dataWire;
     endmethod
     method Bit#(TDiv#(dsize,8))     tkeep(); return maxBound; endmethod
     method Bit#(1)                tlast(); return pack(False); endmethod
     method Action                 tready(Bit#(1) v);
	readyWire <= unpack(v);
     endmethod
     method Bit#(1)                tvalid(); return pack(f.notEmpty()); endmethod
   endmodule
endinstance

instance MkAxiStream#(AxiStreamSlave#(dsize), FIFOF#(Bit#(dsize)));
   module mkAxiStream#(FIFOF#(Bit#(dsize)) f)(AxiStreamSlave#(dsize));
      Wire#(Bit#(dsize)) dataWire <- mkDWire(unpack(0));
      Wire#(Bool) validWire <- mkDWire(False);
      rule enq if (validWire && f.notFull());
	 f.enq(dataWire);
      endrule
      method Action      tdata(Bit#(dsize) v);
	 dataWire <= v;
      endmethod
      method Action      tkeep(Bit#(TDiv#(dsize,8)) v); endmethod
      method Action      tlast(Bit#(1) v); endmethod
      method Bit#(1)     tready(); return pack(f.notFull()); endmethod
      method Action      tvalid(Bit#(1) v);
	 validWire <= unpack(v);
      endmethod
   endmodule
endinstance
