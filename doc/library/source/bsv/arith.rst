Arith Package
=============

.. bsv:package:: Arith

The Arith package implements some functions that correspond to infix operators.

.. bsv:function:: Bool booland(Bool x1, Bool x2)

   Returns logical "and" of inputs. Named to avoid conflict with the Verilog keyword "and".

.. bsv:function:: Bool boolor(Bool x1, Bool x2)

   Returns logical "or" of inputs. Named to avoid conflict with the Verilog keyword "or".

.. bsv:function:: Bool eq(a x1, a x2);

.. bsv:function:: a add(a x1, a x2)

   Returns sum of inputs. Requires Arith#(a).

.. bsv:function:: a mul(a x1, a x2)

   Returns product of inputs. Requires Arith#(a).

.. bsv:function:: Bit#(b) rshift(Bit#(b) x1, Integer i)

   Returns input right shifted by i bits.

.. bsv:function:: Vector#(n, a) vadd(Vector#(n, a) x1, Vector#(n, a) x2)

   Returns sum of input vectors.

.. bsv:function:: Vector#(n, a) vmul(Vector#(n, a) x1, Vector#(n, a) x2)

   Returns element-wise product of input vectors.

.. bsv:function:: Vector#(n, Bit#(b)) vrshift(Vector#(n, Bit#(b)) x1, Integer i)

   Right shifts the elements of the input vector by i bits.
