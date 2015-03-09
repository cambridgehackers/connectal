# Serial Configuration Register

L. Stewart, Quanta Research Cambridge, stewart@qrclab.com

In many designs, there is a need for configuration control registers
that do not have high bandwidth requirements. They are used to configure
a piece of hardware, to contain near constants, etc.

There is also a need to read the contents of registers in the design.

The straightforward way to specify configuration registers using
portals leads to wide parallel busses to each register.

Serial Configuration Registers are intended to solve these problems.

The example defines two modules, an SpiReg and an SpiRoot.

An SpiReg creates a Register for a user defined type, and also
an SpiTap to read and write the register over a serial bus.

This is much like a JTAG scannable register, but with simpler SPI type
serial protocol.  Each SpiReg has an address and up to 32 bits of data.

The SpiRoot module provides a parallel, FIFO interface to a collection
of Spi Registers.  The Registers are connected in a serial chain. To
perform a write to an SpiReg, the client writes register address and data
into the FIFO.  Returning read data (and acks for write data) show
up at the output of the FIFO.

