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
