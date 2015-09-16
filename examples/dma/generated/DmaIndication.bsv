package DmaIndication;

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
import DmaController::*;
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
    Bit#(32) objId;
    Bit#(32) base;
    Bit#(8) tag;
} ReadDone_Message deriving (Bits);

typedef struct {
    Bit#(32) objId;
    Bit#(32) base;
    Bit#(8) tag;
} WriteDone_Message deriving (Bits);

// exposed wrapper portal interface
interface DmaIndicationInputPipes;
    interface PipeOut#(ReadDone_Message) readDone_PipeOut;
    interface PipeOut#(WriteDone_Message) writeDone_PipeOut;

endinterface
interface DmaIndicationInput;
    interface PipePortal#(2, 0, SlaveDataBusWidth) portalIfc;
    interface DmaIndicationInputPipes pipes;
endinterface
interface DmaIndicationWrapperPortal;
    interface PipePortal#(2, 0, SlaveDataBusWidth) portalIfc;
endinterface
// exposed wrapper MemPortal interface
interface DmaIndicationWrapper;
    interface StdPortal portalIfc;
endinterface

instance Connectable#(DmaIndicationInputPipes,DmaIndication);
   module mkConnection#(DmaIndicationInputPipes pipes, DmaIndication ifc)(Empty);

    rule handle_readDone_request;
        let request <- toGet(pipes.readDone_PipeOut).get();
        ifc.readDone(request.objId, request.base, request.tag);
    endrule

    rule handle_writeDone_request;
        let request <- toGet(pipes.writeDone_PipeOut).get();
        ifc.writeDone(request.objId, request.base, request.tag);
    endrule

   endmodule
endinstance

// exposed wrapper Portal implementation
(* synthesize *)
module mkDmaIndicationInput(DmaIndicationInput);
    Vector#(2, PipeIn#(Bit#(SlaveDataBusWidth))) requestPipeIn;

    AdapterFromBus#(SlaveDataBusWidth,ReadDone_Message) readDone_requestAdapter <- mkAdapterFromBus();
    requestPipeIn[0] = readDone_requestAdapter.in;

    AdapterFromBus#(SlaveDataBusWidth,WriteDone_Message) writeDone_requestAdapter <- mkAdapterFromBus();
    requestPipeIn[1] = writeDone_requestAdapter.in;

    interface PipePortal portalIfc;
        interface PortalSize messageSize;
        method Bit#(16) size(Bit#(16) methodNumber);
            case (methodNumber)
            0: return fromInteger(valueOf(SizeOf#(ReadDone_Message)));
            1: return fromInteger(valueOf(SizeOf#(WriteDone_Message)));
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
    interface DmaIndicationInputPipes pipes;
        interface readDone_PipeOut = readDone_requestAdapter.out;
        interface writeDone_PipeOut = writeDone_requestAdapter.out;
    endinterface
endmodule

module mkDmaIndicationWrapperPortal#(DmaIndication ifc)(DmaIndicationWrapperPortal);
    let dut <- mkDmaIndicationInput;
    mkConnection(dut.pipes, ifc);
    interface PipePortal portalIfc = dut.portalIfc;
endmodule

interface DmaIndicationWrapperMemPortalPipes;
    interface DmaIndicationInputPipes pipes;
    interface MemPortal#(12,32) portalIfc;
endinterface

(* synthesize *)
module mkDmaIndicationWrapperMemPortalPipes#(Bit#(SlaveDataBusWidth) id)(DmaIndicationWrapperMemPortalPipes);

  let dut <- mkDmaIndicationInput;
  PortalCtrlMemSlave#(SlaveControlAddrWidth,SlaveDataBusWidth) ctrlPort <- mkPortalCtrlMemSlave(id, dut.portalIfc.intr);
  let memslave  <- mkMemMethodMuxIn(ctrlPort.memSlave,dut.portalIfc.requests);
  interface DmaIndicationInputPipes pipes = dut.pipes;
  interface MemPortal portalIfc = (interface MemPortal;
      interface PhysMemSlave slave = memslave;
      interface ReadOnly interrupt = ctrlPort.interrupt;
      interface WriteOnly num_portals = ctrlPort.num_portals;
    endinterface);
endmodule

// exposed wrapper MemPortal implementation
module mkDmaIndicationWrapper#(idType id, DmaIndication ifc)(DmaIndicationWrapper)
   provisos (Bits#(idType, a__),
	     Add#(b__, a__, SlaveDataBusWidth));
  let dut <- mkDmaIndicationWrapperMemPortalPipes(zeroExtend(pack(id)));
  mkConnection(dut.pipes, ifc);
  interface MemPortal portalIfc = dut.portalIfc;
endmodule

// exposed proxy interface
interface DmaIndicationOutput;
    interface PipePortal#(0, 2, SlaveDataBusWidth) portalIfc;
    interface DmaController::DmaIndication ifc;
endinterface
interface DmaIndicationProxy;
    interface StdPortal portalIfc;
    interface DmaController::DmaIndication ifc;
endinterface

interface DmaIndicationOutputPipeMethods;
    interface PipeIn#(ReadDone_Message) readDone;
    interface PipeIn#(WriteDone_Message) writeDone;

endinterface

interface DmaIndicationOutputPipes;
    interface DmaIndicationOutputPipeMethods methods;
    interface PipePortal#(0, 2, SlaveDataBusWidth) portalIfc;
endinterface

function Bit#(16) getDmaIndicationMessageSize(Bit#(16) methodNumber);
    case (methodNumber)
            0: return fromInteger(valueOf(SizeOf#(ReadDone_Message)));
            1: return fromInteger(valueOf(SizeOf#(WriteDone_Message)));
    endcase
endfunction

(* synthesize *)
module mkDmaIndicationOutputPipes(DmaIndicationOutputPipes);
    Vector#(2, PipeOut#(Bit#(SlaveDataBusWidth))) indicationPipes;

    AdapterToBus#(SlaveDataBusWidth,ReadDone_Message) readDone_responseAdapter <- mkAdapterToBus();
    indicationPipes[0] = readDone_responseAdapter.out;

    AdapterToBus#(SlaveDataBusWidth,WriteDone_Message) writeDone_responseAdapter <- mkAdapterToBus();
    indicationPipes[1] = writeDone_responseAdapter.out;

    PortalInterrupt#(SlaveDataBusWidth) intrInst <- mkPortalInterrupt(indicationPipes);
    interface DmaIndicationOutputPipeMethods methods;
    interface readDone = readDone_responseAdapter.in;
    interface writeDone = writeDone_responseAdapter.in;

    endinterface
    interface PipePortal portalIfc;
        interface PortalSize messageSize;
            method size = getDmaIndicationMessageSize;
        endinterface
        interface Vector requests = nil;
        interface Vector indications = indicationPipes;
        interface PortalInterrupt intr = intrInst;
    endinterface
endmodule

(* synthesize *)
module mkDmaIndicationOutput(DmaIndicationOutput);
    let indicationPipes <- mkDmaIndicationOutputPipes;
    interface DmaController::DmaIndication ifc;

    method Action readDone(Bit#(32) objId, Bit#(32) base, Bit#(8) tag);
        indicationPipes.methods.readDone.enq(ReadDone_Message {objId: objId, base: base, tag: tag});
        //$display("indicationMethod 'readDone' invoked");
    endmethod
    method Action writeDone(Bit#(32) objId, Bit#(32) base, Bit#(8) tag);
        indicationPipes.methods.writeDone.enq(WriteDone_Message {objId: objId, base: base, tag: tag});
        //$display("indicationMethod 'writeDone' invoked");
    endmethod
    endinterface
    interface PipePortal portalIfc = indicationPipes.portalIfc;
endmodule
instance PortalMessageSize#(DmaIndicationOutput);
   function Bit#(16) portalMessageSize(DmaIndicationOutput p, Bit#(16) methodNumber);
      return getDmaIndicationMessageSize(methodNumber);
   endfunction
endinstance


interface DmaIndicationInverse;
    method ActionValue#(ReadDone_Message) readDone;
    method ActionValue#(WriteDone_Message) writeDone;

endinterface

interface DmaIndicationInverter;
    interface DmaController::DmaIndication ifc;
    interface DmaIndicationInverse inverseIfc;
endinterface

instance Connectable#(DmaIndicationInverse, DmaIndicationOutputPipeMethods);
   module mkConnection#(DmaIndicationInverse in, DmaIndicationOutputPipeMethods out)(Empty);
    mkConnection(in.readDone, out.readDone);
    mkConnection(in.writeDone, out.writeDone);

   endmodule
endinstance

(* synthesize *)
module mkDmaIndicationInverter(DmaIndicationInverter);
    FIFOF#(ReadDone_Message) fifo_readDone <- mkFIFOF();
    FIFOF#(WriteDone_Message) fifo_writeDone <- mkFIFOF();

    interface DmaController::DmaIndication ifc;

    method Action readDone(Bit#(32) objId, Bit#(32) base, Bit#(8) tag);
        fifo_readDone.enq(ReadDone_Message {objId: objId, base: base, tag: tag});
    endmethod
    method Action writeDone(Bit#(32) objId, Bit#(32) base, Bit#(8) tag);
        fifo_writeDone.enq(WriteDone_Message {objId: objId, base: base, tag: tag});
    endmethod
    endinterface
    interface DmaIndicationInverse inverseIfc;

    method ActionValue#(ReadDone_Message) readDone;
        fifo_readDone.deq;
        return fifo_readDone.first;
    endmethod
    method ActionValue#(WriteDone_Message) writeDone;
        fifo_writeDone.deq;
        return fifo_writeDone.first;
    endmethod
    endinterface
endmodule

(* synthesize *)
module mkDmaIndicationInverterV(DmaIndicationInverter);
    PutInverter#(ReadDone_Message) inv_readDone <- mkPutInverter();
    PutInverter#(WriteDone_Message) inv_writeDone <- mkPutInverter();

    interface DmaController::DmaIndication ifc;

    method Action readDone(Bit#(32) objId, Bit#(32) base, Bit#(8) tag);
        inv_readDone.mod.put(ReadDone_Message {objId: objId, base: base, tag: tag});
    endmethod
    method Action writeDone(Bit#(32) objId, Bit#(32) base, Bit#(8) tag);
        inv_writeDone.mod.put(WriteDone_Message {objId: objId, base: base, tag: tag});
    endmethod
    endinterface
    interface DmaIndicationInverse inverseIfc;

    method ActionValue#(ReadDone_Message) readDone;
        let v <- inv_readDone.inverse.get;
        return v;
    endmethod
    method ActionValue#(WriteDone_Message) writeDone;
        let v <- inv_writeDone.inverse.get;
        return v;
    endmethod
    endinterface
endmodule

// synthesizeable proxy MemPortal
(* synthesize *)
module mkDmaIndicationProxySynth#(Bit#(SlaveDataBusWidth) id)(DmaIndicationProxy);
  let dut <- mkDmaIndicationOutput();
  PortalCtrlMemSlave#(SlaveControlAddrWidth,SlaveDataBusWidth) ctrlPort <- mkPortalCtrlMemSlave(id, dut.portalIfc.intr);
  let memslave  <- mkMemMethodMuxOut(ctrlPort.memSlave,dut.portalIfc.indications);
  interface MemPortal portalIfc = (interface MemPortal;
      interface PhysMemSlave slave = memslave;
      interface ReadOnly interrupt = ctrlPort.interrupt;
      interface WriteOnly num_portals = ctrlPort.num_portals;
    endinterface);
  interface DmaController::DmaIndication ifc = dut.ifc;
endmodule

// exposed proxy MemPortal
module mkDmaIndicationProxy#(idType id)(DmaIndicationProxy)
   provisos (Bits#(idType, a__),
	     Add#(b__, a__, SlaveDataBusWidth));
   let rv <- mkDmaIndicationProxySynth(extend(pack(id)));
   return rv;
endmodule
endpackage: DmaIndication
