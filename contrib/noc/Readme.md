Network on Chip

This example is an extension of the serialconfig scheme to make
more of an on-chip network.

The network is composed of nodes, each of which can send or receive
messages.  Point to point links between the nodes complete the design.

Stage 1:  1-D mesh

Each node has two links, called East and West, and an address which is
its coordinate.

Each node therefore has inputs from East, West, and Local. plus three
outputs to East, West, and Local.  The local link is called "host"

The switch is a 3x3 crossbar, implemented with three three input
muxes.  (In the alternative, we could choose not to support loopback
traffic, simplifying the switch by 1 leg on the muxes.)

The Each swith input is a FIFOF.  Each output (row) is a round-robin
arbiter that selects the next message to send from the various inputs.

Each input link has a distributor switch column) rule that routes an 
arriving message to the proper swith FIFO.


Each link is a SerialFIFO, which is two back-to-back Gearbox modules,
so the node ends of a link have the DataMessage type, while the "middle" of
the link is serial (a 1-bit wide FIFO, really).

Test Program

The test program sends a message from each node to each other node
