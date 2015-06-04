C/C++ Portal
============

.. c:function:: void setClockFrequency(int clkNum, long requestedFrequency, long *actualFrequency)

   Changes the frequency of Zynq FPGA Clock clkNum to the closest
   frequency to requestedFrequency available from the PLL. If the
   actualFrequency pointer is non-null, stores the actual freqency
   before returning.

****deprecated*****

.. c:function:: void *portalExec(void *__x)
   Polls the registered portals and invokes their callback handlers.

.. c:function:: void portalExec_start()

.. c:function:: void portalExec_poll()

.. c:function:: int portalAlloc(args)
