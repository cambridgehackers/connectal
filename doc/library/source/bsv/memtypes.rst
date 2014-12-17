MemTypes Package
================

Constants
------------------

.. bsv:typedef:: Bit#(32) SGLId
.. bsv:typedef:: 44 MemOffsetSize
.. bsv:typedef:: 6 MemTagSize
.. bsv:typedef:: 8 BurstLenSize
.. bsv:typedef:: 32 MemServerTags

Data Types
----------

.. bsv:struct:: PhysMemRequest#(numeric type addrWidth)

   A memory request containing a physical memory address

   .. bsv:field:: Bit#(addrWidth) addr

      Physical address to read or write

   .. bsv:field:: Bit#(BurstLenSize) burstLen

      Length of read or write burst, in bytes.  The number of beats of the request will be the burst length divided by the physical width of the memory interface.

   .. bsv:field:: Bit#(MemTagSize) tag

.. bsv:struct:: MemRequest

   A logical memory read or write request. The linear offset of the request will be translated by an MMU according to the specified scatter-gather list.

   .. bsv:field:: SGLId sglId

      Indicates which scatter-gather list the MMU should use when translating the address

   .. bsv:field:: Bit#(MemOffsetSize) offset

      Linear byte offset to read or write.

   .. bsv:field:: Bit#(BurstLenSize) burstLen

      Length of read or write burst, in bytes. The number of beats of the request will be the burst length divided by the physical width of the memory interface.

   .. bsv:field:: Bit#(MemTagSize)  tag

.. bsv:struct:: MemData#(numeric type dsz)

   One beat of the payload of a physical or logical memory read or write request.

   .. bsv:field:: Bit#(dsz) data

      One data beat worth of data.

   .. bsv:field:: Bit#(MemTagSize) tag

      Indicates to which request this beat belongs.

   .. bsv:field:: Bool last

      Indicates that this is the last beat of a burst.

Physical Memory Clients and Servers
-----------------------------------

.. bsv:interface:: PhysMemSlave#(numeric type addrWidth, numeric type dataWidth)

   .. bsv:subinterface:: PhysMemReadServer#(addrWidth, dataWidth) read_server

   .. bsv:subinterface:: PhysMemWriteServer#(addrWidth, dataWidth) write_server 

.. bsv:interface:: PhysMemMaster#(numeric type addrWidth, numeric type dataWidth)

   .. bsv:subinterface:: PhysMemReadClient#(addrWidth, dataWidth) read_client

   .. bsv:subinterface:: PhysMemWriteClient#(addrWidth, dataWidth) write_client 

.. bsv:interface:: PhysMemReadClient#(numeric type asz, numeric type dsz)

   .. bsv:subinterface:: Get#(PhysMemRequest#(asz))    readReq

   .. bsv:subinterface:: Put#(MemData#(dsz)) readData

.. bsv:interface:: PhysMemWriteClient#(numeric type asz, numeric type dsz)

   .. bsv:subinterface:: Get#(PhysMemRequest#(asz))    writeReq

   .. bsv:subinterface:: Get#(MemData#(dsz)) writeData

   .. bsv:subinterface:: Put#(Bit#(MemTagSize))       writeDone

.. bsv:interface:: PhysMemReadServer#(numeric type asz, numeric type dsz)

   .. bsv:subinterface:: Put#(PhysMemRequest#(asz)) readReq

   .. bsv:subinterface:: Get#(MemData#(dsz))     readData


.. bsv:interface:: PhysMemWriteServer#(numeric type asz, numeric type dsz)

   .. bsv:subinterface:: Put#(PhysMemRequest#(asz)) writeReq

   .. bsv:subinterface:: Put#(MemData#(dsz))     writeData

   .. bsv:subinterface:: Get#(Bit#(MemTagSize))           writeDone


Memory Clients and Servers
--------------------------

.. bsv:interface:: MemReadClient#(numeric type dsz)

   .. bsv:subinterface:: Get#(MemRequest)    readReq

   .. bsv:subinterface:: Put#(MemData#(dsz)) readData


.. bsv:interface:: MemWriteClient#(numeric type dsz)

   .. bsv:subinterface:: Get#(MemRequest)    writeReq

   .. bsv:subinterface:: Get#(MemData#(dsz)) writeData

   .. bsv:subinterface:: Put#(Bit#(MemTagSize))       writeDone

.. bsv:interface:: MemReadServer#(numeric type dsz)

   .. bsv:subinterface:: Put#(MemRequest) readReq

   .. bsv:subinterface:: Get#(MemData#(dsz))     readData


.. bsv:interface:: MemWriteServer#(numeric type dsz)

   .. bsv:subinterface:: Put#(MemRequest) writeReq

   .. bsv:subinterface:: Put#(MemData#(dsz))     writeData

   .. bsv:subinterface:: Get#(Bit#(MemTagSize)) writeDone


Memory Engine Types
-------------------

.. bsv:struct:: MemengineCmd

   A read or write request for a MemreadEngine or a MemwriteEngine. Memread and Memwrite engines will issue one or more burst requests to satisfy the overall length of the request.

   .. bsv:field:: SGLId sglId

      Which scatter gather list the MMU should use to translate the addresses

   .. bsv:field:: Bit#(MemOffsetSize) base

      Logical base address of the request, as a byte offset

   .. bsv:field:: Bit#(BurstLenSize) burstLen

      Maximum burst length, in bytes.

   .. bsv:field:: Bit#(32) len

      Number of bytes to transfer. Must be a multiple of the data bus width.

   .. bsv:field:: Bit#(MemTagSize) tag

      Identifier for this request.

Memory Engine Interfaces
------------------------

.. bsv:interface:: MemwriteServer#(numeric type dataWidth)

   .. bsv:subinterface:: Server#(MemengineCmd,Bool) cmdServer

   .. bsv:subinterface:: PipeIn#(Bit#(dataWidth)) dataPipe

.. bsv:interface:: MemwriteEngineV#(numeric type dataWidth, numeric type cmdQDepth, numeric type numServers)

   .. bsv:subinterface:: MemWriteClient#(dataWidth) dmaClient

   .. bsv:subinterface:: Vector#(numServers, Server#(MemengineCmd,Bool)) writeServers

   .. bsv:subinterface:: Vector#(numServers, PipeIn#(Bit#(dataWidth))) dataPipes

   .. bsv:subinterface:: Vector#(numServers, MemwriteServer#(dataWidth)) write_servers

.. bsv:typedef:: MemwriteEngineV#(dataWidth,cmdQDepth,1) MemwriteEngine#(numeric type dataWidth, numeric type cmdQDepth)

.. bsv:interface:: MemreadServer#(numeric type dataWidth)

   .. bsv:subinterface:: Server#(MemengineCmd,Bool) cmdServer

   .. bsv:subinterface:: PipeOut#(Bit#(dataWidth)) dataPipe
      
.. bsv:interface:: MemreadEngineV#(numeric type dataWidth, numeric type cmdQDepth, numeric type numServers)

   .. bsv:subinterface:: MemReadClient#(dataWidth) dmaClient

   .. bsv:subinterface:: Vector#(numServers, Server#(MemengineCmd,Bool)) readServers

   .. bsv:subinterface:: Vector#(numServers, PipeOut#(Bit#(dataWidth))) dataPipes

   .. bsv:subinterface:: Vector#(numServers, MemreadServer#(dataWidth)) read_servers

.. bsv:typedef:: MemreadEngineV#(dataWidth,cmdQDepth,1) MemreadEngine#(numeric type dataWidth, numeric type cmdQDepth)

Memory Traffic Interfaces
-------------------------


.. bsv:interface:: DmaDbg

   .. bsv:method:: ActionValue#(Bit#(64)) getMemoryTraffic()
   .. bsv:method:: ActionValue#(DmaDbgRec) dbg()

Connectable Instances
---------------------

.. bsv:instance:: Connectable#(MemReadClient#(dsz), MemReadServer#(dsz))

.. bsv:instance:: Connectable#(MemWriteClient#(dsz), MemWriteServer#(dsz))

.. bsv:instance:: Connectable#(PhysMemMaster#(addrWidth, busWidth), PhysMemSlave#(addrWidth, busWidth))

.. bsv:instance:: Connectable#(PhysMemMaster#(32, busWidth), PhysMemSlave#(40, busWidth))




