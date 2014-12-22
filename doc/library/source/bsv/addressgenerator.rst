Address Generator
=================

.. bsv:package:: AddressGenerator

One of the common patterns that leads to long critical paths in
designs on the FPGA are counters and comparisons against
counters. This package contains a module for generating the sequence
of addresses used by a memory read or write burst, along with a field
indicating the last beat of the burst.

.. bsv:struct:: AddrBeat#(numeric type addrWidth)

   .. bsv:field:: Bit#(addrWidth) addr

      The address for this beat of the request.

   .. bsv:field:: Bit#(BurstLenSize) bc

   .. bsv:field:: Bit#(MemTagSize) tag

   .. bsv:field:: Bool    last


.. bsv:interface:: AddressGenerator#(numeric type addrWidth, numeric type dataWidth)

   .. bsv:subinterface:: Put#(PhysMemRequest#(addrWidth)) request

      The interface for requesting a sequence of addresses.

   .. bsv:subinterface:: Get#(AddrBeat#(addrWidth)) addrBeat

      The interface for getting the address beats of the burst. There
      is one pipeline cycle from the reuqest to the first address
      beat.

.. bsv:module:: mkAddressGenerator#()(AddressGenerator#(addrWidth, dataWidth))

   Instantiates an address generator.
