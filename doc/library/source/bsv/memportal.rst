MemPortal Package
=================

.. bsv:package:: MemPortal


mkMemPortal Module
------------------

.. bsv:module:: mkMemPortal#(Bit#(slaveDataWidth) ifcId, PipePortal#(numRequests, numIndications, slaveDataWidth) portal)(MemPortal#(slaveAddrWidth, slaveDataWidth))

   Takes an interface identifier and a PipePortal and returns a MemPortal.

