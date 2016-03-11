Larry Stewart <stewart@serissa.com>
Fib is an example of a stylized way to construct recursive algorithms
in hardware.

The main algorithm is constructed as a state machine.  In the
case of fibonacci, the pseudo code is

    
    fib(n):
       int tmp1, tmp2;
       if n == 0 return 0
       if n == 1 return 1
       tmp1 = fib(n-1)
       tmp2 = fib(n-2)   
       return tmp1 + tmp2

Except for the recursion, this could be implemented in the StmtFSM
language, but StmtFSM leaves the state machinery hidden, so there is no way
to save and restore the "program counter" as would be needed to
resume execution in the middle of an FSM after a return.

Likewise, FSM server doesn't help, because you cannot call yourself.

Instead, Fib is implemented using an FSM constructed out of individual rules
which fire according to a state variable.  Fib takes three rules:


   rule fib1 (fibstate == FIBSTATE1);
     if (fibn == 0)
	fibreturn(0);
     else if (fibn == 1)
	fibreturn(1);
     else
	callfib(fibn - 1, FIBSTATE2);
     endrule

   rule fib2 (fibstate == FIBSTATE2);
      fibtmp1 <= fibretval;
      callfib(fibn - 2, FIBSTATE3);
   endrule
   
   rule fib3 (fibstate == FIBSTATE3);
      fibreturn(fibtmp1 + fibretval);
   endrule

In accordance with bluespec, each rule takes exactly one cycle to run,
once its guards are satisfied.

The newest version of thisfib is in the module FibWide.bsv, which uses
the library module lib/bsv/StackReg.bsv

The idea of StackReg is that it stores the entire "local frame" on a stack.
The local frame includes the program counter, the function arguments,
and any local variables.  These are all stored in parallel, so it takes
three BRAMs of the appropriate widths.  Additional registers are used
for the "top of stack" and a bypass register that permits single cycle
returns.

To use the StackReg library, you instantiate a StackReg, with
parameters for stack depth, types for the PC, arguments, and locals,
and a parameter for the initial value of the PC.

Thereafter, you can use the docall and doreturn methods to implement
recursive algorithms.

      
The original version of thisFib is in the module Fib.bsv, which uses
the library module lib/bsv/Stack.bsv

Stack uses a single 16 bit wide BRAM to store all the stack data in the
local frame.  This is a multicycle operation, and requires the caller to
implement the FSMs to do the save and restore.  It uses less hardware, more
time, and is messy to code.

The original caller of this FSM uses "callfib" to start the run.
The first argument to callfib is the argument to this invocation of
fib, and the second argument is the "state" to return to. In effect
this is the program counter value to push on the stack.  The state
machine returns from a call by using "fibreturn" with a return value.
   
   method Action fib(Bit#(32) v);
      fibn <= truncate(v);
      callfib(truncate(v), FIBSTATECOMPLETE);
   endmethod

   rule fibcomplete (fibstate == FIBSTATECOMPLETE);
      indication.fibresult(zeroExtend(fibretval));
      fibstate <= FIBSTATEIDLE;
   endrule

Call and return are a bit more complicated

   function Action callfib(Bit#(16) arg,  FSState returnto);
   return action
	     fibstate <= FIBCALLING;
	     fibcallarg <= arg;
	     fibcallreturnto <= returnto;
	     callFibFSM.start();
	  endaction;
   endfunction
   
Because it is a multicycle process to push the current state onto the
stack and start the recursive call, the callfib function saves its
arguments in registers, changes the FSM state to FIBCALLING and launches
the callFibFSM.


   Stmt callfibstmt =
   seq
      stack.store(fsoffsetn, fibn);
      stack.store(fsoffsettmp1, fibtmp1);
      stack.store(fsoffsetnext, zeroExtend(pack(fibcallreturnto)));
      par
	 stack.push();
	 fibn <= fibcallarg;
	 fibstate <= FIBSTATE1;
      endpar
   endseq;

This state machine pushes local variables onto the stack, increments the
stack pointer, and changes the working register for the new call.  It 
then sets the state to FIBSTATE1, the state for the first chunk of code
in fib.

When an invocation is finished, it calls "fibreturn" with a return value.
   
   function Action fibreturn(Bit#(16) returnval);
      return action
		fibstate <= FIBRETURNING;
		fibretval <= returnval;      
		fibreturnFSM.start();
	     endaction;
   endfunction

Similar to callfib, the process of popping the previous state off the
stack is multicycle, so it is relegated to a StmtFSM.  While that FSM
runs, the main machine state is set to FIBRETURNING

   Stmt fibreturnstmt =
   seq
      stack.pop();
      stack.loadstart(fsoffsetn);
      action
	 let t <- stack.loadfinish();
	 stack.loadstart(fsoffsettmp1);
	 fibn <= t;
      endaction
      action
	 let t <- stack.loadfinish();
	 stack.loadstart(fsoffsetnext);
	 fibtmp1 <= t;
      endaction
      action
	 let t <- stack.loadfinish();
	 fibstate <= unpack(truncate(t));
      endaction
   endseq;

This FSM decrements the frame pointer, then restores the local variables
to their previous values.  The final step is restoring the "pc" which
causes the original state machine to resume execution in its previous
context.

