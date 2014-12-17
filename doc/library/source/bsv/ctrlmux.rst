CtrlMux Package
=====================

.. bsv:package:: CtrlMux

.. bsv:module:: mkInterruptMux#(Vector#(numPortals,MemPortal#(aw,dataWidth)) portals)(ReadOnly#(Bool))

   Used by BsimTop, PcieTop, and ZynqTop

.. bsv:module:: mkSlaveMux#(Vector#(numPortals,MemPortal#(aw,dataWidth)) portals)(PhysMemSlave#(addrWidth,dataWidth))

   Takes a vector of MemPortals and returns a PhysMemSlave combining them.

