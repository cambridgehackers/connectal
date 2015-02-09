.. _Sec-StrStr:

Accelerating String Search
==========================

The structure of a hardware/software (HW/SW) system can evolve quite
dramatically to reflect changing requirements, or during design
exploration.  In this section, we consider several different
implementations of a simple string search
application~\cite{mpAlgo}. Each variation represents a step in the
iterative refinement process, intended to enhance performance or
enable a different software execution environment.

    \begin{figure}[!h]
      \centering
     \includegraphics[width=0.43\textwidth]{platform.pdf}
      \caption{\label{Fig:Platform0}Target platform for string search
	application}
    \end{figure}

Figure~\ref{Fig:Platform0} shows the target platform for our example.
The pertinent components of the host system are the multi-core CPU,
system memory, and PCI Express (PCIe) bus.  The software components of
our application will be run on the CPU in a Linux environment.
Connected to the host is a PCIe expansion card containing (among other
things) a high-performance FPGA chip and a large array of flash
memory.  The FPGA board was designed as a platform to accelerate ``big
data'' analytics by moving more processing power closer to the storage
device.

.. _Sec:StrStrInitial:

Initial Implementation
----------------------

    \begin{figure}[!h]
      \centering
     \includegraphics[width=0.43\textwidth]{data_accel_logical0.pdf}
      \caption{\label{Fig:StringSearch0}Logical components of the string
	search system}
    \end{figure}

The design process really begins with a pure software implementation
of the algorithm, but the first attempt we consider is the initial
inclusion of HW acceleration shown in Figure~\ref{Fig:StringSearch0}.
The search functionality is executed by software running in user-space
which communicates with the hardware accelerator through a device
driver running in the Linux kernel.  The hardware accelerator,
implemented in the FPGA fabric, executes searches over data stored in
the flash array as directed by the software.

The FPGA has direct access to the massive flash memory array, so if we
implement the search kernel in hardware, we can avoid bringing data
into the CPU cache (an important consideration if we intend to run
other programs simultaneously).  By exploiting the high parallelism of
the execution fabric as well as application aware caching of data, an
FPGA implementation can outperform the same search executed on the
CPU.

Multithreading the Software
---------------------------

The efficient use of flash memory requires a relatively sophisticated
management strategy.  Our first refinement is based on the observation
that there are four distinct tasks which the application software
executes (mostly) independently:


* Send search command to the hardware.
* Receive search results from the hardware.
* Send commands to the hardware to manage the flash arrays
* Receive responses from the flash management hardware

To exploit the task-level parallelism in our application, we can
assign one thread to each of the four enumerated tasks.  To further
improve efficiency, the two threads receiving data from the hardware
put themselves to sleep by calling \textbf{poll} and are woken up only
when a message has been received.  

    \begin{figure}[!h]
      \centering
     \includegraphics[width=0.43\textwidth]{data_accel_logical1.pdf}
      \caption{\label{Fig:StringSearch1}Using a mutex to coordinate
      user-level access to hardware accelerator}
    \end{figure}

With the introduction of multithreading, we will need a
synchronization mechanism to enforce coherent access to the hardware
resources. Because the tasks which need coordinating are all being
executed as user-space threads, the access control must be implemented
in software as well.  As shown in Figure~\ref{Fig:StringSearch1}, a
mutex is used to coordinate access to the shared hardware resource
between user-level processes.

.. _Sec:StrStrRefiningInterfaces:

Refining the Interfaces
-----------------------

    \begin{figure}[!h]
      \centering
      \includegraphics[width=0.43\textwidth]{data_accel_logical2.pdf}
      \caption{\label{Fig:StringSearch2}Movement of functionality from
	user to kernel space.  Software-based coordination between kernel
	and user processes are prohibitively expensive.}
    \end{figure}

Figure~\ref{Fig:StringSearch2} shows a further refinement to our
system in which we have reimplemented the Flash Management
functionality as a block-device driver.  Instead of directly operating
on physical addresses, the string search now takes a file descriptor
as input and uses a Linux system-call to retrieve the file block addresses
through the file system. This refinement permits other developers to
write applications which can take advantage of the accelerator without
any knowledge of the internal details of the underlying storage
device.  It also enables support for different file systems as we now
use a POSIX interface to generate physical block lists for the the
storage device hardware.  The problem with this refinement is that we
no longer have an efficient SW mechanism to synchronize the block
device driver running in kernel space with the application running in
user space.

    \begin{figure}[htb]
      \centering
      \includegraphics[width=0.43\textwidth]{data_accel_logical3.pdf}
      \caption{\label{Fig:StringSearch3}Correct interface design
	removes the need for coordination between user and kernel
	threads.}
    \end{figure}
 
To solve to this problem (shown in Figure~\ref{Fig:StringSearch3}), we
can remove the need for explicit SW coordination altogether by giving
each thread uncontested access to its own dedicated HW resources
mapped into disjoint address regions. (There will of course be
implicit synchronization through the file system.)

.. _Sec:StrStrDma:

Shared Access to Host Memory
----------------------------

In the previous implementations, all communication between hardware
and software takes place through memory mapped register IO.  Suppose that instead of
searching for single strings, we want to search for large numbers of
(potentially lengthy) strings stored in the flash array.  Attempting
to transfer these strings to the hardware accelerator using programmed
register transfers introduces a performance bottleneck.  In our final
refinement, the program will allocate memory on the host system,
populate it with the search strings, and pass a reference to this
memory to the hardware accelerator which can then read the search
strings directly from the host memory.

    \begin{figure}[htb]
      \centering
      \includegraphics[width=0.43\textwidth]{data_accel_logical4.pdf}
      \caption{\label{Fig:StringSearch4}Connectal support for DMA.}
    \end{figure}

Efficient high-bandwidth communication in this style requires the
ability to share allocated memory regions between hardware and
software processes without copying.  Normally, a programmer would
simply call application space \textbf{malloc}, but this does not
provide a buffer that can be shared with hardware or other software
processes.  As shown in Figure~\ref{Fig:StringSearch4}, a
special-purpose memory allocator has been implemented in Linux, using
dmabuf\cite{dmabuf} to provide reference counted sharing of memory
buffers across user processes and hardware.

To conclude, we consider how the HW/SW interface changed to
accommodate each step in the refinement process: The hardware
interface required by the design in Figure~\ref{Fig:StringSearch0} is
relatively simple.  Command/response queues in the hardware
accelerator are exposed using a register interface with accompanying
*empty*/*full* signals.  To support the use of *poll* by
the refinement in Figure~\ref{Fig:StringSearch1}, interrupt signals
must be added to the hardware interface and connected to the Linux
kernel.  Partitioning the address space as required by the refinement
in Figure~\ref{Fig:StringSearch3} necessitates a consistent remapping
of registers in both hardware and software.


