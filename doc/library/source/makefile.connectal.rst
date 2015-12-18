Makefile.connectal
==================

A Connectal design imports Makefile.connectal into its Makefile in order to drive the build.

A number of variables are used to control the build and parameters of the design.

Environment Variables
---------------------

.. envvar:: CONNECTALDIR

   Points to the location where Makefile.connectal and the connectal tools are installed.

Make Variables Defining the Application
---------------------------------------

.. make:var:: BOARD

   This is typically set from the suffix of the build target, e.g., make build.zedbard defines BOARD=zedboard.

.. make:var:: INTERFACES

   Specifies for which interfaces to generate c/c++/bsv proxies and wrappers.

.. make:var:: NUMBER_OF_MASTERS

   Number of DMA masters in the design. Defaults to 1.

.. make:var:: PIN_TYPE

   BSV interface of exported pins. Defaults to Empty. BSV type bsv:typedef::PinType is defined from PIN_TYPE.

.. make:var:: PIN_TYPE_INCLUDE

   Which BSV package to import to get the declaration of PIN_TYPE.

.. make:var:: PINOUT_FILE

   Which pin usage JSON files to pass to makefilegen.py as :option::`--pinout` options.

.. make:var:: BSVFILES

   Lists the BSV files to scan when processing INTERFACES.

.. make:var:: CPPFILES

   Lists the C/C++ files that implement the application.

.. make:var:: CPPFILES2

   Lists the C/C++ files that implement the (optional) second executable of an application. For example, a daemon that coordinates access to the hardware.

.. make:var:: PORTAL_DUMP_MAP

   Specifies the option to provide to pcieflat to annotate PCIe traces with portal numbers and method names. Uses generatedDesignInterfaceFile.json.


Auto Top
--------

.. make:var:: S2H_INTERFACES

.. make:var:: H2S_INTERFACES

.. make:var:: MEM_READ_INTERFACES

.. make:var:: MEM_WRITE_INTERFACES



Controlling the Build
---------------------

.. make:var:: CONNECTALFLAGS

   Flags to pass to makefilegen.py. See :ref:`_invocation_makefilegen.py` for its options.

.. make:var:: V

   Controls verbosity of the build. V=1 for verbose.

.. make:var:: USE_BUILDCACHE

   Define USE_BUILDCACHE=1 to use buildcache. Except fpgamake seems to use buildcache anyway.

.. make:var:: BUILDCACHE

   Location of buildcache script.

.. make:var:: BUILDCACHE_CACHEDIR

   To specify an alternate location for the buildcache cache files.

.. make:var:: IPDIR

   Specifies into which directory to generate IP cores. This allows generated cores to be shared between designs when the FPGA part and core parameters match.


.. make:var:: MAIN_CLOCK_PERIOD

   Bound to the clock period, in nanoseconds, of the clock domain of mkConnectalTop.

   Defaults to 8ns for vc707 and kc705.

   Defaults to 10ns for zedboard.

   Defaults to 5ns for zc706.

.. make:var:: DEFAULT_DERIVED_CLOCK_PERIOD

   Bound to the default clock period, in nanoseconds, of the derived
   clock provided via HostInterface to mkConnectalTop. Defaults to
   half the period, twice the frequency of the main clock.

.. make:var:: DERIVED_CLOCK_PERIOD

   Bound to the clock period, in nanoseconds, of the derived clock provided via HostInterface to mkConnectalTop. Defaults to DEFAULT_DERIVED_CLOCK_PERIOD.

.. make:var:: BURST_LEN_SIZE

   Controls width of fields specifying memory request burst lengths. Defaults to 8.

.. make:var:: RUNPARAM

   Specifies the name or IP address of the machine on which to run the application, e.g.::

      make RUNPARAM=192.168.168.100 run.android


Top Level Make Targets
----------------------

.. make:target:: build.%

   Builds software and bitfile for the specified board name, e.g.,::

     make build.zedboard

.. make:target:: run.%

   Programs the FPGA and runs the application using the build for the specified board name. Uses :make:var:RUNPARAM. For example,::

      make RUNPARAM=sj10 run.vc707

Intermediate Make Targets
-------------------------

.. make:target:: verilog

   Runs the build up through generation of verilog from BSV. Requires BOARD to be defined.

.. make:target:: bits

   Generates the FPGA bit file from the design. Requires BOARD to be defined.

.. make:target:: bsim

   For BOARD=bluesim, generates the simulation executable.

.. make:target:: xsim

   For BOARD=xsim, generates the simulation executable.

.. make:target:: android.exe

   Builds the software executable for boards using Android.

.. make:target:: ubuntu.exe

   Builds the software executable for boards using Ubunto/CentOS.

.. make:target:: bsim_exe

   Builds the software executable for bluesim.

.. make:target:: gentarget

   This step creates the board directory and Makefile.

.. make:target:: prebuild

   Additional steps needed before making verilog, etc.  Use this
   target for dependences such as constraint file and IP core
   generation that need to be run before the design is built. This is
   a :: dependence, so you can specify it multiple times.
