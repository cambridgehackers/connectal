Leds Package
=====================

The HostInterface package provides host-specific typedefs and interfaces.

.. bsv:package:: Leds

.. bsv:interface:: LEDS

.. bsv:data:: LedsWidth

   Defined to be the number of default LEDs on the FPGA board.

   The Zedboard has 8, Zc706 has 4, ...

.. bsv:method:: leds
   :returntype: Bit#(LedsWidth)
   :parameter:

