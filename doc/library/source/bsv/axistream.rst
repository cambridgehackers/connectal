AxiStream Package
================

.. bsv:package:: AxiStream



AXI Stream Interfaces
---------------------

.. bsv:interface:: AxiStreamMaster#(numeric type dataWidth)

   AXI stream source with dataWidth data bits.

    .. bsv:method:: Bit#(dsz) tdata()

       Returns the data from this beat if tvalid is asserted, otherwise returns undefined.
    
    .. bsv:method:: Bit#(TDiv#(dsz,8))     tkeep()

       Returns the byte enables from this beat if tvalid is asserted, otherwise returns undefined.

    .. bsv:method::  Bit#(1)               tlast()

       Indicates if this is the last data beat of this transaction tvalid is asserted, otherwise returns undefined.

    .. bsv:method::  Action                 tready(Bit#(1) v)

       When tvalid and tready are both asserted the current data is
       consumed. The value passed to tready may not depend on the output
       of tvalid.

    .. bsv:method:: Bit#(1)                tvalid()

       Asserted when the data is valid.

.. bsv:interface:: AxiStreamSlave#(numeric type dataWidth)

   AXI stream sink with dataWidth data bits.

    .. bsv:method:: Action tdata(Bit#(dsz) data)

       The data passed from the source if tvalid is asserted, otherwise undefined..
    
    .. bsv:method:: Action tkeep(Bit#(TDiv#(dsz,8)) keep)

       The byte enables passed from the source if tvalid is asserted, otherwise undefined.

    .. bsv:method::  Action tlast(Bit#(1) last)

       Indicates if this is the last data beat of this transaction tvalid is asserted, otherwise returns undefined.

    .. bsv:method::  Bit#(1) tready()

       Return 1 if ready to receive data, 0 otherwise.

       When tvalid and tready are both asserted the current data is
       consumed. The value passed to tready may not depend on the output
       of tvalid.

    .. bsv:method:: Action tvalid(Bit#(1) v)

       Indicates the data from the source is valid.

Connectable Type Instances
--------------------------

.. bsv:instance:: Connectable#(AxiStreamMaster#(dataWidth), AxiStreamSlave#(dataWidth))

   .. bsv::module:: mkConnection#(AxiStreamMaster#(dataWidth) from, AxiStreamSlave#(dataWidth) to)(Empty)

      Enables mkConnection(axiStreamMaster, axiStreamSlave)


.. bsv:instance:: ToGetM#(AxiStreamMaster#(asz), Bit#(asz))
			
   .. bsv:module: toGetM#(AxiStreamMaster#(asz) m)(Get#(Bit#(asz)))

.. bsv:instance:: ToPutM#(AxiStreamSlave#(asz), Bit#(asz))

   .. bsv:module: toPutM#(AxiStreamSlave#(asz) m)(Put#(Bit#(asz)))

AXI Stream Type Classes and Instances   
----------------------------------------

.. bsv:typeclass:: ToAxiStream#(type atype, type btype)

   .. bsv:function:: atype toAxiStream(btype b)

      Convert to an AXI stream interface.

.. bsv:typeclass:: MkAxiStream#(type atype, type btype)

   .. bsv:module:: mkAxiStream#(btype b)(atype)

      Create a module with an AXI Stream interface.

.. bsv:instance:: MkAxiStream#(AxiStreamMaster#(dsize), FIFOF#(Bit#(dsize)))

   .. bsv:module:: mkAxiStream#(FIFOF#(Bit#(dsize)) f)(AxiStreamMaster#(dsize));

   Create an AXI Stream master from a FIFOF of bits

.. bsv:instance:: MkAxiStream#(AxiStreamSlave#(dsize), FIFOF#(Bit#(dsize)))

   .. bsv:module:: mkAxiStream#(FIFOF#(Bit#(dsize)) f)(AxiStreamSlave#(dsize));

      Create an AXI Stream slave from a FIFOF of bits

.. bsv:instance:: MkAxiStream#(AxiStreamMaster#(dsize), FIFOF#(Bit#(dsize)))

   .. bsv:module:: mkAxiStream#(FIFOF#(Bit#(dsize)) f)(AxiStreamMaster#(dsize));

   Create an AXI Stream master from a FIFOF of MemDataF

.. bsv:instance:: MkAxiStream#(AxiStreamSlave#(dsize), FIFOF#(MemDataF#(dsize)))

   .. bsv:module:: mkAxiStream#(FIFOF#(MemDataF#(dsize)) f)(AxiStreamSlave#(dsize));

      Create an AXI Stream slave from a FIFOF of MemDataF

.. bsv:instance:: MkAxiStream#(AxiStreamMaster#(dsize), PipeOut#(dtype))

   .. bsv:module:: mkAxiStream#(PipeOut#(dtype) f)(AxiStreamMaster#(dsize));

   Create an AXI Stream master from a PipeOut#(dtype)

.. bsv:instance:: MkAxiStream#(AxiStreamSlave#(dsize), FIFOF#(PipeIn#(dtype))

   .. bsv:module:: mkAxiStream#(PipeIn#(dtype) f)(AxiStreamSlave#(dsize));

      Create an AXI Stream slave from a PipeIn#(dtype)
