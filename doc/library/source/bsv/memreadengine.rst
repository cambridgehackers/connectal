MemReadEngine Package
=====================

.. bsv:package:: MemReadEngine

.. bsv:module:: mkMemReadEngine(MemReadEngineV#(dataWidth, cmdQDepth, numServers))

   Creates a MemReadEngine with default 256 bytes of buffer per server.

.. bsv:module:: mkMemReadEngineBuff#(Integer bufferSizeBytes) (MemReadEngineV#(dataWidth, cmdQDepth, numServers))

   Creates a MemReadEngine with the specified buffer size.

