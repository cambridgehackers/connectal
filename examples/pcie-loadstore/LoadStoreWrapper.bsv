package LoadStoreWrapper;

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
import LoadStore::*;
import CoreIndicationWrapper::*;
import CoreRequestWrapper::*;
import FIFO::*;
import AxiClientServer::*;



interface LoadStoreWrapper;
    interface Axi3Slave#(32,32,4,12) ctrl;
    interface Vector#(1,ReadOnly#(Bit#(1))) interrupts;

    interface Axi3Master#(40,64,8,12) m_axi;








    interface ReadOnly#(Bit#(4)) numPortals;
endinterface

module mkLoadStoreWrapper(LoadStoreWrapper);
    Reg#(Bit#(TLog#(1))) axiSlaveWS <- mkReg(0);
    Reg#(Bit#(TLog#(1))) axiSlaveRS <- mkReg(0); 
    CoreIndicationWrapper coreIndicationWrapper <- mkCoreIndicationWrapper();

    LoadStoreIndication indication = (interface LoadStoreIndication;
        interface CoreIndication coreIndication = coreIndicationWrapper.indication;
    endinterface);

    LoadStoreRequest loadStoreRequest <- mkLoadStoreRequest( indication);
    Axi3Master#(40,64,8,12) m_axiMaster <- mkAxi3Master(loadStoreRequest.m_axi);
    CoreRequestWrapper coreRequestWrapper <- mkCoreRequestWrapper(loadStoreRequest.coreRequest,coreIndicationWrapper);

    Vector#(1,Axi3Slave#(32,32,4,12)) ctrls_v;
    Vector#(1,ReadOnly#(Bit#(1))) interrupts_v;
    ctrls_v[0] = coreIndicationWrapper.ctrl;

    interrupts_v[0] = coreIndicationWrapper.interrupt;

    let ctrl_mux <- mkAxiSlaveMux(ctrls_v);

    interface Axi3Master m_axi = m_axiMaster;








    interface ctrl = ctrl_mux;
    interface Vector interrupts = interrupts_v;
    interface ReadOnly numPortals;
        method Bit#(4) _read();
            return 1;
        endmethod
    endinterface
endmodule: mkLoadStoreWrapper
endpackage: LoadStoreWrapper
