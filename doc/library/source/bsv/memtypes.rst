MemTypes Package
================

.. bsv:package:: MemTypes

Constants
------------------

.. bsv:typedef:: Bit#(32) SGLId
.. bsv:typedef:: 44 MemOffsetSize
.. bsv:typedef:: 6 MemTagSize
.. bsv:typedef:: 8 BurstLenSize
.. bsv:typedef:: 32 MemServerTags
.. bsv:typedef:: TDiv#(DataBusSize,8) ByteEnableSize

Data Types
----------

.. bsv:struct:: PhysMemRequest#(numeric type addrWidth, dataWidth)

   A memory request containing a physical memory address

   .. bsv:field:: Bit#(addrWidth) addr

      Physical address to read or write

   .. bsv:field:: Bit#(BurstLenSize) burstLen

      Length of read or write burst, in bytes.  The number of beats of the request will be the burst length divided by the physical width of the memory interface.

   .. bsv:field:: Bit#(MemTagSize) tag

   .. bsv:field:: Bit#(TDiv#(dataWidth,8)) firstbe

   .. bsv:field:: Bit#(TDiv#(dataWidth,8)) lastbe

      If BYTE_ENABLESis defined as aBSV preprocessor macro,byte write
      enables are added to PhysMemRequest, intwo fields: firstbe and
      lastbe.The idea is to enable writing any number of contiguous
      bytes even if it is less than the width of the shared memory
      data bus.

      These have roughly the same semantics as in PCIE. The write
      enable in firstbe apply to the first beat of a burst request and
      those inlastbe apply to the last beat of a multi-beat burst
      request. Intervening beats of a burst request enable the write
      of all beats of that burst.

.. bsv:struct:: MemRequest

   A logical memory read or write request. The linear offset of the request will be translated by an MMU according to the specified scatter-gather list.

   .. bsv:field:: SGLId sglId

      Indicates which scatter-gather list the MMU should use when translating the address

   .. bsv:field:: Bit#(MemOffsetSize) offset

      Linear byte offset to read or write.

   .. bsv:field:: Bit#(BurstLenSize) burstLen

      Length of read or write burst, in bytes. The number of beats of the request will be the burst length divided by the physical width of the memory interface.

   .. bsv:field:: Bit#(MemTagSize)  tag

   .. bsv:field:: Bit#(ByteEnableSize) firstbe

   .. bsv:field:: Bit#(ByteEnableSize) lastbe

      If BYTE_ENABLESis defined as aBSV preprocessor macro,byte write
      enables are added to PhysMemRequest, intwo fields: firstbe and
      lastbe.The idea is to enable writing any number of contiguous
      bytes even if it is less than the width of the shared memory
      data bus.

      These have roughly the same semantics as in PCIE. The write
      enable in firstbe apply to the first beat of a burst request and
      those inlastbe apply to the last beat of a multi-beat burst
      request. Intervening beats of a burst request enable the write
      of all beats of that burst.


.. bsv:struct:: MemData#(numeric type dsz)

   One beat of the payload of a physical or logical memory read or write request.

   .. bsv:field:: Bit#(dsz) data

      One data beat worth of data.

   .. bsv:field:: Bit#(MemTagSize) tag

      Indicates to which request this beat belongs.

   .. bsv:field:: Bool last

      Indicates that this is the last beat of a burst.


.. bsv:struct:: MemDataF#(numeric type dsz)

   One beat of the payload of a physical or logical memory read or write request. Used by MemReadEngine and MemWriteEngine.

   .. bsv:field:: Bit#(dsz) data

      One data beat worth of data.

   .. bsv:field:: Bit#(MemTagSize) tag

      Indicates to which request this beat belongs.

   .. bsv:field:: Bool first

      Indicates that this is the first data beat of a request.

   .. bsv:field:: Bool last

      Indicates that this is the last data beat of a request.

Physical Memory Clients and Servers
-----------------------------------

.. bsv:interface:: PhysMemMaster#(numeric type addrWidth, numeric type dataWidth)

   The physical memory interface exposed by MemMaster. For example, connects via AXI to Zynq or via PCIe to x86 memory.

   .. bsv:subinterface:: PhysMemReadClient#(addrWidth, dataWidth) read_client

   .. bsv:subinterface:: PhysMemWriteClient#(addrWidth, dataWidth) write_client 

.. bsv:interface:: PhysMemReadClient#(numeric type asz, numeric type dsz)

   .. bsv:subinterface:: Get#(PhysMemRequest#(asz))    readReq

   .. bsv:subinterface:: Put#(MemData#(dsz)) readData

.. bsv:interface:: PhysMemWriteClient#(numeric type asz, numeric type dsz)

   .. bsv:subinterface:: Get#(PhysMemRequest#(asz))    writeReq

   .. bsv:subinterface:: Get#(MemData#(dsz)) writeData

   .. bsv:subinterface:: Put#(Bit#(MemTagSize))       writeDone

.. bsv:interface:: PhysMemSlave#(numeric type addrWidth, numeric type dataWidth)

   .. bsv:subinterface:: PhysMemReadServer#(addrWidth, dataWidth) read_server

   .. bsv:subinterface:: PhysMemWriteServer#(addrWidth, dataWidth) write_server 


.. bsv:interface:: PhysMemReadServer#(numeric type asz, numeric type dsz)

   .. bsv:subinterface:: Put#(PhysMemRequest#(asz)) readReq

   .. bsv:subinterface:: Get#(MemData#(dsz))     readData


.. bsv:interface:: PhysMemWriteServer#(numeric type asz, numeric type dsz)

   .. bsv:subinterface:: Put#(PhysMemRequest#(asz)) writeReq

   .. bsv:subinterface:: Put#(MemData#(dsz))     writeData

   .. bsv:subinterface:: Get#(Bit#(MemTagSize))           writeDone


Memory Clients and Servers
--------------------------

These clients and servers operate on logical addresses. These are
translated by an MMU before being issued to system memory.

.. bsv:interface:: MemReadClient#(numeric type dsz)

   The system memory read interface exported by a client of MemServer, such as MemReadEngine.

   .. bsv:subinterface:: Get#(MemRequest)    readReq

   .. bsv:subinterface:: Put#(MemData#(dsz)) readData


.. bsv:interface:: MemWriteClient#(numeric type dsz)

   The system memory write interface exported by a client of MemServer, such as MemWriteEngine.

   .. bsv:subinterface:: Get#(MemRequest)    writeReq

   .. bsv:subinterface:: Get#(MemData#(dsz)) writeData

   .. bsv:subinterface:: Put#(Bit#(MemTagSize))       writeDone

.. bsv:interface:: MemReadServer#(numeric type dsz)

   The system memory read interface exported by MemServer.

   .. bsv:subinterface:: Put#(MemRequest) readReq

   .. bsv:subinterface:: Get#(MemData#(dsz))     readData


.. bsv:interface:: MemWriteServer#(numeric type dsz)

   The system memory write interface exported by MemServer.

   .. bsv:subinterface:: Put#(MemRequest) writeReq

   .. bsv:subinterface:: Put#(MemData#(dsz))     writeData

   .. bsv:subinterface:: Get#(Bit#(MemTagSize)) writeDone


Memory Engine Types
-------------------

.. bsv:struct:: MemengineCmd

   A read or write request for a MemReadEngine or a MemWriteEngine. MemRead and MemWrite engines will issue one or more burst requests to satisfy the overall length of the request.

   .. bsv:field:: SGLId sglId

      Which memory object identifer (scatter gather list ID) the MMU should use to translate the addresses

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

.. bsv:interface:: MemWriteEngineServer#(numeric type userWidth)

   The interface used by one client of a MemWriteEngine.

   .. bsv:subinterface:: Put#(MemengineCmd)       request

   .. bsv:subinterface:: Get#(Bool)               done

   .. bsv:subinterface:: PipeIn#(Bit#(userWidth)) data

.. bsv:interface:: MemWriteEngine#(numeric type busWidth, numeric type userWidth, numeric type cmdQDepth, numeric type numServers)

   A multi-client component that supports multi-burst writes to system memory.

   .. bsv:subinterface:: MemWriteClient#(busWidth) dmaClient

   .. bsv:subinterface:: Vector#(numServers, MemWriteEngineServer#(userWidth)) writeServers

.. bsv:interface:: MemReadEngineServer#(numeric type userWidth)

   The interface used by one client of a MemReadEngine.

   .. bsv:subinterface:: Put#(MemengineCmd)        request

   .. bsv:subinterface:: PipeOut#(MemDataF#(userWidth)) data
      
.. bsv:interface:: MemReadEngine#(numeric type busWidth, numeric type userWidth, numeric type cmdQDepth, numeric type numServers)

   A multi-client component that supports multi-burst reads from system memory.

   .. bsv:subinterface:: MemReadClient#(busWidth) dmaClient

   .. bsv:subinterface:: Vector#(numServers, MemReadEngineServer#(userWidth)) readServers


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




