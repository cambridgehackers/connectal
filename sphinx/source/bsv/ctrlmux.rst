CtrlMux Package
=====================

.. bsv:package:: CtrlMux

.. bsv:module:: mkInterruptMux

   Used by BsimTop, PcieTop, and ZynqTop

.. bsv:module:: mkSlaveMux
   :parameter: Vector#(numPortals,MemPortal#(aw,dataWidth)) portals
   :returntype: PhysMemSlave#(addrWidth,dataWidth)

   Takes a vector of MemPortals and returns a PhysMemSlave combining them.

