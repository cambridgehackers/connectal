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
