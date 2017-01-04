/* Copyright (c) 2013 Quanta Research Cambridge, Inc
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included
 * in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */

/*
 * Implementation of:
 *    MP algorithm on pages 7-11 from "Pattern Matching Algorithms" by
 *       Alberto Apostolico, Zvi Galil, 1997
 *
 *    pattern x of length m
 *    text    t of length n
 *
 *    procedure MP(x, t: string; m, n: integer);
 *    begin
 *        i := 1; j := 1;
 *        while j <= n do begin
 *            while (i = m + 1) or (i > 0 and x[i] != t[j]) do i := MP_next[i];
 *            i := i + 1; j := j + 1;
 *            if i = m + 1 then writeln('x occurs in t at position ', j - i + 1);
 *        end;
 *    end;
 *    
 *    procedure Compute_borders(x: string; m: integer);
 *    begin
 *        Border[0] := -1;
 *        for i := 1 to m do begin
 *            j := Border[i - 1];
 *            while j >= 0 and x[i] != x[j + 1] do j := Border[j];
 *            Border[i] := j + 1;
 *        end;
 *    end;
 *    
 *    procedure Compute_MP_next(x: string; m: integer);
 *    begin
 *        MP_next[i] := 0; j := 0;
 *        for i := 1 to m do begin
 *            { at this point, we have j = MP_next[i] }
 *            while j > 0 and x[i] != x[j] do j := MP_next[j];
 *            j := j + 1;
 *            MP_next[i + 1] := j;
 *        end;
 *    end;
 *
 */

#ifndef _MP_H_
#define _MP_H_

void compute_borders(const char *x, int *border, int m)
{
  border[0] = -1;
  for(int i = 1; i <=m; i++){
    int j = border[i-1];
    while ((j>=0) && (x[i] != x[j+1]))
      j = border[j];
    border[i] = j+1;
  }
}

struct MP {
MP(uint16_t x, uint16_t index) : index(index), x(x) {}
  uint16_t index;
  uint16_t x;
};

void compute_MP_next(const char *x, struct MP *MP_next, int m)
{
  MP_next[1] = MP(0, 0);
  int j = 0;
  for(int i = 1; i <= m; i++){
    while ((j>0) && (x[i] != x[j]))
      j = MP_next[j].index;
    j = j+1;
    MP_next[i+1] = MP(x[j-1], j);
  }
}

void MP(const char *x, const char *t, struct MP *MP_next, int m, int n, int *match_cnt)
{
  int i = 1;
  int j = 1;
  fprintf(stderr, "MP starting\n");
  while (j <= n) {
    while ((i==m+1) || ((i>0) && (x[i-1] != t[j-1]))){
      //fprintf(stderr, "char mismatch %d %d MP_next[i]=%d\n", i,j,MP_next[i]);
      i = MP_next[i].index;
    }
    //fprintf(stderr, "   char match %d %d\n", i, j);
    i = i+1;
    j = j+1;
    if (i==m+1){
      fprintf(stderr, "%s occurs in t at position %d\n", x, j-i);
      i = 1;
      (*match_cnt)++;
    }
  }
  fprintf(stderr, "MP exiting\n");
}

#endif // _MP_H_
