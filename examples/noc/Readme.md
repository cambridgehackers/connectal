Network on Chip

This example is an extension of the serialconfig scheme to make
more of an on-chip network.

The network is composed of nodes, each of which can send or receive
messages.  Point to point links between the nodes complete the design.

Stage 1:  1-D mesh

Each node has two links, called East and West, and an address which is
its coordinate.

Each node therefore has inputs from East, West, and Local. plus three
outputs to East, West, and Local

The switch is a 3x3 crossbar, implemented with three three input
muxes.  (In the alternative, we could choose not to support loopback
traffic, simplifying the switch by 1 leg on the muxes.)

The switch has input buffers only.  Each incoming link (East, West, Local)
has two flit buffers.

Each link transmits flits (a flit is the unit of flow control).
The reverse channel of a link transmits buffer occupancy data.

Messages on the reverse channel consist of a bitmap of occupied
buffers and an "as of" counters.

The forward channel messages include a link sequence number and
a buffer selector.  The LSN is echoed back in the reverse link
message.

Alternate:

A link has a fifo at the receiving end, and a return path that shows space 
remaining "as of" the last LSN received.


It is ok to send a packet on a link when there is room for it at the next switch and when the packet is ready to send.  The logic that sends packets
on a link will arbitrate among packets that are eligible to send,
probably with round-robin priority among candidates


Module LinkPort parameters for how many output channels 
   datain link
   reverse channel out
   pktbuffer out   // does there need to be a buffer per crosspoint?
                           // or just one per incoming link?
	mux inputs to accept packets from host or link outs
	
   
Module HostPort
   parameters for how many links
   PktBuffer in
