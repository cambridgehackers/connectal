MMU Package
===========

.. bsv:package:: MMU

.. bsv:typedef:: 32 MaxNumSGLists
.. bsv:typedef:: Bit#(TLog#(MaxNumSGLists)) SGListId
.. bsv:typedef:: 12 SGListPageShift0
.. bsv:typedef:: 16 SGListPageShift4
.. bsv:typedef:: 20 SGListPageShift8
.. bsv:typedef:: Bit#(TLog#(MaxNumSGLists)) RegionsIdx

.. bsv:typedef:: 8 IndexWidth

Address Translation
-------------------

.. bsv:struct:: ReqTup

   Address translation request type

   .. bsv:field:: SGListId             id

      Which SGList to use.

   .. bsv:field:: Bit#(MemOffsetSize) off

      The address to translate.

.. bsv:interface:: MMU#(numeric type addrWidth)

   An address translator

   .. bsv:subinterface:: MMURequest request

      The interface of the MMU that is exposed to software as a portal.

   .. bsv:subinterface:: Vector#(2,Server#(ReqTup,Bit#(addrWidth))) addr

      The address translation servers

.. bsv:module:: mkMMU#(Integer iid, Bool bsimMMap, MMUIndication mmuIndication)(MMU#(addrWidth))

   Instantiates an address translator that stores a scatter-gather
   list to define the logical to physical address mapping.

   Parameter iid is the portal identifier of the MMURequest interface.

   Parameter bsimMMAP ??

Multiple Address Translators
----------------------------

.. bsv:interface:: MMUAddrServer#(numeric type addrWidth, numeric type numServers)

   Used by mkMemServer to share an MMU among multiple memory interfaces.

   .. bsv:interface:: Vector#(numServers,Server#(ReqTup,Bit#(addrWidth))) servers

      The vector of address translators.

.. bsv:module:: mkMMUAddrServer#(Server#(ReqTup,Bit#(addrWidth)) server)(MMUAddrServer#(addrWidth,numServers))

   Instantiates an MMUAddrServer that shares the input server among multiple clients.


