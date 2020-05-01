C/C++ Portal
============

Connecting to Bluesim
---------------------

.. envvar:: BLUESIM_SOCKET_NAME

   Controls the name of the socket used for connecting software and hardware simulated by bluesim.

Connecting to Xsim and Verilator
--------------------------------

.. envvar:: SOFTWARE_SOCKET_NAME

   Controls the name of the socket used for connecting software and hardware simulated by xsim/verilator.

Automatically Programming the FPGA
----------------------------------

Connectal application executables or shared objects contain the FPGA
bitstream in the "fpgadata" section of the ELF file. When the
application (or library) first tries to access the hardware, the
Connectal library automatically programs the FGPA with the associated
bitstream, unless :c:data:`noprogram` is set to a non-zero value or
environment variable :envvar:`NOPROGRAM` is nonzero.

In the case of simulation hardware, the simulator is launched when the
application first tries to access the hardware. This behavior is also
suppressed by a nonzero value for either :c:data:`noprogram` or
:envvar:`NOPROGRAM`.

.. c:var:: int noprogram

   If :c:data:`noprogram` is set to a non-zero value, then the FPGA is not programmed automatically.
   
Tracing Simulation
------------------

.. envvar:: DUMP_VCD

   If set, directs the simulator to dump a VCD trace to the $DUMP_VCD.

.. c:var:: int simulator_dump_vcd

   The application can enable VCD tracing by setting
   :c:data:`simulator_dump_vcd` to 1. It takes the file name from
   :c:data:`simulator_vcd_name`. DUMP_VCD overrides this variable.

.. c:var::  const char *simulator_vcd_name;

   Specifies the name of the vcd file. Defaults to
   "dump.vcd". DUMP_VCD overrides this variable.

Zynq Clock Control
------------------

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


PortalPoller
============

.. cpp:class:: PortalPoller

   Polls portals

   .. cpp:member:: PortalPoller::PortalPoller(int autostart = 1)

      If autostart is 1, then invoke :cpp:member:`start()` from :cpp:member:`registerInstance()`

   .. cpp:member:: void PortalPoller::start();

      Starts the poller. Called automatically from :cpp:member:`registerInstance()` if :cpp:member:`autostart` is 1.

   .. cpp:member:: void PortalPoller::stop();

      Stops the poller.

   .. cpp:member:: int PortalPoller::timeout

      The timeout value, in milliseconds, passed to :c:function:`poll()`

:envvar:`PORTAL_TIMEOUT`.

    Overrides the default value for :cpp:member:`PortalPoller::timeout`.

Deprecated Functions
--------------------

.. c:function:: void *portalExec(void *__x)
   Polls the registered portals and invokes their callback handlers.

.. c:function:: void portalExec_start()

.. c:function:: void portalExec_poll()

