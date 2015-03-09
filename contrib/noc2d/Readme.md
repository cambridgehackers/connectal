Network on Chip

This is a two dimensional mesh network with 16 nodes.

Each node has four links to adjacent nodes, plus a link to the local
"host". Each node has a crossbar switch for routing.

Messages are a compiled-in datatype, plus a message address which is
the coordinates of the destination host in the X and Y directions.

Links are SerialFIFOs, from the connectal library.  The link "transmitter"
is a GearBox from the message datatype to a Bit#(1) serial datatype.
The link "receiver" is a Gearbox from Bit#(1) back to the message
datatype.


The crossbar switch consists of a matrix of FIFOF.  A particular FIFO
accepts messages from a particular input link which are routed to a
particular output link.

The four input links, plus a FIFO from the host, feed distributors.
Each distributor examines the address of a message and copies the
message to the correct crosspoint FIFO.

A "row" in the crossbar consists of all the FIFOs which accept traffic
from a particular link plus a row for messages from the host.  A
"column" in the crossbar consists of all the FIFOs which send traffic
to a particular link, plus a column for traffic to the host.

Each output link has an arbiter, which merges traffic from the
associated FIFOs.

In order to avoid deadlock, the network uses dimension order routing.
A message traverses links in the X direction until it reaches the
correct X coordinate, and then traverses links in the Y direction
until the Y coordinates match. The message is then delivered to the
host.

A message can never be routed back to the node from which it just
arrived, so there are no FIFOs needed on the diagonal of the switch
matrix.  There is a crosspoint to route host messages back to the
local host.
