package MemcpyWrapper;

import FIFO::*;
import FIFOF::*;
import GetPut::*;
import Connectable::*;
import Clocks::*;
import Adapter::*;
import AxiMasterSlave::*;
import AxiClientServer::*;
import Zynq::*;
import Vector::*;
import SpecialFIFOs::*;
import AxiDMA::*;
import XbsvReadyQueue::*;
import Memcpy::*;
import BlueScope::*;
import AxiDMA::*;
import CoreIndicationWrapper::*;
import CoreRequestWrapper::*;
import BlueScopeIndicationWrapper::*;
import BlueScopeRequestWrapper::*;
import DMAIndicationWrapper::*;
import DMARequestWrapper::*;
import FIFOF::*;
import BRAMFIFO::*;
import GetPut::*;
import AxiClientServer::*;
import AxiDMA::*;
import BlueScope::*;
import Clocks::*;
import FIFO::*;
import FIFOF::*;
import BRAMFIFO::*;
import GetPut::*;
import AxiDMA::*;
import ClientServer::*;
import FIFOF::*;
import Vector::*;
import GetPut::*;
import ClientServer::*;
import BRAMFIFO::*;
import BRAM::*;
import AxiClientServer::*;
import BRAMFIFOFLevel::*;
import PortalMemory::*;
import SGList::*;



interface MemcpyWrapper;
    interface Axi3Slave#(32,32,4,12) ctrl;
    interface Vector#(3,ReadOnly#(Bit#(1))) interrupts;

    interface Axi3Master#(40,64,8,12) m_axi;








endinterface

module mkMemcpyWrapper(MemcpyWrapper);
    Reg#(Bit#(TLog#(3))) axiSlaveWS <- mkReg(0);
    Reg#(Bit#(TLog#(3))) axiSlaveRS <- mkReg(0); 
    CoreIndicationWrapper coreIndicationWrapper <- mkCoreIndicationWrapper();
    BlueScopeIndicationWrapper bsIndicationWrapper <- mkBlueScopeIndicationWrapper();
    DMAIndicationWrapper dmaIndicationWrapper <- mkDMAIndicationWrapper();

    MemcpyIndication indication = (interface MemcpyIndication;
        interface CoreIndication coreIndication = coreIndicationWrapper.indication;
        interface BlueScopeIndication bsIndication = bsIndicationWrapper.indication;
        interface DMAIndication dmaIndication = dmaIndicationWrapper.indication;
    endinterface);

    MemcpyRequest memcpyRequest <- mkMemcpyRequest( indication);
    Axi3Master#(40,64,8,12) m_axiMaster <- mkAxi3Master(memcpyRequest.m_axi);
    CoreRequestWrapper coreRequestWrapper <- mkCoreRequestWrapper(memcpyRequest.coreRequest,coreIndicationWrapper);
    BlueScopeRequestWrapper bsRequestWrapper <- mkBlueScopeRequestWrapper(memcpyRequest.bsRequest,bsIndicationWrapper);
    DMARequestWrapper dmaRequestWrapper <- mkDMARequestWrapper(memcpyRequest.dmaRequest,dmaIndicationWrapper);

    Vector#(3,Axi3Slave#(32,32,4,12)) ctrls_v;
    Vector#(3,ReadOnly#(Bit#(1))) interrupts_v;
    ctrls_v[0] = coreIndicationWrapper.ctrl;
    ctrls_v[1] = bsIndicationWrapper.ctrl;
    ctrls_v[2] = dmaIndicationWrapper.ctrl;

    interrupts_v[0] = coreIndicationWrapper.interrupt;
    interrupts_v[1] = bsIndicationWrapper.interrupt;
    interrupts_v[2] = dmaIndicationWrapper.interrupt;

    let ctrl_mux <- mkAxiSlaveMux(ctrls_v);

    interface Axi3Master m_axi = m_axiMaster;








    interface ctrl = ctrl_mux;
    interface Vector interrupts = interrupts_v;
endmodule
endpackage: MemcpyWrapper