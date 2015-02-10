.. _Sec-Performance:

Performance of Generated Systems
================================

A framework is only useful if it reduces the effort required by
developers to achieve the desired performance objective. Trying to gauge the
relative effort is difficult since the authors implemented both the
framework and the running example. On PCIE-based platforms we were
able to reduce the time required to search for a fixed set of strings
in a large corpus by an order of magnitude after integrating hardware
acceleration using Connectal.  Performance improvements on the
Zynq-based platforms was even greater due to the relative processing
power of the ARM CPU and scaled with the number of bus master
interfaced used for DMA.  In the Connectal framework, developing these
applications took very little time.

Performance of Portals
----------------------

The current implementation of HW/SW \textbf{portal} transfers 32 bits
per FPGA clock cycle. Our example designs run at 100MHz to 250MHz,
depending on the complexity of the design and the speed grade of the
FPGA used. Due to their intended use, the important performance metric
of Portals is latency.  These values are given in
Figure~\ref{Fig:PortalLatency}.

    \begin{figure}
      \centering
      \begin{tabular}{|c|c|c|c|c|c|c|c|c|}
	\hline
	     & \rt{KC705} & \rt{VC707} & \rt{ZYBO} & \rt{Zedboard} & \rt{ZC702} & \rt{ZC706} & \rt{Parallel} & \rt{Mini-ITX} \\
	\hline
	HW $\rightarrow$ SW  &  3  &  3  &  X  &  0.80  &  0.80  &  0.65  &  X  &  0.65  \\
	\hline
	SW $\rightarrow$ HW  & 5  &  5  &  X  &  1.50  &  1.50 &  1.10  &  X  &  1.10  \\
	\hline
      \end{tabular}
      \caption{Latency ($\mu$s) of communication through portals on supported
	platforms\label{Fig:PortalLatency}}
    \end{figure}

The Xilinx KC705 and VC707 boards connect to x86 CPUs and system
memory via PCIe gen1. The default FPGA clock for those boards is
125MHz.  The other platforms use AXI to connect the programmable logic
to the quad-core ARM Cortex A9 and system memory. The ZYBO, Zedboard
and ZC702 use a slower speed grade part on which our designs run at
100MHz. The ZC706 and Mini-ITX use a faster part on which many of our
designs run at 200MHz. The lower latency measured on the ZC706
reflects the higher clock speed of the latency performance test.

Performance of Reads/Writes of System Memory
--------------------------------------------

For high bandwidth transfers, we assume the developer will have the
application hardware read or write system memory directly. Direct
access to memory enables transfers with longer bursts, reducing memory
bus protocol overhead. The framework supports transfer widths of 32 to
128 bits per cycle, depending on the interconnect used. 

Our goal in the design of the library components used to read and
write system memory is to ensure that a developer's application can
use all bandwidth available to the FPGA when accessing system memory.
DMA Bandwidth on supported platforms is listed in
Figure\ref{Fig:DmaBandwidth}.

    \begin{figure}
      \centering
      \begin{tabular}{|c|c|c|c|c|c|c|c|c|}
	\hline
	     & \rt{KC705} & \rt{VC707} & \rt{ZYBO} & \rt{Zedboard} & \rt{ZC702} & \rt{ZC706} & \rt{Parallel} & \rt{Mini-ITX} \\
	\hline
	Read  &  1.4  &  1.4  &  X  &  0.8  &  0.8  &  1.6  &  X  &  1.6  \\
	\hline
	Write  &  1.4  &  1.4  &  X  &  0.8  &  0.8  &  1.6  &  X  &  1.6  \\
	\hline
      \end{tabular}
      \caption{Maximum bandwidth (GB/s) between FPGA and host memory using
	Connectal RTL libraries on supported
	platforms\label{Fig:DmaBandwidth}}
    \end{figure}

On PCIe systems, Connectal currently supports 8 lane PCIe gen1. We've
measured 1.4 gigabytes per second for both reads and writes. Maximum
throughput of 8 lane PCIe gen1 is 1.8GB/s, taking into account 1
header transaction per 8 data transactions, where 8 is the maximum
number of data transactions per request supported by our server's
chipset.  The current version of the test needs some more tuning in order to
reach the full bandwidth available. In addition, we are
in the process of updating to 8 lane PCIe gen2 using newer Xilinx
cores.

Zynq systems have four *high performance* ports for accessing system
memory. Connectal enables an accelerator to use all four. In our
experiments, we have been able to achieve 3.6x higher bandwidth using
4 ports than using 1 port.



