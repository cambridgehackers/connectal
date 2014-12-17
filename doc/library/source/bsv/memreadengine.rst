MemreadEngine Package
=====================

.. bsv:package:: MemreadEngine

.. bsv:module:: mkMemreadEngine(MemreadEngineV#(dataWidth, cmdQDepth, numServers))

   Creates a MemreadEngine with default 256 bytes of buffer per server.

.. bsv:module:: mkMemreadEngineBuff#(Integer bufferSizeBytes) (MemreadEngineV#(dataWidth, cmdQDepth, numServers))

   Creates a MemreadEngine with the specified buffer size.

