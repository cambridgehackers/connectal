/* Assembler Library for Thacker's Tiny Computer 3
 * L. Stewart   <stewart@serissa.com>
 */

#include <stdio.h>
#include <stdint.h>
#include <stdargs.h>

/* Field access macros */
#define GETFIELD(field, value) \
  ((value >> field ## _START) & ((1 << field ## _WIDTH) - 1))

#define SETFIELD(word, field, value)			     \
  word = (word & (~((1 << field ## _WIDTH) - 1) << field ## _START)) \
    | ((value & ((1 << field ## _WIDTH) - 1)) << field ## _START)

#define RW_START 25
#define RW_WIDTH 7
#define LC_START 24
#define RA_START 17
#define RA_WIDTH 7
#define RB_START 10
#define RB_WIDTH 7
#define FUNC_START 7
#define FUNC_WIDTH 3
#define SHIFT_START 5
#define SHIFT_WIDTH 2
#define SKIP_START 3
#define SKIP_WIDTH 2
#define OP_START 0
#define OP_WIDTH 3

#define FUNC { plus, minus, plus1, minus1, and, or, xor, func_reserved };

#define SHIFT { cy0, cy1, cy8, cy16 };

#define SKIP { noskip, sneg, sz, inrdy};

#define OP { norm, op_storeDM, op_storeIM, op_out, op_loadDM, op_in, op_jump, op_reserved};

/* Data memory image */
#define DMSIZE 1024
uint32_t dm[DMSIZE];

/* Instruction memory image */
#define IMSIZE 1024
uint32_t im[IMSIZE];



/* Allocation pointers for data, instruction, registers */
int next_dm = 0;
int next_in = 0;
int next_reg = 0;

int label(void)
{
  return(next_im);
}

int allocreg()
{
  if (next_reg >= NUMREGS) return(-1);
  return(next_reg++);
}

int alloc(int words)
{
  int loc = next_dm;
  if ((loc + words) > DMSIZE) return(-1);
  next_dm = loc + words;
  return(loc);
}

/* There's a function for each main type of instruction */
uint32_t inst = 0;

void pushinst()
{
  im[next_im++] = inst;
  inst = 0;
}

void ins(int rw, int lc, int ra, int rb, int function, int shift, int skip, int op)
{
  SETFIELD(inst, RW, rw);
  SETFIELD(inst, LC, lc);
  SETFIELD(inst, RA, ra);
  SETFIELD(inst, RB, rb);
  SETFIELD(inst, FUNC, function);
  SETFIELD(inst, SHIFT, shift);
  SETFIELD(inst, SKIP, skip);
  SETFIELD(inst, OP, op);
}

void constant(int rw, uint32_t value)
{
  inst = value & 0xffffff;
  SETFIELD(inst, LC, lc);
  pushinst();
}




uint32_t add(int rw, int ra, int rb)
{
  ins(rw, 0, ra, rb, plus, noshift, noskip, norm);
  return(inst);
}

uint32_t sub(int rw, int ra, int rb)
{
  ins(rw, 0, ra, rb, minus, noshift, noskip, norm);
  return(inst);
}

uint32_t and(int rw, int ra, int rb)
{
  ins(rw, 0, ra, rb, and, noshift, noskip, norm);
  return(inst);
}

uint32_t or(int rw, int ra, int rb)
{
  ins(rw, 0, ra, rb, or, noshift, noskip, norm);
  return(inst);
}

uint32_t xor(int rw, int ra, int rb)
{
  ins(rw, 0, ra, rb, xor, noshift, noskip, norm);
  return(inst);
}

uint32_t inc(int rw, int ra, int rb)
{
  ins(rw, 0, ra, rb, plus1, noshift, noskip, norm);
  return(inst);
}

uint32_t dec(int rw, int ra, int rb)
{
  ins(rw, 0, ra, rb, minus1, noshift, noskip, norm);
  return(inst);
}


uint32_t skip_neg(uint32_t i)
{
  SETFIELD(i, SKIP, sneg);
  return(i);
}

uint32_t skip_zero(uint32_t i)
{
  SETFIELD(i, SKIP, sz);
  return(i);
}

uint32_t skip_inputready(uint32_t i)
{
  SETFIELD(i, SKIP, inrdy);
  return(i);
}

uint32_t cy1(uint32_t i)
{
  SETFIELD(i, SHIFT, cy1);
  return(i);
}

uint32_t cy8(uint32_t i)
{
  SETFIELD(i, SHIFT, cy8);
  return(i);
}

uint32_t cy16(uint32_t i)
{
  SETFIELD(i, SHIFT, cy16);
  return(i);
}

void storedm(uint32_t i)
{
  SETFIELD(i, OP, op_storeDM);
  inst = i;
  pushinst();
}

void storeim(uint32_t i)
{
  SETFIELD(i, OP, op_storeIM);
  inst = i;
  pushinst();
}

void out(uint32_t i)
{
  SETFIELD(i, OP, op_out);
  inst = i;
  pushinst();
}

void loaddm(uint32_t i)
{
  SETFIELD(i, OP, op_loadDM);
  inst = i;
  pushinst();
}

void in(uint32_t i)
{
  SETFIELD(i, OP, op_in);
  inst = i;
  pushinst();
}

void jump(uint32_t i)
{
  SETFIELD(i, OP, op_jump);
  inst = i;
  pushinst();
}




/* user programs */


void genmonitor()
{
  int cmd = allocreg();
  int junk = allocreg();
  int zero = allocreg();
  int sp = allocreg();
  int temp = allocreg();
  int locstack = alloc(100);

  /* labels and potential labels */
  int d1, d2, d3, d4, d5, d6, d7;
  
  int monitor;
  {
    /* initialize */
    constant(zero, 0);
    constant(sp, locstack);
    /* wait for input */
    monitor = label();
    constant(temp, monitor);
    skip_inputready(add(junk, junk, junk));
    jump(or(junk, zero, temp));
    /* read input and dispatch */
    in(or(cmd, junk, junk));
    constant(junk, 7);
    and(temp, cmd, junk);
    /* dispatcher */
    constant(junk, 0);
    skip_zero(xor(temp, junk));
    

} 
int print10 = label();
