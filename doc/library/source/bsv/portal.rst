Portal Package
==============

.. bsv:package:: Portal

PipePortal Interface
--------------------

.. bsv:interface:: PipePortal#(numeric type numRequests, numeric type numIndications, numeric type slaveDataWidth)

   .. bsv:method:: Bit#(16) messageSize(Bit#(16) methodNumber)

      Returns the message size of the methodNumber method of the portal.

  .. bsv:subinterface:: Vector#(numRequests, PipeIn#(Bit#(slaveDataWidth))) requests

  .. bsv:subinterface:: Vector#(numIndications, PipeOut#(Bit#(slaveDataWidth))) indications


MemPortal Interface
-------------------

.. bsv:interface:: MemPortal#(numeric type slaveAddrWidth, numeric type slaveDataWidth)

   .. bsv:subinterface:: PhysMemSlave#(slaveAddrWidth,slaveDataWidth) slave
   
   .. bsv:subinterface:: ReadOnly#(Bool) interrupt

   .. bsv:subinterface:: WriteOnly#(Bool) top

.. bsv:function:: PhysMemSlave(_a,_d) getSlave(MemPortal#(_a,_d) p)

.. bsv:function:: ReadOnly#(Bool) getInterrupt(MemPortal#(_a,_d) p)

.. bsv:function:: Vector#(16,ReadOnly#(Bool)) getInterruptVector(Vector#(numPortals, MemPortal#(_a,_d)) portals)


ShareMemoryPortal Interface
---------------------------

.. bsv:interface:: SharedMemoryPortal#(numeric type dataBusWidth)

   Should be in SharedMemoryPortal.bsv

   .. bsv:subinterface:: MemReadClient(dataBusWidth) readClient

   .. bsv:subinterface:: MemWriteClient#(dataBusWidth) writeClient

   .. bsv:subinterface:: SharedMemoryPortalConfig cfg

   .. bsv:subinterface:: ReadOnly#(Bool) interrupt

ConnectalTop Interface
----------------------

.. bsv:interface:: ConnectalTop#(numeric type addrWidth, numeric type dataWidth, type pins, numeric type numMasters)

   Interface ConnectalTop is the interface exposed by the top module of a Connectal hardware design.

   .. bsv:subinterface:: PhysMemSlave#(32,32) slave

   .. bsv:subinterface:: Vector#(numMasters,PhysMemMaster#(addrWidth, dataWidth)) masters

   .. bsv:subinterface:: Vector#(16,ReadOnly#(Bool)) interrupt		   

   .. bsv:subinterface:: LEDS leds

   .. bsv:subinterface:: pins pins

StdConnectalTop Typedef
-----------------------

.. bsv:typedef:: StdConnectalTop
   :parameter: numeric type addrWidth	 
   :returntype: ConnectalTop#(addrWidth,64,Empty,0)

   Type StdConnectalTop indicates a Connectal hardware design with no
   user defined pins and no user of host shared memory. The "pins"
   interface is Empty and the number of masters is 0.

.. bsv:typedef:: StdConnectalDmaTop
   :parameter: numeric type addrWidth
   :returnType:  ConnectalTop#(addrWidth,64,Empty,1)

   Type StdConnectalDmaTop indicates a Connectal hardware design with
   no user defined pins and a single client of host shared memory. The
   "pins" interface is Empty and the number of masters is 1.
