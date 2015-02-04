Portal Interface Structure
**************************

Connectal connects software and hardware via portals, where each portal is
an interface that allows one side to invoke methods on the other side.

We generally call a portal from software to hardware to be a "request"
and from hardware to software to be an "indication" interface.

["seqdiag",target="request-response-21.png"]
---------------------------------------------------------------------
{
  SW; HW
  SW -> HW [label = "request"];
  SW <- HW [label = "indication"];
}
---------------------------------------------------------------------

A portal is conceptually a FIFO, where the arguments to a method are
packaged as a message. CONNECTAL generates a "proxy" that marshalls the
arguments to the method into a message and a "wrapper" that unpacks
the arguments and invokes the method.

Currently, connectal Includes a library that implements portals from
software to hardware via memory mapped hardware FIFOs.

Portal Device Drivers
=====================

Connectal uses a platform-specific driver to enable user-space applications
to memory-map each portal used by the application and to enable the
application to wait for interrupts from the hardware.

indexterm:pcieportal
indexterm:zynqportal

* pcieportal.ko
* zynqportal.ko

Connectal also uses a generic driver to enable the applications to allocate DRAM that will be shared with the hardware and to send the memory mapping of that memory to the hardware.

* portalmem.ko

Portal Memory Map
=================

Connectal currently supports up to 16 portals connected between software and hardware, for a total of 1MB of address space.

=============  =========
 Base address  Function
=============  =========
      0x00000  Portal 0
      0x10000  Portal 1
      0x20000  Portal 2
      0x30000  Portal 3
      0x40000  Portal 4
      0x50000  Portal 5
      0x60000  Portal 6
      0x70000  Portal 7
      0x80000  Portal 8
      0x90000  Portal 9
      0xa0000  Portal 10
      0xb0000  Portal 11
      0xc0000  Portal 12
      0xd0000  Portal 13
      0xe0000  Portal 14
      0xf0000  Portal 15
=============  =========

Each portal uses 64KB of address space, consisting of a control
register region and then per-method FIFOs.

============== ==========
 Base address   Function
============== ==========
 0x0000        Portal control regs
 0x0100        Method 0 FIFO
 0x0200        Method 1 FIFO
 ...           ...
============== ==========

For request portals, the FIFOs are from software to hardware, and for
indication portals the FIFOs are from hardware to software.

=== Portal FIFOs

=== Portal Control Registers


============= ============================= =========================================================
Base address  Function                      Description
============= ============================= =========================================================
      0xc000  Interrupt status register     1 if this portal has any messages ready, 0 otherwise
      0xC004  Interrupt enable register     Write 1 to enable interrupts, 0 to disable
      0xC008  7                             Fixed value
      0xC00C  Underflow read count reg      
      0xC010  Out of range read count reg   
      0xC014  Out of range write count reg  
      0xC018  Ready channel indication      channel number + 1 if message is available, 0 otherwise
============= ============================= =========================================================


