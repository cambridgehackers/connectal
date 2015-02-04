Connectal Project Structure
***************************

The set of files composing the input to the Connectal toolchain is
referred to as a project.  A collection of out-of-tree example
projects is available at https://github.com/connectal-examples.
To illustrate the structure of a project, this chapter uses the
example https://github.com/connectal-examples/leds, which can be
executed using the Bluesim or Zynq target platforms.

Project Makefile
================

The top-level Makefile
(https://github.com/connectal-examples/leds/blob/master/Makefile)
defines parameters building and executing the project.  In its
simplest form, it specifies which Bluespec interfaces to use as
portals, the hardware and software source files, and the libraries to
use for the hardware and software compilation::

    INTERFACES = LedControllerRequest
    BSVFILES = LedController.bsv Top.bsv
    CPPFILES= testleds.cpp
    NUMBER_OF_MASTERS =0
    include \$(CONNECTALDIR)/Makefile.connectal

``INTERFACES`` is a list of names of BSV interfaces which may be
used to communicate between the HW and SW componentsy.  In addition to
user-defined interfaces, there are a wide variety of interfaces
defined in Connectal libraries which may be included in this list.

``BSVFILES`` is a list of bsv files containing interface
definitions used to generate portals and module definitions used to
generate HW components.  Connectal bsv libraries can be used without
being listed explicitly.

``CPPFILES`` is a list of C/C++ files containing software
components and ``main``.  The Connectal C/C++ libraries can be
used without being listed explicitly.

``NUMBER_OF_MASTERS`` is used to designate the number of host
bus masters the hardware components will instantiate.  For PCIe-based
platforms, this value can be set to 0 or 1, while on Zynq-based
platforms values from 0 to 4 are valid.

``CONNECTALDIR`` must be set so that the top-level Connectal
makefile can be included.  This brings in the default definitions of
all project build parameters as well as the Connectal hardware and
software libraries.  When running the toolchain on AWS, this varible
is set automatically in the build environment.
(\hyperref[compiling_a_project]{Section~\ref{compiling_a_project}})

Project Source
==============

Interface Definitions
---------------------
\label{interface_definitions}

When generating portals, the Connectal interface compiler searches the
Connectal bsv libraries and the files listed in ``BSVFILES`` for
definitions of all the interfaces listed in ``INTERFACES``.  If
an the definition of a listed interfaces is not found, an error is
reported the the compilation aborts.  The interfaces in this list must
be composed exclusively of ``Action`` methods.  Supported method
argument types are ``Bit\#(n)``, ``Bool``,
``Int\#(32)``, ``UInt\#(32)``, ``Float``,
``Vector\#(t)``, ``enum``, and ``struct``.

Software
--------

The software in a Connectal project consists of at least one C++ file
which instantiates the generated portal wrappers and proxies and
implements ``main()``.  The following source defines the SW
component of the example, which simply toggles LEDs on the Zedboard
(\url{https://github.com/connectal-examples/leds/blob/master/testleds.cpp})::

    #include <unistd.h>
    #include "LedControllerRequest.h"
    #include "GeneratedTypes.h"
    int main(int argc, const char **argv)
    {
      LedControllerRequestProxy *device = 
	new LedControllerRequestProxy(IfcNames_LedControllerRequest);
      for (int i = 0; i < 20; i++) {
	device->setLeds(10, 10000);
	sleep(1);
	device->setLeds(5, 10000);
	sleep(1);
      }
    }


The makefile listed ``LedControllerRequest`` as the only communication
interface.  The generated proxies and wrappers for this interface are
in ``LedControllerRequest.h`` which is included, along with C++
implementations of all additional interface types in
``GeneratedTypes.h``. Line 9 instantiates the proxy through which
the software invokes the hardware methods
(\hyperref[flow_control]{Section~\ref{flow_control}}).

Hardware
=========

Connectal projects typically have at least one BSV file containing
interface declarations and module definitions.  The implementation of
the interfaces and all supporting infrastructure is standard BSV.
Interfaces being used as portals are subject to the type restrictions
described earlier
(\hyperref[interface_definitions]{Section~\ref{interface_definitions}}).

Top.bsv
-------

In Top.bsv
(https://github.com/connectal-examples/leds/blob/master/Top.bsv),
the developer instantiates all hardware modules explicitly.
Interfaces which can be invoked through portals need to be connected
to the generated wrappers and proxies.  To connect to the host
processor bus, a parameterized standard interface is used, making it
easy to synthesize the application for different CPUs or for
simulation::

    // Connectal Libraries
    import CtrlMux::*;
    import Portal::*;
    import Leds::*;
    import MemTypes::*;
    import MemPortal::*;
    import HostInterface::*;
    import LedControllerRequest::*;
    import LedController::*;

    typedef enum {LedControllerRequestPortal} IfcNames deriving (Eq,Bits);

    module mkConnectalTop(StdConnectalTop#(PhysAddrWidth));
       LedController ledController <- mkLedControllerRequest();
       LedControllerRequestWrapper ledControllerRequestWrapper <- 
	  mkLedControllerRequestWrapper(LedControllerRequestPortal,
	  ledController.request);

       Vector#(1,StdPortal) portals;
       portals[0] = ledControllerRequestWrapper.portalIfc;
       let ctrl_mux <- mkSlaveMux(portals);

       interface interrupt = getInterruptVector(portals);
       interface slave = ctrl_mux;
       interface masters = nil;
       interface leds = ledController.leds;
    endmodule

Like the SW components, the HW begins by importing the generated
wrappers and proxies corresponding to the interfaces listed in the
project Makefile.  The user-defined implementation of the
LedControllerRequest interface is instantiated on line 14, and wrapped
on line 15.  This wrapped interface is connected to the bus using the
library module ``mkSlaveMux`` on line 21 so it can be invoked
from the software.  At the end of the module definition, the top-level
interface elements must be connected.  A board-specific top-level
module will include this file, instantiate ``mkConnectalTop`` and
connect the interfaces to the actual peripherals. The name of the file
must be ``Top.bsv`` and the name of the module must be
``mkConnectalTop``.

The Bluespec compiler generates a Verilog module from the top level
BSV module, in which the methods of exposed interfaces are implemented
as Verilog ports. Those ports are associated to physical pins on the
FPGA using a physical constraints file. If CPU specific interface
signals are needed by the design (for example, extra clocks that are
generated by the PCIe core), then an optional CPU-specific interface
can also be used.  If the design uses multiple clock domains or
additional pins on the FPGA, those connections are also made here by
exporting a 'Pins' interface
(\hyperref[host_interface]{Section~\ref{host_interface}}).

