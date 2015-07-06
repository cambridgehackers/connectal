Portal Interface Structure
**************************

Connectal connects software and hardware via portals, where each portal is
an interface that allows one side to invoke methods on the other side.

We generally call a portal from software to hardware to be a "request"
and from hardware to software to be an "indication" interface::

    Sequence Diagram to be drawn
    {
      SW; HW
      SW -> HW [label = "request"];
      SW <- HW [label = "indication"];
    }


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

Connectal is designed to support multiple tiles, each of which can
hold an independent design. Currently, the number of tiles is one.

Connectal currently supports up to 16 portals connected between software and hardware, for a total of 64KB of address space.

=============  =========
 Base address  Function
=============  =========
       0x0000  Portal 0
       0x1000  Portal 1
       0x2000  Portal 2
       0x3000  Portal 3
       0x4000  Portal 4
       0x5000  Portal 5
       0x6000  Portal 6
       0x7000  Portal 7
       0x8000  Portal 8
       0x9000  Portal 9
       0xa000  Portal 10
       0xb000  Portal 11
       0xc000  Portal 12
       0xd000  Portal 13
       0xe000  Portal 14
       0xf000  Portal 15
=============  =========

Each portal uses 16KB of address space, consisting of a control
register region and then per-method FIFOs, each of which takes 32
bytes of address space.

============== ==========
 Base address   Function
============== ==========
  0x000        Portal control regs
  0x020        Method 0 FIFO
  0x040        Method 1 FIFO
 ...           ...
============== ==========

For request portals, the FIFOs are from software to hardware, and for
indication portals the FIFOs are from hardware to software.

Portal FIFOs
------------

============== ==========
 Base address   Function
============== ==========
   0x00        FIFO data (write request data, read indication data)
   0x04        Request FIFO not full / Indication FIFO not empty
============== ==========

Portal Control Registers
------------------------

============= ============================= =========================================================
Base address  Function                      Description
============= ============================= =========================================================
	0x00  Interrupt status register     1 if this portal has any messages ready, 0 otherwise
	0x04  Interrupt enable register     Write 1 to enable interrupts, 0 to disable
	0x08  Number of tiles
	0x0C  Ready Channel number + 1      Reads as zero if no indication channel ready
	0x10  Interface Id
	0x14  Number of portals
	0x18  Cycle count LSW               Snapshots MSW when read
	0x1C  Cycle count MSW               MSW of cycle count when LSW was read
============= ============================= =========================================================


