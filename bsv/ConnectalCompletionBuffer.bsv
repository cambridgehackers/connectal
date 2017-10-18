// Copyright (c) 2013 Quanta Research Cambridge, Inc.

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

// BSV Libraries
import BRAMFIFO::*;
import FIFO::*;
import FIFOF::*;
import Vector::*;
import GetPut::*;
import ClientServer::*;
import Assert::*;
import BRAM::*;
import RegFile::*;

// CONNECTAL Libraries
import ConnectalMemTypes::*;
import ConnectalMemory::*;
import ConfigCounter::*;

interface TagGen#(numeric type numTags);
   method ActionValue#(Bit#(TLog#(numTags))) getTag;
   method Action returnTag(Bit#(TLog#(numTags)) tag);
   method ActionValue#(Bit#(TLog#(numTags))) complete;
endinterface

module mkTagGen(TagGen#(numTags))
   provisos(Log#(numTags,tsz));
   
   BRAM_Configure cfg = defaultValue;
   cfg.outFIFODepth = 1;
   //BRAM2Port#(Bit#(tsz),Bool) tags <- mkBRAM2Server(cfg);
   //Vector#(numTags, Reg#(Bool)) tags <- replicateM(mkReg(False));
   Reg#(Bit#(numTags))     tags[2] <- mkCReg(2, 0);
   Reg#(Bit#(tsz))        head_ptr <- mkReg(0);
   Reg#(Bit#(tsz))        tail_ptr <- mkReg(0);
   Reg#(Bool)               inited <- mkReg(False);
   FIFO#(Bit#(tsz))      comp_fifo <- mkFIFO;
   Reg#(Bit#(numTags))  comp_state <- mkReg(0);
   ConfigCounter#(TAdd#(tsz,1)) counter <- mkConfigCounter(fromInteger(valueOf(numTags)));
   
   let retFifo <- mkFIFO;
   let tagFifo <- mkFIFO;

   //rule complete_rule0 (comp_state[0] != 0);
      //tags.portB.request.put(BRAMRequest{write:False, address:tail_ptr, datain: ?, responseOnWrite: ?});
   //endrule

   rule complete_rule1 (comp_state[0] != 0);
      //let rv <- tags.portB.response.get;
      //let rv = tags[tail_ptr];
      let rv = tags[1][tail_ptr] == 1;
      if (!rv) begin
	 tail_ptr <= tail_ptr+1;
	 counter.increment(1);
	 comp_state <= comp_state >> 1;
	 comp_fifo.enq(tail_ptr);
      end
   endrule
   
   // this used to be in the body of returnTag, but form some reason bsc does not
   // consider access to portA and portB to be conflict free **sigh** 
   (* descending_urgency = "ret_rule, complete_rule1" *)
   rule ret_rule;
      let tag <- toGet(retFifo).get;
      //tags.portB.request.put(BRAMRequest{write:True, responseOnWrite:False, address:tag, datain:False});
      //tags[tag] <= False;
      begin
	 let t = tags[0];
	 t[tag] = 0;
	 tags[0] <= t;
      end
      comp_state <= 1 | (comp_state << 1);
   endrule

   rule init_rule(!inited);
      //tags.portA.request.put(BRAMRequest{write:True,address:head_ptr,responseOnWrite:False,datain:False});
      //Not needed: tags[head_ptr] <= False;
      head_ptr <= head_ptr+1;
      inited <= head_ptr+1==0;
   endrule
   
   rule tag_rule if (inited && counter.positive);
      //tags.portA.request.put(BRAMRequest{write:True, responseOnWrite:False, address:head_ptr, datain:True});
      //tags[head_ptr] <= True;
      begin
	 let t = tags[1];
	 t[head_ptr] = 1;
	 tags[1] <= t;
      end
      head_ptr <= head_ptr+1;
      tagFifo.enq(head_ptr);
      counter.decrement(1);
   endrule

   method ActionValue#(Bit#(tsz)) getTag();
      let tag <- toGet(tagFifo).get();
      return tag;
   endmethod

   method Action returnTag(Bit#(tsz) tag) if (inited);
      retFifo.enq(tag);
   endmethod
   
   method ActionValue#(Bit#(tsz)) complete;
      comp_fifo.deq;
      return comp_fifo.first;
   endmethod
   
endmodule
