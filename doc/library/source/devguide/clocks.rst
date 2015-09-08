.. _devguide_clocks:

***************************************
Clocking Your Design
***************************************

Every board has a main clock, which is the clock exposed by
"exposeCurrentClock". It has a default value, but that value can be
overriden with CONNECTALFLAG --mainclockperiod, which is an integer
specified in nanoseconds.

There is a second clock available, which I called "derivedClock"
because it was derived from the main clock. You can specify its clock
period with --derivedclockperiod, which is a float specified in
nanoseconds. I'm using an MMCM, which has one clock specified by a
fractional divisor.

On PCIe-connected boards, the main clock frequency defaults to the
PCIe user clock frequency (125MHz for gen1, 250MHz for gen2). But you
can override that, in which case your hardware is connected to PCIe
via sync FIFOs.

You are responsible for any synchronization required between the main
and derived clock domains.

There are two ways to get access to the derivedClock in your design.

IMPORT_HOST_CLOCKS
==================

This is simpler, and preserves the synthesis boundary on mkConnectalTop. See examples/echoslow

In the Makefile

    CONNECTALFLAGS += -D IMPORT_HOST_CLOCKS

Add ":host.derivedClock,host.derivedReset" to H2S_INTERFACES:

    H2S_INTERFACES = Echo:EchoIndication:host.derivedClock,host.derivedReset

Or just pass in host.derivedClock and create a reset locally.

Look at the generated <board>/generatedbsv/Top.bsv to see how this changed the generated code.

IMPORT_HOSTIF
=============

This option is only useful for Zynq, in order to get access to other PS7
interfaces and clocks that are not part of the standard portal
interface, e.g., I2C.

    CONNECTALFLAGS += -D IMPORT_HOSTIF

Add ":host" to H2S_INTERFACES.

See tests/test_sdio1 for an example of the use of IMPORT_HOSTIF, though it has a manually written Top.bsv.

Setting Zynq Clock Speeds
=========================



Default Clock Speeds
====================

The default values for --mainclockperiod and --derivedclockperiod for
the each board are in the JSON files in the boardinfo directory.
