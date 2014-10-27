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

#define SHIFT { rcy0, rcy1, rcy8, rcy16 };

#define SKIP { noskip, alult0, alueq0, inrdy};

#define OP { norm, storeDM, storeIM, out, loadDM, in, junk, op_reserved};

#define DMSIZE 1024
uint32_t dm[DMSIZE];

#define IMSIZE 1024
uint32_t im[IMSIZE];


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
  pushinst();
}


void constant(int rw, uint32_t value)
{
  inst = value & 0xffffff;
  SETFIELD(inst, LC, lc);
  pushinst();
}

void t3_add(int rw, int ra, int rb)
{
  ins(rw, 0, ra, rb, plus, noshift, noskip, norm)
}

void t3_add_skip(int rw, int ra, int rb, int skip)
{
  ins(rw, 0, ra, rb, plus, noshift, skip, norm)
}

