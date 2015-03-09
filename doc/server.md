Data Center Accelerators
========================

Approach
--------

 * Application process can request a coprocessing tile to be loaded
 * Process startup triggers tile load
 * Tile deactivated when process ends

 * Tile manager on the FPGA
   * Only user of the pins and PCIe/system interface
   * The tiles export MemClient interfaces, which are connected to a corresponding MemServer for the tile. [draw nifty picture.]
   * As part of this, prepends tile number onto object ID used to access the MMU in MemServer, providing inter-tile, inter-process access control
   * Responsible for QoS, Fairness, Arbitration of resource use by tiles.

 * For virtualization, device-driver in the host OS controls the actual hardware
 * Device-driver in the guest OS requests resources from the host OS, i.e., a tile

 * Misbehaviour in a tile cannot affect other tiles:
   * PCIe transactions buffered.  If tile logic not ready, then TLP deleted.  
   * If worried about integrity of bitfile contents, perhaps only load ones that have been signed by an authorized build server

Tasks
-----

 * Construct tile manager with fixed per-tile interface ports
   * Per-tile ports disabled during tile reconfiguration
 * Tile manager configuration and floor planning
 * Partial reconfiguration to load a tile
 * Disable ports without locking PCIe
 * Floor planning.
 * Relocatable tiles?
 * Implement tile loader

Tile Interface
--------------

 interface Tile;
   interface PhysMemSlave portal;
   interface ReadOnly#(Bool) interrupt;

   interface Vector#(N,MemReadClient) readClients;
   interface Vector#(N,MemWriteClient) writeClients;
   interface Pins pins;
 endinterface

Notes
-----

 * The Tile Manager looks like the infra that a Verilog module would plug into, but with fixed configuration.

Questions
---------

