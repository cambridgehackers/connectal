Abstract
********

The cost and complexity of hardware-centric systems can often be
reduced by using software to perform tasks which don't appear on the
critical path.  Alternately, the performance of software can sometimes
be improved by using special purpose hardware to implement tasks which
*do* appear on the critical path.  Whatever the motivation,
most modern systems are composed of both hardware and software
components.

Given the importance of the connection between hardware and
software in these systems, it is surprising how little automated and
machine-checkable support there is for co-design space exploration.
This paper presents the Connectal framework, which enables the
development of hardware accelerators for software applications by
generating hardware/software interface implementations from abstract
Interface Design Language (IDL) specifications.

`Connectal`_ generates stubs to support asynchronous remote method
invocation from software to software, hardware to software, software
to hardware, and hardware to hardware. For high-bandwidth
communication, the Connectal framework provides comprehensive support
for shared memory between hardware and software components, removing
the repetitive work of processor bus interfacing from project tasks.

This framework is released as open software under an MIT license, making
it available for use in any projects.

.. _Connectal: http://www.connectal.org/
