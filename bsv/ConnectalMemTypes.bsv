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
import FIFOF::*;
import Adapter::*;
import Vector::*;
import Connectable::*;
import BRAMFIFO::*;
import GetPut::*;
import ClientServer::*;

import ConnectalConfig::*;
import Pipe::*;
import ConnectalMemory::*;
import DefaultValue::*;
import AxiStream::*;

`include "ConnectalProjectConfig.bsv"

typedef Bit#(32) SGLId;
`ifndef ZYNQ
typedef 40 MemOffsetSize; // must be at least as large as PhysAddrSize
`else
`ifdef ZynqUltrascale
typedef 40 MemOffsetSize; // ZynqUltrascale PhysAddrWidth=40
`else
typedef 32 MemOffsetSize;
`endif
`endif
`ifdef MemTagSize
typedef `MemTagSize MemTagSize;
`else
typedef 6 MemTagSize;
`endif
typedef `BurstLenSize BurstLenSize;


`ifdef MemServerTags
    typedef `MemServerTags MemServerTags;
`else

    `ifndef USE_ACP
	`ifdef PCIE3
	// as configured, the Xilinx gen3 PCIe core supports 5 bit tags, and
	// we need to use unique tags for all transactions in flight. Since
	// MemServer uses the same tag numbers for reads and writes, we use
	// tag[4] to distinguish the two, leaving 4 bits for unique tags.
	// TODO: There is an option for longer tags in the gen3 core.
	typedef 16 MemServerTags;
	`else
	typedef 32 MemServerTags;
	`endif
    `else
	typedef 8 MemServerTags;
    `endif
`endif // MemServerTags

`ifdef DataBusWidth
typedef TDiv#(`DataBusWidth,8) ByteEnableSize;
`else
typedef TDiv#(64,8) ByteEnableSize;
`endif

// memory request with physical addresses.
// these can be transmitted directly to the bus master
typedef struct {
   Bit#(addrWidth) addr;
   Bit#(BurstLenSize) burstLen;
   Bit#(MemTagSize) tag;
`ifdef BYTE_ENABLES
   Bit#(TDiv#(dataBusWidth,8)) firstbe; // maybe we only need lastbe
   Bit#(TDiv#(dataBusWidth,8)) lastbe;
`endif
   } PhysMemRequest#(numeric type addrWidth, numeric type dataBusWidth) deriving (Bits, Eq, FShow);

instance DefaultValue#(PhysMemRequest#(addrWidth,dataBusWidth));
   defaultValue = PhysMemRequest { addr: 0, burstLen: 0, tag: 0
`ifdef BYTE_ENABLES
				  , firstbe: maxBound, lastbe: maxBound
`endif
      };
endinstance

// memory request with "virtual" addresses.
// these need to be translated before they can be send to the bus
typedef struct {
   SGLId sglId;
   Bit#(MemOffsetSize) offset;
   Bit#(BurstLenSize) burstLen;
   Bit#(MemTagSize)  tag;
`ifdef BYTE_ENABLES
   Bit#(ByteEnableSize) firstbe; // maybe we only need lastbe
   Bit#(ByteEnableSize) lastbe;
`endif
   } MemRequest deriving (Bits, FShow);

instance DefaultValue#(MemRequest);
   defaultValue = MemRequest {
      sglId: 0, offset: 0, burstLen: 0, tag: 0
`ifdef BYTE_ENABLES
      , firstbe: maxBound, lastbe: maxBound
`endif
      };
endinstance

// memory payload
typedef struct {
   Bit#(dsz) data;
   Bit#(MemTagSize) tag;
   Bool last;
`ifdef BYTE_ENABLES_MEM_DATA
   Bit#(TDiv#(dsz, 8)) byte_enables; // maybe we only need lastbe
`endif
   } MemData#(numeric type dsz) deriving (Bits, Eq, FShow);

function Bit#(dsz) memDataData(MemData#(dsz) md); return md.data; endfunction
function Bit#(TDiv#(dsz,8)) memDataByteEnable(MemData#(dsz) md);
`ifdef BYTE_ENABLES_MEM_DATA
   return md.byte_enables;
`else
   return maxBound;
`endif
endfunction

typeclass ReqByteEnables#(type t, numeric type besz);
   function Bit#(besz) reqFirstByteEnable(t req);
   function Bit#(besz) reqLastByteEnable(t req);
endtypeclass
instance ReqByteEnables#(PhysMemRequest#(addrWidth,dataBusWidth),TDiv#(dataBusWidth,8));
`ifdef BYTE_ENABLES
   function Bit#(TDiv#(dataBusWidth,8)) reqFirstByteEnable(PhysMemRequest#(addrWidth,dataBusWidth) req); return req.firstbe; endfunction
   function Bit#(TDiv#(dataBusWidth,8)) reqLastByteEnable(PhysMemRequest#(addrWidth,dataBusWidth) req); return req.lastbe; endfunction
`else
   function Bit#(TDiv#(dataBusWidth,8)) reqFirstByteEnable(PhysMemRequest#(addrWidth,dataBusWidth) req); return maxBound; endfunction
   function Bit#(TDiv#(dataBusWidth,8)) reqLastByteEnable(PhysMemRequest#(addrWidth,dataBusWidth) req); return maxBound; endfunction
`endif
endinstance
instance ReqByteEnables#(MemRequest,ByteEnableSize);
`ifdef BYTE_ENABLES
   function Bit#(ByteEnableSize) reqFirstByteEnable(MemRequest req); return req.firstbe; endfunction
   function Bit#(ByteEnableSize) reqLastByteEnable(MemRequest req); return req.lastbe; endfunction
`else
   function Bit#(ByteEnableSize) reqFirstByteEnable(MemRequest req); return maxBound; endfunction
   function Bit#(ByteEnableSize) reqLastByteEnable(MemRequest req); return maxBound; endfunction
`endif
endinstance

///////////////////////////////////////////////////////////////////////////////////
//

typedef struct {SGLId sglId;
		Bit#(32) base;
		Bit#(BurstLenSize) burstLen;
		Bit#(32) len;
		Bit#(MemTagSize) tag;
		} MemengineCmd deriving (Eq,Bits);

interface MemWriteEngineServer#(numeric type userWidth);
   interface Put#(MemengineCmd)       request;
   interface Get#(Bool)               done;
   interface PipeIn#(Bit#(userWidth)) data;
   interface PipeOut#(MemRequestCycles)     requestCycles;
endinterface

interface MemWriteEngine#(numeric type busWidth, numeric type userWidth, numeric type cmdQDepth, numeric type numServers);
   interface MemWriteClient#(busWidth) dmaClient;
   interface Vector#(numServers, MemWriteEngineServer#(userWidth)) writeServers;
endinterface

typedef struct {
   Bit#(dsz) data;
   Bit#(MemTagSize) tag;
   Bool first;
   Bool last;
   } MemDataF#(numeric type dsz) deriving (Bits);

typedef struct {
   Bit#(MemTagSize) tag;
   Bit#(32)         cycles;
   } MemRequestCycles deriving (Bits);

interface MemReadEngineServer#(numeric type userWidth);
   interface Put#(MemengineCmd)             request;
   interface PipeOut#(MemDataF#(userWidth)) data;
   interface PipeOut#(MemRequestCycles)     requestCycles;
endinterface

interface MemReadEngine#(numeric type busWidth, numeric type userWidth, numeric type cmdQDepth, numeric type numServers);
   interface MemReadClient#(busWidth) dmaClient;
   interface Vector#(numServers, MemReadEngineServer#(userWidth)) readServers;
endinterface

//
///////////////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////////////
//

interface MemReadClient#(numeric type dsz);
   interface Get#(MemRequest)    readReq;
   interface Put#(MemData#(dsz)) readData;
endinterface

interface MemWriteClient#(numeric type dsz);
   interface Get#(MemRequest)    writeReq;
   interface Get#(MemData#(dsz)) writeData;
   interface Put#(Bit#(MemTagSize))       writeDone;
endinterface

interface MemClient#(numeric type dsz);
   interface MemReadClient#(dsz) readClient;
   interface MemWriteClient#(dsz) writeClient;
endinterface

interface MemReadServer#(numeric type dsz);
   interface Put#(MemRequest) readReq;
   interface Get#(MemData#(dsz))     readData;
endinterface

interface MemWriteServer#(numeric type dsz);
   interface Put#(MemRequest) writeReq;
   interface Put#(MemData#(dsz))     writeData;
   interface Get#(Bit#(MemTagSize))           writeDone;
endinterface

interface MemServer#(numeric type dataWidth);
   interface MemReadServer#(dataWidth) readServer;
   interface MemWriteServer#(dataWidth) writeServer;
endinterface

//
///////////////////////////////////////////////////////////////////////////////////
//

interface PhysMemSlave#(numeric type addrWidth, numeric type dataWidth);
   interface PhysMemReadServer#(addrWidth, dataWidth) read_server;
   interface PhysMemWriteServer#(addrWidth, dataWidth) write_server;
endinterface

interface PhysMemMaster#(numeric type addrWidth, numeric type dataWidth);
   interface PhysMemReadClient#(addrWidth, dataWidth) read_client;
   interface PhysMemWriteClient#(addrWidth, dataWidth) write_client;
endinterface

interface PhysMemReadClient#(numeric type asz, numeric type dsz);
   interface Get#(PhysMemRequest#(asz,dsz))    readReq;
   interface Put#(MemData#(dsz)) readData;
endinterface

interface PhysMemWriteClient#(numeric type asz, numeric type dsz);
   interface Get#(PhysMemRequest#(asz,dsz))    writeReq;
   interface Get#(MemData#(dsz)) writeData;
   interface Put#(Bit#(MemTagSize))       writeDone;
endinterface

interface PhysMemReadServer#(numeric type asz, numeric type dsz);
   interface Put#(PhysMemRequest#(asz,dsz)) readReq;
   interface Get#(MemData#(dsz))     readData;
endinterface

interface PhysMemWriteServer#(numeric type asz, numeric type dsz);
   interface Put#(PhysMemRequest#(asz,dsz)) writeReq;
   interface Put#(MemData#(dsz))     writeData;
   interface Get#(Bit#(MemTagSize))           writeDone;
endinterface

//
///////////////////////////////////////////////////////////////////////////////////

instance Connectable#(MemReadClient#(dsz), MemReadServer#(dsz));
   module mkConnection#(MemReadClient#(dsz) source, MemReadServer#(dsz) sink)(Empty);
      rule mr_request;
	 let req <- source.readReq.get();
	 sink.readReq.put(req);
      endrule
      rule mr_response;
	 let resp <- sink.readData.get();
	 source.readData.put(resp);
      endrule
   endmodule
endinstance

instance Connectable#(MemWriteClient#(dsz), MemWriteServer#(dsz));
   module mkConnection#(MemWriteClient#(dsz) source, MemWriteServer#(dsz) sink)(Empty);
      rule mw_request;
	 let req <- source.writeReq.get();
	 sink.writeReq.put(req);
      endrule
      rule mw_response;
	 let resp <- source.writeData.get();
	 sink.writeData.put(resp);
      endrule
      rule mw_done;
	 let resp <- sink.writeDone.get();
	 source.writeDone.put(resp);
      endrule
   endmodule
endinstance

instance Connectable#(MemClient#(dsz), MemServer#(dsz));
   module mkConnection#(MemClient#(dsz) source, MemServer#(dsz) sink)(Empty);
      mkConnection(source.readClient, sink.readServer);
      mkConnection(source.writeClient, sink.writeServer);
   endmodule
endinstance

instance Connectable#(PhysMemMaster#(addrWidth, busWidth), PhysMemSlave#(addrWidth, busWidth));
   module mkConnection#(PhysMemMaster#(addrWidth, busWidth) m, PhysMemSlave#(addrWidth, busWidth) s)(Empty);
      mkConnection(m.read_client.readReq, s.read_server.readReq);
      mkConnection(s.read_server.readData, m.read_client.readData);
      mkConnection(m.write_client.writeReq, s.write_server.writeReq);
      mkConnection(m.write_client.writeData, s.write_server.writeData);
      mkConnection(s.write_server.writeDone, m.write_client.writeDone);
   endmodule
endinstance

// this is used for debugging MemToPcie/PcieToMem in BsimTop.bsv
instance Connectable#(PhysMemMaster#(32, busWidth), PhysMemSlave#(40, busWidth));
   module mkConnection#(PhysMemMaster#(32, busWidth) m, PhysMemSlave#(40, busWidth) s)(Empty);
      //mkConnection(m.read_client.readReq, s.read_server.readReq);
      rule readreq;
	 let req <- m.read_client.readReq.get();
	 s.read_server.readReq.put(PhysMemRequest { addr: extend(req.addr), burstLen: req.burstLen, tag: req.tag
`ifdef BYTE_ENABLES
						   , firstbe: req.firstbe, lastbe: req.lastbe
`endif
	    });
      endrule

      mkConnection(s.read_server.readData, m.read_client.readData);
      //mkConnection(m.write_client.writeReq, s.write_server.writeReq);
      rule writereq;
	 let req <- m.write_client.writeReq.get();
	 s.write_server.writeReq.put(PhysMemRequest { addr: extend(req.addr), burstLen: req.burstLen, tag: req.tag
`ifdef BYTE_ENABLES
						     , firstbe: req.firstbe, lastbe: req.lastbe
`endif
 });
      endrule
      mkConnection(m.write_client.writeData, s.write_server.writeData);
      mkConnection(s.write_server.writeDone, m.write_client.writeDone);
   endmodule
endinstance

function Bool isQuadWordAligned(Bit#(7) lower_addr);
   return (lower_addr[2:0]==3'b0);
endfunction

function Put#(t) null_put();
   return (interface Put;
              method Action put(t x) if (False);
                 noAction;
              endmethod
           endinterface);
endfunction

function Get#(t) null_get();
   return (interface Get;
              method ActionValue#(t) get() if (False);
                 return ?;
              endmethod
           endinterface);
endfunction

function  PhysMemWriteClient#(addrWidth, busWidth) null_phys_mem_write_client();
   return (interface PhysMemWriteClient;
              interface Get writeReq = null_get;
              interface Get writeData = null_get;
              interface Put writeDone = null_put;
           endinterface);
endfunction

function  PhysMemReadClient#(addrWidth, busWidth) null_phys_mem_read_client();
   return (interface PhysMemReadClient;
              interface Get readReq = null_get;
              interface Put readData = null_put;
           endinterface);
endfunction

function  MemWriteClient#(busWidth) null_mem_write_client();
   return (interface MemWriteClient;
              interface Get writeReq = null_get;
              interface Get writeData = null_get;
              interface Put writeDone = null_put;
           endinterface);
endfunction

function  MemReadClient#(busWidth) null_mem_read_client();
   return (interface MemReadClient;
              interface Get readReq = null_get;
              interface Put readData = null_put;
           endinterface);
endfunction

instance MkAxiStream#(AxiStreamMaster#(dsize), FIFOF#(MemData#(dsize)));
   module mkAxiStream#(FIFOF#(MemData#(dsize)) f)(AxiStreamMaster#(dsize));
      Wire#(Bool) readyWire <- mkDWire(False);
      Wire#(MemData#(dsize)) dataWire <- mkDWire(unpack(0));
      rule rl_data if (f.notEmpty());
	 dataWire <= f.first();
      endrule
      rule rl_deq if (readyWire && f.notEmpty);
	 f.deq();
      endrule
     method Bit#(dsize)              tdata();
	return dataWire.data;
     endmethod
     method Bit#(TDiv#(dsize,8))     tkeep(); return maxBound; endmethod
     method Bit#(1)                tlast(); return pack(dataWire.last); endmethod
     method Action                 tready(Bit#(1) v);
	readyWire <= unpack(v);
     endmethod
     method Bit#(1)                tvalid(); return pack(f.notEmpty()); endmethod
   endmodule
endinstance

instance MkAxiStream#(AxiStreamSlave#(dsize), FIFOF#(MemData#(dsize)));
   module mkAxiStream#(FIFOF#(MemData#(dsize)) f)(AxiStreamSlave#(dsize));
      Wire#(Bit#(dsize)) dataWire <- mkDWire(unpack(0));
      Wire#(Bit#(1))     lastWire <- mkDWire(unpack(0));
      Wire#(Bool) validWire <- mkDWire(False);
      rule enq if (validWire && f.notFull());
	 f.enq(MemData { data: dataWire, last: unpack(lastWire), tag: 0 });
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

instance MkAxiStream#(AxiStreamMaster#(dsize), FIFOF#(MemDataF#(dsize)));
   module mkAxiStream#(FIFOF#(MemDataF#(dsize)) f)(AxiStreamMaster#(dsize));
      Wire#(Bool) readyWire <- mkDWire(False);
      Wire#(Bool) lastWire <- mkDWire(False);
      rule rl_deq if (readyWire && f.notEmpty);
	 f.deq();
	 lastWire <= f.first().last;
      endrule
     method Bit#(dsize)              tdata();
	if (f.notEmpty())
	  return f.first().data;
	else
	  return 0;
     endmethod
     method Bit#(TDiv#(dsize,8))     tkeep(); return maxBound; endmethod
     method Bit#(1)                tlast(); return pack(lastWire); endmethod
     method Action                 tready(Bit#(1) v);
	readyWire <= unpack(v);
     endmethod
     method Bit#(1)                tvalid(); return pack(f.notEmpty()); endmethod
   endmodule
endinstance

instance MkAxiStream#(AxiStreamSlave#(dsize), FIFOF#(MemDataF#(dsize)));
   module mkAxiStream#(FIFOF#(MemDataF#(dsize)) f)(AxiStreamSlave#(dsize));
      Reg#(Bool) first <- mkReg(True);
      Wire#(Bit#(dsize)) dataWire <- mkDWire(unpack(0));
      Wire#(Bool) validWire <- mkDWire(False);
      Wire#(Bool) lastWire <- mkDWire(False);
      rule enq if (validWire && f.notFull());
	 f.enq(MemDataF { data: dataWire, last: lastWire, first: first, tag: 0 });
	 first <= lastWire;
      endrule
      method Action      tdata(Bit#(dsize) v);
	 dataWire <= v;
      endmethod
      method Action      tkeep(Bit#(TDiv#(dsize,8)) v); endmethod
      method Action      tlast(Bit#(1) v); lastWire <= unpack(v); endmethod
      method Bit#(1)     tready(); return pack(f.notFull()); endmethod
      method Action      tvalid(Bit#(1) v);
	 validWire <= unpack(v);
      endmethod
   endmodule
endinstance

instance MkAxiStream#(AxiStreamMaster#(dsize), PipeOut#(MemDataF#(dsize)));
   module mkAxiStream#(PipeOut#(MemDataF#(dsize)) f)(AxiStreamMaster#(dsize));
      Wire#(Bool) readyWire <- mkDWire(False);
      Wire#(Bool) lastWire <- mkDWire(False);
      Wire#(Bit#(dsize)) dataWire <- mkDWire(0);
      rule rl_data if (f.notEmpty());
	 dataWire <= f.first().data;
	 lastWire <= f.first().last;
      endrule
      rule rl_deq if (readyWire && f.notEmpty);
	 f.deq();
      endrule
     method Bit#(dsize)              tdata();
	return dataWire;
     endmethod
     method Bit#(TDiv#(dsize,8))     tkeep(); return maxBound; endmethod
     method Bit#(1)                tlast(); return pack(lastWire); endmethod
     method Action                 tready(Bit#(1) v);
	readyWire <= unpack(v);
     endmethod
     method Bit#(1)                tvalid(); return pack(f.notEmpty()); endmethod
   endmodule
endinstance

instance MkAxiStream#(AxiStreamSlave#(dsize), PipeIn#(MemDataF#(dsize)));
   module mkAxiStream#(PipeIn#(MemDataF#(dsize)) f)(AxiStreamSlave#(dsize));
      Reg#(Bool) first <- mkReg(True);
      Wire#(Bit#(dsize)) dataWire <- mkDWire(unpack(0));
      Wire#(Bool) validWire <- mkDWire(False);
      Wire#(Bool) lastWire <- mkDWire(False);
      rule enq if (validWire && f.notFull());
	 f.enq(MemDataF { data: dataWire, last: lastWire, first: first, tag: 0 });
	 first <= lastWire;
      endrule
      method Action      tdata(Bit#(dsize) v);
	 dataWire <= v;
      endmethod
      method Action      tkeep(Bit#(TDiv#(dsize,8)) v); endmethod
      method Action      tlast(Bit#(1) v); lastWire <= unpack(v); endmethod
      method Bit#(1)     tready(); return pack(f.notFull()); endmethod
      method Action      tvalid(Bit#(1) v);
	 validWire <= unpack(v);
      endmethod
   endmodule
endinstance

instance MkAxiStream#(AxiStreamMaster#(dsize), PipeOut#(MemData#(dsize)));
   module mkAxiStream#(PipeOut#(MemData#(dsize)) f)(AxiStreamMaster#(dsize));
      Wire#(Bool) readyWire <- mkDWire(False);
      Wire#(Bool) lastWire <- mkDWire(False);
      Wire#(Bit#(dsize)) dataWire <- mkDWire(0);
      rule rl_data if (f.notEmpty());
	 dataWire <= f.first().data;
	 lastWire <= f.first().last;
      endrule
      rule rl_deq if (readyWire && f.notEmpty);
	 f.deq();
      endrule
     method Bit#(dsize)              tdata();
	return dataWire;
     endmethod
     method Bit#(TDiv#(dsize,8))     tkeep(); return maxBound; endmethod
     method Bit#(1)                tlast(); return pack(lastWire); endmethod
     method Action                 tready(Bit#(1) v);
	readyWire <= unpack(v);
     endmethod
     method Bit#(1)                tvalid(); return pack(f.notEmpty()); endmethod
   endmodule
endinstance

instance MkAxiStream#(AxiStreamSlave#(dsize), PipeIn#(MemData#(dsize)));
   module mkAxiStream#(PipeIn#(MemData#(dsize)) f)(AxiStreamSlave#(dsize));
      Wire#(Bit#(dsize)) dataWire <- mkDWire(unpack(0));
      Wire#(Bool) validWire <- mkDWire(False);
      Wire#(Bool) lastWire <- mkDWire(False);
      rule enq if (validWire && f.notFull());
	 f.enq(MemData { data: dataWire, last: lastWire, tag: 0 });
      endrule
      method Action      tdata(Bit#(dsize) v);
	 dataWire <= v;
      endmethod
      method Action      tkeep(Bit#(TDiv#(dsize,8)) v); endmethod
      method Action      tlast(Bit#(1) v); lastWire <= unpack(v); endmethod
      method Bit#(1)     tready(); return pack(f.notFull()); endmethod
      method Action      tvalid(Bit#(1) v);
	 validWire <= unpack(v);
      endmethod
   endmodule
endinstance

typeclass MkPhysMemSlave#(type srctype, numeric type addrWidth, numeric type dataWidth);
   module mkPhysMemSlave#(srctype axiSlave)(PhysMemSlave#(addrWidth,dataWidth));
endtypeclass
typeclass MkPhysMemMaster#(type srctype, numeric type addrWidth, numeric type dataWidth);
   module mkPhysMemMaster#(srctype axiSlave)(PhysMemMaster#(addrWidth,dataWidth));
endtypeclass

