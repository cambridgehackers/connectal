HostInterface Package
=====================

The HostInterface package provides host-specific typedefs and interfaces.

.. bsv:package:: HostInterface

Host-Specific Constants
------------------------

.. bsv:typedef:: DataBusWidth

   Width in bits of the data bus connected to host shared memory.

.. bsv:typedef:: PhysAddrWidth

   Width in bits of physical addresses on the data bus connected to host shared memory.

.. bsv:typedef:: NumberOfMasters

   Number of memory interfaces used for connecting to host shared memory.

Host-Specific Interfaces
------------------------

.. bsv:interface:: BsimHost

   Host interface for the bluesim platform

.. bsv:interface:: PcieHost

   Host interface for PCIe-attached FPGAs such as vc707 and kc705

.. bsv:interface:: ZynqHost

   Host interface for Zynq FPGAs such as zedboard, zc702, zc706, and zybo.

   The Zc706 is a ZynqHost even when it is plugged into a PCIe slot.

Application-Specific Types
--------------------------

.. bsv:typedef:: PinType

   Specifies the type of the application pins interface. Defined from PIN_TYPE.

