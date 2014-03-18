Jamey Hicks, John Ankcorn, Myron King

L. Stewart - Scribe

January 21, 2014

Temporary change to see if I can commit from the page editor

## What is Portal?

Portal provides a hardware-software interface for applications split between user mode code and custom hardware in an FPGA or ASIC.  Portal can automaticaly build the software and hardware glue for a message based interface and also provides for configuring and using shared memory between applications and hardware. Communications between hardware and software are provided by a bidirectional flow of events and regions of memory shared between hardware and software.  Events from software to hardware are called requests and events from hardware to software are called indications, but in fact they are symmetric.

**Lexicon:**

xbsv: The name of our project, whose goal is to ease the task of building applications composed of hardware and software components.  Programmers use bsv as an IDL to specify the interface between the hardware and software components.   A combination of generated code and libraries coordinate the data-flow between the program modules.   Because the HW and SW stacks are customized for each application, the overheads associated with communicating across the HW/SW boundary are low.

HW/SW interface :: [portal]

bluespec: bsv

bsv: Bluespec system verilog.  bsv is a language for describing hardware that is might higher level than verilog. See [BSV Documentation ](http://wiki.bluespec.com/Home/BSV-Documentation)and [bluespec](http://bluespec.com/)

portal: a logical request/indication pair is referred to as a portal.  current tools require their specification in the IDL to be syntactically identifiable (i.e. fooRequest/fooIndication).  An application can make use of multiple portals, which may be specified independently.

request interface: These methods are implemented by the application hardware to be invoked by application software.   A bsv interface consisting of ‘Action’ methods.  Because of the ‘Action’ type, data flow across this interface is unidirectional (SW -> HW).

indication interface: The dual of a request interface, indication interfaces are ‘Action’ methods implemented by application software to be invoked by application hardware.   As with request interfaces, the data flow across this interface is unidirectional, but in the opposite direction.

pcieportal/zynqportal: these two loadable kernel modules implement the minimal set of driver functionality.  Specifically, they expose portal HW registers to SW through mmap, and set up interrupts to notify SW that an indication method has been invoked by HW.  

portalalloc: This loadable kernel module exposes a subset of dma-buf functionality to user-space software (though a set of ioctl commands) to allocate and manage memory regions which can be shared between SW and HW processes.   Maintaining coherence of the allocated buffers between processes is not automatic: ioctl commands for flush/invalidate are provided to be invoked explicitly by the users if necessary. 

genxprogfrombsv: The name of the interface compiler which takes as input the bsv interface specification along with a description of a target platform and generates logic in both HW and SW to support this interface across the communication fabric.

## Example setups:

A zedboard ( [http://www.zedboard.org/](http://www.zedboard.org/) ), with Android running on the embedded ARM processors (the Processing System 7), an application running as a user process, and custom hardware configured into the Programmable Logic FPGA.

An x86 server, with Linux running on the host processor, an application running partly as a user process on the host and partly as hardware configured into an FPGA connected by PCI express (such as the Xilinx VC707 [http://www.xilinx.com/products/boards-and-kits/EK-V7-VC707-G.htm](http://www.xilinx.com/products/boards-and-kits/EK-V7-VC707-G.htm) ).

## Background

When running part or all of an application in an FPGA, it is usually necessary to communicate between code running in user mode on the host and the hardware.  Typically this has been accomplished by custom device drivers in the OS, or by shared memory mapped between the software and the hardware, or both.  Shared memory has been particularly troublesome under Linux or Android, because devices frequently require contiguous memory, and the mechanisms for guaranteeing successful memory allocation often require reserving the maximum amount of memory at boot time.  

Portal tries to provide convenient solutions to these problems in a portable way.

It is desirable to have

* low latency for small messages

* high bandwidth for large messages

* notification of arriving messages

* asynchronous replies to messages

* support for hardware simulation by a separate user mode process

* support for shared memory (DMA) between hardware and software

## Overview

Portal is implemented as a loadable kernel module device driver for Linux/Android and a set of tools to automatically construct the hardware and software glue necessary for communications.

Short messages are handled by programmed I/O.  The message interface from software to hardware (so called "requests") is defined as a bsv interface containing a number of Action methods, each with a name and typed arguments.  The interface generator creates all the software and hardware glue so that software invocations of the interface stubs flow through to, and are turned into bsv invocations of the matching hardware.  The machinery does not have flow control. Software is responsible for not overrunning the hardware.  There is a debug mechanism which will return the request type of a failed method, but it does not tell which invocation failed.  Hardware to software interfaces (so called “indications”) are likewise defined by bsv interfaces containing Action methods. Hardware invocations of these methods flow through to and cause software calls to corresponding user-supplied functions.  In the current implementation there is flow control, in that the hardware will stall until there is room for a hardware to software message.  There is also a mechanism for software to report a failure, and there is machinery for these failures to be returned to the hardware.

Incoming messages can cause host interrupts, which wake up the device driver, which can wake up the user mode application by using the select(2) or poll(2) interfaces or by unblocking a pending read(2) [is that true about read?].

Most of the time, communications between hardware and software will proceed without requiring use of the OS.  User code will read and write directly to memory mapped I/O space. Library code will poll for incoming messages, and [true? eventually time out and call poll(2).]  Only when poll(2) or select(2) are called will the device driver enable hardware interrupts.  Thus interrupts are only used to wake up software after a quiet period.

The designer specifies a set of hardware functions that can be called from software, and a set of actions that the hardware can take which result in messages to software. Portal tools take this specification and build software glue modules to translate software function calls into I/O writes to hardware registers, and to report hardware events to software.

For larger memory and OS bypass (OS bypass means letting the user mode application talk directly to the hardware without using the OS except for setup), portal implements shared memory.  Portal memory objects are allocated by the user mode program, and appear as Linux file descriptors. The user can mmap(2) the file to obtain user mode access to the shared memory region. Portal does not assure that the memory is physically contiguous, but does pin it to prevent the OS from reusing the memory.  An FPGA DMA controller module is provided that gives the illusion of contiguous memory to application hardware, while under the covers using a translation table of scattered addresses.

The physical addresses are provided to the user code in order to initialize the dma controller, and address "handles" are provided for the application hardware to use.

The DMA controller provides Bluespec objects that support streaming access with automatic page crossings, or random access.

## An Example

An application developer will typically write the hardware part of the application in Bluespec and the software part of the application in C or C++.  In a short example, there will be a bsv source file for the hardware and a cpp source file for the application.

The application developer is free to specify whatever hardware-software interface makes sense.

Refer to [https://github.com/cambridgehackers/xbsv](https://github.com/cambridgehackers/xbsv)

In the examples directory, see [echo](../examples/echo/).  The file [Echo.bsv](../examples/echo/Echo.bsv) defines the hardware, and testecho.cpp supplies the software part. In this case, the software part is a test framework for the hardware.  This example has a second interface, defined by [Swallow.bsv](../examples/echo/Swallow.bsv).

Echo.bsv defines the actions (called Requests) that software can use to cause the hardware to act, and defines the notifications (called Indications) that the hardware can use to signal the software.

    interface EchoIndication;
    	method Action heard(Bit#(32) v);
    	method Action heard2(Bit#(16) a, Bit#(16) b);
    endinterface
    interface EchoRequest;
       method Action say(Bit#(32) v);
       method Action say2(Bit#(16) a, Bit#(16) b);
       method Action setLeds(Bit#(8) v);
    endinterface


Swallow.bsv defines another group of actions:

    interface Swallow; 
       method Action swallow(Bit#(32) v);
    endinterface


Software can start the hardware working via say, say2, setLeds, and swallow. Hardware signals back to software with heard and heard2.  In the case of this example, say and say2 merely echo their arguments back to software. setLeds blinks the zedboard lights, and swallow throws away its argument.

The definitions in the bsv file are used by the xbsv infrastructure ( a python program)  to automatically create corresponding c++ interfaces.

    ../../genxpsprojfrombsv -Bbluesim -p bluesim -x mkBsimTop \
         -s2h Swallow  -s2h EchoRequest \
         -h2s EchoIndication \
         -s testecho.cpp \
         -t ../../bsv/BsimTop.bsv  Echo.bsv Swallow.bsv Top.bsv

The tools have to be told which interface records should be used for Software to Hardware messages and which should be used for Hardware to Software messages. These interfaces are given on the command line for genxpprojfrombsv

genxpsprojfrombsv constructs all the hardware and software modules needed to wire up portals. This is sort of like an RPC compiler for the hardware-software interface.

The user must also create a toplevel bsv module Top.bsv, which instantiates the user portals, the standard hardware environment, and any additional hardware modules.

Rather than constructing the `genxpsprojfrombsv` command line from
scratch, the examples in xbsv use include
[Makefile.common](../Makefile.common) and define some `make`
variables.

Here is the Makefile for the `echo` example:

```make
    ## hardware interfaces invoked from software (requests)
    S2H = Swallow EchoRequest
    ## software interfaces invoked from hardware (indications)
    H2S = EchoIndication
    ## all the BSV files to be scanned for types and interfaces
    BSVFILES = Echo.bsv Swallow.bsv Top.bsv
    ## the source files in the example
    CPPFILES=testecho.cpp

    include ../../Makefile.common
```

### genxpsprojfrombsv parameters


| Option | Long Option | Default | Description |
---------|-------------|---------|-------------------------------------|
| -B     | --board     | zc702   | Board to generate code for (Mandatory) [bluesim, zedboard, zc702, vc707, kc705, ...]|
| -C     | --constraint|         | Additional constraint files (Optional) |
| -I     | --contentid |         | Specify 64-bit contentid for PCIe designs (Optional) |
| -M     | --make      |         | Run make on the specified targets after generating code (Optional) |
| -O     | --OS        |         | Operating system of platform, inferred from board (Optional) |
| -V     | --verilog   |         | Additional verilog sources to include in hardware synthesis. (Optional) |
| -h2s   | --h2sinterface |      | Hardware to software interface |
| -l     | --clib      |         | Additional C++ libary (Optional) |
| -p     | --project-dir | ./xpsproj | Directory in which to generate files (Optional) |
| -s     | --source    |         | C++ source files (Optional) |
| -s2h   |--s2hinterface |       | Software to hardware interface |
| -t     | --topbsv    |         | Top-level bsv file (Required) |
| -x     | --export    |         | Promote/export named interface from top module (Required) |


### Generated files



## Design Structure

Designs using `xbsv` may also include `xbsv/Makefile.common` if they define `XBSVDIR` in their Makefile:

```make
    XBSVDIR=/scratch/xbsv
    S2H = FooRequest
    H2S = FooIndication
    BSVFILES = Foo.bsv
    CPPFILES = foo.cpp
    include $(XBSVDIR)/Makefile.common
```

## Shared Memory

In order to use shared memory, the hardware design instantiates a DMA module.  In Memread.bsv, this is

`   AxiDMA          	dma <- mkAxiDMA(indication.dmaIndication);`

The hardware design must also include the standard Request and Indications interfaces that support shared memory, which are DMARequest and DMAIndications.

The code generation tools will then produce the software glue necessary for the shared memory support libraries to initialize the DMA "library module" included in the hardware.

There are several implementations of the DMA interfaces:

AxiSDMA  - axi  (fpga) sequential DMA

AxiRDMA - axi (fpga) random access DMA

BsimSDMA - Bluesim simulator sequential DMA

BsimRDMA - Bluesim simulator random access DMA

the hardware design will use whichever implementation is appropriate, but all have the same Request and Indications interface, so software can does not have to change.  [Although one presumes that the software knows it is sequential or random, so it kind of needs to know.]

Sequential Interface

If the designer chooses a sequential interface, the DMA hardware interface module includes a memory that is initialized with a list of base-address,length pairs. As the hardware makes memory references, the memory address is automatically incremented and stepped through the list of descriptors. This is a hardware instance of the iovec data type common to software, and is called an sglist, for scatter-gather list.

In order to start again from the beginning of the address list, a special reset action is invoked, either by software [or by hardware?].

Random Access Interface

If the designer chooses a random access interface, the DMA hardware interface module includes a memory that is initialized with a page table spanning the allocated memory region. As the hardware makes requests, the interface module uses the high part of the address to look up the proper physical address.

[stewart notes

Currently there are no valid bits and no protections against bursts crossing page boundaries]

There needs to be a way to synchronize Request actions and DMA reads, and to synchronize DMA writes with Indications, so that the writes complete to the coherence point before the indication is delivered to software. One could imagine an absurdly buffered memory interface and a rather direct path for I/O reads that could get out of order.

]
