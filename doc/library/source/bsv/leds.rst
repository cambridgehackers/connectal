Leds Package
=====================

.. bsv:package:: Leds

.. bsv:interface:: LEDS

.. bsv:typedef:: LedsWidth

   Defined to be the number of default LEDs on the FPGA board.

   The Zedboard has 8, Zc706 has 4, ...

.. bsv:method:: Bit#(LedsWidth) leds()

