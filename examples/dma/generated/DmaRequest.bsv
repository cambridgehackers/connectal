package DmaRequest;

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
    Bit#(8) burstLenBytes;
} BurstLen_Message deriving (Bits);

typedef struct {
    Bit#(32) objId;
    Bit#(32) base;
    Bit#(32) bytes;
    Bit#(8) tag;
} Read_Message deriving (Bits);

typedef struct {
    Bit#(32) objId;
    Bit#(32) base;
    Bit#(32) bytes;
    Bit#(8) tag;
} Write_Message deriving (Bits);

// exposed wrapper portal interface
interface DmaRequestInputPipes;
    interface PipeOut#(BurstLen_Message) burstLen_PipeOut;
    interface PipeOut#(Read_Message) read_PipeOut;
    interface PipeOut#(Write_Message) write_PipeOut;

endinterface
interface DmaRequestInput;
    interface PipePortal#(3, 0, SlaveDataBusWidth) portalIfc;
    interface DmaRequestInputPipes pipes;
endinterface
interface DmaRequestWrapperPortal;
    interface PipePortal#(3, 0, SlaveDataBusWidth) portalIfc;
endinterface
// exposed wrapper MemPortal interface
interface DmaRequestWrapper;
    interface StdPortal portalIfc;
endinterface

instance Connectable#(DmaRequestInputPipes,DmaRequest);
   module mkConnection#(DmaRequestInputPipes pipes, DmaRequest ifc)(Empty);

    rule handle_burstLen_request;
        let request <- toGet(pipes.burstLen_PipeOut).get();
        ifc.burstLen(request.burstLenBytes);
    endrule

    rule handle_read_request;
        let request <- toGet(pipes.read_PipeOut).get();
        ifc.read(request.objId, request.base, request.bytes, request.tag);
    endrule

    rule handle_write_request;
        let request <- toGet(pipes.write_PipeOut).get();
        ifc.write(request.objId, request.base, request.bytes, request.tag);
    endrule

   endmodule
endinstance

// exposed wrapper Portal implementation
(* synthesize *)
module mkDmaRequestInput(DmaRequestInput);
    Vector#(3, PipeIn#(Bit#(SlaveDataBusWidth))) requestPipeIn;

    AdapterFromBus#(SlaveDataBusWidth,BurstLen_Message) burstLen_requestAdapter <- mkAdapterFromBus();
    requestPipeIn[0] = burstLen_requestAdapter.in;

    AdapterFromBus#(SlaveDataBusWidth,Read_Message) read_requestAdapter <- mkAdapterFromBus();
    requestPipeIn[1] = read_requestAdapter.in;

    AdapterFromBus#(SlaveDataBusWidth,Write_Message) write_requestAdapter <- mkAdapterFromBus();
    requestPipeIn[2] = write_requestAdapter.in;

    interface PipePortal portalIfc;
        interface PortalSize messageSize;
        method Bit#(16) size(Bit#(16) methodNumber);
            case (methodNumber)
            0: return fromInteger(valueOf(SizeOf#(BurstLen_Message)));
            1: return fromInteger(valueOf(SizeOf#(Read_Message)));
            2: return fromInteger(valueOf(SizeOf#(Write_Message)));
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
    interface DmaRequestInputPipes pipes;
        interface burstLen_PipeOut = burstLen_requestAdapter.out;
        interface read_PipeOut = read_requestAdapter.out;
        interface write_PipeOut = write_requestAdapter.out;
    endinterface
endmodule

module mkDmaRequestWrapperPortal#(DmaRequest ifc)(DmaRequestWrapperPortal);
    let dut <- mkDmaRequestInput;
    mkConnection(dut.pipes, ifc);
    interface PipePortal portalIfc = dut.portalIfc;
endmodule

interface DmaRequestWrapperMemPortalPipes;
    interface DmaRequestInputPipes pipes;
    interface MemPortal#(12,32) portalIfc;
endinterface

(* synthesize *)
module mkDmaRequestWrapperMemPortalPipes#(Bit#(SlaveDataBusWidth) id)(DmaRequestWrapperMemPortalPipes);

  let dut <- mkDmaRequestInput;
  PortalCtrlMemSlave#(SlaveControlAddrWidth,SlaveDataBusWidth) ctrlPort <- mkPortalCtrlMemSlave(id, dut.portalIfc.intr);
  let memslave  <- mkMemMethodMuxIn(ctrlPort.memSlave,dut.portalIfc.requests);
  interface DmaRequestInputPipes pipes = dut.pipes;
  interface MemPortal portalIfc = (interface MemPortal;
      interface PhysMemSlave slave = memslave;
      interface ReadOnly interrupt = ctrlPort.interrupt;
      interface WriteOnly num_portals = ctrlPort.num_portals;
    endinterface);
endmodule

// exposed wrapper MemPortal implementation
module mkDmaRequestWrapper#(idType id, DmaRequest ifc)(DmaRequestWrapper)
   provisos (Bits#(idType, a__),
	     Add#(b__, a__, SlaveDataBusWidth));
  let dut <- mkDmaRequestWrapperMemPortalPipes(zeroExtend(pack(id)));
  mkConnection(dut.pipes, ifc);
  interface MemPortal portalIfc = dut.portalIfc;
endmodule

// exposed proxy interface
interface DmaRequestOutput;
    interface PipePortal#(0, 3, SlaveDataBusWidth) portalIfc;
    interface DmaController::DmaRequest ifc;
endinterface
interface DmaRequestProxy;
    interface StdPortal portalIfc;
    interface DmaController::DmaRequest ifc;
endinterface

interface DmaRequestOutputPipeMethods;
    interface PipeIn#(BurstLen_Message) burstLen;
    interface PipeIn#(Read_Message) read;
    interface PipeIn#(Write_Message) write;

endinterface

interface DmaRequestOutputPipes;
    interface DmaRequestOutputPipeMethods methods;
    interface PipePortal#(0, 3, SlaveDataBusWidth) portalIfc;
endinterface

function Bit#(16) getDmaRequestMessageSize(Bit#(16) methodNumber);
    case (methodNumber)
            0: return fromInteger(valueOf(SizeOf#(BurstLen_Message)));
            1: return fromInteger(valueOf(SizeOf#(Read_Message)));
            2: return fromInteger(valueOf(SizeOf#(Write_Message)));
    endcase
endfunction

(* synthesize *)
module mkDmaRequestOutputPipes(DmaRequestOutputPipes);
    Vector#(3, PipeOut#(Bit#(SlaveDataBusWidth))) indicationPipes;

    AdapterToBus#(SlaveDataBusWidth,BurstLen_Message) burstLen_responseAdapter <- mkAdapterToBus();
    indicationPipes[0] = burstLen_responseAdapter.out;

    AdapterToBus#(SlaveDataBusWidth,Read_Message) read_responseAdapter <- mkAdapterToBus();
    indicationPipes[1] = read_responseAdapter.out;

    AdapterToBus#(SlaveDataBusWidth,Write_Message) write_responseAdapter <- mkAdapterToBus();
    indicationPipes[2] = write_responseAdapter.out;

    PortalInterrupt#(SlaveDataBusWidth) intrInst <- mkPortalInterrupt(indicationPipes);
    interface DmaRequestOutputPipeMethods methods;
    interface burstLen = burstLen_responseAdapter.in;
    interface read = read_responseAdapter.in;
    interface write = write_responseAdapter.in;

    endinterface
    interface PipePortal portalIfc;
        interface PortalSize messageSize;
            method size = getDmaRequestMessageSize;
        endinterface
        interface Vector requests = nil;
        interface Vector indications = indicationPipes;
        interface PortalInterrupt intr = intrInst;
    endinterface
endmodule

(* synthesize *)
module mkDmaRequestOutput(DmaRequestOutput);
    let indicationPipes <- mkDmaRequestOutputPipes;
    interface DmaController::DmaRequest ifc;

    method Action burstLen(Bit#(8) burstLenBytes);
        indicationPipes.methods.burstLen.enq(BurstLen_Message {burstLenBytes: burstLenBytes});
        //$display("indicationMethod 'burstLen' invoked");
    endmethod
    method Action read(Bit#(32) objId, Bit#(32) base, Bit#(32) bytes, Bit#(8) tag);
        indicationPipes.methods.read.enq(Read_Message {objId: objId, base: base, bytes: bytes, tag: tag});
        //$display("indicationMethod 'read' invoked");
    endmethod
    method Action write(Bit#(32) objId, Bit#(32) base, Bit#(32) bytes, Bit#(8) tag);
        indicationPipes.methods.write.enq(Write_Message {objId: objId, base: base, bytes: bytes, tag: tag});
        //$display("indicationMethod 'write' invoked");
    endmethod
    endinterface
    interface PipePortal portalIfc = indicationPipes.portalIfc;
endmodule
instance PortalMessageSize#(DmaRequestOutput);
   function Bit#(16) portalMessageSize(DmaRequestOutput p, Bit#(16) methodNumber);
      return getDmaRequestMessageSize(methodNumber);
   endfunction
endinstance


interface DmaRequestInverse;
    method ActionValue#(BurstLen_Message) burstLen;
    method ActionValue#(Read_Message) read;
    method ActionValue#(Write_Message) write;

endinterface

interface DmaRequestInverter;
    interface DmaController::DmaRequest ifc;
    interface DmaRequestInverse inverseIfc;
endinterface

instance Connectable#(DmaRequestInverse, DmaRequestOutputPipeMethods);
   module mkConnection#(DmaRequestInverse in, DmaRequestOutputPipeMethods out)(Empty);
    mkConnection(in.burstLen, out.burstLen);
    mkConnection(in.read, out.read);
    mkConnection(in.write, out.write);

   endmodule
endinstance

(* synthesize *)
module mkDmaRequestInverter(DmaRequestInverter);
    FIFOF#(BurstLen_Message) fifo_burstLen <- mkFIFOF();
    FIFOF#(Read_Message) fifo_read <- mkFIFOF();
    FIFOF#(Write_Message) fifo_write <- mkFIFOF();

    interface DmaController::DmaRequest ifc;

    method Action burstLen(Bit#(8) burstLenBytes);
        fifo_burstLen.enq(BurstLen_Message {burstLenBytes: burstLenBytes});
    endmethod
    method Action read(Bit#(32) objId, Bit#(32) base, Bit#(32) bytes, Bit#(8) tag);
        fifo_read.enq(Read_Message {objId: objId, base: base, bytes: bytes, tag: tag});
    endmethod
    method Action write(Bit#(32) objId, Bit#(32) base, Bit#(32) bytes, Bit#(8) tag);
        fifo_write.enq(Write_Message {objId: objId, base: base, bytes: bytes, tag: tag});
    endmethod
    endinterface
    interface DmaRequestInverse inverseIfc;

    method ActionValue#(BurstLen_Message) burstLen;
        fifo_burstLen.deq;
        return fifo_burstLen.first;
    endmethod
    method ActionValue#(Read_Message) read;
        fifo_read.deq;
        return fifo_read.first;
    endmethod
    method ActionValue#(Write_Message) write;
        fifo_write.deq;
        return fifo_write.first;
    endmethod
    endinterface
endmodule

(* synthesize *)
module mkDmaRequestInverterV(DmaRequestInverter);
    PutInverter#(BurstLen_Message) inv_burstLen <- mkPutInverter();
    PutInverter#(Read_Message) inv_read <- mkPutInverter();
    PutInverter#(Write_Message) inv_write <- mkPutInverter();

    interface DmaController::DmaRequest ifc;

    method Action burstLen(Bit#(8) burstLenBytes);
        inv_burstLen.mod.put(BurstLen_Message {burstLenBytes: burstLenBytes});
    endmethod
    method Action read(Bit#(32) objId, Bit#(32) base, Bit#(32) bytes, Bit#(8) tag);
        inv_read.mod.put(Read_Message {objId: objId, base: base, bytes: bytes, tag: tag});
    endmethod
    method Action write(Bit#(32) objId, Bit#(32) base, Bit#(32) bytes, Bit#(8) tag);
        inv_write.mod.put(Write_Message {objId: objId, base: base, bytes: bytes, tag: tag});
    endmethod
    endinterface
    interface DmaRequestInverse inverseIfc;

    method ActionValue#(BurstLen_Message) burstLen;
        let v <- inv_burstLen.inverse.get;
        return v;
    endmethod
    method ActionValue#(Read_Message) read;
        let v <- inv_read.inverse.get;
        return v;
    endmethod
    method ActionValue#(Write_Message) write;
        let v <- inv_write.inverse.get;
        return v;
    endmethod
    endinterface
endmodule

// synthesizeable proxy MemPortal
(* synthesize *)
module mkDmaRequestProxySynth#(Bit#(SlaveDataBusWidth) id)(DmaRequestProxy);
  let dut <- mkDmaRequestOutput();
  PortalCtrlMemSlave#(SlaveControlAddrWidth,SlaveDataBusWidth) ctrlPort <- mkPortalCtrlMemSlave(id, dut.portalIfc.intr);
  let memslave  <- mkMemMethodMuxOut(ctrlPort.memSlave,dut.portalIfc.indications);
  interface MemPortal portalIfc = (interface MemPortal;
      interface PhysMemSlave slave = memslave;
      interface ReadOnly interrupt = ctrlPort.interrupt;
      interface WriteOnly num_portals = ctrlPort.num_portals;
    endinterface);
  interface DmaController::DmaRequest ifc = dut.ifc;
endmodule

// exposed proxy MemPortal
module mkDmaRequestProxy#(idType id)(DmaRequestProxy)
   provisos (Bits#(idType, a__),
	     Add#(b__, a__, SlaveDataBusWidth));
   let rv <- mkDmaRequestProxySynth(extend(pack(id)));
   return rv;
endmodule
endpackage: DmaRequest
