
.. _invocation_pcieflat

pcieflat
========

Usage::

    pcieflat

Dumps trace of PCIE transactions.

The trace contains the following columns:

=========  ======================
col        description
=========  ======================
dirtype    TLP direction and type
timestamp  Timestamp of TLP, in main clock cycles
delta      Number of cycles since previous TLP
type       type:pktype:format
be         Byte enables
hit        BAR hit
eof        End of frame
sof        Start of frame
address    Request physical address
tag        Request tag
=========  ======================

The first column, `dirtype`, contains RX if received by FPGA, TX if
transmitted by FPGA, qq for start of request, pp for start of
response, and cc for continuation.

The second column, `timestamp`, displays the timestamp in terms of a
64-bit counter running at the PCIe user clock frequency (125MHz for
gen1, 250MHz for gen2 and gen3).

The third column, `delta`, displays the number of cycles since the
previous TLP. If a TLP is transmitted and received on the same cycle,
then the transmitted TLP will have a delta of 0. The first TLP shown
in the trace will have a delta of 0.

The fourth column shows the type of the TLP. If it is the start of a
transaction, it will be of the form `type:tlppkttype:tlpformat`, where
the types are:

  * CpuRReq: read request from CPU to FPGA
  * CpuWReq: write request from CPU to FPGA
  * CpuRRsp: read response from FPGA to CPU
  * DmaRReq: read request from FPGA to CPU DRAM
  * DmaWReq: write request from FPGA to CPU DRAM
  * DmaRRsp: read response from CPU DRAM to FPGA
  * CpuRCon: continuation data sent from FPGA to CPU (continuation of CpuRRsp or DmaWReq)
  * DmaRCon: continuation data sent from CPU DRAM to FPGA (continuation of DmaRRsp or CpuWReq)
  * Interru: interrupt message from FPGA to CPU

The TLP `pkttype` is one of the following:

  * MRW:  Memory read/write
  * COMP: additional data ("completion") of transaction

The TLP `format` is one of the following:

  * MEM_WRITE_3DW_DATA: 96-bit write request header containing 32-bit address and 32-bit data
  * MEM_WRITE_4DW_DATA: 128-bit write request header containing 64-bit address and no data
  * MEM_READ__3DW: 96-bit read request header containing 32-bit address
  * MEM_READ__4DW: 128-bit read request header containing 64-bit address

The `sof` and `eof` flags indicate the start and end TLPs of each
transaction.

Diagnosing Crashes
------------------

If the machine crashed, look for transactions that were
started but not ended.

These will generally fall before very large deltas, where the machine
was rebooted before it had any more interactions with the FPGA.

Example Trace
--------------

Here are some excerpts from the output of `pcieflat` after running `tests/memserver_copy`::

    pcieflat: devices are ['/dev/portal_0_6', '/dev/portal_0_5', '/dev/portal_0_4', '/dev/portal_0_3', '/dev/portal_0_2', '/dev/portal_0_1']
		 ts     delta   response                     XXX          tlp          address  off   be       tag     clid  nosnp  laddr        data
				    pkttype format               foo (be hit eof sof)            (1st last)        req     stat  bcnt    length
    RXpp  513858932          0 DmaRRsp:COMP:MEM_WRITE_3DW_DATA 09 0x4 tlp(ffff 0 0 1)                        tag:07 0300 0000 0 00 080 00  16 01179d1d 
    TXcc  513858932          0 CpuRCon                         10 0x8 tlp(ffff 0 0 0)                            data:259b17012c9b1701339b17013a9b1701 
    RXcc  513858933          1 DmaRCon                         08 0x4 tlp(ffff 0 0 0)                            data:249d17012b9d1701329d1701399d1701 
    TXcc  513858933          0 CpuRCon                         10 0x8 tlp(ffff 0 1 0)                            data:419b1701489b17014f9b1701569b1701 
    RXcc  513858934          1 DmaRCon                         08 0x4 tlp(ffff 0 0 0)                            data:409d1701479d17014e9d1701559d1701 
    RXcc  513858935          1 DmaRCon                         08 0x4 tlp(ffff 0 0 0)                            data:5c9d1701639d17016a9d1701719d1701 
    RXcc  513858936          1 DmaRCon                         08 0x4 tlp(ffff 0 1 0)                            data:789d17017f9d1701869d170164b19a21 
    RXpp  513858938          2 DmaRRsp:COMP:MEM_WRITE_3DW_DATA 09 0x4 tlp(ffff 0 0 1)                        tag:07 0300 0000 0 00 040 40  16 01179d8d 
    RXcc  513858939          1 DmaRCon                         08 0x4 tlp(ffff 0 0 0)                            data:949d17019b9d1701a29d1701a99d1701 
    RXcc  513858940          1 DmaRCon                         08 0x4 tlp(ffff 0 0 0)                            data:b09d1701b79d1701be9d1701c59d1701 
    RXcc  513858941          1 DmaRCon                         08 0x4 tlp(ffff 0 0 0)                            data:cc9d1701d39d1701da9d1701e19d1701 
    RXcc  513858942          1 DmaRCon                         08 0x4 tlp(ffff 0 1 0)                            data:e89d1701ef9d1701f69d1701af3ad2c2 
    TXqq  513858949          7 DmaWReq: MRW:MEM_WRITE_4DW_DATA 11 0x8 tlp(ffff 0 0 1) address: 000000035f4fc680 be(1st: f last:f) tag:05 reqid:0300 length:32 
    TXcc  513858950          1 CpuRCon                         10 0x8 tlp(ffff 0 0 0)                            data:5d9b1701649b17016b9b1701729b1701 
    TXcc  513858951          1 CpuRCon                         10 0x8 tlp(ffff 0 0 0)                            data:799b1701809b1701879b17018e9b1701 
    TXcc  513858952          1 CpuRCon                         10 0x8 tlp(ffff 0 0 0)                            data:959b17019c9b1701a39b1701aa9b1701 
    TXcc  513858953          1 CpuRCon                         10 0x8 tlp(ffff 0 0 0)                            data:b19b1701b89b1701bf9b1701c69b1701 
    TXcc  513858954          1 CpuRCon                         10 0x8 tlp(ffff 0 0 0)                            data:cd9b1701d49b1701db9b1701e29b1701 
    TXcc  513858955          1 CpuRCon                         10 0x8 tlp(ffff 0 0 0)                            data:e99b1701f09b1701f79b1701fe9b1701 
    TXcc  513858956          1 CpuRCon                         10 0x8 tlp(ffff 0 0 0)                            data:059c17010c9c1701139c17011a9c1701 
    TXcc  513858957          1 CpuRCon                         10 0x8 tlp(ffff 0 1 0)                            data:219c1701289c17012f9c1701369c1701 


It may contain DMA Read Requests::

    TXqq  513859009          1 DmaRReq: MRW:MEM_READ__4DW      11 0x8 tlp(ffff 0 1 1) address: 000000039e8fc800 be(1st: f last:f) tag:00 reqid:0300 length:32 
    TXqq  513859010          1 DmaRReq: MRW:MEM_READ__4DW      11 0x8 tlp(ffff 0 1 1) address: 000000039e8fc880 be(1st: f last:f) tag:01 reqid:0300 length:32 

The trace may contain interrupts::

    TXqq  513865009         12 Interru: MRW:MEM_WRITE_3DW_DATA 11 0x8 tlp(ffff 0 1 1)  fee00000    0 be(f 0) tag:00 0300                    1 0000406e 

It will also contain reads and writes from the CPU to the FPGA::

    RXqq  513874994       9985 CpuRReq: MRW:MEM_READ__3DW      09 0x4 tlp(ffff 4 1 1)  df400000    0 be(f 0) tag:00 0038                    1 
    TXpp  513875008         14 CpuRRsp:COMP:MEM_WRITE_3DW_DATA 11 0x8 tlp(ffff 4 1 1)                        tag:00 0038 0300 0 00 004 00   1 00000001 
    RXqq  513875159        151 CpuRReq: MRW:MEM_READ__3DW      09 0x4 tlp(ffff 4 1 1)  df402000  800 be(f 0) tag:00 0038                    1 
    TXpp  513875173         14 CpuRRsp:COMP:MEM_WRITE_3DW_DATA 11 0x8 tlp(ffff 4 1 1)                        tag:00 0038 0300 0 00 004 00   1 00000000 
    RXqq  513875323        150 CpuRReq: MRW:MEM_READ__3DW      09 0x4 tlp(ffff 4 1 1)  df401000  400 be(f 0) tag:00 0038                    1 
    TXpp  513875337         14 CpuRRsp:COMP:MEM_WRITE_3DW_DATA 11 0x8 tlp(ffff 4 1 1)                        tag:00 0038 0300 0 00 004 00   1 00000000 
    RXqq  513876236        899 CpuRReq: MRW:MEM_READ__3DW      09 0x4 tlp(ffff 4 1 1)  df40000c    3 be(f 0) tag:00 0038                    1 
    TXpp  513876250         14 CpuRRsp:COMP:MEM_WRITE_3DW_DATA 11 0x8 tlp(ffff 4 1 1)                        tag:00 0038 0300 0 00 004 0c   1 00000001 
    RXqq  513876449        199 CpuRReq: MRW:MEM_READ__3DW      09 0x4 tlp(ffff 4 1 1)  df400020    8 be(f 0) tag:00 0038                    1 
    TXpp  513876463         14 CpuRRsp:COMP:MEM_WRITE_3DW_DATA 11 0x8 tlp(ffff 4 1 1)                        tag:00 0038 0300 0 00 004 20   1 00000000 
    RXqq  513883818       7355 CpuRReq: MRW:MEM_READ__3DW      09 0x4 tlp(ffff 4 1 1)  df40000c    3 be(f 0) tag:00 0038                    1 
    TXpp  513883832         14 CpuRRsp:COMP:MEM_WRITE_3DW_DATA 11 0x8 tlp(ffff 4 1 1)                        tag:00 0038 0300 0 00 004 0c   1 00000000 
    RXqq  513883976        144 CpuWReq: MRW:MEM_WRITE_3DW_DATA 09 0x4 tlp(ffff 4 1 1)  df400004    1 be(f 0) tag:02 0000                    1 00000001 
    RXqq  513884007         31 CpuRReq: MRW:MEM_READ__3DW      09 0x4 tlp(ffff 4 1 1)  df40200c  803 be(f 0) tag:00 0038                    1 
    TXpp  513884021         14 CpuRRsp:COMP:MEM_WRITE_3DW_DATA 11 0x8 tlp(ffff 4 1 1)                        tag:00 0038 0300 0 00 004 0c   1 00000000 
    RXqq  513884165        144 CpuWReq: MRW:MEM_WRITE_3DW_DATA 09 0x4 tlp(ffff 4 1 1)  df402004  801 be(f 0) tag:03 0000                    1 00000001 

The trace will end with a summary of the kinds of PCIe transactions::

    {'DmaWReq': 115, 'CpuRReq': 45, 'Interru': 3, 'CpuRRsp': 45, 'CpuRCon': 922, 'CpuWReq': 15, 'DmaRReq': 112, 'DmaRRsp': 141, 'DmaRCon': 904}
    2302

