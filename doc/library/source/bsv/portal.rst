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

   .. bsv:subinterface:: readClient;
      :returntype: MemReadClient(dataBusWidth)

   .. bsv:subinterface:: writeClient
      :returntype: MemWriteClient#(dataBusWidth)

   .. bsv:interface:: cfg
      :returntype: SharedMemoryPortalConfig

   .. bsv:subinterface:: interrupt
      :returntype: ReadOnly#(Bool)

