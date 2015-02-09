.. Sec-Introduction:

Introduction
************

Because they are so small and inexpensive, processors are now included
in all but the smallest hardware designs. This grants flexibility to
hardware designers because the non-performance-critical components can
be implemented in software and the performance-critical components
can be implemented in hardware.  Using software for parts of the
design can decrease the effort required to implement configuration and
orchestration logic (for example). It can also offer hardware
developers greater adaptability in meeting new project requirements or
supporting additional applications.

As a system evolves through design exploration, the boundary between
the software and hardware pieces can change substantially.  The old
paradigm of ``separate hardware and software designs before the
project starts'' is no longer sustainable, and hardware teams are
increasingly responsible for delivering significant software
components.

Despite this trend, hardware engineers find themselves with
surprisingly poor support for the development of the software that is
so integral to their project's success. They are often required to
manually develop the necessary software and hardware to connect the
two environments. In the software world, this is equivalent to
manually re-creating header files from the prose description of an
interface implemented by a library.  Such ad hoc solutions are tedious,
fragile, and difficult to maintain. Without a consistent framework and
toolchain for jointly managing the components of the hardware/software
boundary, designers are prone to make simple errors which can be
expensive to debug.

The goal of our work is to support the flexible and consistent
partitioning of designs across hardware and software components.  We
have identified the following four goals as central to this endeavor:


* Connect software and hardware by compiling interface declarations.
* Enable concurrent access to hardware accelerators from software.
* Enable high-bandwidth sharing of system memory with hardware accelerators.
* Provide portability across platforms (CPU, OS, bus types, FPGAs).

In this paper, we present a software-driven hardware development
framework called `Connectal`_.  Connectal consists of a
fully-scripted tool-chain and a collection of libraries which can be
used to develop production quality applications comprised of software components running
on CPUs communicating with hardware components implemented in FPGA or
ASIC.

When designing Connectal, our primary goal was to create a collection
of components which are easy to use for simple implementations and
which can be configured or tuned for high performance in more
complicated applications.  To this end, we adopted a decidedly
minimalist approach, attempting to provide the smallest viable
programming interface which can guarantee consistent access to shared
resources in a wide range of software and hardware execution
environments.  Because our framework targets the implementation of
performance-critical systems rather than their simulation, we have
worked hard to remove any performance penalty associated with its use.

We wrote the hardware components of the Connectal libraries in
`Bluespec System Verilog`_
(BSV) because it enables a higher level of abstraction than the
alternatives and supports parameterized types.  The software
components are implemented in C/C++. We chose Bluespec interfaces as
the interface definition language (IDL) for Connectal's interface
compiler.

This paper describes the Connectal framework, and how it can be used
to flexibly move between a variety of software environments and
communication models when mapping applications to platforms with
connected FPGAs and CPUs.

Document Organization
=====================

In Section :ref:`Sec-StrStr`, we present an example running in a
number of different execution environments. In Section
:ref:`Sec-Framework`, we give an overview of the Connectal framework
and its design goals.  In Section :ref:`Sec-Impl` we discuss the
details of Connectal and how it can be used to implement the
example. Section :ref:`Sec-ToolChain` describes the implementation of
Connectal, supported platforms, and the tool chain used to coordinate
the various parts of the framework.  The paper concludes with a
discussion of performance metrics and related work.

.. _Connectal: http://www.connectal.org/
.. _Bluespec System Verilog: http://www.bluespec.com/
.. [Hoe:Thesis]: Hoe:Thesis
.. [HoeArvind:TRS_Synthesis2]: HoeArvind:TRS_Synthesis2
