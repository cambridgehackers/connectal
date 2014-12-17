Portal Package
==============

.. bsv:package:: Portal

PipePortal Interface
--------------------

.. bsv:interface:: PipePortal
   :parameter: numeric type numRequests, numeric type numIndications, numeric type slaveDataWidth

   .. bsv:method:: messageSize
      :parameter: Bit#(16) methodNumber
      :returntype: Bit#(16)

      Returns the message size of the methodNumber method of the portal.

  .. bsv:subinterface:: requests
     :returntype: Vector#(numRequests, PipeIn#(Bit#(slaveDataWidth)))

  .. bsv:subinterface:: indications
     :returntype: Vector#(numIndications, PipeOut#(Bit#(slaveDataWidth)))


MemPortal Interface
-------------------

.. bsv:interface:: MemPortal
   :parameter: numeric type slaveAddrWidth, numeric type slaveDataWidth

   .. bsv:subinterface:: slave
      :returntype: PhysMemSlave#(slaveAddrWidth,slaveDataWidth)
   
   .. bsv:subinterface:: interrupt
      :returntype: ReadOnly#(Bool)

   .. bsv:subinterface:: top
      :returntype: WriteOnly#(Bool)

.. bsv:function:: getSlave
   :parameter: MemPortal#(_a,_d) p
   :returnType: PhysMemSlave(_a,_d)

.. bsv:function:: getInterrupt
   :parameter: MemPortal#(_a,_d) p
   :returntype: ReadOnly#(Bool)

.. bsv:function:: getInterruptVector
   :parameter: Vector#(numPortals, MemPortal#(_a,_d)) portals
   :returntype: Vector#(16, ReadOnly#(Bool))

ShareMemoryPortal Interface
---------------------------

.. bsv:interface:: SharedMemoryPortal
   :parameter: numeric type dataBusWidth

   Should be in SharedMemoryPortal.bsv

   .. bsv:subinterface:: readClient
      :returntype: MemReadClient(dataBusWidth)

   .. bsv:subinterface:: writeClient
      :returntype: MemWriteClient#(dataBusWidth)

   .. bsv:interface:: cfg
      :returntype: SharedMemoryPortalConfig

   .. bsv:subinterface:: interrupt
      :returntype: ReadOnly#(Bool)

ConnectalTop Interface
----------------------

.. bsv:interface:: ConnectalTop
   :parameter: numeric type addrWidth, numeric type dataWidth, type pins, numeric type numMasters

   Interface ConnectalTop is the interface exposed by the top module of a Connectal hardware design.

   .. bsv:subinterface:: slave
      :returntype: PhysMemSlave#(32,32)

   .. bsv:subinterface:: masters
      :returntype: Vector#(numMasters,PhysMemMaster#(addrWidth, dataWidth))

   .. bsv:subinterface:: interrupt		   
      :returntype: Vector#(16,ReadOnly#(Bool))

   .. bsv:subinterface:: leds
      :returntype: LEDS

   .. bsv:subinterface:: pins
      :returntype: pins

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
