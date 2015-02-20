Makefile.connectal
==================

A Connectal design imports Makefile.connectal into its Makefile in order to drive the build.

A number of variables are used to control the build and parameters of the design.

Environment Variables
---------------------

.. envvar:: CONNECTALDIR

   Points to the location where Makefile.connectal and the connectal tools are installed.

Make Variables
--------------

.. make:var:: V

   Controls verbosity of the build. V=1 for verbose.

.. make:var:: BOARD

   This is typically set from the suffix of the build target, e.g., make build.zedbard defines BOARD=zedboard.

.. make:var:: IPDIR

   Specifies into which directory to generate IP cores. This allows generated cores to be shared between designs when the FPGA part and core parameters match.


.. make:var:: NUMBER_OF_MASTERS

   Number of DMA masters in the design. Defaults to 1.

.. make:var:: PIN_TYPE

   BSV interface of exported pins. Defaults to Empty.

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

.. make:var:: INTERFACES

   Specifies for which interfaces to generate c/c++/bsv proxies and wrappers.

.. make:var:: RUNPARAM

   Specifies the name or IP address of the machine on which to run the application, e.g.::

      make RUNPARAM=192.168.168.100 run.zedboard


Make Targets
------------

.. make:target:: build.%

   Builds software and bitfile for the specified board name, e.g.,::

     make build.zedboard

.. make:target:: run.%

   Programs the FPGA and runs the application using the build for the specified board name. Uses :make:var:RUNPARAM. For example,::

      make RUNPARAM=sj10 run.vc707

