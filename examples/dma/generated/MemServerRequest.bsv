package MemServerRequest;

import FIFO::*;
import FIFOF::*;
import GetPut::*;
import Connectable::*;
import Clocks::*;
import FloatingPoint::*;
import Adapter::*;
import Leds::*;
import Vector::*;
import SpecialFIFOs::*;
import ConnectalMemory::*;
import Portal::*;
import CtrlMux::*;
import MemTypes::*;
import Pipe::*;
import HostInterface::*;
import LinkerLib::*;
import ConnectalMemory::*;
import Vector::*;
import BuildVector::*;
import FIFO::*;
import FIFOF::*;
import GetPut::*;
import Connectable::*;
import Pipe::*;
import MemTypes::*;
import MemReadEngine::*;
import MemWriteEngine::*;
import HostInterface::*;




typedef struct {
    Bit#(32) sglId;
    Bit#(32) offset;
} AddrTrans_Message deriving (Bits);

typedef struct {
    TileControl tc;
} SetTileState_Message deriving (Bits);

typedef struct {
    ChannelType rc;
} StateDbg_Message deriving (Bits);

typedef struct {
    ChannelType rc;
} MemoryTraffic_Message deriving (Bits);

// exposed wrapper portal interface
interface MemServerRequestInputPipes;
    interface PipeOut#(AddrTrans_Message) addrTrans_PipeOut;
    interface PipeOut#(SetTileState_Message) setTileState_PipeOut;
    interface PipeOut#(StateDbg_Message) stateDbg_PipeOut;
    interface PipeOut#(MemoryTraffic_Message) memoryTraffic_PipeOut;

endinterface
interface MemServerRequestInput;
    interface PipePortal#(4, 0, SlaveDataBusWidth) portalIfc;
    interface MemServerRequestInputPipes pipes;
endinterface
interface MemServerRequestWrapperPortal;
    interface PipePortal#(4, 0, SlaveDataBusWidth) portalIfc;
endinterface
// exposed wrapper MemPortal interface
interface MemServerRequestWrapper;
    interface StdPortal portalIfc;
endinterface

instance Connectable#(MemServerRequestInputPipes,MemServerRequest);
   module mkConnection#(MemServerRequestInputPipes pipes, MemServerRequest ifc)(Empty);

    rule handle_addrTrans_request;
        let request <- toGet(pipes.addrTrans_PipeOut).get();
        ifc.addrTrans(request.sglId, request.offset);
    endrule

    rule handle_setTileState_request;
        let request <- toGet(pipes.setTileState_PipeOut).get();
        ifc.setTileState(request.tc);
    endrule

    rule handle_stateDbg_request;
        let request <- toGet(pipes.stateDbg_PipeOut).get();
        ifc.stateDbg(request.rc);
    endrule

    rule handle_memoryTraffic_request;
        let request <- toGet(pipes.memoryTraffic_PipeOut).get();
        ifc.memoryTraffic(request.rc);
    endrule

   endmodule
endinstance

// exposed wrapper Portal implementation
(* synthesize *)
module mkMemServerRequestInput(MemServerRequestInput);
    Vector#(4, PipeIn#(Bit#(SlaveDataBusWidth))) requestPipeIn;

    AdapterFromBus#(SlaveDataBusWidth,AddrTrans_Message) addrTrans_requestAdapter <- mkAdapterFromBus();
    requestPipeIn[0] = addrTrans_requestAdapter.in;

    AdapterFromBus#(SlaveDataBusWidth,SetTileState_Message) setTileState_requestAdapter <- mkAdapterFromBus();
    requestPipeIn[1] = setTileState_requestAdapter.in;

    AdapterFromBus#(SlaveDataBusWidth,StateDbg_Message) stateDbg_requestAdapter <- mkAdapterFromBus();
    requestPipeIn[2] = stateDbg_requestAdapter.in;

    AdapterFromBus#(SlaveDataBusWidth,MemoryTraffic_Message) memoryTraffic_requestAdapter <- mkAdapterFromBus();
    requestPipeIn[3] = memoryTraffic_requestAdapter.in;

    interface PipePortal portalIfc;
        interface PortalSize messageSize;
        method Bit#(16) size(Bit#(16) methodNumber);
            case (methodNumber)
            0: return fromInteger(valueOf(SizeOf#(AddrTrans_Message)));
            1: return fromInteger(valueOf(SizeOf#(SetTileState_Message)));
            2: return fromInteger(valueOf(SizeOf#(StateDbg_Message)));
            3: return fromInteger(valueOf(SizeOf#(MemoryTraffic_Message)));
            endcase
        endmethod
        endinterface
        interface Vector requests = requestPipeIn;
        interface Vector indications = nil;
        interface PortalInterrupt intr;
           method Bool status();
              return False;
           endmethod
           method Bit#(dataWidth) channel();
              return -1;
           endmethod
        endinterface
    endinterface
    interface MemServerRequestInputPipes pipes;
        interface addrTrans_PipeOut = addrTrans_requestAdapter.out;
        interface setTileState_PipeOut = setTileState_requestAdapter.out;
        interface stateDbg_PipeOut = stateDbg_requestAdapter.out;
        interface memoryTraffic_PipeOut = memoryTraffic_requestAdapter.out;
    endinterface
endmodule

module mkMemServerRequestWrapperPortal#(MemServerRequest ifc)(MemServerRequestWrapperPortal);
    let dut <- mkMemServerRequestInput;
    mkConnection(dut.pipes, ifc);
    interface PipePortal portalIfc = dut.portalIfc;
endmodule

interface MemServerRequestWrapperMemPortalPipes;
    interface MemServerRequestInputPipes pipes;
    interface MemPortal#(12,32) portalIfc;
endinterface

(* synthesize *)
module mkMemServerRequestWrapperMemPortalPipes#(Bit#(SlaveDataBusWidth) id)(MemServerRequestWrapperMemPortalPipes);

  let dut <- mkMemServerRequestInput;
  PortalCtrlMemSlave#(SlaveControlAddrWidth,SlaveDataBusWidth) ctrlPort <- mkPortalCtrlMemSlave(id, dut.portalIfc.intr);
  let memslave  <- mkMemMethodMuxIn(ctrlPort.memSlave,dut.portalIfc.requests);
  interface MemServerRequestInputPipes pipes = dut.pipes;
  interface MemPortal portalIfc = (interface MemPortal;
      interface PhysMemSlave slave = memslave;
      interface ReadOnly interrupt = ctrlPort.interrupt;
      interface WriteOnly num_portals = ctrlPort.num_portals;
    endinterface);
endmodule

// exposed wrapper MemPortal implementation
module mkMemServerRequestWrapper#(idType id, MemServerRequest ifc)(MemServerRequestWrapper)
   provisos (Bits#(idType, a__),
	     Add#(b__, a__, SlaveDataBusWidth));
  let dut <- mkMemServerRequestWrapperMemPortalPipes(zeroExtend(pack(id)));
  mkConnection(dut.pipes, ifc);
  interface MemPortal portalIfc = dut.portalIfc;
endmodule

// exposed proxy interface
interface MemServerRequestOutput;
    interface PipePortal#(0, 4, SlaveDataBusWidth) portalIfc;
    interface ConnectalMemory::MemServerRequest ifc;
endinterface
interface MemServerRequestProxy;
    interface StdPortal portalIfc;
    interface ConnectalMemory::MemServerRequest ifc;
endinterface

interface MemServerRequestOutputPipeMethods;
    interface PipeIn#(AddrTrans_Message) addrTrans;
    interface PipeIn#(SetTileState_Message) setTileState;
    interface PipeIn#(StateDbg_Message) stateDbg;
    interface PipeIn#(MemoryTraffic_Message) memoryTraffic;

endinterface

interface MemServerRequestOutputPipes;
    interface MemServerRequestOutputPipeMethods methods;
    interface PipePortal#(0, 4, SlaveDataBusWidth) portalIfc;
endinterface

function Bit#(16) getMemServerRequestMessageSize(Bit#(16) methodNumber);
    case (methodNumber)
            0: return fromInteger(valueOf(SizeOf#(AddrTrans_Message)));
            1: return fromInteger(valueOf(SizeOf#(SetTileState_Message)));
            2: return fromInteger(valueOf(SizeOf#(StateDbg_Message)));
            3: return fromInteger(valueOf(SizeOf#(MemoryTraffic_Message)));
    endcase
endfunction

(* synthesize *)
module mkMemServerRequestOutputPipes(MemServerRequestOutputPipes);
    Vector#(4, PipeOut#(Bit#(SlaveDataBusWidth))) indicationPipes;

    AdapterToBus#(SlaveDataBusWidth,AddrTrans_Message) addrTrans_responseAdapter <- mkAdapterToBus();
    indicationPipes[0] = addrTrans_responseAdapter.out;

    AdapterToBus#(SlaveDataBusWidth,SetTileState_Message) setTileState_responseAdapter <- mkAdapterToBus();
    indicationPipes[1] = setTileState_responseAdapter.out;

    AdapterToBus#(SlaveDataBusWidth,StateDbg_Message) stateDbg_responseAdapter <- mkAdapterToBus();
    indicationPipes[2] = stateDbg_responseAdapter.out;

    AdapterToBus#(SlaveDataBusWidth,MemoryTraffic_Message) memoryTraffic_responseAdapter <- mkAdapterToBus();
    indicationPipes[3] = memoryTraffic_responseAdapter.out;

    PortalInterrupt#(SlaveDataBusWidth) intrInst <- mkPortalInterrupt(indicationPipes);
    interface MemServerRequestOutputPipeMethods methods;
    interface addrTrans = addrTrans_responseAdapter.in;
    interface setTileState = setTileState_responseAdapter.in;
    interface stateDbg = stateDbg_responseAdapter.in;
    interface memoryTraffic = memoryTraffic_responseAdapter.in;

    endinterface
    interface PipePortal portalIfc;
        interface PortalSize messageSize;
            method size = getMemServerRequestMessageSize;
        endinterface
        interface Vector requests = nil;
        interface Vector indications = indicationPipes;
        interface PortalInterrupt intr = intrInst;
    endinterface
endmodule

(* synthesize *)
module mkMemServerRequestOutput(MemServerRequestOutput);
    let indicationPipes <- mkMemServerRequestOutputPipes;
    interface ConnectalMemory::MemServerRequest ifc;

    method Action addrTrans(Bit#(32) sglId, Bit#(32) offset);
        indicationPipes.methods.addrTrans.enq(AddrTrans_Message {sglId: sglId, offset: offset});
        //$display("indicationMethod 'addrTrans' invoked");
    endmethod
    method Action setTileState(TileControl tc);
        indicationPipes.methods.setTileState.enq(SetTileState_Message {tc: tc});
        //$display("indicationMethod 'setTileState' invoked");
    endmethod
    method Action stateDbg(ChannelType rc);
        indicationPipes.methods.stateDbg.enq(StateDbg_Message {rc: rc});
        //$display("indicationMethod 'stateDbg' invoked");
    endmethod
    method Action memoryTraffic(ChannelType rc);
        indicationPipes.methods.memoryTraffic.enq(MemoryTraffic_Message {rc: rc});
        //$display("indicationMethod 'memoryTraffic' invoked");
    endmethod
    endinterface
    interface PipePortal portalIfc = indicationPipes.portalIfc;
endmodule
instance PortalMessageSize#(MemServerRequestOutput);
   function Bit#(16) portalMessageSize(MemServerRequestOutput p, Bit#(16) methodNumber);
      return getMemServerRequestMessageSize(methodNumber);
   endfunction
endinstance


interface MemServerRequestInverse;
    method ActionValue#(AddrTrans_Message) addrTrans;
    method ActionValue#(SetTileState_Message) setTileState;
    method ActionValue#(StateDbg_Message) stateDbg;
    method ActionValue#(MemoryTraffic_Message) memoryTraffic;

endinterface

interface MemServerRequestInverter;
    interface ConnectalMemory::MemServerRequest ifc;
    interface MemServerRequestInverse inverseIfc;
endinterface

instance Connectable#(MemServerRequestInverse, MemServerRequestOutputPipeMethods);
   module mkConnection#(MemServerRequestInverse in, MemServerRequestOutputPipeMethods out)(Empty);
    mkConnection(in.addrTrans, out.addrTrans);
    mkConnection(in.setTileState, out.setTileState);
    mkConnection(in.stateDbg, out.stateDbg);
    mkConnection(in.memoryTraffic, out.memoryTraffic);

   endmodule
endinstance

(* synthesize *)
module mkMemServerRequestInverter(MemServerRequestInverter);
    FIFOF#(AddrTrans_Message) fifo_addrTrans <- mkFIFOF();
    FIFOF#(SetTileState_Message) fifo_setTileState <- mkFIFOF();
    FIFOF#(StateDbg_Message) fifo_stateDbg <- mkFIFOF();
    FIFOF#(MemoryTraffic_Message) fifo_memoryTraffic <- mkFIFOF();

    interface ConnectalMemory::MemServerRequest ifc;

    method Action addrTrans(Bit#(32) sglId, Bit#(32) offset);
        fifo_addrTrans.enq(AddrTrans_Message {sglId: sglId, offset: offset});
    endmethod
    method Action setTileState(TileControl tc);
        fifo_setTileState.enq(SetTileState_Message {tc: tc});
    endmethod
    method Action stateDbg(ChannelType rc);
        fifo_stateDbg.enq(StateDbg_Message {rc: rc});
    endmethod
    method Action memoryTraffic(ChannelType rc);
        fifo_memoryTraffic.enq(MemoryTraffic_Message {rc: rc});
    endmethod
    endinterface
    interface MemServerRequestInverse inverseIfc;

    method ActionValue#(AddrTrans_Message) addrTrans;
        fifo_addrTrans.deq;
        return fifo_addrTrans.first;
    endmethod
    method ActionValue#(SetTileState_Message) setTileState;
        fifo_setTileState.deq;
        return fifo_setTileState.first;
    endmethod
    method ActionValue#(StateDbg_Message) stateDbg;
        fifo_stateDbg.deq;
        return fifo_stateDbg.first;
    endmethod
    method ActionValue#(MemoryTraffic_Message) memoryTraffic;
        fifo_memoryTraffic.deq;
        return fifo_memoryTraffic.first;
    endmethod
    endinterface
endmodule

(* synthesize *)
module mkMemServerRequestInverterV(MemServerRequestInverter);
    PutInverter#(AddrTrans_Message) inv_addrTrans <- mkPutInverter();
    PutInverter#(SetTileState_Message) inv_setTileState <- mkPutInverter();
    PutInverter#(StateDbg_Message) inv_stateDbg <- mkPutInverter();
    PutInverter#(MemoryTraffic_Message) inv_memoryTraffic <- mkPutInverter();

    interface ConnectalMemory::MemServerRequest ifc;

    method Action addrTrans(Bit#(32) sglId, Bit#(32) offset);
        inv_addrTrans.mod.put(AddrTrans_Message {sglId: sglId, offset: offset});
    endmethod
    method Action setTileState(TileControl tc);
        inv_setTileState.mod.put(SetTileState_Message {tc: tc});
    endmethod
    method Action stateDbg(ChannelType rc);
        inv_stateDbg.mod.put(StateDbg_Message {rc: rc});
    endmethod
    method Action memoryTraffic(ChannelType rc);
        inv_memoryTraffic.mod.put(MemoryTraffic_Message {rc: rc});
    endmethod
    endinterface
    interface MemServerRequestInverse inverseIfc;

    method ActionValue#(AddrTrans_Message) addrTrans;
        let v <- inv_addrTrans.inverse.get;
        return v;
    endmethod
    method ActionValue#(SetTileState_Message) setTileState;
        let v <- inv_setTileState.inverse.get;
        return v;
    endmethod
    method ActionValue#(StateDbg_Message) stateDbg;
        let v <- inv_stateDbg.inverse.get;
        return v;
    endmethod
    method ActionValue#(MemoryTraffic_Message) memoryTraffic;
        let v <- inv_memoryTraffic.inverse.get;
        return v;
    endmethod
    endinterface
endmodule

// synthesizeable proxy MemPortal
(* synthesize *)
module mkMemServerRequestProxySynth#(Bit#(SlaveDataBusWidth) id)(MemServerRequestProxy);
  let dut <- mkMemServerRequestOutput();
  PortalCtrlMemSlave#(SlaveControlAddrWidth,SlaveDataBusWidth) ctrlPort <- mkPortalCtrlMemSlave(id, dut.portalIfc.intr);
  let memslave  <- mkMemMethodMuxOut(ctrlPort.memSlave,dut.portalIfc.indications);
  interface MemPortal portalIfc = (interface MemPortal;
      interface PhysMemSlave slave = memslave;
      interface ReadOnly interrupt = ctrlPort.interrupt;
      interface WriteOnly num_portals = ctrlPort.num_portals;
    endinterface);
  interface ConnectalMemory::MemServerRequest ifc = dut.ifc;
endmodule

// exposed proxy MemPortal
module mkMemServerRequestProxy#(idType id)(MemServerRequestProxy)
   provisos (Bits#(idType, a__),
	     Add#(b__, a__, SlaveDataBusWidth));
   let rv <- mkMemServerRequestProxySynth(extend(pack(id)));
   return rv;
endmodule
endpackage: MemServerRequest
