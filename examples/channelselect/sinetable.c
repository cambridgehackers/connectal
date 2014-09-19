/* create hex file to load BRAM with sine and cosine tables
 * for the direct digital synthesizer
 */
/*
 Copyright (c) 2014 Quanta Research Cambridge, Inc.

 Permission is hereby granted, free of charge, to any person
 obtaining a copy of this software and associated documentation
 files (the "Software"), to deal in the Software without
 restriction, including without limitation the rights to use, copy,
 modify, merge, publish, distribute, sublicense, and/or sell copies
 of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be
 included in all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
 BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
 ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
*/


#include <stdio.h>
#include <math.h>


int main(int argc, char *argv[])
{
  double s, c;
  double phase;
  int i, j;
  unsigned long c_frac, s_frac;
  for (i = 0; i < 1024; i += 1) {
    c = cos(((double) i / 1024.0) * 2.0 * M_PI);
    s = sin(((double) i / 1024.0) * 2.0 * M_PI);
    c_frac = c * (double) (1L << 23);
    s_frac = s * (double) (1L << 23);
    for (j = 24; j >= 0; j -= 1)
      printf("%1lx", (c_frac >> j) & 0x1);
    for (j = 24; j >= 0; j -= 1)
      printf("%1lx", (s_frac >> j) & 0x1);
    printf("\n");
  }
  return(0);
}
