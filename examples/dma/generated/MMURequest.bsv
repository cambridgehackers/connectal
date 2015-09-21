package MMURequest;

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
    Bit#(32) sglIndex;
    Bit#(64) addr;
    Bit#(32) len;
} Sglist_Message deriving (Bits);

typedef struct {
    Bit#(32) sglId;
    Bit#(64) barr12;
    Bit#(32) index12;
    Bit#(64) barr8;
    Bit#(32) index8;
    Bit#(64) barr4;
    Bit#(32) index4;
    Bit#(64) barr0;
    Bit#(32) index0;
} Region_Message deriving (Bits);

typedef struct {
    SpecialTypeForSendingFd fd;
} IdRequest_Message deriving (Bits);

typedef struct {
    Bit#(32) sglId;
} IdReturn_Message deriving (Bits);

typedef struct {
    Bit#(32) interfaceId;
    Bit#(32) sglId;
} SetInterface_Message deriving (Bits);

// exposed wrapper portal interface
interface MMURequestInputPipes;
    interface PipeOut#(Sglist_Message) sglist_PipeOut;
    interface PipeOut#(Region_Message) region_PipeOut;
    interface PipeOut#(IdRequest_Message) idRequest_PipeOut;
    interface PipeOut#(IdReturn_Message) idReturn_PipeOut;
    interface PipeOut#(SetInterface_Message) setInterface_PipeOut;

endinterface
interface MMURequestInput;
    interface PipePortal#(5, 0, SlaveDataBusWidth) portalIfc;
    interface MMURequestInputPipes pipes;
endinterface
interface MMURequestWrapperPortal;
    interface PipePortal#(5, 0, SlaveDataBusWidth) portalIfc;
endinterface
// exposed wrapper MemPortal interface
interface MMURequestWrapper;
    interface StdPortal portalIfc;
endinterface

instance Connectable#(MMURequestInputPipes,MMURequest);
   module mkConnection#(MMURequestInputPipes pipes, MMURequest ifc)(Empty);

    rule handle_sglist_request;
        let request <- toGet(pipes.sglist_PipeOut).get();
        ifc.sglist(request.sglId, request.sglIndex, request.addr, request.len);
    endrule

    rule handle_region_request;
        let request <- toGet(pipes.region_PipeOut).get();
        ifc.region(request.sglId, request.barr12, request.index12, request.barr8, request.index8, request.barr4, request.index4, request.barr0, request.index0);
    endrule

    rule handle_idRequest_request;
        let request <- toGet(pipes.idRequest_PipeOut).get();
        ifc.idRequest(request.fd);
    endrule

    rule handle_idReturn_request;
        let request <- toGet(pipes.idReturn_PipeOut).get();
        ifc.idReturn(request.sglId);
    endrule

    rule handle_setInterface_request;
        let request <- toGet(pipes.setInterface_PipeOut).get();
        ifc.setInterface(request.interfaceId, request.sglId);
    endrule

   endmodule
endinstance

// exposed wrapper Portal implementation
(* synthesize *)
module mkMMURequestInput(MMURequestInput);
    Vector#(5, PipeIn#(Bit#(SlaveDataBusWidth))) requestPipeIn;

    AdapterFromBus#(SlaveDataBusWidth,Sglist_Message) sglist_requestAdapter <- mkAdapterFromBus();
    requestPipeIn[0] = sglist_requestAdapter.in;

    AdapterFromBus#(SlaveDataBusWidth,Region_Message) region_requestAdapter <- mkAdapterFromBus();
    requestPipeIn[1] = region_requestAdapter.in;

    AdapterFromBus#(SlaveDataBusWidth,IdRequest_Message) idRequest_requestAdapter <- mkAdapterFromBus();
    requestPipeIn[2] = idRequest_requestAdapter.in;

    AdapterFromBus#(SlaveDataBusWidth,IdReturn_Message) idReturn_requestAdapter <- mkAdapterFromBus();
    requestPipeIn[3] = idReturn_requestAdapter.in;

    AdapterFromBus#(SlaveDataBusWidth,SetInterface_Message) setInterface_requestAdapter <- mkAdapterFromBus();
    requestPipeIn[4] = setInterface_requestAdapter.in;

    interface PipePortal portalIfc;
        interface PortalSize messageSize;
        method Bit#(16) size(Bit#(16) methodNumber);
            case (methodNumber)
            0: return fromInteger(valueOf(SizeOf#(Sglist_Message)));
            1: return fromInteger(valueOf(SizeOf#(Region_Message)));
            2: return fromInteger(valueOf(SizeOf#(IdRequest_Message)));
            3: return fromInteger(valueOf(SizeOf#(IdReturn_Message)));
            4: return fromInteger(valueOf(SizeOf#(SetInterface_Message)));
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
    interface MMURequestInputPipes pipes;
        interface sglist_PipeOut = sglist_requestAdapter.out;
        interface region_PipeOut = region_requestAdapter.out;
        interface idRequest_PipeOut = idRequest_requestAdapter.out;
        interface idReturn_PipeOut = idReturn_requestAdapter.out;
        interface setInterface_PipeOut = setInterface_requestAdapter.out;
    endinterface
endmodule

module mkMMURequestWrapperPortal#(MMURequest ifc)(MMURequestWrapperPortal);
    let dut <- mkMMURequestInput;
    mkConnection(dut.pipes, ifc);
    interface PipePortal portalIfc = dut.portalIfc;
endmodule

interface MMURequestWrapperMemPortalPipes;
    interface MMURequestInputPipes pipes;
    interface MemPortal#(12,32) portalIfc;
endinterface

(* synthesize *)
module mkMMURequestWrapperMemPortalPipes#(Bit#(SlaveDataBusWidth) id)(MMURequestWrapperMemPortalPipes);

  let dut <- mkMMURequestInput;
  PortalCtrlMemSlave#(SlaveControlAddrWidth,SlaveDataBusWidth) ctrlPort <- mkPortalCtrlMemSlave(id, dut.portalIfc.intr);
  let memslave  <- mkMemMethodMuxIn(ctrlPort.memSlave,dut.portalIfc.requests);
  interface MMURequestInputPipes pipes = dut.pipes;
  interface MemPortal portalIfc = (interface MemPortal;
      interface PhysMemSlave slave = memslave;
      interface ReadOnly interrupt = ctrlPort.interrupt;
      interface WriteOnly num_portals = ctrlPort.num_portals;
    endinterface);
endmodule

// exposed wrapper MemPortal implementation
module mkMMURequestWrapper#(idType id, MMURequest ifc)(MMURequestWrapper)
   provisos (Bits#(idType, a__),
	     Add#(b__, a__, SlaveDataBusWidth));
  let dut <- mkMMURequestWrapperMemPortalPipes(zeroExtend(pack(id)));
  mkConnection(dut.pipes, ifc);
  interface MemPortal portalIfc = dut.portalIfc;
endmodule

// exposed proxy interface
interface MMURequestOutput;
    interface PipePortal#(0, 5, SlaveDataBusWidth) portalIfc;
    interface ConnectalMemory::MMURequest ifc;
endinterface
interface MMURequestProxy;
    interface StdPortal portalIfc;
    interface ConnectalMemory::MMURequest ifc;
endinterface

interface MMURequestOutputPipeMethods;
    interface PipeIn#(Sglist_Message) sglist;
    interface PipeIn#(Region_Message) region;
    interface PipeIn#(IdRequest_Message) idRequest;
    interface PipeIn#(IdReturn_Message) idReturn;
    interface PipeIn#(SetInterface_Message) setInterface;

endinterface

interface MMURequestOutputPipes;
    interface MMURequestOutputPipeMethods methods;
    interface PipePortal#(0, 5, SlaveDataBusWidth) portalIfc;
endinterface

function Bit#(16) getMMURequestMessageSize(Bit#(16) methodNumber);
    case (methodNumber)
            0: return fromInteger(valueOf(SizeOf#(Sglist_Message)));
            1: return fromInteger(valueOf(SizeOf#(Region_Message)));
            2: return fromInteger(valueOf(SizeOf#(IdRequest_Message)));
            3: return fromInteger(valueOf(SizeOf#(IdReturn_Message)));
            4: return fromInteger(valueOf(SizeOf#(SetInterface_Message)));
    endcase
endfunction

(* synthesize *)
module mkMMURequestOutputPipes(MMURequestOutputPipes);
    Vector#(5, PipeOut#(Bit#(SlaveDataBusWidth))) indicationPipes;

    AdapterToBus#(SlaveDataBusWidth,Sglist_Message) sglist_responseAdapter <- mkAdapterToBus();
    indicationPipes[0] = sglist_responseAdapter.out;

    AdapterToBus#(SlaveDataBusWidth,Region_Message) region_responseAdapter <- mkAdapterToBus();
    indicationPipes[1] = region_responseAdapter.out;

    AdapterToBus#(SlaveDataBusWidth,IdRequest_Message) idRequest_responseAdapter <- mkAdapterToBus();
    indicationPipes[2] = idRequest_responseAdapter.out;

    AdapterToBus#(SlaveDataBusWidth,IdReturn_Message) idReturn_responseAdapter <- mkAdapterToBus();
    indicationPipes[3] = idReturn_responseAdapter.out;

    AdapterToBus#(SlaveDataBusWidth,SetInterface_Message) setInterface_responseAdapter <- mkAdapterToBus();
    indicationPipes[4] = setInterface_responseAdapter.out;

    PortalInterrupt#(SlaveDataBusWidth) intrInst <- mkPortalInterrupt(indicationPipes);
    interface MMURequestOutputPipeMethods methods;
    interface sglist = sglist_responseAdapter.in;
    interface region = region_responseAdapter.in;
    interface idRequest = idRequest_responseAdapter.in;
    interface idReturn = idReturn_responseAdapter.in;
    interface setInterface = setInterface_responseAdapter.in;

    endinterface
    interface PipePortal portalIfc;
        interface PortalSize messageSize;
            method size = getMMURequestMessageSize;
        endinterface
        interface Vector requests = nil;
        interface Vector indications = indicationPipes;
        interface PortalInterrupt intr = intrInst;
    endinterface
endmodule

(* synthesize *)
module mkMMURequestOutput(MMURequestOutput);
    let indicationPipes <- mkMMURequestOutputPipes;
    interface ConnectalMemory::MMURequest ifc;

    method Action sglist(Bit#(32) sglId, Bit#(32) sglIndex, Bit#(64) addr, Bit#(32) len);
        indicationPipes.methods.sglist.enq(Sglist_Message {sglId: sglId, sglIndex: sglIndex, addr: addr, len: len});
        //$display("indicationMethod 'sglist' invoked");
    endmethod
    method Action region(Bit#(32) sglId, Bit#(64) barr12, Bit#(32) index12, Bit#(64) barr8, Bit#(32) index8, Bit#(64) barr4, Bit#(32) index4, Bit#(64) barr0, Bit#(32) index0);
        indicationPipes.methods.region.enq(Region_Message {sglId: sglId, barr12: barr12, index12: index12, barr8: barr8, index8: index8, barr4: barr4, index4: index4, barr0: barr0, index0: index0});
        //$display("indicationMethod 'region' invoked");
    endmethod
    method Action idRequest(SpecialTypeForSendingFd fd);
        indicationPipes.methods.idRequest.enq(IdRequest_Message {fd: fd});
        //$display("indicationMethod 'idRequest' invoked");
    endmethod
    method Action idReturn(Bit#(32) sglId);
        indicationPipes.methods.idReturn.enq(IdReturn_Message {sglId: sglId});
        //$display("indicationMethod 'idReturn' invoked");
    endmethod
    method Action setInterface(Bit#(32) interfaceId, Bit#(32) sglId);
        indicationPipes.methods.setInterface.enq(SetInterface_Message {interfaceId: interfaceId, sglId: sglId});
        //$display("indicationMethod 'setInterface' invoked");
    endmethod
    endinterface
    interface PipePortal portalIfc = indicationPipes.portalIfc;
endmodule
instance PortalMessageSize#(MMURequestOutput);
   function Bit#(16) portalMessageSize(MMURequestOutput p, Bit#(16) methodNumber);
      return getMMURequestMessageSize(methodNumber);
   endfunction
endinstance


interface MMURequestInverse;
    method ActionValue#(Sglist_Message) sglist;
    method ActionValue#(Region_Message) region;
    method ActionValue#(IdRequest_Message) idRequest;
    method ActionValue#(IdReturn_Message) idReturn;
    method ActionValue#(SetInterface_Message) setInterface;

endinterface

interface MMURequestInverter;
    interface ConnectalMemory::MMURequest ifc;
    interface MMURequestInverse inverseIfc;
endinterface

instance Connectable#(MMURequestInverse, MMURequestOutputPipeMethods);
   module mkConnection#(MMURequestInverse in, MMURequestOutputPipeMethods out)(Empty);
    mkConnection(in.sglist, out.sglist);
    mkConnection(in.region, out.region);
    mkConnection(in.idRequest, out.idRequest);
    mkConnection(in.idReturn, out.idReturn);
    mkConnection(in.setInterface, out.setInterface);

   endmodule
endinstance

(* synthesize *)
module mkMMURequestInverter(MMURequestInverter);
    FIFOF#(Sglist_Message) fifo_sglist <- mkFIFOF();
    FIFOF#(Region_Message) fifo_region <- mkFIFOF();
    FIFOF#(IdRequest_Message) fifo_idRequest <- mkFIFOF();
    FIFOF#(IdReturn_Message) fifo_idReturn <- mkFIFOF();
    FIFOF#(SetInterface_Message) fifo_setInterface <- mkFIFOF();

    interface ConnectalMemory::MMURequest ifc;

    method Action sglist(Bit#(32) sglId, Bit#(32) sglIndex, Bit#(64) addr, Bit#(32) len);
        fifo_sglist.enq(Sglist_Message {sglId: sglId, sglIndex: sglIndex, addr: addr, len: len});
    endmethod
    method Action region(Bit#(32) sglId, Bit#(64) barr12, Bit#(32) index12, Bit#(64) barr8, Bit#(32) index8, Bit#(64) barr4, Bit#(32) index4, Bit#(64) barr0, Bit#(32) index0);
        fifo_region.enq(Region_Message {sglId: sglId, barr12: barr12, index12: index12, barr8: barr8, index8: index8, barr4: barr4, index4: index4, barr0: barr0, index0: index0});
    endmethod
    method Action idRequest(SpecialTypeForSendingFd fd);
        fifo_idRequest.enq(IdRequest_Message {fd: fd});
    endmethod
    method Action idReturn(Bit#(32) sglId);
        fifo_idReturn.enq(IdReturn_Message {sglId: sglId});
    endmethod
    method Action setInterface(Bit#(32) interfaceId, Bit#(32) sglId);
        fifo_setInterface.enq(SetInterface_Message {interfaceId: interfaceId, sglId: sglId});
    endmethod
    endinterface
    interface MMURequestInverse inverseIfc;

    method ActionValue#(Sglist_Message) sglist;
        fifo_sglist.deq;
        return fifo_sglist.first;
    endmethod
    method ActionValue#(Region_Message) region;
        fifo_region.deq;
        return fifo_region.first;
    endmethod
    method ActionValue#(IdRequest_Message) idRequest;
        fifo_idRequest.deq;
        return fifo_idRequest.first;
    endmethod
    method ActionValue#(IdReturn_Message) idReturn;
        fifo_idReturn.deq;
        return fifo_idReturn.first;
    endmethod
    method ActionValue#(SetInterface_Message) setInterface;
        fifo_setInterface.deq;
        return fifo_setInterface.first;
    endmethod
    endinterface
endmodule

(* synthesize *)
module mkMMURequestInverterV(MMURequestInverter);
    PutInverter#(Sglist_Message) inv_sglist <- mkPutInverter();
    PutInverter#(Region_Message) inv_region <- mkPutInverter();
    PutInverter#(IdRequest_Message) inv_idRequest <- mkPutInverter();
    PutInverter#(IdReturn_Message) inv_idReturn <- mkPutInverter();
    PutInverter#(SetInterface_Message) inv_setInterface <- mkPutInverter();

    interface ConnectalMemory::MMURequest ifc;

    method Action sglist(Bit#(32) sglId, Bit#(32) sglIndex, Bit#(64) addr, Bit#(32) len);
        inv_sglist.mod.put(Sglist_Message {sglId: sglId, sglIndex: sglIndex, addr: addr, len: len});
    endmethod
    method Action region(Bit#(32) sglId, Bit#(64) barr12, Bit#(32) index12, Bit#(64) barr8, Bit#(32) index8, Bit#(64) barr4, Bit#(32) index4, Bit#(64) barr0, Bit#(32) index0);
        inv_region.mod.put(Region_Message {sglId: sglId, barr12: barr12, index12: index12, barr8: barr8, index8: index8, barr4: barr4, index4: index4, barr0: barr0, index0: index0});
    endmethod
    method Action idRequest(SpecialTypeForSendingFd fd);
        inv_idRequest.mod.put(IdRequest_Message {fd: fd});
    endmethod
    method Action idReturn(Bit#(32) sglId);
        inv_idReturn.mod.put(IdReturn_Message {sglId: sglId});
    endmethod
    method Action setInterface(Bit#(32) interfaceId, Bit#(32) sglId);
        inv_setInterface.mod.put(SetInterface_Message {interfaceId: interfaceId, sglId: sglId});
    endmethod
    endinterface
    interface MMURequestInverse inverseIfc;

    method ActionValue#(Sglist_Message) sglist;
        let v <- inv_sglist.inverse.get;
        return v;
    endmethod
    method ActionValue#(Region_Message) region;
        let v <- inv_region.inverse.get;
        return v;
    endmethod
    method ActionValue#(IdRequest_Message) idRequest;
        let v <- inv_idRequest.inverse.get;
        return v;
    endmethod
    method ActionValue#(IdReturn_Message) idReturn;
        let v <- inv_idReturn.inverse.get;
        return v;
    endmethod
    method ActionValue#(SetInterface_Message) setInterface;
        let v <- inv_setInterface.inverse.get;
        return v;
    endmethod
    endinterface
endmodule

// synthesizeable proxy MemPortal
(* synthesize *)
module mkMMURequestProxySynth#(Bit#(SlaveDataBusWidth) id)(MMURequestProxy);
  let dut <- mkMMURequestOutput();
  PortalCtrlMemSlave#(SlaveControlAddrWidth,SlaveDataBusWidth) ctrlPort <- mkPortalCtrlMemSlave(id, dut.portalIfc.intr);
  let memslave  <- mkMemMethodMuxOut(ctrlPort.memSlave,dut.portalIfc.indications);
  interface MemPortal portalIfc = (interface MemPortal;
      interface PhysMemSlave slave = memslave;
      interface ReadOnly interrupt = ctrlPort.interrupt;
      interface WriteOnly num_portals = ctrlPort.num_portals;
    endinterface);
  interface ConnectalMemory::MMURequest ifc = dut.ifc;
endmodule

// exposed proxy MemPortal
module mkMMURequestProxy#(idType id)(MMURequestProxy)
   provisos (Bits#(idType, a__),
	     Add#(b__, a__, SlaveDataBusWidth));
   let rv <- mkMMURequestProxySynth(extend(pack(id)));
   return rv;
endmodule
endpackage: MMURequest
