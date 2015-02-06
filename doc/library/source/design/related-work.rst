.. _Sec:RelWork

Related Work
============

A number of research projects, such as Lime~\cite{REL:Lime},
BCL~\cite{King:2012:AGH:2150976.2151011},
HThreads~\cite{DBLP:conf/fpl/PeckAASBA06}, and
CatapaultC~\cite{CatC:www} (to name just a few) bridge the
software/hardware development gap by providing a single language for
developing both the software and hardware components of the design.
In addition, Altera and Xilinx have both implemented
OpenCL~\cite{Opencl} on FPGAs~\cite{AlteraOpencl,XilinxOpencl} in an
attempt to attract GPU programmers.

The computation model of software differs significantly from that of
hardware, and so far none of the unified language approaches deliver
the same performance as languages designed specifically for hardware
or software. Connectal is intended to be used for the design of
performance-critical systems.  In this context we think that designers
prefer a mix of languages specifically designed for their respective
implementation contexts.

Infrastructures such as LEAP~\cite{DBLP:conf/fpl/FlemingYAE14},
Rainbow~\cite{DBLP:journals/ijrc/JozwikHETT13}, and
OmpSs~\cite{DBLP:conf/fpga/FilguerasGJAMLNV14} (to name just a
few) use resource abstraction to enable FPGA development.  We found
that in their intended context, these tools were easy to use but that
performance tuning in applications not foreseen by the infrastructure
developers was problematic.

Some projects such as
TMD-MPI~\cite{DBLP:journals/trets/SaldanaPMNWCWSP10},
VFORCE/ \\VSIPL++~\cite{DBLP:journals/jpdc/MooreLK12}, and
GASNet/GAScore~\cite{DBLP:conf/fpga/WillenbergC13} target only the
hardware software interface.  These tools provide message passing
capabilities, but rely on purely operational semantics to describe the
HW/SW interface.  Apart from the implementation details, Connectal
distinguishes itself by using an IDL to enforce denotational interface
semantics.

UIO~\cite{UIO:Howto} is a user-space device driver framework for
Linux. It is very similar to the Connectal's portal device driver, but
it does not provide a solution to multiple device nodes per hardware
device. The portal driver provides this so that different interfaces
of a design may be accessed independently, providing process boundary
protection, thread safety, and the ability for user processes and the
kernel both to access the hardware device.
