
import GetPut::*;
import Connectable::*;
import Vector::*;
import BuildVector::*;

import ConnectalConfig::*;
import ConnectalMemory::*;
import ConnectalMemTypes::*;
import MemServer::*;
import ConnectalMMU::*;

import NandSim::*;
import Strstr::*;

interface Algo1NandSim;
   interface NandCfgRequest   nandCfgRequest;
   interface MMURequest       nandMMURequest;
   interface MemServerRequest nandMemServerRequest;
   interface StrstrRequest    strstrRequest;
   interface Vector#(2, MemReadClient#(DataBusWidth)) dmaReadClients;
   interface Vector#(1, MemWriteClient#(DataBusWidth)) dmaWriteClients;
endinterface


module mkAlgo1NandSim#(NandCfgIndication nandCfgIndication, MMUIndication nandMMUIndication, MemServerIndication nandSimMemServerIndication, StrstrIndication strstrIndication)(Algo1NandSim);


   Strstr#(64,64) strstr <- mkStrstr(strstrIndication);

   NandSim nandSim <- mkNandSim(nandCfgIndication);
   MMU#(PhysAddrWidth) nandMMU <- mkMMU(0, False, nandMMUIndication);
   MemServer#(PhysAddrWidth,64,1) nandSimMemServer <- mkMemServer(strstr.haystack_read_client, nil, vec(nandMMU), nandSimMemServerIndication);
   let nandSimMemCnx <- mkConnection(nandSimMemServer.masters[0], nandSim.memSlave);
   // rule rl_readReq;
   //    let req <- nandSimMemServer.masters[0].read_client.readReq.get();
   //    $display("rl_readReq addr=%h", req.addr);
   //    nandSim.memSlave.read_server.readReq.put(req);
   // endrule

   // let readDataCnx  <- mkConnection(nandSimMemServer.masters[0].read_client.readData, nandSim.memSlave.read_server.readData);
   // let writeReqCnx  <- mkConnection(nandSimMemServer.masters[0].write_client.writeReq, nandSim.memSlave.write_server.writeReq);
   // let writeDataCnx <- mkConnection(nandSimMemServer.masters[0].write_client.writeData, nandSim.memSlave.write_server.writeData);
   // let writeDoneCnx <- mkConnection(nandSimMemServer.masters[0].write_client.writeDone, nandSim.memSlave.write_server.writeDone);

   interface dmaReadClients = append(nandSim.readClient, strstr.config_read_client);
   interface dmaWriteClients = nandSim.writeClient;

   interface nandCfgRequest          = nandSim.request;
   interface nandMMURequest          = nandMMU.request;
   interface strstrRequest           = strstr.request;
   interface nandMemServerRequest    = nandSimMemServer.request;
endmodule
