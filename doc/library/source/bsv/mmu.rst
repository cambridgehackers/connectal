MMU Package
===========

.. bsv:package:: MMU

.. bsv:typedef:: 32 MaxNumSGLists
.. bsv:typedef:: Bit#(TLog#(MaxNumSGLists)) SGListId
.. bsv:typedef:: 12 SGListPageShift0
.. bsv:typedef:: 16 SGListPageShift4
.. bsv:typedef:: 20 SGListPageShift8
.. bsv:typedef:: 24 SGListPageShift12
.. bsv:typedef:: Bit#(TLog#(MaxNumSGLists)) RegionsIdx

.. bsv:typedef:: 8 IndexWidth

Address Translation
-------------------

.. bsv:struct:: AddrTransRequest

   Address translation request type

   .. bsv:field:: SGListId             id

      Which object identifier to use.

   .. bsv:field:: Bit#(MemOffsetSize) off

      The address to translate.

.. bsv:interface:: MMU#(numeric type addrWidth)

   An address translator

   .. bsv:subinterface:: MMURequest request

      The interface of the MMU that is exposed to software as a portal.

   .. bsv:subinterface:: Vector#(2,Server#(AddrTransRequest,Bit#(addrWidth))) addr

      The address translation servers


.. bsv:interface:: MMURequest;

   The Connectal MMU maps linear offsets on objects identified by
   sglId to dmaAddress. It is constructed from a list of
   segments, where the segments are sorted by size in descending
   order. Each segment must be one of the supported sizes.

   .. bsv:method:: Action sglist(Bit#(32) sglId, Bit#(32) segmentIndex, Bit#(64) addr,  Bit#(32) len);

      Updates the address of the segment number segmentIndex for object identified by sglId. The
      address has been preshifted so that the final address may be
      constructed by concatenating addr and offset within the segment.

   .. bsv:method:: Action region(Bit#(32) sglId, Bit#(64) barr12, Bit#(32) idxOffset12, Bit#(64) barr8, Bit#(32) idxOffset8, Bit#(64) barr4, Bit#(32) idxOffset4, Bit#(64) barr0, Bit#(32) idxOffset0);

      Updates the boundaries between the segments of different sizes for the object identified by sglId.

      For example, if an offset to be translated is less than barr12,
      then the target segment is of size SGListPageShift12 (2^24
      bytes). If the offset is less than barr12, then idxOffset12 points to the first translation table entry for segments of that size

      pbase      = offset >> segAddrSize + idxOffset
      segNumber  = pbase + idxOffset
      dmaBase    = translationTable[sglId,segNumber]
      dmaAddress = {dmaBase[physAddrSize-segAddrSize-1:0],offset[segAddrSize-1:0]}

   .. bsv:method:: Action idRequest(SpecialTypeForSendingFd fd);

      Requests a new object identifier.

   .. bsv:method:: Action idReturn(Bit#(32) sglId);

      Indicates that the designated object is no longer in use. The MMU clears the translation entries for this object.

   .. bsv:method:: Action setInterface(Bit#(32) interfaceId, Bit#(32) sglId);

      This method is only implemented in software responders.

.. bsv:interface:: MMUIndication;
   .. bsv:method:: Action idResponse(Bit#(32) sglId);

      Response from idRequest indicating the new object identifier sglId.

   .. bsv:method:: Action configResp(Bit#(32) sglId);

   .. bsv:method:: Action error(Bit#(32) code, Bit#(32) sglId, Bit#(64) offset, Bit#(64) extra);

      Sent from the MMU when there is a translation error.

.. bsv:struct:: DmaErrorType

   .. bsv:field:: DmaErrorNone

      Code 0 indicates no error.

   .. bsv:field:: DmaErrorSGLIdOutOfRange_r

      Code 1 indicates object identifier was out of range during a read request.

   .. bsv:field:: DmaErrorSGLIdOutOfRange_w

      Code 2 indicates object identifier was out of range during a read request.

   .. bsv:field:: DmaErrorMMUOutOfRange_r

      Code 3 indicates MMU identifier was out of range during a read request.

   .. bsv:field:: DmaErrorMMUOutOfRange_w

      Code 4 indicates MMU identifier was out of range during a read request.

   .. bsv:field:: DmaErrorOffsetOutOfRange

      Code 5 indicates offset was out of range for the designated object.

   .. bsv:field:: DmaErrorSGLIdInvalid

      Code 6 indicates the object identifier was out of range.

   .. bsv:field:: DmaErrorTileTagOutOfRange

      Code 7 indicates the tag was out of range for the requesting platform application tile.

.. bsv:module:: mkMMU#(Integer iid, Bool hostMapped, MMUIndication mmuIndication)(MMU#(addrWidth))

   Instantiates an address translator that stores a scatter-gather
   list to define the logical to physical address mapping.

   Parameter iid is the portal identifier of the MMURequest interface.

   Parameter hostMapped is true for simulation.


.. bsv:interface:: MemServerRequest;

   .. bsv:method:: Action addrTrans(Bit#(32) sglId, Bit#(32) offset);

      Requests an address translation

   .. bsv:method:: Action setTileState(TileControl tc);

      Changes tile status

   .. bsv:method:: Action stateDbg(ChannelType rc)

      Requests debug info for the specified channel type

   .. bsv:method:: Action memoryTraffic(ChannelType rc);

.. bsv:interface:: MemServerIndication;
   .. bsv:method:: Action addrResponse(Bit#(64) physAddr);
   .. bsv:method:: Action reportStateDbg(DmaDbgRec rec);
   .. bsv:method:: Action reportMemoryTraffic(Bit#(64) words);
   .. bsv:method:: Action error(Bit#(32) code, Bit#(32) sglId, Bit#(64) offset, Bit#(64) extra);
