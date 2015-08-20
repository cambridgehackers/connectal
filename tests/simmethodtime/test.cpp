/* Copyright (c) 2014 Quanta Research Cambridge, Inc
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
#include "SimmRequest.h"

#include "papi.h"

#define NUM_EVENTS 4
static void perfinit(void)
{
  static int once = 1;
  int event[NUM_EVENTS] = {PAPI_TOT_INS, PAPI_TOT_CYC, PAPI_BR_MSP, PAPI_L1_DCM };
  if (once) {
    once = 0;
    /* Start counting events */
    if (PAPI_start_counters(event, NUM_EVENTS) != PAPI_OK) {
        fprintf(stderr, "PAPI_start_counters - FAILED\n");
        exit(1);
    }
  }
}
static void perfprint(long long *perfvalues, const char *name)
{
    printf("%s: Total instructions: %6lld;", name, perfvalues[0]);
    printf("Total cycles: %6lld;", perfvalues[1]);
    //printf("Instr per cycle: %2.3f;", (double)perfvalues[0] / (double) perfvalues[1]);
    //printf("Branches mispredicted: %6lld;", perfvalues[2]);
    //printf("L1 Cache misses: %6lld;", perfvalues[3]);
    printf("\n");
}

int main(int argc, const char **argv)
{
    long long perfvalues1[NUM_EVENTS], perfvalues2[NUM_EVENTS];
    bsvvector_Luint32_t_L100 testvec = {0};
    SimmRequestProxy *req = new SimmRequestProxy(IfcNames_SimmRequestS2H);
    perfinit();
    for (int i = 0; i < 10; i++) {
        if (PAPI_read_counters(perfvalues1, NUM_EVENTS) != PAPI_OK) {
            fprintf(stderr, "PAPI_read_counters - FAILED\n");
            exit(1);
        }
        req->shortreq(1);
        if (PAPI_read_counters(perfvalues1, NUM_EVENTS) != PAPI_OK) {
            fprintf(stderr, "PAPI_read_counters - FAILED\n");
            exit(1);
        }
        req->longreq(testvec);
        if (PAPI_read_counters(perfvalues2, NUM_EVENTS) != PAPI_OK) {
            fprintf(stderr, "PAPI_read_counters - FAILED\n");
            exit(1);
        }
        perfprint(perfvalues1, "short");
        perfprint(perfvalues2, "long");
    }
    return 0;
}
