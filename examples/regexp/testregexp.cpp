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
#include <assert.h>
//#include <iostream>
//#include <fstream>
//#include <sys/stat.h>
#include "dmaManager.h"
#include "RegexpIndication.h"
#include "RegexpRequest.h"
#include "regexp_utils.h"

int main(int argc, const char **argv)
{
  fprintf(stderr, "%s %s\n", __DATE__, __TIME__);
  const char *charMapFilename = "../jregexp.charMap";
  const char *stateMapFilename = "../jregexp.stateMap";
  const char *stateTransitionsFilename = "../jregexp.stateTransitions";
  const char *testFilename = "../test.bin";
  if (argc >= 4) {
    charMapFilename = argv[1];
    stateMapFilename = argv[2];
    stateTransitionsFilename = argv[3];
    testFilename = argv[4];
  }
  fprintf(stderr, "Using charMap %s stateMap %s stateTransitions %s test %s\n",
	  charMapFilename, stateMapFilename, stateTransitionsFilename, testFilename);

  RegexpRequestProxy *device = new RegexpRequestProxy(IfcNames_RegexpRequestS2H);
  DmaManager *hostDma = platformInit();
  RegexpIndication *deviceIndication = new RegexpIndication(IfcNames_RegexpIndicationH2S);
  
  haystack_dma = hostDma;
  //haystack_mmu = hostMMURequest;
  regexp = device;

  if(sem_init(&test_sem, 1, 0)){
    fprintf(stderr, "failed to init test_sem\n");
    return -1;
  }

  // this is hard-coded into the REParser.java
  assert(32 == MAX_NUM_STATES);
  assert(32 == MAX_NUM_CHARS);

  if(1){
    P charMapP;
    P stateMapP;
    P stateTransitionsP;
    
    readfile(charMapFilename, &charMapP);
    readfile(stateMapFilename, &stateMapP);
    readfile(stateTransitionsFilename, &stateTransitionsP);

    portalCacheFlush(charMapP.alloc, charMapP.mem, charMapP.length, 1);
    portalCacheFlush(stateMapP.alloc, stateMapP.mem, stateMapP.length, 1);
    portalCacheFlush(stateTransitionsP.alloc, stateTransitionsP.mem, stateTransitionsP.length, 1);

    for(int i = 0; i < num_tests; i++){
      device->setup(charMapP.ref, charMapP.length);
      device->setup(stateMapP.ref, stateMapP.length);
      device->setup(stateTransitionsP.ref, stateTransitionsP.length);

      readfile(testFilename, &haystackP[i]);
      portalCacheFlush(haystackP[i].alloc, haystackP[i].mem, haystackP[i].length, 1);

      if(i==0)
	sw_match_cnt = num_tests*sw_ref(&haystackP[0], &charMapP, &stateMapP, &stateTransitionsP);

      sem_wait(&test_sem);
      int token = deviceIndication->token;

      assert(token < max_num_tokens);
      token_map[token] = i;
      // Regexp uses a data-bus width of 8 bytes.  length must be a multiple of this dimension
      device->search(token, haystackP[i].ref, haystackP[i].length & ~((1<<3)-1));
    }

    sem_wait(&test_sem);
    close(charMapP.alloc);
    close(stateMapP.alloc);
    close(stateTransitionsP.alloc);
  }
  fprintf(stderr, " testregexp: Done, hw_match_cnt=%d, sw_match_cnt=%d\n", hw_match_cnt, sw_match_cnt);
  sleep(1);
  return (hw_match_cnt == sw_match_cnt ? 0 : -1);
}
