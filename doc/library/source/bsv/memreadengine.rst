MemReadEngine Package
=====================

.. bsv:package:: MemReadEngine

.. bsv:module:: mkMemReadEngine(MemReadEngine#(busWidth, userWidth, cmdQDepth, numServers))

   Creates a MemReadEngine with default 256 bytes of buffer per server.

.. bsv:module:: mkMemReadEngineBuff#(Integer bufferSizeBytes) (MemReadEngine#(busWidth, userWidth, cmdQDepth, numServers))

   Creates a MemReadEngine with the specified buffer size.

