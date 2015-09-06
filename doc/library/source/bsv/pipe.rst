Pipe Package
============

.. bsv:package:: Pipe

The Pipe package is modeled on Bluespec, Inc's PAClib package. It
provides functions and modules for composing pipelines of operations.

Pipe Interfaces
---------------

.. bsv:interface:: PipeIn#(type a)

   Corresponds to the input interface of a FIFOF.

   .. bsv:method:: Action enq(a v)

   .. bsv:method:: Bool notFull()

.. bsv:interface:: PipeOut#(type a)

   Corresponds to the output interface of a FIFOF.

   .. bsv:method:: a first()

   .. bsv:method:: Action deq()

   .. bsv:method:: Bool notEmpty()

.. bsv:typeclass:: ToPipeIn#(type a, type b)

   .. bsv:function:: PipeIn#(a) toPipeIn(b in)

      Returns a PipeIn to the object "in" with no additional buffering.

.. bsv:typeclass:: ToPipeOut#(type a, type b)

   .. bsv:function:: PipeOut#(a) toPipeOut(b in)

      Returns a PipeOut from the object "in" with no additional buffering.

.. bsv:typeclass:: MkPipeIn#(type a, type b)

   .. bsv:module:: mkPipeIn#(b in)(PipeIn#(a))

      Instantiates a module whose interface is a PipeIn to the input
      parameter "in". Includes a FIFO buffering stage.

.. bsv:typeclass:: MkPipeOut#(type a, type b)

   .. bsv:module:: mkPipeOut#(b in)(PipeOut#(a))

      Instantiates a module whose interface is PipeOut from the input
      parameter "in". Includes a FIFO buffering stage.

.. bsv:instance:: ToPipeIn#(a, FIFOF#(a))

   Converts a FIFOF to a PipeIn.

.. bsv:instance:: ToPipeOut#(a, function a pipefn())

   Converts a function to a PipeOut.

.. bsv:instance:: ToPipeOut#(a, Reg#(a))

   Converts a register to a PipeOut.

.. bsv:instance:: ToPipeIn#(Vector#(m, a), Gearbox#(m, n, a))

   Converts a Gearbox to a PipeOut.

.. bsv:instance:: ToPipeOut#(a, FIFOF#(a))

   Converts a FIFOF to a PipeOut.

.. bsv:instance:: ToPipeOut#(Vector#(n,a), MIMO#(k,n,sz,a))

   Converts a MIMO to a PipeOut.

.. bsv:instance:: ToPipeOut#(Vector#(n, a), Gearbox#(m, n, a))

   Converts a Gearbox to a PipeOut.

.. bsv:instance:: MkPipeOut#(a, Get#(a))

   Instantiates a pipelined PipeOut from a Get interface.

.. bsv:instance:: MkPipeIn#(a, Put#(a))

   Instantiates a pipelined PipeIn to a Put interface.

Get and Put Pipes
-----------------

.. bsv:instance:: ToGet #(PipeOut #(a), a)

.. bsv:instance:: ToPut #(PipeIn #(a), a)

Connectable Pipes
-----------------

.. bsv:instance:: Connectable#(PipeOut#(a),Put#(a))

.. bsv:instance:: Connectable#(PipeOut#(a),PipeIn#(a))


Mapping over Pipes
------------------

.. bsv:function:: PipeOut#(a) toCountedPipeOut(Reg#(Bit#(n)) r, PipeOut#(a) pipe)

.. bsv:function:: PipeOut#(Tuple2#(a,b)) zipPipeOut(PipeOut#(a) ina, PipeOut#(b) inb)

   Returns a PipeOut whose elements are 2-tuples of the elements of the input pipes.


.. bsv:function:: PipeOut#(b) mapPipe(function b f(a av), PipeOut#(a) apipe)

   Returns a PipeOut that maps the function f to each element of the
   input pipes with no buffering.

.. bsv:module:: mkMapPipe#(function b f(a av), PipeOut#(a) apipe)(PipeOut#(b))

   Instantiates a PipeOut that maps the function f to each element of
   the input pipes using a FIFOF for buffering.

.. bsv:function:: PipeIn#(a) mapPipeIn(function b f(a av), PipeIn#(b) apipe)

   Returns a PipeIn applies the function f to each value that is enqueued.


Reducing Pipes
--------------

.. bsv::typeclass ReducePipe#( numeric type n, type a)

   Instantiates a tree of logic to reduce the values of the input pipes using the combinepipe function.

   .. bsv:module::  mkReducePipe (CombinePipe#(Tuple2#(a,a), a) combinepipe, PipeOut#(Vector#(n,a)) inpipe, PipeOut#(a) ifc)

   .. bsv:module::  mkReducePipes (CombinePipe#(Tuple2#(a,a), a) combinepipe, Vector#(n,PipeOut#(a)) inpipe, PipeOut#(a) ifc)



Functions on Pipes of Vectors
-----------------------------

.. bsv:function:: PipeOut#(a) unvectorPipeOut(PipeOut#(Vector#(1,a)) in)

Funneling and Unfunneling
-------------------------

.. bsv:module:: mkFunnel#(PipeOut#(Vector#(mk,a)) in)(PipeOut#(Vector#(m, a)))

   Returns k Vectors of m elements for each Vector#(mk,a) element of the input pipe.

.. bsv:module:: mkFunnel1#(PipeOut#(Vector#(k,a)) in)(PipeOut#(a))

   Sames as mkFunnel, but returns k singleton elements for each vector
   element of the input pipe.

.. bsv:module:: mkFunnelGB1#(Clock slowClock, Reset slowReset, Clock fastClock, Reset fastReset, PipeOut#(Vector#(k,a)) in)(PipeOut#(a))

   Same as mkFunnel1, but uses a Gearbox with a 1 to k ratio.

.. bsv:module:: mkUnfunnel#(PipeOut#(Vector#(m,a)) in)(PipeOut#(Vector#(mk, a)))

   The dual of mkFunnel. Consumes k elements from the input pipe, each of which is an
   m-element vector, and returns an mk-element vector.

.. bsv:module:: mkUnfunnelGB#(Clock slowClock, Reset slowReset, Clock fastClock, Reset fastReset, PipeOut#(Vector#(1,a)) in)(PipeOut#(Vector#(k, a)))

   The same as mkUnfunnel, but uses a Gearbox with a 1-to-k.

.. bsv:module:: mkRepeat#(UInt#(n) repetitions, PipeOut#(a) inpipe)(PipeOut#(a))

   Returns a PipeOut which repeats each element of the input pipe the specified number of times.



Fork and Join
-------------

Fork and Join with limited scalability

.. bsv:module:: mkForkVector#(PipeOut#(a) inpipe)(Vector#(n, PipeOut#(a)))

   Replicates each element of the input pipe to each of the output
   pipes. It uses a FIFOF per output pipe.

.. bsv:module:: mkSizedForkVector#(Integer size, PipeOut#(a) inpipe)(Vector#(n, PipeOut#(a)))

   Used a SizedFIFOF for each of the output pipes.


.. bsv:module:: mkJoin#(function c f(a av, b bv), PipeOut#(a) apipe, PipeOut#(b) bpipe)(PipeOut#(c))

   Returns a PipeOut that applies the function f to the elements of
   the input pipes, with no buffering.

.. bsv:module:: mkJoinBuffered#(function c f(a av, b bv), PipeOut#(a) apipe, PipeOut#(b) bpipe)(PipeOut#(c))

   Returns a PipeOut that applies the function f to the elements of
   the input pipes, using a FIFOF to buffer the output.
   
.. bsv:module:: mkJoinVector#(function b f(Vector#(n, a) av), Vector#(n, PipeOut#(a)) apipes)(PipeOut#(b))

   Same as mkJoin, but operates on a vector of PipeOut as input.



Funnel Pipes
---------------

Fork and Join with tree-based fanout and fanin for scalability.

These are used by MemReadEngine and MemWriteEngine.

.. bsv:typedef:: Vector#(j,PipeOut#(a))   FunnelPipe#(numeric type j, numeric type k, type a, numeric type bitsPerCycle)

.. bsv:typedef:: Vector#(k,PipeOut#(a)) UnFunnelPipe#(numeric type j, numeric type k, type a, numeric type bitsPerCycle)

.. bsv:typeclass:: FunnelPipesPipelined#(numeric type j, numeric type k, type a, numeric type bpc)

   .. bsv:module:: mkFunnelPipesPipelined#(Vector#(k,PipeOut#(a)) in) (FunnelPipe#(j,k,a,bpc))

   .. bsv:module:: mkFunnelPipesPipelinedRR#(Vector#(k,PipeOut#(a)) in, Integer c) (FunnelPipe#(j,k,a,bpc))

   .. bsv:module:: mkUnFunnelPipesPipelined#(Vector#(j,PipeOut#(Tuple2#(Bit#(TLog#(k)),a))) in) (UnFunnelPipe#(j,k,a,bpc))

   .. bsv:module:: mkUnFunnelPipesPipelinedRR#(Vector#(j,PipeOut#(a)) in, Integer c) (UnFunnelPipe#(j,k,a,bpc))



.. bsv:instance:: FunnelPipesPipelined#(1,1,a,bpc)

.. bsv:instance:: FunnelPipesPipelined#(1,k,a,bpc)

.. bsv:module:: mkUnFunnelPipesPipelinedInternal#(Vector#(1, PipeOut#(Tuple2#(Bit#(TLog#(k)),a))) in)(UnFunnelPipe#(1,k,a,bpc))

.. bsv:module:: mkFunnelPipes#(Vector#(mk, PipeOut#(a)) ins)(Vector#(m, PipeOut#(a)))

.. bsv:module:: mkFunnelPipes1#(Vector#(k, PipeOut#(a)) ins)(PipeOut#(a))

.. bsv:module:: mkUnfunnelPipes#(Vector#(m, PipeOut#(a)) ins)(Vector#(mk, PipeOut#(a)))

.. bsv:module:: mkPipelinedForkVector#(PipeOut#(a) inpipe, Integer id)(UnFunnelPipe#(1,k,a,bpc))

Delimited Pipes
---------------

.. bsv:interface:: FirstLastPipe#(type a)

   A pipe whose elements two-tuples of boolean values indicating first
   and last in a series. The ttype a indicates the type of the counter
   used.

   .. bsv:subinterface:: PipeOut#(Tuple2#(Bool,Bool)) pipe

      The pipe of delimited elements

   .. bsv:method:: Action start(a count)

      Starts the series of count elements

.. bsv:module:: mkFirstLastPipe#()(FirstLastPipe#(a))

   Creates a FirstLastPipe.

.. bsv:struct:: RangeConfig#(type a)

   The base, limit and step for mkRangePipeOut.

   .. bsv:field:: a xbase

   .. bsv:field:: a xlimit

   .. bsv:field:: a xstep

.. bsv:interface:: RangePipeIfc#(type a)

   .. bsv:subinterface:: PipeOut#(a) pipe

   .. bsv:method:: Bool isFirst()

   .. bsv:method:: Bool isLast()

   .. bsv:method:: Action start(RangeConfig#(a) cfg)

.. bsv:module:: mkRangePipeOut#()(RangePipeIfc#(a))

   Creates a Pipe of values from xbase to xlimit by xstep. Used by MemRead.

