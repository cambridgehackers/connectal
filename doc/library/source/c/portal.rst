C/C++ Portal
============

.. c:function:: void setClockFrequency(int clkNum, long requestedFrequency, long *actualFrequency)

   Changes the frequency of Zynq FPGA Clock clkNum to the closest
   frequency to requestedFrequency available from the PLL. If the
   actualFrequency pointer is non-null, stores the actual freqency
   before returning.

Portal Memory
-------------

.. c:function:: int portalAlloc(size_t size, int cached)

   Uses portalmem to allocate a region of size bytes.

   On platforms that support non-cache-coherent I/O (e.g., zedboard),
   cached=0 indicates that the programmable logic will use a port to
   memory that is not snooped by the CPU's caches. In this case, it is
   up to the allocation to flush or invalidate the CPU cache as
   needed, using portalCacheFlush().

   Returns the file descriptor associated with the memory region.

.. c:function:: void *portalMmap(int fd, size_t size)

   Memory maps size bytes of the portal memory region indicated by fd.

   Returns a pointer to memory on success or -1 on failure.

.. c:function:: portalCacheFlush(int fd, void *__p, long size, int flush)


Deprecated Functions
--------------------

.. c:function:: void *portalExec(void *__x)
   Polls the registered portals and invokes their callback handlers.

.. c:function:: void portalExec_start()

.. c:function:: void portalExec_poll()

